import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hasPLMA from '@salesforce/apex/FFUpdateILMAsFromPLMAController.hasPLMA';
import updateILMAs from '@salesforce/apex/FFUpdateILMAsFromPLMAController.updateILMAs';

export default class UpdatePracticeILMAsButton extends LightningElement {
    @api recordId;
    @track showButton = false;
    isLoading = false;

    @wire(hasPLMA, { accountId: '$recordId' })
    wiredHasPLMA({ error, data }) {
        if (data !== undefined) {
            this.showButton = data;
        } else if (error) {
            this.showButton = false;
            console.error(error);
        }
    }

    handleClick() {
        this.isLoading = true;
        updateILMAs({ accountId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'ILMAs updated successfully from PLMA.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.error(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating ILMAs',
                        message: error.body ? error.body.message : 'Unknown error',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}