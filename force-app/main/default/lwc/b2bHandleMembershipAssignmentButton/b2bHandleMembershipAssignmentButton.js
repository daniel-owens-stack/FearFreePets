import { LightningElement, api } from 'lwc';
import handleJobAssignmentManual from '@salesforce/apex/B2BSchooxAPIController.handleJobAssignmentManual';
import handleJobUnassignmentManual from '@salesforce/apex/B2BSchooxAPIController.handleJobUnassignmentManual';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class B2bHandleMembershipAssignmentButton extends LightningElement {
    @api recordId;
    @api syncToStripeButton;

    handleAssignment() {
        handleJobAssignmentManual({ recordId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Job assignment processed successfully.', 'success');
            })
            .catch((error) => {
                this.showToast('Error', error.body.message || 'An error occurred.', 'error');
            });
    }

    handleUnassignment() {
        handleJobUnassignmentManual({ recordId: this.recordId })
        .then(() => {
            this.showToast('Success', 'Job Unassignment processed successfully.', 'success');
        })
        .catch((error) => {
            this.showToast('Error', error.body.message || 'An error occurred.', 'error');
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}
