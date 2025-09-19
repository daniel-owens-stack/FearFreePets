import { LightningElement, wire, api } from 'lwc';
import { CartSummaryAdapter } from 'commerce/cartApi'
import isGuest from '@salesforce/user/isGuest';
import updateTaxIdOnCart from '@salesforce/apex/B2BUtils.updateTaxIdOnCart';

export default class B2bInternationalTax extends LightningElement {

    @api internationalTaxLinkLabel;
    @api applyButtonLabel;
    @api inputPlaceHolder;
    @api readOnlyTaxLabel;
    @api changeButtonLabel;
    @api cartId;

    showTemplate = false;
    showText = false;
    showInputField = false;
    showTaxId = false;
    disableButton = true;
    isRendered = false;

    taxId;

    @wire(CartSummaryAdapter, {'cartStateOrId': 'current'})
    wiredCartSummaryData(result) {
        if (result.data && result.data.cartId) {
            this.cartId = result.data.cartId;

            if(result.data.customFields && Object.keys(result.data.customFields).length > 0) {
                this.taxId = result.data?.customFields[0]?.B2B_International_Tax_Id__c;
            }
            this.showText = this.taxId === null || this.taxId === undefined || this.taxId === '';
            this.showTaxId =  this.taxId != null && this.taxId != undefined && this.taxId != '';
        }
    }

    connectedCallback() {
        if(this.isInSitePreview()) {
            this.showTemplate = true;
            this.showText = true;
        }
        else {
            this.showTemplate = !isGuest;
            console.log('Show Template: ', this.showTemplate);
        }
    }

    handleTextClick() {
        this.showText = false;
        this.taxId = '';
        this.showInputField = true;
        this.showTaxId = false;
    }

    handleTaxIdChange(event) {
        this.taxId = event.target.value;
        this.disableButton = (this.taxId.trim().length == 0 || this.taxId === undefined || this.taxId === null) ? true : false;
    }

    updateWebCart() {
        updateTaxIdOnCart({
            cartId : this.cartId,
            taxId : this.taxId
        })
        .then(() => { 
            this.showTaxId = this.taxId != null;
            this.showInputField = this.taxId === null;
            this.disableButton = true;
        })
        .catch((error) => {
            console.error('Error in updateTaxIdOnCart: ', error);
            this.showTaxId = false;
            this.showInputField = true;
            this.disableButton = true;
        })
    }

    handleChange() {
        this.showTaxId = false;
        this.showInputField = true;
    }

    renderedCallback() {
        if(!this.isRendered && this.showInputField) {
            this.appendCustomStyle();
            this.isRendered = true;
        }
    }

    appendCustomStyle() {
        let style = document.createElement('style');  
        style.innerText = '.applyBtn .slds-button:disabled {background: rgba(217, 215, 213, 1) !important; border-color: rgba(217, 215, 213, 1) !important; color: rgba(18, 61, 100, 1)}';   
        this.template.querySelector('.applyButton').appendChild(style);
    }

    isInSitePreview() {
        let url = document.URL;
        
        return (url.indexOf('sitepreview') > 0 
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0 
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }
}