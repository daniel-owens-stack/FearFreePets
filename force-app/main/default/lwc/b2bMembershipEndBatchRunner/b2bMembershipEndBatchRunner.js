import { LightningElement } from 'lwc';
import simulateRun from '@salesforce/apex/B2BMembershipEndBatchRunner.simulateRun';

export default class B2bMembershipEndBatchRunner extends LightningElement {
    runDate;
    isLoading = false;
    isbuttonDisabled = true;
    successMessage = '';
    errorMessage = '';

    handleDateChange(event) {
        this.runDate = event.target.value;
        if(this.runDate) {
            this.isbuttonDisabled = false;
        }
    }

    runBatch() {
        this.successMessage = '';
        this.errorMessage = '';
        this.isLoading = true;

        if(!this.runDate) {
            this.errorMessage = 'Please select a date';
            this.isLoading = false;
            this.isbuttonDisabled = true;
            return;
        }

        simulateRun({ runDate: this.runDate })
            .then((result) => {
                this.successMessage = result;
            })
            .catch(error => {
                this.errorMessage = 'Error: ' + (error?.body?.message || 'Unable to run the batch');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}