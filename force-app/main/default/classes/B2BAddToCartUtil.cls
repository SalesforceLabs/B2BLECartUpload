/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class B2BAddToCartUtil {

    public static final Integer ADD_TO_CART_MAX = 100;
    public static final Integer CART_ITEM_MAX = 500;
    public static final Integer MAX_UPLOAD_ROWS = 500;

    /*
        Adds items to the cart in batches of 100.
        The cart adds are done synchronously.
    */
    public static List<B2BAddToCartUtil.ImportItem> processBatchInputItems(String webstoreId, String effectiveAccountId, String activeCartOrId, List<ConnectApi.BatchInput> batchInputList, List<B2BAddToCartUtil.ImportItem> itemsList, Map<String, Object> responseMap) {

        List<ConnectApi.BatchInput> tempBatchList = new List<ConnectApi.BatchInput>();

        List<B2BAddToCartUtil.ImportItem> tempItemsList = new List<B2BAddToCartUtil.ImportItem>();

        List<B2BAddToCartUtil.ImportItem> processedItemsList = new List<B2BAddToCartUtil.ImportItem>();

        Integer count = 0;
        Integer totBatches = 0;
        Integer totItems = 0;

        for(ConnectApi.BatchInput bi : batchInputList) {

            tempBatchList.add(bi);

            B2BAddToCartUtil.ImportItem importItem = itemsList.get(count);

            tempItemsList.add(importItem);

            count++;

            totItems++;

            if(count == ADD_TO_CART_MAX) {

                totBatches++;

                addBatchToCart(webstoreId, effectiveAccountId, activeCartOrId, tempBatchList, tempItemsList, totBatches, responseMap);

                processedItemsList.addAll(tempItemsList);

                count = 0;

                tempBatchList = new List<ConnectApi.BatchInput>();

                tempItemsList = new List<B2BAddToCartUtil.ImportItem>();

            }

        }

        if(tempBatchList.size() > 0) {

            totBatches++;

            addBatchToCart(webstoreId, effectiveAccountId, activeCartOrId, tempBatchList, tempItemsList, totBatches, responseMap);

            processedItemsList.addAll(tempItemsList);

        }

        responseMap.put('batchCount', totBatches);

        if(responseMap.containsKey('totItems')) {
            Integer tempTotItems = (Integer)responseMap.get('totItems');
            tempTotItems += totItems;
            responseMap.put('totItems', tempTotItems);
        }
        else {
            responseMap.put('totItems', totItems);
        }

        return processedItemsList;

    }

    /*
        Adds a batch of 100 or less items to the cart.
    */
    public static void addBatchToCart(String webstoreId, String effectiveAccountId, String activeCartOrId, List<ConnectApi.BatchInput> batchInputList, List<B2BAddToCartUtil.ImportItem> itemsList, Integer batchCount, Map<String, Object> responseMap) {

        ConnectApi.BatchResult[] batchResults = null;

        if(Test.isRunningTest() == false) {
            batchResults = B2BAddToCartUtil.addItemsToCart(webstoreId, effectiveAccountId, activeCartOrId, batchInputList);
        }

        B2BAddToCartUtil.processBatchResults(batchResults, itemsList, responseMap);

    }
    
    public static ConnectApi.BatchResult[] addItemsToCart(String webstoreId, String effectiveAccountId, String activeCartOrId, List<ConnectApi.BatchInput> batchInputList) {

        System.debug('--- addItemsToCart() begin');

        System.debug('batchInputList size = ' + batchInputList.size());

        ConnectApi.BatchResult[] batchResults = ConnectApi.CommerceCart.addItemsToCart(webstoreId, effectiveAccountId, activeCartOrId, batchInputList);

        System.debug('batchResults size = ' + batchResults.size());

        System.debug('--- addItemsToCart() exit');

        return batchResults;
    }

    public static void processBatchResults(ConnectApi.BatchResult[] batchResults, List<ImportItem> itemsList, Map<String, Object> responseMap) {

        System.debug('--- processBatchResults() begin');

        Integer i = 0;
        Integer totErrors = 0;
        Integer totSuccess = 0;

        if(batchResults != null) {

            for(ConnectApi.BatchResult batchResult : batchResults) {

                System.debug('batchResult: ' + JSON.serialize(batchResult));

                ImportItem importItem = itemsList.get(i);

                ConnectApi.CartItem cartItem;

                if(batchResult.getResult() instanceof ConnectApi.CartItem) {
                    cartItem = (ConnectApi.CartItem)batchResult.getResult();
                }

                if(cartItem != null) {

                    System.debug('cartItem: ' + JSON.serialize(cartItem));

                    if(batchResult.isSuccess == false) {

                        importItem.isSuccess = batchResult.isSuccess;
                        importItem.errorMsg = batchResult.getErrorMessage();

                        totErrors++;

                        System.debug('Error adding product ' + importItem.sku + ': ' + batchResult.getErrorMessage());
                    }
                    else {
                        importItem.isSuccess = true;

                        totSuccess++;
                    }

                }
                else {

                    // Handle add to cart error
                    
                    if(batchResult.isSuccess == false) {

                        importItem.isSuccess = batchResult.isSuccess;
                        importItem.errorMsg = batchResult.getErrorMessage();

                        totErrors++;

                        System.debug('Error adding product ' + importItem.sku + ': ' + batchResult.getErrorMessage());
                    }

                }

                itemsList.set(i, importItem);

                i++;

            }

        }

        // Modify the itemsList to look like the batchInputList was actually sent to the ConnectApi and processed.
        if(Test.isRunningTest()) {

            for(ImportItem importItem : itemsList) {
                importItem.isSuccess = true;
                totSuccess++;
            }

        }

        System.debug('totSuccess: ' + totSuccess);
        System.debug('totErrors: ' + totErrors);

        updateResponseMapTotalValue('totSuccess', totSuccess, responseMap);

        updateResponseMapTotalValue('totErrors', totErrors, responseMap);

        System.debug('--- processBatchResults() exit');

    }

    public static void sendEmailMsg(String subject, String emailBody, String emailAddress) {

        List<Messaging.SingleEmailMessage> mails =
                new List<Messaging.SingleEmailMessage>();

        Messaging.SingleEmailMessage mail =
                new Messaging.SingleEmailMessage();

        List<String> sendTo = new List<String>();
        sendTo.add(emailAddress);
        mail.setToAddresses(sendTo);

        mail.setSubject(subject);

        mail.setHtmlBody(emailBody);

        mails.add(mail);

        Messaging.sendEmail(mails);
    }

    public static String getUserEmailAddress(String userId) {

        String emailAddress = null;

        if(Schema.sObjectType.User.fields.Id.isAccessible() 
           && Schema.sObjectType.User.fields.Name.isAccessible()
           && Schema.sObjectType.User.fields.Email.isAccessible()){
            List<User> userList = [Select Id, Name, Email from User where Id = :userId];

            User user = userList.get(0);
            emailAddress = user.Email;
        }

        return emailAddress;
    }

    public static void addMessage(Message msg, Integer pos, Map<String, Object> responseMap) {

        List<B2BAddToCartUtil.Message> retMessages = null;

        if(responseMap.containsKey('messages')) {
            retMessages = (List<B2BAddToCartUtil.Message>)responseMap.get('messages');
        }
        else {
            retMessages = new List<B2BAddToCartUtil.Message>();
        }

        if(pos == null) {
            retMessages.add(msg);
        }
        else if(retMessages.size() <= 0) {
            retMessages.add(msg);
        }
        else {
            retMessages.add(pos, msg);
        }

        responseMap.put('messages', retMessages);

    }

    public static void updateResponseMapTotalValue(String key, Integer value, Map<String, Object> responseMap) {

        if(responseMap.containsKey(key)) {
            Integer tempTot = (Integer)responseMap.get(key);
            tempTot += value;
            responseMap.put(key, tempTot);
        }
        else {
            responseMap.put(key, value);
        }

    }

    public class ImportItem {

        public String sku {get; set;}
        public Decimal qty {get; set;}
        public String productId {get; set;}
        public Boolean isValid {get; set;}

        public Integer row {get; set;}

        public Boolean isSuccess {get; set;}
        public String errorMsg {get; set;}

        public ImportItem() {
            isValid = false;
            isSuccess = false;
        }
    }

    public static final String ERROR = 'error';
    public static final String INFO = 'info';
    public static final String SUCCESS = 'success';
    public static final String WARN = 'warn';

    public class Message {

        public String severity {get; set;}
        public String title {get; set;}
        public String message {get; set;}
        public Boolean toast {get; set;}

        public Message() {
            toast = true;
        }

        public Message(String title, String message, String severity) {
            this();
            this.title = title;
            this.message = message;
            this.severity = severity;
        }

        public Message(String title, String message, String severity, Boolean toast) {
            this();
            this.title = title;
            this.message = message;
            this.severity = severity;
            this.toast = toast;
        }

    }

}