/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
@IsTest
global class B2BCartUpload_ProductSearchRestApiMock implements HttpCalloutMock {
    
    public String responseStr {get; set;}

    public B2BCartUpload_ProductSearchRestApiMock(List<Product2> productObjList) {

        Map<String, Object> responseMap = new Map<String, Object>();

        responseMap.put('hasErrors', false);

        List<Object> resultsList = new List<Object>();

        Map<String, Object> resultsMap = new Map<String, Object>();

        Map<String, Object> resultMap = new Map<String, Object>();

        resultMap.put('statusCode', 201);

        Map<String, Object> productsPageMap = new Map<String, Object>();

        productsPageMap.put('pageSize', 50);

        List<Object> productsList = new List<Object>();

        for(Product2 productObj : productObjList) {

            Map<String, Object> productMap = new Map<String, Object>();

            productMap.put('id', productObj.Id);
            productMap.put('name', productObj.Name);

            Map<String, Object> fieldsMap = new Map<String, Object>();

            Map<String, Object> fieldValueMap = new Map<String, Object>();

            fieldValueMap.put('value', productObj.StockKeepingUnit);

            fieldsMap.put('StockKeepingUnit', fieldValueMap);

            productMap.put('fields', fieldsMap);

            productsList.add(productMap);

        }

        productsPageMap.put('products', productsList);
        productsPageMap.put('total', productObjList.size());

        resultMap.put('productsPage', productsPageMap);

        resultsMap.put('result', resultMap);

        resultsList.add(resultsMap);

        responseMap.put('results', resultsList);

        responseStr = JSON.serialize(responseMap);

    }

    global HttpResponse respond(HttpRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.responseStr);
        res.setStatusCode(200);

        return res;
    }

}