import { LightningElement, api, wire } from 'lwc';
import createBillingPortalSession from '@salesforce/apex/StripeBillingController.createBillingPortalSession';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import STRIPE_CUSTOMER from '@salesforce/schema/User.Stripe_Customer__c';
import LightningAlert from 'lightning/alert';

//const FIELDS = ['User.Stripe_Customer__c'];

export default class ffMyBillingButton extends LightningElement {
    @api buttonLabel = 'Click Here to View My Billing Info';
    @api alignment;

    stripeEnabled = false;
    isLoading = false;

    // Get Stripe_Customer__c from current User
    @wire(getRecord, { recordId: USER_ID, fields: [STRIPE_CUSTOMER] })
    //@wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            this.stripeEnabled = data.fields.Stripe_Customer__c.value;
        } else if (error) {
            console.error('Error retrieving Stripe_Customer__c:', error);
        }
    }

    // Only show button if enabled
    get showBillingButton() {
        return this.stripeEnabled;
    }

    // Button click handler
    async handleClick() {
        this.isLoading = true;

        try {
            const url = await createBillingPortalSession();
            console.log('Redirecting to Stripe billing portal:', url);
            window.location.href = url;
        } catch (error) {
            console.error('Error launching Stripe portal:', error);

            const message = error?.body?.message || error?.message || 'An unknown error occurred';
            await LightningAlert.open({
                message,
                theme: 'error',
                label: 'Stripe Billing Error'
            });
        } finally {
            this.isLoading = false;
        }
    }
}