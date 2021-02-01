/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
/*
    Lessons learned:
        Must use an existing WebStore, as only that will be associated to an community.
        The test user must be assigned to a profile that is associated with the store/community.
        The preferred way to create a cart is using the Api.
            You cannot do DML before doing an HTTP callout.
            Create the cart using the API as the system admin
            Then change the owner to the store user as the system admin.
            Then add items to the cart as the store user.

        ConnectApi.ConnectApiException: Argument: account '001B000001LC89B' does not belong to webstore '0ZEB00000008Q2e
            Make sure the test store user has access to the store.  The profile associated with the user must be included as a community member.
*/
@IsTest
public with sharing class CartUploadControllerTest {

    private static Id userId = null;
    private static Id accountId = null;
    private static Id storeId;
    private static Id cartId;
    private static User storeUser;
    private static Id productId;
    private static List<Product2> productList;

    private static void setupTestData(Boolean createProducts) {

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

        
        if(createProducts) {
            
            productId =  B2BCartUploadTestUtils.createProduct2('Sample Product', '999AAA000111', '');

                System.debug('productId: ' + productId);

            List<String> productIdList = new List<String>();
            productIdList.add(productId);

            productList = B2BCartUploadTestUtils.getProducts(productIdList);

            B2BCartUploadTestUtils.createStandardPricebookEntry(productId);

            B2BCartUploadTestUtils.createPricebookEntry(pricebookId, productId);

        }

    }

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = false
        ignoreInvalidSkus = true
        emailResults = true
    */
    public static void testCode1() {

        System.debug('begin testCode1()');

        User adminUser = B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        B2B_Cart_Upload_Settings__c cs = B2B_Cart_Upload_Settings__c.getOrgDefaults();

        System.debug('cs: ' + cs);

        Test.setMock(HttpCalloutMock.class, new B2BCartUpload_ProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('999AAA000111,1');  // This is a valid SKU
        rows.add('111000AAA999,2');  // This is an invalid SKU

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

        System.assertEquals(1, totItems);

    }

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = true
        ignoreInvalidSkus = false
        emailResults = false
    */
    public static void testCode2() {

        System.debug('begin testCode2()');

        User adminUser = B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        B2B_Cart_Upload_Settings__c cs = B2B_Cart_Upload_Settings__c.getOrgDefaults();

        System.debug('cs: ' + cs);

        Test.setMock(HttpCalloutMock.class, new B2BCartUpload_ProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('SKU,QTY');  // This is the header row
        rows.add('999AAA000111,1');  // This is a valid SKU
        rows.add('111000AAA999,2');  // This is an invalid SKU

        String webstoreId = storeId;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = true;
        Boolean ignoreInvalidSkus = false;
        Boolean emailResults = false;

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

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = true
        ignoreInvalidSkus = false
        emailResults = false

        Handle some corner cases:
            Duplicate SKUs in the input
            Empty line in the input
            No qty supplied in the input
    */
    public static void testCode3() {

        System.debug('begin testCode3()');

        User adminUser = B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        B2B_Cart_Upload_Settings__c cs = B2B_Cart_Upload_Settings__c.getOrgDefaults();

        System.debug('cs: ' + cs);

        Test.setMock(HttpCalloutMock.class, new B2BCartUpload_ProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('SKU,QTY');  // This is the header row
        rows.add('999AAA000111,1');  // This is a valid SKU
        rows.add('999AAA000111,1');  // Duplicate valid SKU
        rows.add('999AAA000111');  // No qty supplied
        rows.add('');  // Empty line
        rows.add('111000AAA999,2');  // This is an invalid SKU

        String webstoreId = storeId;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = true;
        Boolean ignoreInvalidSkus = false;
        Boolean emailResults = false;

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

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = true
        ignoreInvalidSkus = false
        emailResults = false

        Handle some corner cases:
            Too many rows
    */
    public static void testCode4() {

        System.debug('begin testCode4()');

        User adminUser = B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        B2B_Cart_Upload_Settings__c cs = B2B_Cart_Upload_Settings__c.getOrgDefaults();

        System.debug('cs: ' + cs);

        Test.setMock(HttpCalloutMock.class, new B2BCartUpload_ProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('SKU,QTY');  // This is the header row
        rows.add('999AAA000111,1');  // This is a valid SKU

        // Add more than the max allowed in the code
        for(Integer i = 0; i < B2BAddToCartUtil.MAX_UPLOAD_ROWS; i++) {
            rows.add('PROD-' + i + ',1');  // This is a dummy SKU
        }

        String webstoreId = storeId;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = true;
        Boolean ignoreInvalidSkus = false;
        Boolean emailResults = false;

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

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = true
        ignoreInvalidSkus = false
        emailResults = false

        Handle some corner cases:
            Throw an Exception by supplying an invalid qty value
    */
    public static void testCode5() {

        System.debug('begin testCode5()');

        User adminUser = B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(true);
        }

        B2B_Cart_Upload_Settings__c cs = B2B_Cart_Upload_Settings__c.getOrgDefaults();

        System.debug('cs: ' + cs);

        Test.setMock(HttpCalloutMock.class, new B2BCartUpload_ProductSearchRestApiMock(productList));

        List<String> rows = new List<String>();
        rows.add('SKU,QTY');  // This is the header row
        rows.add('999AAA000111,ABCDEFG');  // This is a valid SKU

        String webstoreId = storeId;
        String effectiveAccountId = accountId;
        Boolean hasHeaderRow = true;
        Boolean ignoreInvalidSkus = false;
        Boolean emailResults = false;

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

    @IsTest
    /*
        one valid SKU, one invalid SKU
        hasHeaderRow = true
        ignoreInvalidSkus = false
        emailResults = false
    */
    public static void testGetInfo() {

        System.debug('begin testGetInfo()');

        User adminUser = B2BCartUploadTestUtils.createAdminUser();

        System.runAs(adminUser) {
            setupTestData(false);
        }

        Map<String, Object> responseMap = null;

        Test.startTest();

        System.runAs(storeUser) {

            // Don't do any DML prior to making this call:

            responseMap = CartUploadController.getInfo(userId, accountId, null, storeId);

        }

        Test.stopTest();

        System.debug('responseMap: ' + JSON.serialize(responseMap));

        Integer maxUploadRows = (Integer)responseMap.get('maxUploadRows');

        System.assertEquals(B2BAddToCartUtil.MAX_UPLOAD_ROWS, maxUploadRows);

    }
    
}