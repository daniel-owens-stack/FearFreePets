import { wire, api } from 'lwc';
import {CartItemsAdapter} from 'commerce/cartApi';
import { CheckoutComponentBase } from 'commerce/checkoutApi';
import getAccountDetails from '@salesforce/apex/B2BCreateMyTeamController.getAccountDetails';

const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: 'CHECK_VALIDITY_UPDATE',
    REPORT_VALIDITY_SAVE: 'REPORT_VALIDITY_SAVE',
    BEFORE_PAYMENT: 'BEFORE_PAYMENT',
    PAYMENT: 'PAYMENT',
    BEFORE_PLACE_ORDER: 'BEFORE_PLACE_ORDER',
    PLACE_ORDER: 'PLACE_ORDER'
};

export default class B2bCreateMyTeam extends CheckoutComponentBase {

    @api practiceMembership;
    @api hasBusinessMessage;
    @api reqErrorMessage;
    @api flowApiName; 
    @api templateTitle;
    showTemplate = false;
    hasBusinessAccount = false;
    isTeamAdmin = false;
    showhasBusinessMessage = false;
    showNoBusinessMessage = false;
    showReqError = false;
    isPreview = false;
    showSuccessMsg = false;
    renderFlow = true;
    teamName;
    successMessage;

    @wire(CartItemsAdapter, {'cartStateOrId': 'active'}) 
    getCartItems({ data, error }) {
        if (data) {
            this.cartItems = data.cartItems;
            this.checkforPracticeMembership();
        } else if (error) {
            console.error('Error in getCartItems : ', error);
        }
    }
    async connectedCallback(){
        this.isPreview = this.isInSitePreview();
        if(this.isPreview){
            this.showTemplate = true;
            this.showhasBusinessMessage = true;
            this.showNoBusinessMessage = true;
        }
    }

    checkforPracticeMembership() {
        if(this.cartItems.length > 0) {
            for(let i = 0; i < this.cartItems.length; i++) {
                if(this.cartItems[i].cartItem.productDetails.fields.Product_Group__c === this.practiceMembership) {
                    this.showTemplate = true;
                    break;
                }
            }
            if(this.showTemplate) {
                this.checkIsBusinessAccount();
            }
        }
    }

    checkIsBusinessAccount() {
        getAccountDetails({})
        .then(result => {
            if(result != null) {
                this.hasBusinessAccount = result.Business__c != null ? true : false;
                this.isTeamAdmin = result.Admin_Account__c;

                if(!this.renderFlow && this.hasBusinessAccount) {
                    this.teamName = result.Business__r.Name;
                    this.showSuccessMsg = true;
                    this.successMessage = 'You are now an Admin of the team \'' + this.teamName + '\'.';
                }

                if(this.hasBusinessAccount && !this.isTeamAdmin) {
                    this.showhasBusinessMessage = true;
                    this.showNoBusinessMessage = false;
                }
                else if(!this.hasBusinessAccount) {
                    this.showhasBusinessMessage = false;
                    this.showNoBusinessMessage = true;
                }
                else {
                    this.showTemplate = false;
                }
            }
        })
        .catch(error => {
            console.error('Error in getAccountDetails: ', error);
        })
    }

    stageAction(checkoutStage) {
        switch (checkoutStage) {
            case CheckoutStage.REPORT_VALIDITY_SAVE:
                return Promise.resolve(this.reportValidity());
            case CheckoutStage.BEFORE_PAYMENT:
                return Promise.resolve(this.reportValidity());
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                return Promise.resolve(this.checkValidity);
            default:
                return Promise.resolve(true);
        }
    }

    get checkValidity() {
        if(this.showTemplate) {
            return (this.teamName != null && this.teamName != undefined);
        }
        return true;
    }

    async reportValidity() {
        if(this.showTemplate) {
            this.showReqError = (this.teamName == null || this.teamName == undefined) ? true : false;
        }
        return this.checkValidity ? true : false;
    }

    handleFlowStatusChange(event) {
        this.showReqError = false;
        if (event.detail.status === 'FINISHED') {
            this.renderFlow = false;
            this.checkIsBusinessAccount();
        }
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