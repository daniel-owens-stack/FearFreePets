import { LightningElement, wire, api } from 'lwc';
import { CartSummaryAdapter, CartItemsAdapter, deleteItemFromCart } from 'commerce/cartApi';
import { getSessionContext } from 'commerce/contextApi';
import { useCheckoutComponent } from 'commerce/checkoutApi';
import communityBasePath from '@salesforce/community/basePath';

import getCustomerId from '@salesforce/apex/B2BStripePaymentController.getCustomerId';
import processPayments from '@salesforce/apex/B2BStripePaymentController.processPayments';
import validateSession from '@salesforce/apex/B2BStripePaymentController.validateSession';
import convertCartToOrder from '@salesforce/apex/B2BStripePaymentController.convertCartToOrder';
import createInvoice from '@salesforce/apex/B2BStripePaymentController.createInvoice';
import canInvoice from '@salesforce/apex/B2BStripePaymentController.canInvoice';
import modalWindow from 'c/b2bCustomModalWindow';
import { CurrentPageReference } from 'lightning/navigation';
import { publish, MessageContext } from 'lightning/messageService';
import MY_MESSAGE_CHANNEL from '@salesforce/messageChannel/MyMessageChannel__c';
import updateCart from '@salesforce/apex/B2BUtils.updateCart';

const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: 'CHECK_VALIDITY_UPDATE',
    REPORT_VALIDITY_SAVE: 'REPORT_VALIDITY_SAVE',
    BEFORE_PAYMENT: 'BEFORE_PAYMENT',
    PAYMENT: 'PAYMENT',
    BEFORE_PLACE_ORDER: 'BEFORE_PLACE_ORDER',
    PLACE_ORDER: 'PLACE_ORDER'
};

export default class B2bCheckoutPayment extends useCheckoutComponent(LightningElement) {
    @wire(CurrentPageReference) 
    handleStateChange(pageReference) {
        this.pageReference = pageReference;
        this.checkSession();
    }

    @wire(MessageContext)
    messageContext;

    @wire(CartSummaryAdapter, {'cartStateOrId': 'active'})
    async wiredCartSummaryData(result) {
        if (result.data && result.data.cartId) {
            this.recordId = result.data.cartId;
        }
        this.checkSession();
    }

    async checkSession() {
        if(this.pageReference == undefined || !this.recordId) { return; }
        let session = this.pageReference.state.session;
        if (!!session && !this.isChecked) {
            this.showSpinner = true;
            this.isChecked = true;
            let result = await this.validateSession(session);
            if (result) {
                const summaryNumber = await this.convertCartToOrder();
                if(!summaryNumber){
                    this.showSpinner = false;
                    this.showError = true;
                    this.errorMessage = 'Error occurred during order creation, please contact System Administrator.';
                } else {
                    window.location = `${communityBasePath}/order?orderNumber=${summaryNumber}`;
                    this.showSpinner = false;
                }
            }
            else {
                this.showSpinner = false;
            }
        }
    }

    @wire(CartItemsAdapter, {'cartStateOrId': 'active'}) 
    async getCartItems(wireResult) {
        const { data, error } = wireResult;
        this.wiredCartItems = wireResult;
        this.shippableCartItemIds = [];
        if (data) {
            this.cartItems = data.cartItems;
            this.hasShippableProducts = false;
            for(let i = 0; i < this.cartItems.length; i++) {
                if(this.cartItems[i].cartItem.productDetails.fields.IsShippingChargeNotApplicable === 'false') {
                    this.hasShippableProducts = true;
                    this.shippableCartItemIds.push(this.cartItems[i].cartItem.cartItemId);
                }
            }
        } else if (error) {
            console.error('Error in getCartItems : ', error);
        }
    }

    @api recordId;
    @api modalSize;
    @api cancelButton;
    @api updateCartButton
    @api modalMessage;
    @api modalTitle;
    @api loadingMessage;
    hasShippableProducts = false;
    showModal = false;
    showError = false;
    isRendered = false;
    isChecked = false;
    showSpinner = false;
    errorMessage = '';
    pageReference;
    paymentOption = 'paynow';
    effectiveAccountId;
    customerId;
    session;
    paymentIntent;
    cartItems = [];
    shippableCartItemIds = [];
    wiredCartItems;

    paymentOptions = [
        {label: 'Pay now', value: 'paynow'},
        {label: 'Invoice', value: 'invoice'},
    ];

    get options() {
        return this.paymentOptions;
    }

    async selectPaymentOption(event) {
        this.paymentOption = event.target.value;
        await this.getCustomerId();
        this.showModal = this.paymentOption === 'invoice' && this.hasShippableProducts === true;
        if(this.showModal) {
            //Open Modal Window
            const result = await modalWindow.open({
                size: this.modalSize,
                modalHeading: this.modalTitle,
                modalContent: this.modalMessage,
                button1Label: this.cancelButton,
                button2Label: this.updateCartButton,
                lwcName: 'checkoutPayment',
                onselectedbutton: (event) => {
                    this.handleSelectedButton(event);
                }
            }); 
            if(result == undefined) {
                this.deselectInvoiceOption();
            }
        }
    }

    async connectedCallback() {
        this.effectiveAccountId = await this.getEffectiveAccountId();
        await this.getCustomerId();
        await this.checkCanInvoice();
    }

