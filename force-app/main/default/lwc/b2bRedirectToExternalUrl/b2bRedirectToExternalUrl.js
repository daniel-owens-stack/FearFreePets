import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import EXTERNAL_URL from "@salesforce/schema/Product2.External_URL__c";

const FIELDS = [EXTERNAL_URL];

export default class B2bRedirectToExternalUrl extends LightningElement {

    @api recordId;
    @api buttonLabel;
    @api externalUrl;
    //  url;

    // connectedCallback() {
    //     this.url = this.externalUrl;
    // }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    product;

    get url() {
        return getFieldValue(this.product.data, EXTERNAL_URL);
    }

    handleClick() {
        if (this.url) {
            window.open(this.url, '_blank');
        } else {
            console.error('URL is not set');
        }
    }
}