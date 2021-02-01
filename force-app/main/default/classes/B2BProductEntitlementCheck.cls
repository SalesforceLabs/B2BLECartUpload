/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class B2BProductEntitlementCheck {

    private static final Integer MAX_SEARCH_TERMS = 32;
    private static final Integer MAX_SUBREQUESTS = 25;
    private static final Integer MAX_PAGE_SIZE = 50;

    public static Map<String, String> productSearch(List<String> skus, String webstoreId, String effectiveAccountId, Integer pageSize) {

        Map<String, String> validSkuMap = new Map<String, String>();

        //Make sure your Salesforce instance URL is added in remote site settings

        B2B_Cart_Upload_Settings__c cs = B2B_Cart_Upload_Settings__c.getOrgDefaults();

        String domain = cs.REST_API_Domain__c;

        System.debug('domain: ' + domain);

        String restAPIURL = '/v49.0/commerce/webstores/' + webStoreId + '/search/product-search';

        String batchRestAPIURL = domain + '/services/data/v49.0/connect/batch';

        if(effectiveAccountId != null) {
            restAPIURL += '?effectiveAccountId=' + effectiveAccountId;
        }

        System.debug('restAPIURL: ' + restAPIURL);

        Map<String, Object> batchRequest = new Map<String, Object>();

        // Process all input skus, creating one long string of them separated by spaces

        String searchTerm = '';

        for(String sku : skus) {

            if(searchTerm != '') {
                searchTerm += ' ';
            }

            searchTerm += sku;

        }

        String [] searchTermWords = searchTerm.split(' ');

        System.debug('searchTermWords size = ' + searchTermWords.size());

        // Create a batch request for each set of 32 search term words

        Integer count = 0;

        Set<String> searchTerms = new Set<String>();

        List<Object> batchRequestList = new List<Object>();

        for(String st : searchTermWords) {
            count++;

            searchTerms.add(st);

            if(searchTerms.size() == MAX_SEARCH_TERMS) {
                Map<String, Object> searchRequest = createSearchRequest(searchTerms, 'Post', restAPIURL, MAX_PAGE_SIZE);

                batchRequestList.add(searchRequest);

                searchTerms = new Set<String>();
            }

            if(batchRequestList.size() >= MAX_SUBREQUESTS) {

                String response = submitBatchrequest(batchRestAPIURL, batchRequestList);

                Map<String, String> temp = processBatchResults(response);

                validSkuMap.putAll(temp);

                batchRequestList = new List<Object>();

            }
        }

        // Process whatever search terms that remain

        if(searchTerms.size() > 0) {

            Map<String, Object> searchRequest = createSearchRequest(searchTerms, 'POST', restAPIURL, 50);
            batchRequestList.add(searchRequest);
        }

        // Process the search requests that remain

        if(batchRequestList.size() > 0) {
            String response = submitBatchrequest(batchRestAPIURL, batchRequestList);

            Map<String, String> temp = processBatchResults(response);

            validSkuMap.putAll(temp);
        }

        System.debug('validSkus: ' + JSON.serialize(validSkuMap));

        // List<String> skuList = new List<String>();
        // skuList.addAll(validSkus);

        // System.debug('skuList size: ' + skuList.size());

        return validSkuMap;

    }

    private static String submitBatchrequest(String batchRestAPIURL, List<Object> batchRequestList) {

        String response = '';

        Set<String> validSkus = new Set<String>();

        Map<String, Object> batchInput = new Map<String, Object>();

        batchInput.put('batchRequests', batchRequestList);

        HttpRequest httpRequest = new HttpRequest();  
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        httpRequest.setEndpoint(batchRestAPIURL);

        String requestBody = JSON.serialize(batchInput);

        System.debug('requestBody: ' + requestBody);

        httpRequest.setBody(requestBody);

        try {
            Http http = new Http();
            HttpResponse httpResponse = http.send(httpRequest);

            System.debug('httpResponse.getStatusCode(): ' + httpResponse.getStatusCode());

            if (httpResponse.getStatusCode() == 200 || httpResponse.getStatusCode() == 201 ) {

                //System.debug('body: ' + httpResponse.getBody());

                response = httpResponse.getBody();

            } else {
                System.debug(' httpResponse ' + httpResponse.getBody() );
                throw new CalloutException( httpResponse.getBody() );
            }
        } catch( System.Exception e) {
                System.debug('ERROR: '+ e.getMessage());
        }

        System.debug(' ** response ** : ' + response );

        return response;

    }

    private static Map<String, String> processBatchResults(String response) {

        Map<String, String> validSkuMap = new Map<String, String>();

        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);

        Boolean hasErrors = (Boolean)responseMap.get('hasErrors');

        List<Object> resultsList = (List<Object>)responseMap.get('results');

        for(Object obj : resultsList) {

            Map<String, Object> resultsMap = (Map<String, Object>)obj;

            if(hasErrors == false) {

                Map<String, Object> result = (Map<String, Object>)resultsMap.get('result');

                Map<String, Object> productsPage = (Map<String, Object>)result.get('productsPage');

                List<Object> products = (List<Object>)productsPage.get('products');

                for(Object obj2 : products) {

                    Map<String, Object> product = (Map<String, Object>)obj2;

                    String productId = (String)product.get('id');

                    Map<String, Object> fields = (Map<String, Object>)product.get('fields');

                    Map<String, Object> skuField = (Map<String, Object>)fields.get('StockKeepingUnit');

                    String sku = (String)skuField.get('value');

                    validSkuMap.put(sku, productId);
                }

            }
            else {

                List<Object> results = (List<Object>)resultsMap.get('result');

                for(Object obj3 : results) {
                    Map<String, Object> result = (Map<String, Object>)obj3;

                    String message = (String)result.get('message');

                    System.debug(message);
                }

            }

        }

        return validSkuMap;

    }

    /*
        Creates a product search batch request.
        Maximum of 32 search term words.
    */
    private static Map<String, Object> createSearchRequest(Set<String>searchTerms, String method, String url, Integer pageSize) {

        Map<String, Object> batchRequest = new Map<String, Object>();

        batchRequest.put('method', method);
        batchRequest.put('url', url);

        Map<String, Object> searchInput = new Map<String, Object>();

        String searchTerm = '';

        // Separate each serch term with a space
        for(String st : searchTerms) {

            if(searchTerm != '') {
                searchTerm += ' ';
            }

            searchTerm += st;

        }

        System.debug('searchTerm: ' + searchTerm);

        searchInput.put('searchTerm', searchTerm);
        
        List<String> fieldList = new List<String>();
        fieldList.add('StockKeepingUnit');

        searchInput.put('fields', fieldList);

        searchInput.put('page', 0);
        searchInput.put('pageSize', pageSize);

        batchRequest.put('richInput', searchInput);

        return batchRequest;

    }

}