    async checkCanInvoice() {
        try {
            const canInvoiceResult = await canInvoice({ accountId: this.effectiveAccountId });
            if (!canInvoiceResult) {
                this.paymentOptions = this.paymentOptions.filter(option => option.value !== 'invoice');
            }
        } catch (error) {
            console.error('Error checking invoicing option', error);
            this.showError = true;
            this.errorMessage = 'Unable to determine invoicing option. Please try again later.';
        }
    }

    async getCustomerId() {
        let { isSuccess, result, errorMessage } = await this.doRequest(getCustomerId, { accountId: this.effectiveAccountId, paymentOption: this.paymentOption });
        if (isSuccess) {
            this.customerId = result;
        } else {
            console.error('getCustomerId: ', errorMessage);
        }
    }

    async getEffectiveAccountId() {
        return new Promise(async (resolve, reject) => {
            let result = null;
            await getSessionContext()
                .then((response) => {
                    result = response.effectiveAccountId || response.accountId;
                    resolve(result);
                })
                .catch((error) => {
                    console.error(error);
                    reject(result);
                });
        });
    }

    async validateSession(session) {
        let {isSuccess, result, errorMessage} = await this.doRequest(validateSession, {
            sessionId: session,
            webCartId: this.recordId
        });
        if (isSuccess) {
            this.paymentIntent = result.paymentIntent;
        } else {
            console.error('validateSession: ',errorMessage);
        }
        return result.isSessionValid;
    }

    async convertCartToOrder() {
        let {isSuccess, result, errorMessage} = await this.doRequest(convertCartToOrder, {webCartId: this.recordId, paymentIntent: this.paymentIntent});

        if (isSuccess) {
         
        } else {
            console.error('convertCartToOrder: ', errorMessage);
        }
        return result;
    }

    async stageAction(checkoutStage) {
        this.showError = false;
        switch (checkoutStage) {
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                return Promise.resolve(true);
            case CheckoutStage.REPORT_VALIDITY_SAVE:
                return Promise.resolve(true);
            case CheckoutStage.BEFORE_PAYMENT:
                if (this.checkValidity()) {
                    this.showSpinner = true;
                    await this.getCustomerId();
                    if (this.paymentOption == 'paynow') {
                        const href = window.location.href;
                        this.session = await this.processPayments(href);
                        window.location = this.session.url;
                        return Promise.resolve(true);
                    } else {
                        const summaryNumber = await this.sendInvoice();
                        if(!summaryNumber){
                            this.showSpinner = false;
                            return Promise.reject('Error occurred during order creation, please contact System Administrator.');
                        } else {
                            window.location = `${communityBasePath}/order?orderNumber=${summaryNumber}`;
                            this.showSpinner = false;
                        }
                    }
                } else {
                    return Promise.reject('Please, resolve errors on the page.');
                }
            default:
                return Promise.resolve(true);
        }
    }

    async processPayments(href) {
        this.showSpinner = true;

        let { isSuccess, result, errorMessage } = await this.doRequest(processPayments, {
            webCartId: this.recordId,
            customerId: this.customerId,
            href: href
        });
        this.showSpinner = false;
        return result;
    }

    async sendInvoice() {
        let { isSuccess, result, errorMessage } = await this.doRequest(createInvoice, {
            webCartId: this.recordId,
            customerId: this.customerId,
            accountId : this.effectiveAccountId
        });
        return result;
    }

    checkValidity() {
        if (!this.paymentOption) {
            this.showError = true;
            this.errorMessage = 'Please, select payment method';
        } else {
            this.showError = false;
            this.errorMessage = '';
        }
        return !this.showError;
    }

    doRequest(action, params) {
        this.showError = false;
        this.errorMessage = '';
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
                    this.showError = true;
                    this.errorMessage = 'Something went wrong. Please, contact your System Administrator.';
                    setTimeout(() => {
                        this.showError = false;
                        this.errorMessage = '';
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
        this.publishMessage();
    }

    publishMessage() {
        const message = { selectedPayment : this.paymentOption };
        publish(this.messageContext, MY_MESSAGE_CHANNEL, message);
    }

    addCustomCssStyles() {
        const style = document.createElement('style');
        let customCssStyles = ` 
            c-checkout-payment .error svg {
                fill: white;
            }
        `;
        style.innerText = customCssStyles.replace(/ +(?= )|\n/g, '');
        this.template.querySelector('.custom-css-container').appendChild(style);
    }

    handleSelectedButton = (event) => {
        const selectedButton = event.detail;
        if (selectedButton === 'cancel') {
            this.deselectInvoiceOption();
        } else if (selectedButton === 'updateCart') {
            this.removeShippableItems();
        }
    }

    deselectInvoiceOption() {
        this.paymentOption = 'paynow';
    }

    async removeShippableItems() {
        await Promise.all(this.shippableCartItemIds.map(shippableItem => {
            deleteItemFromCart(shippableItem)
            .then(() => {console.log('Items deleted successfuly!')})
            .catch(error => {console.error('Error in deleteItemFromCart: ', error);})
        }));

        setTimeout(()=> {
            this.refreshCheckout();
        }, 3000);
    }

    async refreshCheckout() {
        updateCart({cartId : this.recordId})
        .then(() => { 
            if(this.cartItems.length == 0) {
                let currentUrl = window.location.href;
                let cartPage = currentUrl.replace('checkout', 'cart');
                window.open(cartPage, '_self');
            } else {
                window.location.reload();
            }
        })
        .catch((error) => {
            console.error('Error in updateCart: ', error);
        })
    }
}