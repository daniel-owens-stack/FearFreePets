import { LightningElement, api } from 'lwc';
import chargeCustomerInvoice from '@salesforce/apex/B2BChargeCustomerInvoice.chargeCustomerInvoice';
import getInvoice from '@salesforce/apex/B2BChargeCustomerInvoice.getInvoice';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class B2bChargeCustomerInvoice extends LightningElement {
    @api recordId;
    invoiceIds = [];
    invoiceId;
    showTemplate = false;

    connectedCallback() {
        this.invoiceId = this.recordId;
        getInvoice({
            invoiceId : this.invoiceId 
        })
        .then(result => {
            if(result != null) {
                this.showTemplate = result.Stripe_Payment_URL__c != null ? false : true;
                this.invoiceIds.push(result.Stripe_Invoice_Id__c);
            }
            else {
                this.showTemplate = false;
            }
        })
        .catch((error) => {
            this.showToast('Error', 'An error occurred while getting invoice details', 'error');
            console.error('Error getting invoices:', error);
        });

    }

    handleChargeInvoices() {
        chargeCustomerInvoice({ invoiceIds: this.invoiceIds })
        .then((result) => {
            if(result === 'success'){
                this.showToast('Success', 'Invoice charged successfully', 'success');
            }
            else {
                this.showToast('Error', result, 'error');
            }
        })
        .catch((error) => {
            this.showToast('Error', 'An error occurred while processing invoice', 'error');
            console.error('Error charging invoices:', error);
        }); 
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}