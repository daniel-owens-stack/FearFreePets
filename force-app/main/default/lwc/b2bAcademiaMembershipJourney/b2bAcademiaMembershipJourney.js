import { wire, api } from 'lwc';
import Toast from 'lightning/toast';
import {CartItemsAdapter} from 'commerce/cartApi';
import { CheckoutComponentBase } from 'commerce/checkoutApi';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import JOB_TITLE from "@salesforce/schema/Account.Academia_Job_Title__c";
import uploadFile from '@salesforce/apex/B2BAcademiaMembershipJourneyController.uploadFile';
import updateAccount from '@salesforce/apex/B2BAcademiaMembershipJourneyController.updateAccount';

const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: 'CHECK_VALIDITY_UPDATE',
    REPORT_VALIDITY_SAVE: 'REPORT_VALIDITY_SAVE',
    BEFORE_PAYMENT: 'BEFORE_PAYMENT',
    PAYMENT: 'PAYMENT',
    BEFORE_PLACE_ORDER: 'BEFORE_PLACE_ORDER',
    PLACE_ORDER: 'PLACE_ORDER'
};

export default class B2bAcademiaMembershipJourney extends CheckoutComponentBase {

    @api academiaMembership;
    @api labelStudentOrFaculty;
    @api labelStudent;
    @api labelFaculty;
    @api labelUploadFile;
    @api labeluploadFileButton;
    @api labelGraduationYear;
    @api labelSchoolUniversity;
    @api labelJobTitle;
    @api errorMessage;
    @api errorMsgTitle;
    @api jobTitleHelpText;
    @api reqErrorMessage;
    @api schoolErrorMessage;
    @api filesData = [];
    cartItems = [];
    jobTitleOptions = [];
    jobTitle;
    graduationYear;
    schoolUniversity;    
    selectedOption;
    progress;
    titleLabel;
    isFileUploaded;
    showTemplate = false;
    showAdditionalFields = false;
    showStudentFields = false;
    showFacultyFields = false;
    showSpinner = false;
    showReqError = false;
    showSchoolError = false;
    maxFileSize = 1029746;//bytes
    isPreview = true;

    connectedCallback() {
        this.isPreview = this.isInSitePreview();
        this.showTemplate = this.isPreview ? true : false;
    }

    isInSitePreview() {
        let url = document.URL;
        
        return (url.indexOf('sitepreview') > 0 
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0 
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }
    
    @wire(CartItemsAdapter, {'cartStateOrId': 'active'}) 
    getCartItems({ data, error }) {
        if (data) {
            this.cartItems = data.cartItems;
            this.checkforAcademiaMembership();
        } else if (error) {
            console.error('Error in getCartItems : ', error);
        }
    }

    checkforAcademiaMembership() {
        if(this.cartItems.length > 0) {
            for(let i = 0; i < this.cartItems.length; i++) {
                if(this.cartItems[i].cartItem.productDetails.fields.Product_Group__c === this.academiaMembership) {
                    this.showTemplate = true;
                    break;
                }
            }
        }
    }

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: JOB_TITLE })
    jobTitleValues({ error, data }) {
        if (data) {
            this.jobTitleOptions = data.values.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
        }
        else if (error) {
            console.error('Error in getPicklistValues: ', error);
        }
    }

    handleOptionChange(event) {
        this.showReqError = false;
        this.showAdditionalFields = true;
        this.graduationYear = null;
        this.jobTitle = null;
        this.selectedOption = event.target.value;
        if(this.selectedOption == 'student') {
            this.showStudentFields = true;
            this.showFacultyFields = false;
        }
        else if(this.selectedOption == 'faculty') {
            this.showStudentFields = false;
            this.showFacultyFields = true;
        }
        else {
            this.showStudentFields = false;
            this.showFacultyFields = false;
            this.showAdditionalFields = false;
        }
    }

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.tiff'];
    }

    closeModal(){
        this.isFileUploaded = false;
        this.filesData = [];
    }

    handleFileChange(event) {
        this.filesData = [];
        const files = event.target.files;

        if (files.length > 0) {
            Array.from(files).forEach(file => {
                if(file.size > this.maxFileSize) {
                    this.showToastMsg(this.errorMsgTitle, this.errorMessage, 'error');
                }
                else {
                    const reader = new FileReader();
                    reader.onload = () => {
                        const fileContent = reader.result.split(',')[1];    
                        this.filesData.push({
                            'filename': file.name,
                            'fileContent': fileContent,
                            'filesize' : file.size
                        });
                        this.showSpinner = true;
                        this.handleSpinner();
                        this.fileToUpload();
                    };
                    reader.readAsDataURL(file);
                }
            });
        }
    }


    fileToUpload() {
        Promise.all(this.filesData.map(file => {
            const { filename, fileContent } = file;
            return uploadFile({ 
                fileName: filename, 
                base64Content: encodeURIComponent(fileContent)
            });
        }))
        .then(results => {
            this.isFileUploaded = true;
            this.titleLabel = results[0] + ' Uploaded Successfully';
            this.showSpinner = false;
        })
        .catch(error => {
            console.error('Error in file upload: ', error);
            this.showSpinner = false;
            this.isFileUploaded = false;
            this.showToastMsg(this.errorMsgTitle, error.body.fieldErrors.Name[0].message, 'error');
        })
    }

    handleSpinner() {
        const totalFileSize = this.filesData[0].filesize;
        const increment = totalFileSize/100;
        this.progress = 0;

        this._interval = setInterval(() => {
            this.progress = Math.min(this.progress + increment, totalFileSize);
            if (this.progress >= totalFileSize) {
                clearInterval(this._interval);
            }
        }, 200);
    }

    showToastMsg(title, message, variant) {
        Toast.show({
            label: title,
            message: message,
            mode: 'dismissable',
            variant: variant
        }, this);
    }

    handleGraduationYearChange(event) {
        this.graduationYear = event.target.value;
    }

    handleJobTitleChange(event) {
        this.jobTitle = event.target.value;
        this.handleLostFocus();
    }

    handleSchoolUniversityChange(event) {
        this.schoolUniversity = event.target.value;
        this.showSchoolError = (this.schoolUniversity != null && this.schoolUniversity != '') ? false : true;
    }

    handleLostFocus() {
        if(this.schoolUniversity != null && this.schoolUniversity != ''){
            this.setFieldsOnAccount();
        }
    }

    setFieldsOnAccount() {
        updateAccount({
            graduationYear : this.graduationYear,
            schoolUniversity : this.schoolUniversity,
            JobTitle : this.jobTitle
        })
        .then(() => {
            console.log('Updated values in the Account!')
        })
        .catch(error => {
            console.error('Error in updateAccount: ', error);
        })
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

    get checkValidity() {
        if(this.showTemplate){
            this.showReqError = this.selectedOption == undefined ? true : false;
            if(this.showReqError) {
                return false;
            } 
            else {
                this.showSchoolError = (this.showReqError == false && (this.schoolUniversity == '' || this.schoolUniversity == null)) ? true : false;
                if(this.showSchoolError) {
                    return false;
                }
            }
        }
        return true;
    }

    async reportValidity() {
        return this.checkValidity ? true : false;
    }
}