/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import processData from '@salesforce/apex/CartUploadController.processData';
import getInfo from '@salesforce/apex/CartUploadController.getInfo';

import LOCALE from '@salesforce/i18n/locale';
import USERID from '@salesforce/user/Id';
import COMMUNITYID from '@salesforce/community/Id';

import { loadStyle } from 'lightning/platformResourceLoader';
import cssResources from '@salesforce/resourceUrl/b2bCartUpload';

// Labels
import processSelectedFile from '@salesforce/label/c.B2B_Process_Selected_File';
import selectFiles from '@salesforce/label/c.B2B_Select_Files';
import reset from '@salesforce/label/c.B2B_Reset';
import filesSelected from '@salesforce/label/c.B2B_Files_Selected';
import processingError from '@salesforce/label/c.B2B_Upload_Processing_Error';
import pasteInputHere from '@salesforce/label/c.B2B_Paste_your_input_here';
import processText from '@salesforce/label/c.B2B_Process_pasted_text';
import selectInputType from '@salesforce/label/c.B2B_Select_input_type';
import csvFile from '@salesforce/label/c.B2B_CSV_file';
import textArea from '@salesforce/label/c.B2B_Text_area';
import showHelpDialog from '@salesforce/label/c.B2B_Show_Help_Dialog';
import pleaseWait from '@salesforce/label/c.B2B_Cart_Upload_please_wait';
import includesHeaderRow from '@salesforce/label/c.B2B_Includes_header_row';
import noTextFound from '@salesforce/label/c.B2B_Text_area_no_text_found';
import emailResultsCheckbox from '@salesforce/label/c.B2B_Email_Results';
import ignoreInvalidSkusCheckbox from '@salesforce/label/c.B2B_Ignore_invalid_SKUs';
import processingOptions from '@salesforce/label/c.B2B_Cart_Upload_Processing_options';
import maxUploadRowsExceeded from '@salesforce/label/c.B2B_CU_Max_Upload_Rows_Exceeded';

const INCLUDES_HEADER_ROW_OPTION = 'includesHeaderRowOption';
const EMAIL_RESULTS_OPTION = 'emailResultsOption';
const IGNORE_INVALID_SKUS_OPTION = 'ignoreInvalidSkusOption';

export default class CartUpload extends LightningElement {

    @api componentTitle;

    @api effectiveAccountId;

    @track inputSelection = 'csv';

    @track textAreaValue;

    @track isShowHelp = false;

    // For the help dialog
    @api contentId;
    @api contentType;

    @api isAsynchronous = false;

    @track hasHeaderRow = true;  // user option
    @api ignoreInvalidSkus = false;  // user option

    // component properties
    @api showEmailResultsCheckbox;
    @api emailResults;  // user option

    @track showProcessLog = false;
    @track processLog;

    label = {
        processSelectedFile
        , selectFiles
        , reset
        , filesSelected
        , processingError
        , pasteInputHere
        , processText
        , selectInputType
        , csvFile
        , textArea
        , showHelpDialog
        , pleaseWait
        , includesHeaderRow
        , noTextFound
        , emailResultsCheckbox
        , ignoreInvalidSkusCheckbox
        , processingOptions
        , maxUploadRowsExceeded
    };

    communityId = COMMUNITYID;

    locale = LOCALE;
    userId = USERID;

    cartId;
    webstoreId;
    maxUploadRows;

    selectedProcessingValues = [];

    connectedCallback() {
        this.selectedProcessingValues.push(INCLUDES_HEADER_ROW_OPTION);

        if (this.emailResults) {
            this.selectedProcessingValues.push(EMAIL_RESULTS_OPTION);
        }

        console.log('communityId: ' + this.communityId);

        this.loadInfo();
    }

    get options() {
        return [
            { label: this.label.csvFile, value: 'csv' },
            { label: this.label.textArea, value: 'text' },
        ];
    }

