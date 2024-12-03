import { LightningElement, api } from 'lwc';
import isAdminAccount from '@salesforce/apex/B2BCustomAddToCartController.isAdminAccount';
import getUnclaimedPracticeLevelKits from '@salesforce/apex/B2BWelcomeKitController.getUnclaimedPracticeLevelKits';
import getShippingAddress from '@salesforce/apex/B2BWelcomeKitController.getShippingAddress';
import createOrderSummary from '@salesforce/apex/B2BWelcomeKitController.createOrderSummary';
import saveShippingAddress from 'c/b2bSaveShippingAddress';
import Toast from 'lightning/toast';

export default class B2bPracticeLevelCertificationKits extends LightningElement {

    @api buttonLabel;
    @api shippingAddressLabel;
    @api editAddressButtonLabel;
    @api newAddressButtonLabel;
    @api shipMyKitButtonLabel;
    @api successTitle;
    @api successMessage;
    showTemplate = false;
    showButton = false;
    hasShippingAddress = false;
    addNewAddress = false;
    unclaimedPracticeKits;
    address;

    connectedCallback() {
        isAdminAccount({})
        .then(result => {
            if(result) {
                this.checkUnclaimedKits();
            }
        })
        .catch(error => {
            console.error('Error in checkIsAdminAccount: ', error);
        })
    }

    checkUnclaimedKits() {
        getUnclaimedPracticeLevelKits({})
        .then(result => {
            if(result != null && result.length > 0) {
                this.unclaimedPracticeKits = result;
                this.showTemplate = true;
                this.showButton = true;
            }
            else {
                this.showTemplate = false;
                this.showButton = false;
            }
        })
        .catch(error => {
            console.error('Error in checkUnclaimedKits: ', error);
        })
    }

    handleButtonClick() {
        getShippingAddress()
        .then(result => {
            this.showButton = false;
            if(result != null) {
                this.hasShippingAddress = true;
                this.addNewAddress = false;
                this.address = result;
            }
            else {
                this.hasShippingAddress = false;
                this.addNewAddress = true;
                this.address = undefined;
            }
        })
        .catch(error => {
            console.error('Error in getShippingAddress: ', error);
        })
    }

    async handleEditAddress() {
        await saveShippingAddress.open({
            size: 'small',
            isEdit: true,
            existingShippingAddress : this.address,
            onFormSubmit: this.handleFormSubmit.bind(this)
        })
    }

    async handleNewAddress() {
        await saveShippingAddress.open({
            size: 'small',
            isEdit: false,
            existingShippingAddress : null,
            onFormSubmit: this.handleFormSubmit.bind(this)
        })
    }

    handleFormSubmit() {
        this.handleButtonClick();
    }

    handleShipMyKit() {
        let membershipIds = [];
        for(let i = 0; i < this.unclaimedPracticeKits.length; i++) {
            membershipIds[i] = this.unclaimedPracticeKits[i].Membership__c;
        }
        createOrderSummary({
            membershipIds: membershipIds,
            shippingAddress: this.address
        })
        .then(result => {
            this.showTemplate = false;
            if(result) {
                Toast.show({
                    label: this.successTitle,
                    message: this.successMessage,
                    mode: 'dismissable',
                    variant: 'success'
                }, this);
            }
        })
        .catch(error => {
            console.error('Error in createOrderSummary: ', error);
        })
    }
}