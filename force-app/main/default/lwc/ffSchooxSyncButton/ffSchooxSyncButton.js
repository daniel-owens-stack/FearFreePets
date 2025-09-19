import { LightningElement, api } from 'lwc';
import runBatchForAccount from '@salesforce/apex/FFSchooxSyncBatchRunner.runBatchForAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ffSchooxSyncButton extends LightningElement {
    @api recordId; // Automatically populated on record page

    handleButtonClick() {
        runBatchForAccount({ accountId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Schoox Jobs Synced. Enrollments sync scheduled for 1 Hour from now',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                let message = error && error.body && error.body.message ? error.body.message : 'Unknown error';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error starting sync',
                        message: message,
                        variant: 'error'
                    })
                );
            });
    }
}