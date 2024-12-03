import { LightningElement, api } from 'lwc';
import getAccountDetails from '@salesforce/apex/B2BBillingEmailVerificationController.getAccountDetails';
import updateAccount from '@salesforce/apex/B2BBillingEmailVerificationController.updateAccount';
import generateVerificationCode from '@salesforce/apex/B2BBillingEmailVerificationController.generateVerificationCode';
import verifyCode from '@salesforce/apex/B2BBillingEmailVerificationController.verifyCode';
import Toast from 'lightning/toast';

export default class B2bBillingEmailVerification extends LightningElement {
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

    showTemplate = false;
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

    existingBillingEmail;
    billingEmail;
    billingEmailVerified;
    verificationCode;
    flowInputVariables;

    async connectedCallback(){
        this.isPreview = this.isInSitePreview();
        if(this.isPreview){
            this.showTemplate = true;
            this.showAddEmail = true;
        } else {
            await this.getCurrentAccountDetails();
        }
    }

    async getCurrentAccountDetails() {
        getAccountDetails()
        .then(result => {    
            if(result.creditOnlyPaymentTerms) {
                if(result.isOnTeam) {
                    if(result.isAdminAccount) {
                        this.showTemplate = true;
                    }
                }
                else {
                    this.showTemplate = true;
                }
            }

            if(this.showTemplate) {
                if(result.hasBillingEmail) {
                    this.showBillingEmail = true;
                    this.existingBillingEmail = result.billingEmail;

                    if(result.isBillingEmailVerified) {
                        this.showChangeEmail = true;
                        this.showVerifyEmail = false;
                        this.showEmailInput = false;
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
                }
            }
        })
        .catch(error => {
            console.error('Error in getUserAccountId: ', error);
        })
    }
    
    handleEmailChange(event) {
        this.billingEmail = event.target.value;
        this.disableUpdate = (this.billingEmail.trim().length != 0 && this.billingEmail != undefined && this.billingEmail != null) ? false : true;
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
                Toast.show({
                    label: 'Success',
                    message: 'Email Verified Successfully!',
                    mode: 'dismissable',
                    variant: 'success'
                }, this);
            }
            else {
                this.showCodeError = true;
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
}