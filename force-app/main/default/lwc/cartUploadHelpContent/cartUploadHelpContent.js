/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, api, wire } from 'lwc';

import getContent from '@salesforce/apex/B2BCartUploadHelp.getContent';

import USER_LOCALE from '@salesforce/i18n/locale';
import COMMUNITYID from '@salesforce/community/Id';
import BASE_PATH from '@salesforce/community/basePath';

import retrievingContent from '@salesforce/label/c.B2B_Retrieving_Content';

export default class CartUploadHelpContent extends LightningElement {

    communityId = COMMUNITYID;

    @api contentId;
    @api contentType;

    managedContentItem;
    body;
    title;

    label = {
        retrievingContent
    };

    // convert the standard locale to one recognized by Salesforce CMS
    get locale() {
        return USER_LOCALE.replace('-', '_');
    }

    // used to change the CMS image source paths to one that includes the community name.
    get communityName() {
        console.log('BASE_PATH: ' + BASE_PATH);

        let path = BASE_PATH;
        let pos = BASE_PATH.lastIndexOf('/s');
        if(pos >= 0) {
            path = BASE_PATH.substring(0, pos);
        }

        console.log('path: ' + path);

        return path;
    }

    @wire(getContent, { communityId: '$communityId', contentId: '$contentId', locale: '$locale', contentType: '$contentType' })
    loadContent(result) {
        //console.log('inside loadContent()');
        //console.log(JSON.stringify(result));

        if (result.data) {

            console.log('success!');

            this.managedContentItem = result.data;

            //console.log('body before: ' + this.managedContentItem.contentNodes.body.value);

            let tempBody = this.htmlDecode(this.managedContentItem.contentNodes.body.value);

            console.log('body after htmlDecode: ' + tempBody);

            if(tempBody.indexOf('/cms/delivery/media')) {
                const searchRegExp = /\/cms\/delivery\/media/g;

                tempBody = tempBody.replace(searchRegExp, this.communityName + '/cms/delivery/media');
            }

            if(tempBody.indexOf('/cms/media')) {
                const searchRegExp = /\/cms\/media/g;

                tempBody = tempBody.replace(searchRegExp, this.communityName + '/cms/delivery/media');
            }

            this.body = tempBody;

            console.log('body after: ' + this.body);

            this.title = this.managedContentItem.contentNodes.title.value;

        }

        if(result.error) {
            console.log('error detected');
            this.title = result.error.body.exceptionType;
            this.body = result.error.body.message;
        }
    }

    // renderedCallback() {
    //     this.template.querySelector('.wrapper').innerHTML = this.body;
    // }

    htmlDecode(input){
        var e = document.createElement('textarea');
        e.innerHTML = input;
        // handle case of empty input
        return e.childNodes.length === 0 ? "" : e.childNodes[0].nodeValue;
      }

}