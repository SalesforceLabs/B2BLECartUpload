/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, track, api } from 'lwc';

import closeDialog from '@salesforce/label/c.B2B_Close_Dialog';

export default class CartUploadHelpDialog extends LightningElement {

    @api isOpen = false;

    @api contentId;
    @api contentType;

    label = {
        closeDialog
    };

    handleCloseModal(event) {
        this.dispatchEvent(new CustomEvent('closehelpdialog'));
    }

}