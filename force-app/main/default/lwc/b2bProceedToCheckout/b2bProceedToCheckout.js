import {LightningElement, wire} from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import {NavigationMixin} from "lightning/navigation";
import {CartSummaryAdapter} from 'commerce/cartApi';

export default class B2BProceedToCheckout extends NavigationMixin(LightningElement) {
    isGuest = isGuest;
    showError = false;
    isLoading = true;
    recordId;
    isRendered = false;
    areCheckoutItemsValid = true;

    get submitDisabled() {
        // return this.isLoading || this.showError;
        return !this.areCheckoutItemsValid;
    }

    @wire(CartSummaryAdapter, {'cartStateOrId': 'active'})
    async wiredCartSummaryData(result) {
        if (result.data && result.data.cartId) {
            this.recordId = result.data.cartId;

            if (this.recordId) {
                this.areCheckoutItemsValid = true;
                this.isLoading = false;

            }
        }
    }

    doRequest(action, params) {
        return new Promise((resolve, reject) => {
            action(params)
                .then(res => {
                    resolve({
                        isSuccess: true,
                        result: res,
                        errorMessage: ''
                    });
                })
                .catch(error => {
                    this.showDeleteError = true;
                    if (error.message) {
                        this.deleteRrrorMessage = errorMessage;
                    } else {
                        console.error(error);
                        this.deleteRrrorMessage = 'Something went wrong. Please, contact your System Administrator.';
                    }
                    setTimeout(() => {
                        this.showDeleteError = false;
                        this.deleteRrrorMessage = '';
                    }, 3000);
                    resolve({
                        isSuccess: false,
                        errorMessage: JSON.stringify(error)
                    });
                });
        });
    }

    renderedCallback() {
        if (!this.isRendered) {
            this.addCustomCssStyles();
            this.isRendered = true;
        }
    }

    navigateToCheckout() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Current_Checkout',
            },
        });
    }

    navigateToLogin() {
        this[NavigationMixin.Navigate]({
            type: "comm__loginPage",
            attributes: {
                actionName: 'login',
            },
        });
    }

    addCustomCssStyles() {
        const style = document.createElement('style');

        let customCssStyles = ` 
            c-b2b-proceed-to-checkout button {
                width: 100% !important;
            }
        `;

        style.innerText = customCssStyles.replace(/ +(?= )|\n/g, '');
        this.template.querySelector('.custom-css-container').appendChild(style);
    }
}