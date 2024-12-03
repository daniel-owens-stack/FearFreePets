import { LightningElement, api, wire } from 'lwc';
import { getRecord} from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import ACCOUNT_ID from '@salesforce/schema/User.AccountId';
import ID_FIELD from "@salesforce/schema/Account.Id";
import LICENSE_NUMBER from '@salesforce/schema/Account.License_Number__c';
import CCPDT_NUMBER from '@salesforce/schema/Account.Trainer_CCPDT_Number__c';
import updateAccountRecord from '@salesforce/apex/B2BEditAccountDetailsController.updateAccountRecord';

const FIELDS = [ID_FIELD, LICENSE_NUMBER, CCPDT_NUMBER];

export default class B2bEditAccountDetails extends LightningElement {

    @api readTemplateTitle;
    @api editTemplateTitle;
    @api editButtonLabel;
    @api licenseNumberLabel;
    @api ccpdtNumberLabel;
    @api cancelButtonLabel;
    @api saveButtonLabel;
    @api licenseNumberHelpText;
    @api ccpdtNumberHelpText;

    showReadTemplate = true;
    showEditTemplate = false;
    isLoading = false;
    isPreview = false;

    accountId;
    licenseNumber;
    ccpdtNumber;
    editedLicenseNumber;
    editedCCPDTNumber;

    connectedCallback() {
        this.isLoading = true;
        this.isPreview = this.isInSitePreview();
        if(this.isPreview){
            this.licenseNumber = 'Test123';
            this.ccpdtNumber = 'Trainer123';
            this.isLoading = false;
        }
    }

    @wire(getRecord, { recordId: USER_ID, fields: [ACCOUNT_ID] })
    wiredUser({ error, data }) {
        if (data) {
            this.accountId = data.fields.AccountId.value;
        } else if (error) {
            console.error('Error fetching AccountId:', error);
        }
    }

    @wire(getRecord, { recordId: '$accountId', fields: FIELDS })
    loadAccountData({ error, data }) {
        if (data) {
            this.licenseNumber = data.fields.License_Number__c.value;
            this.ccpdtNumber = data.fields.Trainer_CCPDT_Number__c.value;
            this.isLoading = false;
        } else if (error) {
            console.error('Error loading account data:', error);
            this.isLoading = false;
        }
    }

    handleEditButton() {
        this.showEditTemplate = true;
        this.showReadTemplate = false;
        this.editedLicenseNumber = this.licenseNumber;
        this.editedCCPDTNumber = this.ccpdtNumber;
    }

    handleLicenseNumberChange(event) {
        this.editedLicenseNumber = event.target.value;
    }

    handleCCPDTNumberChange(event) {
        this.editedCCPDTNumber = event.target.value;
    }

    handleCancel() {
        this.showEditTemplate = false;
        this.showReadTemplate = true;
        this.editedLicenseNumber = '';
        this.editedCCPDTNumber = '';
    }

    updateAccountDetails() {
        this.isLoading = true;
        const inputMap = {
            Id: this.accountId,
            licenseNumber: this.editedLicenseNumber,
            ccpdtNumber: this.editedCCPDTNumber,
        };

        updateAccountRecord({
            accountDetails : inputMap
        })
        .then(() => {
            this.licenseNumber = this.editedLicenseNumber;
            this.ccpdtNumber = this.editedCCPDTNumber;
            this.showEditTemplate = false;
            this.showReadTemplate = true;
            this.isLoading = false;
        })
        .catch((error) => {
            this.isLoading = false;
            console.error('Error updating record:', error);
        });
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