/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
@IsTest
public with sharing class B2BCartUploadTestUtils {
    
    public static User createAdminUser() {

        System.debug('inside createAdminUser()');

        User u = new User();

        u.Username = 'testb2buser1@test.com';
        u.LastName = 'TestLastName';
        u.Email = 'testb2buser1@test.com';
        u.Alias = 'test1';
        u.TimeZoneSidKey = 'America/New_York';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.ProfileId = [select id from Profile where Name = 'System Administrator'].Id;
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.EmployeeNumber = '655321';

        // Do not assign a role to the user.  If you do, this can cause issues with the scratch org you are creating the package in.

        insert u;

        return u;
    }

    public static Id createUser(Id contactId) {

        System.debug('inside createUser()');

        User u = new User();

        u.Username = 'testb2buser2@test.com';
        u.LastName = 'TestLastName';
        u.Email = 'testb2buser2@test.com';
        u.Alias = 'test2';
        u.TimeZoneSidKey = 'America/New_York';
        u.EmailEncodingKey = 'ISO-8859-1';

        u.ProfileId = [select id from Profile where Name = 'Standard User'].Id;
        
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.EmployeeNumber = '24601';
        u.ContactId = contactId;

        // Do not assign a role to the user.  If you do, this can cause issues with the scratch org you are creating the package in.

        insert u;

        return u.Id;
    }

    public static User getUser(Id userId) {
        User user = [Select Id, UserName, LastName, Email, Alias, timeZoneSidKey, EmailEncodingKey, ProfileId, LanguageLocaleKey, EmployeeNumber, ContactId from User where Id = :userId];
        
        return user;
    }

    public static void updateUserProfile(Id userId, Id profileId) {
        User user = new User(
            Id = userId
            , ProfileId = profileId
        );

        update user;
    }

    public Static Id getNetworkIdForWebStore(Id storeId) {

        List<WebStoreNetwork> wsnList = [Select NetworkId from WebStoreNetwork where WebStoreId = :storeId];

        Id networkId = null;

        if(wsnList.size() > 0) {
            WebStoreNetwork wsn = wsnList.get(0);

            networkId = wsn.NetworkId;
        }

        return networkId;

    }

    public Static Id getNetworkMemberId(Id networkId) {

        Id systemAdminProfileId = [select id from Profile where Name = 'System Administrator'].Id;

        List<NetworkMember> nmList = [Select Id, MemberId, Member.Name, Member.ProfileId, Member.Profile.Name, NetworkId from NetworkMember WHERE NetworkId = :networkId
        and Member.ProfileId != :systemAdminProfileId];

        Id networkMemberId = null;

        if(nmList.size() > 0) {
            NetworkMember nm = nmList.get(0);

            System.debug('member name: ' + nm.Member.Name);
            System.debug('member profile: ' + nm.Member.Profile.Name);

            networkMemberId = nm.MemberId;
        }

        return networkMemberId;

    }

    /*
        Exclude Permission Set Assignments that are associated with a Profile.
    */
    public static List<PermissionSetAssignment> getCommunityUserPermissions(Id userId) {

        System.debug('inside getCommunityUserPermissions()');

        List<PermissionSetAssignment> psaList = [Select Id, 
            AssigneeId, 
            PermissionSet.Name, 
            PermissionSet.Description,
            PermissionSet.Id, 
            PermissionSet.ProfileId 
            from PermissionSetAssignment 
            where AssigneeId = :userId and PermissionSet.ProfileId = null];

        for(PermissionSetAssignment psa : psaList) {

            System.debug(psa.PermissionSet.Name);

        }

        return psaList;

    }

    public static void assignPermissionsToUser(Id userId, List<PermissionSetAssignment> psaList) {

        System.debug('inside assignPermissionsToUser()');

        if(psaList.size() <= 0) {
            return;
        }

        List<PermissionSetAssignment> newPsaList = new List<PermissionSetAssignment>();

        for(PermissionSetAssignment psa : psaList) {

            // Don't assign permission sets that are associted with a profile
            if(psa.PermissionSet.ProfileId != null) {
                PermissionSetAssignment newPsa = new PermissionSetAssignment();
                newPsa.AssigneeId = userId;
                newPsa.PermissionSetId = psa.PermissionSetId;

                newPsaList.add(newPsa);
            }
        }

        if(psaList.size() > 0) {
            insert newPsaList;
        }

    }

    public static Id createAccount() {

        System.debug('inside createAccount()');

        Account account = new Account();

        account.Name = 'Ohana, LLC';
        account.Type = 'Customer';
        account.Phone = '1-313-555-1212';
        account.Website = 'https://detroit.org';

        insert account;

        return account.Id;
    }

    public static List<Account> getAccount(Id accountId) {
        return [Select Id, Name, IsBuyer from Account where Id = :accountId];
    }

    public static Account getSingleAccount(Id accountId) {
        Account account = [Select Id, Name from Account where Id = :accountId];

        return account;
    }

    public static void updateAccount(Id accountId) {

        System.debug('inside createAccount()');

        Account account = new Account();

        account.Id = accountId;

        update account;
    }

    public static Id createContact(Id accountId) {

        System.debug('inside createContact()');

        Contact contact = new Contact();

        contact.AccountId = accountId;
        contact.FirstName = 'Chris';
        contact.LastName = 'Cloud';
        contact.Phone = '911';
        contact.Email = 'testuser655321@test.salesforce.com';

        insert contact;

        return contact.Id;
    }

    public static void assignPermissionSetToUser(Id userId, String permissionSetName) {

        System.debug('inside assignPermissionSetToUser()');

        PermissionSet perm = [Select Id, Name from PermissionSet where Name = :permissionSetName];

        PermissionSetAssignment psa = new PermissionSetAssignment (
            PermissionSetId = perm.Id, AssigneeId = userId
        );

        insert psa;
    }

    public static Id createPricebook() {

        Pricebook2 pb = new Pricebook2(
            IsActive = true
            , Description = 'Default price book'
            , Name = 'Standard Price Book ' + getGuid()
        );

        insert pb;

        return pb.Id;
    }

    public static Id createWebStore(Id pricebookId) {

        WebStore store = new WebStore(
            DefaultLanguage = 'en_US'
            , Description = 'Test B2B LE Storefront'
            , MaxValuesPerFacet = 100
            , StrikethroughPricebookId = pricebookId
            , PricingStrategy = 'LowestPrice'
            , PaginationSize = 20
            , Name = 'Detroit Coffee'
            , SupportedLanguages = 'es;en_US'
            
        );

        insert store;
        
        return store.Id;

    }

    public static Id getWebStoreId() {

        WebStore store = null;
        Id webStoreId = null;

        List<WebStore> webStoreList = [Select Id, Name, Description from WebStore];

        if(webStoreList.size() > 0) {
            store = webStoreList.get(0);
            webStoreId = store.Id;
        }

        return webStoreId;

    }

    public static Id getWebStoreId(String storeName) {

        WebStore store = null;
        Id webStoreId = null;

        List<WebStore> webStoreList = [Select Id, Name, Description from WebStore where Name = :storeName];

        if(webStoreList.size() > 0) {
            store = webStoreList.get(0);
            webStoreId = store.Id;
        }

        return webStoreId;

    }

    public static Id createWebStorePricebook(Id storeId, Id pricebookId) {

        WebStorePricebook wspb = new WebStorePricebook(
            IsActive = true
            , Pricebook2Id = pricebookId
            , WebStoreId = storeId
        );

        insert wspb;

        return wspb.Id;

    }

    public static Id createBuyerGroup() {
        BuyerGroup bg = new BuyerGroup(
            Name = 'Store Buyer Group'
            , Description = 'Default buyer group'
        );

        insert bg;

        return bg.Id;
    }

    public static List<BuyerGroup> getBuyerGroup(Id buyerGroupId) {
        return [Select Id, Name, Description from BuyerGroup where Id = :buyerGroupId];
    }

    public Static Id createBuyerAccount(Id accountId) {

        Account account = getSingleAccount(accountId);

        BuyerAccount ba = new BuyerAccount(
            IsActive = true
            , BuyerId = accountId
            , Name = account.Name
            , BuyerStatus = 'Active'
            , CommerceType = 'Buyer'
        );

        insert ba;

        return ba.Id;
    }

    public static List<BuyerAccount> getBuyerAccount(Id buyerAccountId) {
        return [Select Id, Name, IsActive, BuyerId, BuyerStatus, CommerceType from BuyerAccount where Id = :buyerAccountId];
    }

    public static Id createBuyerGroupMember(Id accountId, Id buyerGroupId) {

        BuyerGroupMember bgm = new BuyerGroupMember(
            BuyerId = accountId
            , BuyerGroupId = buyerGroupId
            );

        insert bgm;

        return bgm.Id;
    }

    public static List<BuyerGroupMember> getBuyerGroupMembers(Id buyerGroupMemberId) {

        return [Select Id, BuyerId, BuyerGroupId from BuyerGroupMember where Id = :buyerGroupMemberId];

    }

    public static Id createCommerceEntitlementPolicy() {

        CommerceEntitlementPolicy cep = new CommerceEntitlementPolicy(
            IsActive = true
            , Description = 'For all store users'
            , Name = 'Store policy'
            , CanViewPrice = true
            , CanViewProduct = true
        );

        insert cep;

        return cep.Id;
    }

    public static List<CommerceEntitlementPolicy> getCommerceEntitlementPolicy(Id cepId) {
        return [Select Id, IsActive, Description, Name, CanViewPrice, CanViewProduct from CommerceEntitlementPolicy where Id = :cepId];
    }

    public static Id createCommerceEntitlementBuyerGroup(Id buyerGroupId, Id commercePolicyId) {

        CommerceEntitlementBuyerGroup cebg = new CommerceEntitlementBuyerGroup(
            BuyerGroupId = buyerGroupId
            , PolicyId = commercePolicyId
        );

        insert cebg;

        return cebg.Id;
    }

    public static List<CommerceEntitlementBuyerGroup> getCommerceEntitlementBuyerGroup(Id cebgId) {
        return [Select Id, BuyerGroupId, PolicyId from CommerceEntitlementBuyerGroup where Id = :cebgId];
    }

    public static Id createWebStoreBuyerGroup(Id buyerGroupId, Id storeId) {
        WebStoreBuyerGroup wsbg = new WebStoreBuyerGroup(
            BuyerGroupId = buyerGroupId
            , WebStoreId = storeId
        );

        insert wsbg;

        return wsbg.Id;

    }

    public static List<WebStoreBuyerGroup> getWebStoreBuyerGroup(Id wsbgId) {
        return [Select Id, BuyerGroupId, WebStoreId from WebStoreBuyerGroup where Id = :wsbgId];
    }

    public static Id createProduct2(String name, String sku, String description) {
        Product2 product = new Product2(
            IsActive = true
            , Name = name
            , StockKeepingUnit = sku
            , Description = description
        );

        insert product;

        return product.Id;

    }

    public static List<Product2> getProducts(List<String> productIdList) {
        List<Product2> productList = [Select Id, Name, StockKeepingUnit from Product2 where Id in :productIdList];

        return productList;
    }

    public static Id createCommerceEntitlementProduct(Id productId, Id commercePolicyId) {
        CommerceEntitlementProduct cep = new CommerceEntitlementProduct(
            PolicyId = commercePolicyId
            , ProductId = productId
        );

        insert cep;

        return cep.Id;
    }

    public static Id createStandardPricebookEntry(Id productId) {

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            IsActive = true
            , UnitPrice = 1.98
            , Pricebook2Id = pricebookId
            , Product2Id = productId
            , UseStandardPrice = false
        );

        insert pbe;

        return pbe.Id;
    }

    public static Id createPricebookEntry(Id pricebookId, Id productId) {
        PricebookEntry pbe = new PricebookEntry(
            IsActive = true
            , UnitPrice = 1.98
            , Pricebook2Id = pricebookId
            , Product2Id = productId
        );

        insert pbe;

        return pbe.Id;
    }

    public static void createCustomSettings(String domain) {

        B2B_Cart_Upload_Settings__c cs = new B2B_Cart_Upload_Settings__c();

        cs.REST_API_Domain__c = domain;

        insert cs;
    }

    public static void createCustomSettings(String domain, String userId) {

        B2B_Cart_Upload_Settings__c cs = new B2B_Cart_Upload_Settings__c();

        cs.REST_API_Domain__c = domain;
        cs.SetupOwnerId = userId;

        insert cs;
    }

    public static Product2 createProductBatch(String name, String sku, String description) {
        Product2 product = new Product2(
            IsActive = true
            , Name = name
            , StockKeepingUnit = sku
            , Description = description
        );

        return product;

    }

    public static PricebookEntry createStandardPricebookEntryBatch(Id productId) {

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            IsActive = true
            , UnitPrice = 1.98
            , Pricebook2Id = pricebookId
            , Product2Id = productId
            , UseStandardPrice = false
        );

        return pbe;
    }

    public static PricebookEntry createPricebookEntryBatch(Id pricebookId, Id productId) {
        PricebookEntry pbe = new PricebookEntry(
            IsActive = true
            , UnitPrice = 1.98
            , Pricebook2Id = pricebookId
            , Product2Id = productId
        );

        return pbe;
    }

    // Preferred way to create a cart is using the Api.
    // Use ConnectApi.CommerceCart.createCart(storeId, cartInput) instead.
    public static Id createWebCart(Id accountId, Id storeId) {

        WebCart cart = new WebCart(
            AccountId = accountId
            , WebStoreId = storeId
            , Type = 'Cart'
            , Status = 'Active'
            , Name = 'Cart'
        );

        insert cart;

        return cart.Id;

    }

    public static List<WebCart> getWebCart(Id cartId) {

        return [Select Id, CreatedById, CreatedBy.Name, OwnerId, Owner.Name, AccountId, BillingAddress, Name, CreatedDate, GrandTotalAmount, IsRepricingNeeded,
            LastModifiedDate, LastRepricingDate, PaymentGroupId, PoNumber, Status, WebStoreId, TotalAmount, TotalChargeAmount,
            TotalChargeTaxAmount, TotalListAmount, TotalProductAmount, TotalProductTaxAmount, TotalProductCount, TotalTaxAmount, Type, UniqueProductCount 
            from WebCart where Id = :cartId];

    }

    // When the cart is created, the owner is the System Admin.
    // Change the owner of the cart to the store user.
    public static void changeWebCartOwner(Id cartId, Id userId) {
        WebCart cart = new WebCart(
            Id = cartId,
            OwnerId = userId
        );

        update cart;
    }

    // public static Id createProductCatalog() {
    //     ProductCatalog pc = new ProductCatalog(
    //         Name = 'Sample Catalog'
    //     );

    //     insert pc;

    //     return pc.Id;
    // }

    // This won't work if you're using an existing store, that already has a catalog associated with it
    // public static Id createWebStoreCatalog(Id catalogId, Id storeId) {
    //     WebStoreCatalog wc = new WebStoreCatalog(
    //         ProductCatalogId = catalogId
    //         , SalesStoreId = storeId
    //     );

    //     insert wc;

    //     return wc.Id;

    // }

    public static WebStoreCatalog getWebStoreCatalog(Id storeId) {
        List<WebStoreCatalog> webStoreCatalogList = [Select Id, ProductCatalogId, SalesStoreId from WebStoreCatalog where SalesStoreId = :storeId];

        WebStoreCatalog wsc = null;

        if(webStoreCatalogList.size() > 0) {
            wsc = webStoreCatalogList.get(0);
        }

        return wsc;
    }

    public static ProductCategory getProductCategory(Id catalogId) {
        List<ProductCategory> categoryList = [Select Id, Name, Description, IsNavigational, SortOrder from ProductCategory where CatalogId = :catalogId and ParentCategoryId = null];

        ProductCategory category = null;

        if(categoryList.size() > 0) {
            category = categoryList.get(0);
        }

        return category;
    }

    public static Id createProductCategoryProduct(Id categoryId, Id productId) {
        ProductCategoryProduct pcp = new ProductCategoryProduct(
            ProductCategoryId = categoryId
            , IsPrimaryCategory = true
            , ProductId = productId
        );

        insert pcp;

        return pcp.Id;
    }

    public static String getGuid() {
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        String guid = h.substring(0,8) + '-' + h.substring(8,12) + h.substring(12,16) + '-' + h.substring(16,20) + '-' + h.substring(20);

        return guid;
    }

    // BULK PRODUCT SETUP UTILITIES

    public static List<String> createProductsInBulk(Integer numProducts) {

        List<Product2> productList = new List<Product2>();

        List<String> skus = new List<String>();
        List<String> productIds = new List<String>();

        for(Integer i = 1; i <= numProducts; i++) {

            //String sku = B2BCartUploadTestUtils.getGuid();
            String sku = 'PRODUCT-' + i;

            String productName = 'Product ' + i;

            Product2 product =  B2BCartUploadTestUtils.createProductBatch(productName, sku, '');

            productList.add(product);

            skus.add(sku);

        }

        insert productList;

        for(Product2 product : productList) {
            productIds.add(product.Id);
        }

        return productIds;

    }

    public static void createCommerceEntitlementProducts(List<String> productIds, Id commercePolicyId) {

        List<CommerceEntitlementProduct> cepList = new List<CommerceEntitlementProduct>();

        for(String productId : productIds) {
            CommerceEntitlementProduct cep = new CommerceEntitlementProduct(
                PolicyId = commercePolicyId
                , ProductId = productId
            );

            cepList.add(cep);
        }

        insert cepList;

    }

    public static void createStandardPricebookEntries(List<String> productIds) {

        Id pricebookId = Test.getStandardPricebookId();

        List<PricebookEntry> pbeList = new List<PricebookEntry>();

        for(String productId : productIds) {
            PricebookEntry pbe = new PricebookEntry(
                IsActive = true
                , UnitPrice = 1.98
                , Pricebook2Id = pricebookId
                , Product2Id = productId
                , UseStandardPrice = false
            );

            pbeList.add(pbe);

        }

        insert pbeList;

    }

    public static void createPricebookEntries(Id pricebookId, List<String> productIds) {

        List<PricebookEntry> pbeList = new List<PricebookEntry>();

        for(String productId : productIds) {
            PricebookEntry pbe = new PricebookEntry(
                IsActive = true
                , UnitPrice = 1.98
                , Pricebook2Id = pricebookId
                , Product2Id = productId
            );

            pbeList.add(pbe);

        }

        insert pbeList;

    }

    public static void createProductCategoryProducts(Id categoryId, List<String> productIds) {

        List<ProductCategoryProduct> pcpList = new List<ProductCategoryProduct>();

        for(String productId : productIds) {
            ProductCategoryProduct pcp = new ProductCategoryProduct(
                ProductCategoryId = categoryId
                , IsPrimaryCategory = true
                , ProductId = productId
            );

            pcpList.add(pcp);

        }

        insert pcpList;

    }

    public static List<String> createSampleInput(List<Product2> productList, Boolean includeInvalidSku) {

        List<String> rows = new List<String>();

        for(Product2 product : productList) {
            rows.add(product.StockKeepingUnit + ',1');  // This is a valid SKU

        }

        if(includeInvalidSku) {
            rows.add('111000AAA999,2');  // This is an invalid SKU
        }

        return rows;

    }

}