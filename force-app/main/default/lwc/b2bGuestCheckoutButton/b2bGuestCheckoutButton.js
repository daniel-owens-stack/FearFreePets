import { LightningElement, api } from 'lwc';

export default class B2bGuestCheckoutButton extends LightningElement {

    @api headingLabel;
    @api checkoutButton;
    @api flowApiName;
    @api cartId;
    showFlowScreen;

    handleCheckout(){
        this.showFlowScreen = true;
    }

    closeModal() {
        this.showFlowScreen = false;
    }

    get flowInputVariables() {
        return [
            { name: 'varCartId', type: 'String', value: this.cartId}
        ];
    }

    handleFlowFinish(event) {
        if(event.detail.interviewStatus === 'FINISHED_SCREEN') {
            this.showFlowScreen = false;
        }
    }
}