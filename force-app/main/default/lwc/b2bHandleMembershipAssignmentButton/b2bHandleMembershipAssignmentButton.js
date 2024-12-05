import { LightningElement, api } from 'lwc';
import handleMembershipAssignmentManual from '@salesforce/apex/B2BSchooxAPIController.handleMembershipAssignmentManual';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class B2bHandleMembershipAssignmentButton extends LightningElement {
    @api recordId;
    @api syncToStripeButton;

    handleAssignment() {
        handleMembershipAssignmentManual({ recordId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Membership assignment processed successfully.', 'success');
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
