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
    @api noBusinessMessage;
    @api labelTeamName;
    @api reqErrorMessage;
    showTemplate = false;
    hasBusinessAccount = false;
    isTeamAdmin = false;
    showhasBusinessMessage = false;
    showNoBusinessMessage = false;
    showReqError = false;
    teamName;

    @wire(CartItemsAdapter, {'cartStateOrId': 'active'}) 
    getCartItems({ data, error }) {
        if (data) {
            this.cartItems = data.cartItems;
            this.checkforPracticeMembership();
        } else if (error) {
            console.error('Error in getCartItems : ', error);
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

                if(this.hasBusinessAccount && this.isTeamAdmin === false) {
                    this.showhasBusinessMessage = true;
                }
                else if(this.hasBusinessAccount === false) {
                    this.showNoBusinessMessage = true;
                }
            }
        })
        .catch(error => {
            console.error('Error in getAccountDetails: ', error);
        })
    }

    handleTeamNameChange(event) {
        this.teamName = event.target.value;
        this.showReqError = (this.teamName != null && this.teamName != '') ? false : true;
    }

    handleLostFocus() {
        console.log('Team name : ', this.teamName);
        //TODO:Update Team Name in Backend
    }

    stageAction(checkoutStage) {
        switch (checkoutStage) {
            case CheckoutStage.BEFORE_PAYMENT:
                return Promise.resolve(this.reportValidity());
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                return Promise.resolve(this.checkValidity);
            default:
                return Promise.resolve(true);
        }
    }

    get checkValidity() {
        if(this.hasBusinessAccount === false) {
            return (this.teamName != undefined && this.teamName != '' && this.teamName != null);
        }
        return true;
    }

    async reportValidity() {
        if(this.hasBusinessAccount === false) {
            this.showReqError = (this.teamName == undefined || this.teamName == '' || this.teamName == null) ? true : false;
        }

        return this.checkValidity ? true : false;
    }
}