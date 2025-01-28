import { LightningElement, api, wire } from 'lwc';
import { CheckoutComponentBase } from 'commerce/checkoutApi';
import getAccountDetails from '@salesforce/apex/B2BBillingEmailVerificationController.getAccountDetails';
import updateAccount from '@salesforce/apex/B2BBillingEmailVerificationController.updateAccount';
import generateVerificationCode from '@salesforce/apex/B2BBillingEmailVerificationController.generateVerificationCode';
import verifyCode from '@salesforce/apex/B2BBillingEmailVerificationController.verifyCode';
import Toast from 'lightning/toast';
import { subscribe, MessageContext } from 'lightning/messageService';
import MY_MESSAGE_CHANNEL from '@salesforce/messageChannel/MyMessageChannel__c';

const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: 'CHECK_VALIDITY_UPDATE',
    REPORT_VALIDITY_SAVE: 'REPORT_VALIDITY_SAVE',
    BEFORE_PAYMENT: 'BEFORE_PAYMENT',
    PAYMENT: 'PAYMENT',
    BEFORE_PLACE_ORDER: 'BEFORE_PLACE_ORDER',
    PLACE_ORDER: 'PLACE_ORDER'
};

export default class B2bBillingEmailVerification extends (LightningElement, CheckoutComponentBase) {
    @api templateTitle;
    @api billingEmailLabel;
    @api msgToAddEmail;
    @api msgToVerifyEmail;
    @api msgToChangeEmail;
    @api verifyEmailButtonLabel;
    @api updateEmailButtonLabel;
    @api cancelButtonLabel;
    @api resendCodeButtonLabel;
    @api codeInputLabel;
    @api codeInputPlaceholder;
    @api flowApiName; 
    @api verificationErrorMsg;
    @api flowFinishedMsg;
    @api requiredExceptionMsg;
    @api emailPatternMismatchMsg;

    showMyAccountTemplate = false;
    showBillingEmail = false;
    showAddEmail = false;
    showEmailInput = false;
    showVerifyEmail = false;
    showChangeEmail = false;
    isAdminAccount = false;
    isOnTeam = false;
    creditOnlyPaymentTerms = false;
    renderFlow = false;
    showCodeInput = false;
    disableUpdate = false;
    showCodeError = false;
    disableVerify = true;
    isPreview = false;
    showCheckoutTemplate = false;
    emailVerified = false;
    showEmailError = false;

    existingBillingEmail;
    billingEmail;
    billingEmailVerified;
    verificationCode;
    flowInputVariables;
    pathName;
    selectedPaymentOption;
    emailRegex = /^[a-zA-Z]+(?:[._]?[a-zA-Z0-9]+)*@[a-zA-Z]+(?:\.[a-zA-Z]{2,})+$/;

    @wire(MessageContext)
    messageContext;

    async connectedCallback(){
        subscribe(
            this.messageContext,
            MY_MESSAGE_CHANNEL,
            (message) => this.handleMessage(message)
        );

        subscribe(
            this.messageContext,
            MY_MESSAGE_CHANNEL,
            (message) => this.SyncCheckoutPayment(message)
        );

        this.isPreview = this.isInSitePreview();
        if(this.isPreview){
            this.showMyAccountTemplate = true;
            this.showCheckoutTemplate = true;
            this.showAddEmail = true;
        } else {
            await this.getCurrentAccountDetails();
        }
    }

    handleMessage(message) {
        if (message.status === 'completed') {
            this.getCurrentAccountDetails();
        }
    }

    SyncCheckoutPayment(message) {
        this.selectedPaymentOption = message.selectedPayment;
    }

    async getCurrentAccountDetails() {
        getAccountDetails()
        .then(result => {    
            this.manageTemplateVisibility();

            if(this.showMyAccountTemplate || this.showCheckoutTemplate) {
                if(result.hasBillingEmail) {
                    this.showBillingEmail = true;
                    this.existingBillingEmail = result.billingEmail;

                    if(result.isBillingEmailVerified) {
                        this.showChangeEmail = true;
                        this.showVerifyEmail = false;
                        this.showEmailInput = false;
                        this.emailVerified = true;
                    }
                    else {
                        this.showChangeEmail = true;
                        this.showVerifyEmail = true;
                        this.showEmailInput = false;
                    }
                }
                else {
                    this.showAddEmail = true;
                    this.showEmailInput = false;
                    this.showBillingEmail = false;
                    this.showChangeEmail = false;
                }
            }
        })
        .catch(error => {
            console.error('Error in getUserAccountId: ', error);
        })
    }

