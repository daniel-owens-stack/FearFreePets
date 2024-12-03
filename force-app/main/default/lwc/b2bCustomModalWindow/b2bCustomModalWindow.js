import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class B2bCustomModalWindow extends LightningModal {

    @api modalHeading;
    @api modalContent;
    @api button1Label;
    @api button2Label;
    @api lwcName;
    cartPage;
    selectedButton;

    handleButton1() {
        this.close('okay');

        if(this.lwcName === 'checkoutPayment') {
            this.selectedButton = 'cancel';
            this.sendActionToParent();
        }
    }

    handleButton2() {
        if(this.lwcName === 'checkoutPayment') {
            this.close('okay');
            this.selectedButton = 'updateCart';
            this.sendActionToParent();
        } 
        else {
            //Redirect to Cart Page
            this.cartPage = window.location.origin +'/store/cart';
            window.open(this.cartPage, '_self');
        }
    }

    async sendActionToParent() {
        await this.dispatchEvent(new CustomEvent('selectedbutton', {
            detail: this.selectedButton,
            bubbles : true,
            composed: true
        }));
    }
}