/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class CartUploadController {

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getInfo(String userId, String effectiveAccountId, String communityId, String webstoreId) {

        System.debug('effectiveAccountId: ' + effectiveAccountId);

        Map<String, Object> responseMap = new Map<String, Object>();

        if(webstoreId == null) {
            webstoreId = resolveCommunityIdToWebstoreId(communityId);
        }

        String cartId = null;
        
        if(Test.isRunningTest() == false) {
            // Call the Connect Apex API

            if(effectiveAccountId != null && effectiveAccountId != '000000000000000'){
                ConnectApi.CartSummary cart = ConnectApi.CommerceCart.getOrCreateActiveCartSummary(webstoreId, effectiveAccountId, 'active');
                cartId = cart.cartId;
            }

        }

        responseMap.put('cartId', cartId);
        responseMap.put('webstoreId', webstoreId);

        responseMap.put('maxUploadRows', B2BAddToCartUtil.MAX_UPLOAD_ROWS);

        return responseMap;

    }

    @AuraEnabled
    public static Map<String, Object> processData(
        String userId, 
        List<String> rows, 
        String webstoreId, 
        String effectiveAccountId, 
        String cartId, 
        Boolean hasHeaderRow, 
        Boolean ignoreInvalidSkus,
        Boolean emailResults) {

        System.debug('begin processData()');

        Long startTime = System.now().getTime();

        Map<String, Object> responseMap = new Map<String, Object>();

        Set<String> invalidSkuSet = new Set<String>();

        List<B2BAddToCartUtil.ImportItem> itemsList = new List<B2BAddToCartUtil.ImportItem>();

        System.debug('userId: ' + userId);
        System.debug('webstoreId: ' + webstoreId);
        System.debug('effectiveAccountId: ' + effectiveAccountId);
        System.debug('cartId: ' + cartId);
        System.debug('hasHeaderRow: ' + hasHeaderRow);
        System.debug('ignoreInvalidSkus: ' + ignoreInvalidSkus);
        System.debug('emailResults: ' + emailResults);

        //Savepoint sp = Database.setSavepoint();

        try {

            String activeCartOrId = cartId;

            List<ConnectApi.CartItemInput> linesToAdd = new List<ConnectApi.CartItemInput>();

            List<ConnectApi.BatchInput> batchInputList = new List<ConnectApi.BatchInput>();

            ConnectApi.BatchResult[] batchResults = null;

            itemsList = createItemList(rows, hasHeaderRow);

            System.debug('itemsList size = ' + itemsList.size());

            if (itemsList.size() > B2BAddToCartUtil.MAX_UPLOAD_ROWS) {

                System.debug('Too many rows error');

                B2BAddToCartUtil.addMessage(new B2BAddToCartUtil.Message(
                    Label.B2B_Cart_Upload_Processing_Error, 
                    Label.B2B_CU_Max_Upload_Rows_Exceeded.replace('{0}', B2BAddToCartUtil.MAX_UPLOAD_ROWS.format()), 
                    B2BAddToCartUtil.ERROR), 
                    0, responseMap);

                    B2BAddToCartUtil.updateResponseMapTotalValue('totErrors', 1, responseMap);

                throw new CustomException('Too many rows');

            }

            invalidSkuSet = verifySkus(itemsList, responseMap, webstoreId, effectiveAccountId);

            System.debug('invalidSkuSet size = ' + invalidSkuSet.size());

            if (invalidSkuSet.size() > 0) {

                // Invalid SKUs aren't included in subsequent processing, so totErrors is updated here.
                B2BAddToCartUtil.updateResponseMapTotalValue('totErrors', invalidSkuSet.size(), responseMap);

                processInvalidSkus(itemsList, responseMap, ignoreInvalidSkus);

                if (ignoreInvalidSkus == false) {

                    B2BAddToCartUtil.addMessage(new B2BAddToCartUtil.Message(
                        Label.B2B_CU_Invalid_SKUs_found, 
                        Label.B2B_CU_Please_correct_the_invalid_SKUs_and_resubmit, 
                        B2BAddToCartUtil.ERROR), 
                        0, responseMap);

                    throw new CustomException('Invalid SKUs');

                }

            }

            linesToAdd = createCartItems(itemsList, responseMap);

            System.debug('linesToAdd size = ' + linesToAdd.size());

            batchInputList = createBatchInputLines(linesToAdd, responseMap);

            System.debug('batchInputList size = ' + batchInputList.size());

            if(batchInputList.size() <= B2BAddToCartUtil.ADD_TO_CART_MAX) {

                if(Test.isRunningTest() == false) {

                    // This will only work if there are less than 100 items in the input file.
                    // If the cart will contain more than 500 items, an error will be thrown.
                    batchResults = B2BAddToCartUtil.addItemsToCart(webstoreId, effectiveAccountId, activeCartOrId, batchInputList);

                    System.debug('batchResults: ' + JSON.serialize(batchResults));

                    System.debug('batchResults size = ' + batchResults.size());

                    B2BAddToCartUtil.processBatchResults(batchResults, itemsList, responseMap);

                    responseMap.put('totItems', batchInputList.size());
                }
                else {

                    B2BAddToCartUtil.processBatchResults(batchResults, itemsList, responseMap);

                    // Pretend we called the Connect Api
                    responseMap.put('totItems', linesToAdd.size());
                }

            }
            else {

                List<B2BAddToCartUtil.ImportItem> processedItemsList = addItemsToCartInBatches(webstoreId, effectiveAccountId, activeCartOrId, batchInputList, itemsList, responseMap);
                itemsList = processedItemsList;
                
            }

            Integer totErrors = (Integer)responseMap.get('totErrors');
            if(totErrors > 0) {
                processAddToCartErrors(itemsList, responseMap);
            }

        }
        catch (CustomException ce) {}
        catch (Exception err) {

            //System.debug('rolling back transactions');
            //Database.rollback(sp);

            System.debug(Label.B2B_Cart_Upload_Processing_Error + ': ' + err.getMessage());
            System.debug('Line #: ' + err.getLineNumber());
            System.debug(err.getStackTraceString());

            B2BAddToCartUtil.addMessage(new B2BAddToCartUtil.Message(
                    Label.B2B_Cart_Upload_Processing_Error, 
                    err.getMessage(), 
                    B2BAddToCartUtil.ERROR), 
                    0, responseMap);

            B2BAddToCartUtil.updateResponseMapTotalValue('totErrors', 1, responseMap);

        } finally {
                
            Integer totErrors = (Integer)responseMap.get('totErrors');
            Integer totSuccess = (Integer)responseMap.get('totSuccess');

            if(totErrors > 0) {

                B2BAddToCartUtil.addMessage(new B2BAddToCartUtil.Message(
                    Label.B2B_Cart_Upload_Processing_Error, 
                    Label.B2B_Items_not_added_to_cart.replace('{0}', totErrors.format()), 
                    B2BAddToCartUtil.ERROR,
                    true), 
                    0, responseMap);

            }

            if(totSuccess > 0) {

                B2BAddToCartUtil.addMessage(new B2BAddToCartUtil.Message(
                    Label.B2B_Add_to_cart_processing_complete, 
                    Label.B2B_Items_added_to_cart_successfully.replace('{0}', totSuccess.format()), 
                    B2BAddToCartUtil.SUCCESS,
                    true), 
                    0, responseMap);
            }

            List<B2BAddToCartUtil.Message> retMessages = (List<B2BAddToCartUtil.Message>)responseMap.get('messages');

            String messagesJson = JSON.serialize(retMessages);
            System.debug('messagesJson: ' + messagesJson);
            responseMap.put('messagesJson', messagesJson);

            if(emailResults) {
                sendEmailSummary(itemsList, responseMap, userId);
            }

            Long endTime = System.now().getTime();

            Long milliseconds = endTime - startTime;
            Long seconds = milliseconds / 1000;
            Long minutes = seconds / 60;
            Long hours = minutes / 60;
            Long days = hours / 24;

            System.debug('execution time: ' + (days > 0 ? days + ' days, ' : '') + (hours > 0 ? hours + ' hours, ' : '') + (minutes > 0 ? minutes + ' minutes, ' : '') + (seconds > 0 ? seconds + ' seconds, ' : '') + milliseconds + ' milliseconds');


            System.debug('--- processData() exit');
        }

        return responseMap;

    }

    /*
        Process each line uploaded by the user.
        Creates an ImportItem object for each line.
        Returns a list of ImportItem objects.
    */
    private static List<B2BAddToCartUtil.ImportItem> createItemList(List<String> lines, Boolean hasHeaderRow) {

        System.debug('--- createItemList() begin');

        List<B2BAddToCartUtil.ImportItem> itemsList = new List<B2BAddToCartUtil.ImportItem>();

        Map<String, B2BAddToCartUtil.ImportItem> skuMap = new Map<String, B2BAddToCartUtil.ImportItem>();

        // Only skip the first row when hasHeaderRow is true
        boolean isFirst = hasHeaderRow ? true : false;

        Integer row = 0;

        for (String singleLine : lines) {

            row++;

            //System.debug('Parsing line: ' + singleLine);

            if(singleLine.length() <= 0) {
                continue;
            }

            // Skip the header row

            if (isFirst) {
                isFirst = false;
                continue;
            }

            List<String> values = singleLine.split(',');
            //System.debug('values-----' + values);

            if (values[0] != null) {

                String sku = values[0];

                Decimal qty;

                if (values.size() == 1 || String.isEmpty(values[1]) || String.isBlank(values[1])) {
                    qty = 1;
                } else {
                    qty = Decimal.valueOf(values[1].trim());
                }

                B2BAddToCartUtil.ImportItem item = null;

                if(skuMap.containsKey(sku)) {
                    item = skuMap.get(sku);
                    item.qty += qty;
                }
                else {
                    item = new B2BAddToCartUtil.ImportItem();
                    item.row = row;
                    item.sku = sku;
                    item.qty = qty;
                }

                skuMap.put(sku, item);

            }
            
        }

        itemsList.addAll(skuMap.values());

        System.debug(JSON.serialize(itemsList));

        return itemsList;

    }

    /*
        Verifies that each SKU in the input is contained in the product search index.
        This does not take into account data changes within the org that have not yet been reflected in the product search index.
    */
    private static Set<String> verifySkus(List<B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap, String webstoreId, String effectiveAccountId) {

        System.debug('--- verifySkus() begin');

        List<String> skuList = new List<String>();
        Set<String> invalidSkuSet = new Set<String>();

        Map<String, Object> fetchInputData = new Map<String, Object>();

        // Get all SKUs from the items List

        for(B2BAddToCartUtil.ImportItem item : itemsList) {
            skuList.add(item.sku);
        }

        System.debug('skus: ' + skuList);

        System.debug('verifying product SKUs...');

        Map<String, String> validSkuMap = B2BProductEntitlementCheck.productSearch(skuList, webstoreId, effectiveAccountId, 50);

        Set<String> validSkuSet = new Set<String>();

        // Verify each SKU in the item List has a matching Product2 record.

        for(B2BAddToCartUtil.ImportItem item : itemsList) {
            String sku = item.sku;

            if(validSkuMap.containsKey(sku)) {

                item.isValid = true;
                item.productId = validSkuMap.get(sku);
            }
            else {
                invalidSkuSet.add(sku);

                String msg = 'Invalid SKU: ' + sku;

                System.debug(msg);

                item.isSuccess = false;
                item.errorMsg = 'SKU is not valid';
            }
        }

        responseMap.put('totUniqueSkus', validSkuMap.size());
        responseMap.put('totInvalidSkus', invalidSkuSet.size());

        System.debug('--- verifySkus() exit');

        return invalidSkuSet;

    }

    private static void processInvalidSkus(List<B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap, Boolean ignoreInvalidSkus) {
        
        for(B2BAddToCartUtil.ImportItem item : itemsList) {
            
            if(item.isValid == false) {

                String sku = item.sku;

                String msg = Label.B2B_Invalid_SKU + ' ' + sku;

                B2BAddToCartUtil.addMessage(new B2BAddToCartUtil.Message(
                    Label.B2B_SKU_is_not_valid, 
                    msg, 
                    (ignoreInvalidSkus ? B2BAddToCartUtil.WARN : B2BAddToCartUtil.ERROR),
                    false), 
                    0, responseMap);
            }
            
        }

    }

    private static void processAddToCartErrors(List<B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap) {
        
        for(B2BAddToCartUtil.ImportItem item : itemsList) {
        
            // Only add an error message when the SKU was valid.
            
            if(item.isValid && item.isSuccess == false) {

                B2BAddToCartUtil.addMessage(new B2BAddToCartUtil.Message(
                    Label.B2B_Add_to_cart_error, 
                    item.sku + ': ' + item.errorMsg, 
                    B2BAddToCartUtil.ERROR,
                    false), 
                    0, responseMap);
            }
            
        }

    }

    /*
        Creates a CartItemInput object for each item.
    */
    private static List<ConnectApi.CartItemInput> createCartItems(List<B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap) {

        System.debug('--- createCartItems() begin');

        List<ConnectApi.CartItemInput> linesToAdd = new List<ConnectApi.CartItemInput>();

        for (B2BAddToCartUtil.ImportItem item : itemsList) {

            //System.debug('item: ' + item);

            if(item.isValid) {
            
                ConnectApi.CartItemInput lineToAdd = new ConnectApi.CartItemInput();

                lineToAdd.productId = item.productId;
                lineToAdd.quantity = item.qty.toPlainString();
                lineToAdd.type = ConnectApi.CartItemType.Product;

                //System.debug('lineToAdd: ' + lineToAdd);

                linesToAdd.add(lineToAdd);

            }
            
        }

        //System.debug('size = ' + linesToAdd.size());

        System.debug('--- createCartItems() exit');        

        return linesToAdd;

    }

    /*
        Creates a BatchInput object for each CartInputItem.
        Returns a list of BatchInput objects.
    */
    private static List<ConnectApi.BatchInput> createBatchInputLines(List<ConnectApi.CartItemInput> linesToAdd, Map<String, Object> responseMap) {

        System.debug('--- createBatchInputLines() begin');

        List<ConnectApi.BatchInput> batchInputList = new List<ConnectApi.BatchInput>();

        for (ConnectApi.CartItemInput item : linesToAdd) {
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(item);
            batchInputList.add(batchInput);
        }

        System.debug('batchInputList.size: ' + batchInputList.size());

        System.debug('--- createBatchInputLines() exit');

        return batchInputList;

    }

    /*
        Adds the items to the cart synchronously, in bundles of 100 items.
    */
    private static List<B2BAddToCartUtil.ImportItem> addItemsToCartInBatches(String webstoreId, String effectiveAccountId, String activeCartOrId, List<ConnectApi.BatchInput> batchInputList, List<B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap) {

        List<B2BAddToCartUtil.ImportItem> processedItemsList = B2BAddToCartUtil.processBatchInputItems(webstoreId, effectiveAccountId, activeCartOrId, batchInputList, itemsList, responseMap);

        Integer totBatches = (Integer)responseMap.get('totBatches');

        responseMap.put('batchCount', totBatches);

        return processedItemsList;

    }

    private static void sendEmailSummary(List<B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap, String userId) {

        String emailBody = '';

        Integer totErr = 0;
        Integer totProc = itemsList.size();

        List<B2BAddToCartUtil.Message> messages = (List<B2BAddToCartUtil.Message>)responseMap.get('messages');

        for(B2BAddToCartUtil.Message msg : messages) {
            emailBody += '<p>' + msg.message + '</p>';
        }

        String subject = Label.B2B_Add_to_cart_subject;

        String emailAddress = B2BAddToCartUtil.getUserEmailAddress(userId);

        B2BAddToCartUtil.sendEmailMsg(subject, emailBody, emailAddress);

    }

    /*
        This method is used to convert the community Id to the web store Id.
    */
    public static String resolveCommunityIdToWebstoreId(String communityId) {
        if(communityId == null || communityId == '') {
            return null;
        }
        
        String webstoreId = null;

        if(Schema.sObjectType.WebStoreNetwork.fields.WebStoreId.isAccessible()
            && Schema.sObjectType.WebStoreNetwork.fields.NetworkId.isAccessible()) {
            List<WebStoreNetwork> wsnList = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId];

            if(wsnList.size() > 0) {
                WebStoreNetwork wsn = wsnList.get(0);
                webstoreId = wsn.WebStoreId;
            }
        }

        return webstoreId;
    }

    public class CustomException extends Exception {}

}