    manageTemplateVisibility() {
        let path = window.location.pathname;
        this.pathName = path.trim();

        if(this.pathName == '/store/checkout') {
            this.showCheckoutTemplate = true;
            this.showMyAccountTemplate = false;
        }
        else {
            this.showMyAccountTemplate = true;
            this.showCheckoutTemplate = false;
        }
    }
    
    handleEmailChange(event) {
        this.billingEmail = event.target.value;
        this.disableUpdate = (this.billingEmail.trim().length != 0 && this.billingEmail != undefined && this.billingEmail != null && this.emailRegex.test(this.billingEmail)) ? false : true;
    }

    verifyEmailPattern() {
        this.showEmailError = !this.emailRegex.test(this.billingEmail);
    }

    handleVerifyEmail() {
        this.showCodeError = false;
        generateVerificationCode()
        .then(result => {
            let code = `${result}`;
            
            //Send Code via Email from the flow
            this.flowInputVariables = [
                {name: 'varEmail', type: 'String', value: this.existingBillingEmail},
                {name: 'varCode', type: 'String', value: code},
            ];
            this.renderFlow = true;
        })
        .catch(error => {
            console.error('Error in generateVerificationCode: ', error);
        })
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED_SCREEN') {
            this.renderFlow = false;
            this.showCodeInput = true;
            this.showEmailInput = false;
            this.showChangeEmail = false;
            this.showVerifyEmail = false;
            this.showAddEmail = false;
        }
    }

    handleChangeEmail() {
        this.billingEmail = this.existingBillingEmail;
        this.disableUpdate = (this.billingEmail != undefined && this.billingEmail != null) ? false : true;
        this.showAddEmail = false;
        this.showEmailInput = true;
        this.showBillingEmail = false;
        this.showChangeEmail = false;
        this.showVerifyEmail = false;
        this.showCodeInput = false;
    }

    updateBillingEmail() {
        updateAccount({
            billingEmail : this.billingEmail,
            emailVerified : false
        })
        .then(() => {
            if(this.billingEmail.trim().length != 0 && this.billingEmail != undefined && this.billingEmail != null) {
                this.existingBillingEmail = this.billingEmail;
                this.showBillingEmail = true;
                this.showEmailInput = false;
                this.handleVerifyEmail();
            }
        })
        .catch(error => {
            console.error('Error in updateBillingEmail: ', error);
        })
    }

    handleCodeChange(event) {
        this.verificationCode = event.detail.value;
        this.showCodeError = false;
        this.disableVerify = (this.verificationCode.trim().length == 6 && this.verificationCode != undefined && this.verificationCode != null) ? false : true;
    }

    handleCodeVerify() {
        verifyCode({
            email : this.existingBillingEmail,
            code : this.verificationCode
        })
        .then(result => {
            if(result) {
                this.showCodeError = false;
                this.showCodeInput = false;
                this.showChangeEmail = true;
                this.emailVerified = true;
                Toast.show({
                    label: 'Success',
                    message: 'Email Verified Successfully!',
                    mode: 'dismissable',
                    variant: 'success'
                }, this);
            }
            else {
                this.showCodeError = true;
                this.emailVerified = false;
            }
        })
        .catch(error => {
            console.error('Error in verifyCode: ', error);
        })
    }

    handleCancel() {
        this.getCurrentAccountDetails();
    }

    isInSitePreview() {
        let url = document.URL;
        
        return (url.indexOf('sitepreview') > 0 
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0 
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }

    get checkValidity() {
        if(this.existingBillingEmail == undefined || this.existingBillingEmail == null) {
            return false;
        }
        else if(this.existingBillingEmail.trim().length != 0 && this.emailVerified) {
            return true;
        }
        return false;
     }
 
     @api
     async reportValidity() {
         let isValid = this.checkValidity;
 
         if (isValid) {
             return true;
         } else {
             this.dispatchUpdateErrorAsync({
                 groupId: "BillingEmail",
                 type: "/commerce/errors/checkout-failure",
                 exception: this.requiredExceptionMsg,
             });
         }
 
         return isValid;
     }

    stageAction(checkoutStage) {
        switch (checkoutStage) {
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                return Promise.resolve(this.checkValidity);
            case CheckoutStage.REPORT_VALIDITY_SAVE:
                return Promise.resolve(this.reportValidity());
            case CheckoutStage.BEFORE_PAYMENT:
                return Promise.resolve(this.reportValidity());
            default:
                return Promise.resolve(true);
        }
    }
}