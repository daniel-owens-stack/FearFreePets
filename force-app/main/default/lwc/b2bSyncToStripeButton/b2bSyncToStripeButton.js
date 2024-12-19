import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import Toast from 'lightning/toast';
import ACCOUNTID from "@salesforce/schema/Order.AccountId";
import CUSTOMERID from "@salesforce/schema/Order.Account.StripeCustomerId__c";
import INVOICEID from "@salesforce/schema/Order.InvoiceId__c";
import createInvoiceByOrderId from '@salesforce/apex/B2BStripePaymentController.createInvoiceByOrderId';

const FIELDS = [ACCOUNTID, CUSTOMERID, INVOICEID];

export default class B2bSyncToStripeButton extends LightningElement {

    @api syncToStripeButton;
    @api recordId;

    invoiceId;
    customerId;
    accountId;

    isDisabled = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    order({ error, data }) {
        if(data) {
            this.accountId = data.fields.AccountId.value;
            this.invoiceId = data.fields.InvoiceId__c.value;
            this.customerId = data.fields.Account.value.fields.StripeCustomerId__c.value;;
            if(this.invoiceId != null) {
                this.isDisabled = true;
            }
        }
        else if(error) {
            this.showToastMessage('Error', error.body.message, 'error');
        }
      }

    syncOrderToStripe() {
        createInvoiceByOrderId({
            orderId : this.recordId,
            customerId : this.customerId,
            accountId : this.accountId
        })
        .then(result => {
            if(result != null && result != undefined) {
                this.isDisabled = true;
                this.showToastMessage('Success', 'Order Synced To Stripe Successfully', 'success');
            }
            else {
                this.showToastMessage('Error', 'Something went wrong. Please try again.', 'error');
            }
        })
        .catch(error => {
            this.showToastMessage('Error', error.body.message, 'error');
        })
    }

    showToastMessage(label, message, variant) {
        Toast.show({
            label: label,
            message: message,
            mode: 'dismissable',
            variant: variant
        }, this);
    }
}