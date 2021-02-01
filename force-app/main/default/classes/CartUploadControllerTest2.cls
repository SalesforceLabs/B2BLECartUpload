/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
@IsTest(SeeAllData=true)
public with sharing class CartUploadControllerTest2 {

    private static Id userId = null;
    private static Id accountId = null;
    private static Id storeId;
    private static Id cartId;
    private static User storeUser;
    private static Id productId;
    private static List<Product2> productList;

    private static void setupTestData(Integer numProducts) {

        System.debug('begin setupTestData()');

        accountId = B2BCartUploadTestUtils.createAccount();

        //System.debug('accountId: ' + accountId);

        Id contactId = B2BCartUploadTestUtils.createContact(accountId);
        
        // 2020-08-12 the test storefront user must be associated with a profile that has access to the store/community
        userId = B2BCartUploadTestUtils.createUser(null);

        System.debug('userId: ' + userId);

        storeUser = B2BCartUploadTestUtils.getUser(userId);

        // Need to create custom settings for just the store user, to avoid conflict when seeAllData is true.
        B2BCartUploadTestUtils.createCustomSettings('https://www.salesforce.com', userId);

        Id pricebookId = B2BCartUploadTestUtils.createPricebook();


        // CREATE PRODUCTS AND ENTITLEMENTS IN BULK

        List<String> productIdList = B2BCartUploadTestUtils.createProductsInBulk(numProducts);

        productList = B2BCartUploadTestUtils.getProducts(productIdList);

        B2BCartUploadTestUtils.createStandardPricebookEntries(productIdList);

        B2BCartUploadTestUtils.createPricebookEntries(pricebookId, productIdList);

    }

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = false
        ignoreInvalidSkus = true
        emailResults = true

        valid skus = 201
    */
    public static void testCode1() {

        System.debug('begin testCode1()');

        Boolean includeInvalidSku = true;
        Integer numProducts = 201;

        User adminUser = B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(numProducts);
        }

        Test.setMock(HttpCalloutMock.class, new B2BCartUpload_ProductSearchRestApiMock(productList));

        List<String> rows = B2BCartUploadTestUtils.createSampleInput(productList, includeInvalidSku);

        String webstoreId = storeId;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = false;
        Boolean ignoreInvalidSkus = true;
        Boolean emailResults = true;

        Map<String, Object> responseMap = null;

        Test.startTest();

        System.runAs(storeUser) {

            // Don't do any DML prior to making this call:

            responseMap = CartUploadController.processData(
                userId, 
                rows, 
                webstoreId, 
                effectiveAccountId, 
                cartId, 
                hasHeaderRow, 
                ignoreInvalidSkus,
                emailResults);

        }

        Test.stopTest();

        String successMsg = null;
        String errorMsg = null;

        System.debug('responseMap: ' + JSON.serialize(responseMap));

        String messagesJson = (String)responseMap.get('messagesJson');

        System.debug('messagesJson: ' + messagesJson);

        List<Object> messagesList = (List<Object>)JSON.deserializeUntyped(messagesJson);

        if(messagesList != null) {

            for(Object obj : messagesList) {
                Map<String, Object> messageMap = (Map<String, Object>)obj;

                String severity = (String)messageMap.get('severity');
                String message = (String)messageMap.get('message');

                if(severity == 'success') {
                    successMsg = message;
                }

                if(severity == 'error') {
                    errorMsg = message;
                }
            }

        }

        System.debug('successMsg: ' + successMsg);
        System.debug('errorMsg: ' + errorMsg);

        Integer totItems = (Integer)responseMap.get('totItems');
        Integer totErrors = (Integer)responseMap.get('totErrors');
        Integer totSuccess = (Integer)responseMap.get('totSuccess');

        System.debug('totItems: ' + totItems);
        System.debug('totErrors: ' + totErrors);
        System.debug('totSuccess: ' + totSuccess);

        System.assertEquals(1, totErrors);

    }
}