    get processingOptions() {

        let optionsArray = [];

        optionsArray.push({ label: this.label.includesHeaderRow, value: INCLUDES_HEADER_ROW_OPTION });

        optionsArray.push({ label: this.label.ignoreInvalidSkusCheckbox, value: IGNORE_INVALID_SKUS_OPTION });

        if (this.showEmailResultsCheckbox) {
            optionsArray.push({ label: this.label.emailResultsCheckbox, value: EMAIL_RESULTS_OPTION });
        }

        return optionsArray;

    }

    handleProcessingOptionsChange(event) {

        this.selectedProcessingValues = event.detail.value;

        //console.log(`selected: ${this.selectedProcessingValues}`);

    }

    handleShowHelpDialog(event) {
        this.isShowHelp = true;
    }

    handleCloseHelpDialog(event) {
        this.isShowHelp = false;
    }

    handleInputSelectionChange(event) {
        const selectedOption = event.detail.value;

        this.inputSelection = selectedOption;
    }

    handleTextAreaChange(event) {
        this.textAreaValue = event.detail.value;
    }

    handleTextReset(event) {
        this.textAreaValue = undefined;
    }

    get isCsvSelected() {
        if (this.inputSelection === 'csv') {
            return true;
        }
        else {
            return false;
        }
    }

    constructor() {
        super();

        loadStyle(this, cssResources);

    }

