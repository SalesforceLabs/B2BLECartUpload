/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class B2BCartUploadHelp {
    
    @AuraEnabled(cacheable=true)
    public static ConnectApi.ManagedContentVersion getContent(String communityId, String contentId, String locale, String contentType) {

        System.debug('begin getContent()');

        System.debug('communityId: ' + communityId);
        System.debug('contentId: ' + contentId);
        System.debug('locale: ' + locale);
        System.debug('contentType: ' + contentType);

        List<String> contentIds = new List<String>();
        contentIds.add(contentId);

        ConnectApi.ManagedContentVersionCollection contentList = null;

        try{
            contentList = ConnectApi.ManagedContent.getManagedContentByIds(communityId, contentIds, 0, 25, locale, contentType);
        }
        catch (ConnectApi.ConnectApiException e) {
            System.debug(e.getMessage());
        }

        if(contentList == null) {
            try{
                String localePrefix = locale.substring(0,2);
                System.debug('trying locale prefix: ' + localePrefix);
                contentList = ConnectApi.ManagedContent.getManagedContentByIds(communityId, contentIds, 0, 25, localePrefix, contentType);
            }
            catch (ConnectApi.ConnectApiException e) {
                System.debug(e.getMessage());
            }
        }

        if(contentList == null) {
            try{
                System.debug('trying null locale');
                contentList = ConnectApi.ManagedContent.getManagedContentByIds(communityId, contentIds, 0, 25, null, contentType);
            }
            catch (ConnectApi.ConnectApiException e) {
                System.debug(e.getMessage());
            }
        }

        System.debug('contentList: ' + JSON.serialize(contentList));

        List<ConnectApi.ManagedContentVersion> items = contentList.items;

        ConnectApi.ManagedContentVersion item = items.get(0);

        Map<String, ConnectApi.ManagedContentNodeValue> nodes = item.contentNodes;

        return item;

    }
    
    
}