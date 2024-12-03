import { LightningElement, track } from 'lwc';

export default class B2bMembershipUpdate extends LightningElement {
    @track accountId = '';
    @track membershipId = '';
    @track showSuccessMessage = false;
    @track showErrorMessage = false;
    @track successMessage = '';
    @track errorMessage = '';

    handleAccountIdChange(event) {
        this.accountId = event.detail.value;
    }

    handleMembershipIdChange(event) {
        this.membershipId = event.detail.value;
    }

    // Getter for input variables for the flow
    get inputVariables() {
        return [
            { name: 'varAccountId', type: 'String', value: this.accountId },
            { name: 'varMembershipId', type: 'String', value: this.membershipId }
        ];
    }

    // Handle flow trigger when the button is clicked
    handleRunFlow() {
        const flow = this.template.querySelector('lightning-flow');
        if (flow) {
            flow.startFlow('B2B_Assign_Commerce_Logic_on_Membership_Assignment_Update', this.inputVariables);
        }
    }

    // Handle status changes for success and error messages
    handleStatusChange(event) {
        const { status } = event.detail;
        if (status === 'FINISHED') {
            this.showSuccessMessage = true;
            this.successMessage = 'Flow completed successfully!';
        } else if (status === 'ERROR') {
            this.showErrorMessage = true;
            this.errorMessage = 'There was an error running the flow.';
        }
    }
}