    loadInfo() {

        console.log('inside loadInfo()');

        getInfo({ userId: this.userId, effectiveAccountId: this.resolvedEffectiveAccountId, communityId: this.communityId, webstoreId: null })
            .then((result) => {
                if (result) {
                    console.log("getInfo():result");
                    console.log(JSON.stringify(result));

                    this.cartId = result.cartId;
                    this.webstoreId = result.webstoreId;
                    this.maxUploadRows = result.maxUploadRows;

                }
            })
            .catch((error) => {
                console.log("error from getInfo()");
                console.log(error);
                this.showLoadingSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "SEARCH ERROR",
                        message: error.message,
                        variant: "error"
                    })
                );
            });

    }

    @track showLoadingSpinner = false;
    @track isFileSelected = false;
    @track rows;

    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    content;
    MAX_FILE_SIZE = 1500000;

    get acceptedFormats() {
        return ['.txt', '.csv'];
    }

    get noFileSelected() {
        if (this.filesUploaded.length == 0) {
            return true;
        }
        else {
            return false;
        }
    }

    get hasContent() {
        // console.log('contentId: ' + this.contentId);
        // console.log('contentType: ' + this.contentType);

        if (this.contentId && this.contentType) {

            // console.log('hasContent = true');
            return true;
        }
        else {
            // console.log('hasContent = false');
            return false;
        }
    }

    handleReset() {
        this.filesUploaded = [];
        this.file = undefined;
        this.fileContents = undefined;
        this.content = undefined;
        this.rows = undefined;
        this.isFileSelected = false;
    }

    // getting file 
    handleFilesChange(event) {

        try {
            if (event.target.files.length > 0) {

                this.filesUploaded = event.target.files;
                this.isFileSelected = true;

                // let contentType = event.target.files[0].type;
                // console.log('contentType: ' + contentType);
                // let size = event.target.files[0].size;
                // console.log('size: ' + size);
            }
        }
        catch (error) {
            console.log(error.message);
        }
    }

    handleSave() {
        console.log('inside handleSave()');
        if (this.filesUploaded.length > 0) {
            this.uploadHelper();
        }
        else {

        }
    }

    handleTextSave() {

        console.log('inside handleTextSave');

        if (!this.textAreaValue) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.processingError,
                    message: this.label.noTextFound,
                    variant: 'error',
                }),
            );
        }

        this.rows = this.textAreaValue.split(/\r?\n/g);

        // for(var i = 0; i < this.rows.length; i++) {
        //     console.log(this.rows[i]);
        // }

        this.processUserInput();
    }

    uploadHelper() {
        console.log('inside uploadHelper()');
        this.file = this.filesUploaded[0];
        if (this.file.size > this.MAX_FILE_SIZE) {
            window.console.log('File Size is to long');
            return;
        }
        this.showLoadingSpinner = true;
        // create a FileReader object 
        this.fileReader = new FileReader();
        // set onload function of FileReader object  
        this.fileReader.onloadend = (() => {
            this.fileContents = this.fileReader.result;

            this.rows = this.fileReader.result.split(/\r?\n/g);

            // for(var i = 0; i < this.rows.length; i++) {
            //     console.log(this.rows[i]);
            // }

            this.processUserInput();
        });

        this.fileReader.readAsText(this.file);
    }

    // Calling apex class to insert the file
    processUserInput() {
        console.log('inside processUserInput()');

        // User options
        this.hasHeaderRow = this.selectedProcessingValues.indexOf(INCLUDES_HEADER_ROW_OPTION) >= 0 ? true : false;
        this.ignoreInvalidSkus = this.selectedProcessingValues.indexOf(IGNORE_INVALID_SKUS_OPTION) >= 0 ? true : false;
        this.emailResults = this.selectedProcessingValues.indexOf(EMAIL_RESULTS_OPTION) >= 0 ? true : false;

        this.processLog = undefined;
        this.showProcessLog = false;

        this.showLoadingSpinner = true;

        console.log('hasHeaderRow: ' + this.hasHeaderRow);
        console.log('ignoreInvalidSkus: ' + this.ignoreInvalidSkus);
        console.log('emailResults: ' + this.emailResults);

        processData({
            userId: this.userId
            , rows: this.rows
            , webstoreId: this.webstoreId
            , effectiveAccountId: this.resolvedEffectiveAccountId
            , cartId: this.cartId
            , hasHeaderRow: this.hasHeaderRow
            , ignoreInvalidSkus: this.ignoreInvalidSkus
            , emailResults: this.emailResults
        })
            .then(result => {
                console.log('return from processData()');

                this.showLoadingSpinner = false;

                this.isFileSelected = true;
                this.showLoadingSpinner = false;

                console.log('result: ' + JSON.stringify(result));

                if (result.messagesJson) {
                    let messages = JSON.parse(result.messagesJson);

                    this.showProcessLog = false;
                    let processLog = '';

                    processLog += '<ul>';

                    // Process messages returned
                    // Display toasts when applicable
                    // Create content for the details section
                    for (var i = 0; i < messages.length; i++) {

                        var message = messages[i];

                        if (message.toast === true) {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: message.title,
                                    message: message.message,
                                    variant: message.severity,
                                }),
                            );

                        }

                        let formattedMessage = '';

                        // These classes are defined in cartUploadProcessLog.css
                        let msgClass = '';
                        // if(message.severity === 'info') {
                        //     msgClass = 'msgInfo';
                        // }
                        // if(message.severity === 'success') {
                        //     msgClass = 'msgSuccess';
                        // }
                        // if(message.severity === 'warn') {
                        //     msgClass = 'msgWarn';
                        // }
                        // if(message.severity === 'error') {
                        //     msgClass = 'msgErr';
                        // }

                        if (message.severity === 'info') {
                            msgClass = 'slds-text-color_error';
                        }
                        if (message.severity === 'success') {
                            msgClass = 'slds-text-color_success';
                        }
                        if (message.severity === 'warn') {
                            msgClass = 'slds-text-color_default';
                        }
                        if (message.severity === 'error') {
                            msgClass = 'slds-text-color_error';
                        }

                        formattedMessage = '<li class=\'' + msgClass + '\'>' + message.message + '</li>';

                        processLog += formattedMessage;

                    }

                    processLog += '</ul>';

                    console.log('processLog: ' + processLog);

                    this.processLog = processLog;
                    this.showProcessLog = true;

                    // Refresh the cart icon
                    try {
                        this.dispatchEvent(new CustomEvent("cartchanged", {
                            bubbles: true,
                            composed: true
                        }));
                    }
                    catch (err) {
                        console.log('error: ' + err);
                    }

                }

            })
            .catch(error => {

                console.log('error from processData()');

                window.console.log(error);

                this.showLoadingSpinner = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.processingError,
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });

    }

    get resolvedEffectiveAccountId() {

        const effectiveAcocuntId = this.effectiveAccountId || "";
        let resolved = null;

        if (effectiveAcocuntId.length > 0 && effectiveAcocuntId !== "000000000000000") {
            resolved = effectiveAcocuntId;
        }
        return resolved;
    }

}