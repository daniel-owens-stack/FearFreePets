import { LightningElement, api } from 'lwc';
import convertCartToOrder from '@salesforce/apex/B2BStripePaymentController.convertCartToOrder';

export default class B2bConvertCartToOrder extends LightningElement {

    @api buttonLabel;
    @api inputLabel;
    @api recordId;

    showSuccessMsg = false;
    showErrMsg = false;
    isDisabled = true;

    successMsg;
    errorMsg;
    paymentIntentId;
    orderNumber;
    

    handleInputChange(event) {
        this.paymentIntentId = event.target.value;
        this.isDisabled = (this.paymentIntentId != null && this.paymentIntentId != '') ? false : true;
    }

    async handleCartToOrder() {
        this.isDisabled = true;
        await convertCartToOrder({
                webCartId: this.recordId,
                paymentIntent: this.paymentIntentId,
                stripeInvoiceId: null
        })
        .then(result => {
            if(result != null){
                this.orderNumber = result;
                this.successMsg = 'Order Created Successfully. Order Number: ' + this.orderNumber;
                this.showSuccessMsg = true;
                this.showErrMsg = false;
            }
        })
        .catch(error => {
            console.error('Error in convertCartToOrder: ' + error);
            this.isDisabled = false;
            this.errorMsg = error.body.message;
            this.showErrMsg = true;
            this.showSuccessMsg = false;
        })
    }
}