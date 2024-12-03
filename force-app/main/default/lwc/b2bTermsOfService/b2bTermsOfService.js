import { CheckoutComponentBase } from 'commerce/checkoutApi';
import { api } from 'lwc';
const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: 'CHECK_VALIDITY_UPDATE',
    REPORT_VALIDITY_SAVE: 'REPORT_VALIDITY_SAVE',
    BEFORE_PAYMENT: 'BEFORE_PAYMENT',
    PAYMENT: 'PAYMENT',
    BEFORE_PLACE_ORDER: 'BEFORE_PLACE_ORDER',
    PLACE_ORDER: 'PLACE_ORDER'
};


export default class B2bTermsOfService extends CheckoutComponentBase {
    isChecked = false;
    @api checkbox;
    @api content;

    handleChange(event) {
        this.isChecked = event.target.checked;
        const evt = new CustomEvent('checked', {detail:{'isChecked':this.isChecked}});
        this.dispatchEvent(evt);
    }

    get checkValidity() {
       return this.isChecked;
    }

    @api
    async reportValidity() {
        let isValid = this.isChecked;

        if (isValid) {
            return true;
        } else {
            this.dispatchUpdateErrorAsync({
                groupId: "TermsAndConditions",
                type: "/commerce/errors/checkout-failure",
                exception: "You must agree to the terms before proceeding.",
            });
        }

        return isValid;
    }

    stageAction(checkoutStage /*CheckoutStage*/) {
        console.log(checkoutStage);
        switch (checkoutStage) {
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                return Promise.resolve(this.checkValidity);
            case CheckoutStage.BEFORE_PAYMENT:
                return Promise.resolve(this.reportValidity());
            default:
                return Promise.resolve(true);
        }
    }
}