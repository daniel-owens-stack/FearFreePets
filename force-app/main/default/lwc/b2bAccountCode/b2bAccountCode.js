import { LightningElement, api, wire } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import Toast from 'lightning/toast';
import updateAccountFields from '@salesforce/apex/B2BAccountCodeController.updateAccountFields';
import manageAccountCode from '@salesforce/apex/B2BAccountCodeController.manageAccountCode';
import updateCart from '@salesforce/apex/B2BUtils.updateCart';
import { CartSummaryAdapter } from 'commerce/cartApi';

export default class B2bAccountCode extends LightningElement {

    @api applyButtonLabel;
    @api inputPlaceHolder;
    @api accountCodeLinkLabel;
    @api updateSuccessTitle;
    @api updateSuccessMessage;
    @api updateErrorTitle;
    @api updateErrorMessage;
    showTemplate = false;
    showText = false;
    showInputField = false;
    showAccountCode = false;
    disableButton = true;
    showDeleteButton = false;
    isRendered = false;
    accountCode;
    accountcodeInfo;
    @api recordId;

    @wire(CartSummaryAdapter, {'cartStateOrId': 'active'})
    async wiredCartSummaryData(result) {
        if (result.data && result.data.cartId) {
            this.recordId = result.data.cartId;
        }
    }

    connectedCallback() {
        sessionStorage.removeItem('selectedPayment');
        if(isGuest) {
            this.showTemplate = false;
        }
        else {
            this.showTemplate = true;
            this.getAccountCodeInfo();
        }

        if(this.isInSitePreview()) {
            this.showTemplate = true;
            this.showText = true;
        }
    }

    handleTextClick() {
        this.showText = false;
        this.accountCode = '';
        this.showInputField = true;
        this.showAccountCode = false;
    }

    getAccountCodeInfo() {
        manageAccountCode()
            .then(result => {
                this.accountcodeInfo = result;
                if(result.accountCodeLabel != null) {
                    this.accountCode = result.accountCodeLabel;
                    this.showText = false;
                    this.showInputField = false;
                    this.showAccountCode = true;
                    this.showDeleteButton = (result.teamAdmin || !result.onTeam);
                }
                else {
                    this.showText = (result.teamAdmin || !result.onTeam);
                    this.showInputField = false;
                    this.showAccountCode = false;
                }
                
            })
            .catch(error => {
                console.error('Error in manageAccountCode : ', error);
            })
    }

    handleCodeChange(event) {
        this.accountCode = event.target.value;
        this.disableButton = (this.accountCode.trim().length == 0 || this.accountCode === undefined || this.accountCode === null) ? true : false;
    }

    updateAccountCode() {

        updateAccountFields({
            code : this.accountCode
        })
        .then((result) => {
            if(result) {
                this.showAccountCode = this.accountCode != null;
                this.showDeleteButton = true;
                this.showInputField = this.accountCode === null;
                this.disableButton = true;
                //this.showToastMessage(this.updateSuccessTitle, this.updateSuccessMessage, 'success');
                this.updateCartStatus();
            }
            else {
                this.showAccountCode = false;
                this.showInputField = true;
                this.disableButton = true;
                this.showToastMessage(this.updateErrorTitle, this.updateErrorMessage, 'error');
            } 
        })
        .catch((error) => {
            console.log('Error updating Account Code', error);
            this.showToastMessage(this.updateErrorTitle, this.updateErrorMessage, 'error');
        });
    }

    showToastMessage(label, message, variant) {
        Toast.show({
            label: label,
            message: message,
            mode: 'dismissable',
            variant: variant
        }, this);
    }

    handleClose() {
        this.showAccountCode = false;
        this.showInputField = true;
        this.disableButton = true;
        this.accountCode = null;
        this.updateAccountCode();
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

    updateCartStatus() {
        updateCart({cartId : this.recordId})
        .then(() => { })
        .catch((error) => {
            console.error('Error in updateCart: ', error);
        })
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