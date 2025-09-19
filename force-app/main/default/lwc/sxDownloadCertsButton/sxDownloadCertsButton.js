import { LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import CONTACT_ID from '@salesforce/schema/User.ContactId';
import SX_USER_ID from '@salesforce/schema/Contact.SX_User_Id__c';

export default class SxDownloadCertsButton extends LightningElement {
    sxUserId;
    certsUrl;
    contactId;
    error;

    // Wire the User record to get ContactId
    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    wiredUser({ error, data }) {
        if (data) {
            this.contactId = data.fields.ContactId.value;
        } else if (error) {
            this.error = error;
            console.error('Error fetching User:', error);
        }
    }

    // Wire the Contact record to get SX_User_Id__c
    @wire(getRecord, { recordId: '$contactId', fields: [SX_USER_ID] })
    wiredContact({ error, data }) {
        if (data) {
            this.sxUserId = data.fields.SX_User_Id__c.value;
            this.certsUrl = this.sxUserId 
                ? `https://app.schoox.com/academies/profile.php?acadId=827540346&user=${this.sxUserId}#/certificates`
                : null;
        } else if (error) {
            this.error = error;
            console.error('Error fetching Contact:', error);
        }
    }
}