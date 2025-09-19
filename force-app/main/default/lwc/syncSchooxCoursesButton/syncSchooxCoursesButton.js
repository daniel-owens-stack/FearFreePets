import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import PERSON_CONTACT_ID from '@salesforce/schema/Account.PersonContactId';
import SX_USER_ID from '@salesforce/schema/Contact.SX_User_Id__c';
import getSchooxCourseData from '@salesforce/apex/FFGetUserCourseWrapper.getSchooxCourseData';

export default class SyncSchooxCoursesButton extends LightningElement {
    @api recordId; // Account Id from record page
    @track contactId;
    @track sxUserId;
    @track courseInfo;
    @track error;

    // Step 1: Get the Account's PersonContactId
    @wire(getRecord, { recordId: '$recordId', fields: [PERSON_CONTACT_ID] })
    wiredAccount({ error, data }) {
        if (data) {
            this.contactId = data.fields.PersonContactId.value;
            console.log('PersonContactId fetched:', this.contactId);
        } else if (error) {
            this.error = error;
            console.error('Error fetching Account record:', error);
        }
    }

    // Step 2: Get SX_User_Id__c from Contact
    @wire(getRecord, { recordId: '$contactId', fields: [SX_USER_ID] })
    wiredContact({ error, data }) {
        if (data) {
            this.sxUserId = data.fields.SX_User_Id__c.value;
            console.log('SX_User_Id__c fetched:', this.sxUserId);
        } else if (error) {
            this.error = error;
            console.error('Error fetching Contact record:', error);
        }
    }

    // Step 3: Triggered by button click
    handleButtonClick() {
        if (!this.sxUserId) {
            console.warn('SX User ID not available yet.');
            return;
        }

        getSchooxCourseData({ sxUserId: this.sxUserId })
            .then((result) => {
                this.courseInfo = result;
                console.log('Course data fetched:', result);
            })
            .catch((error) => {
                this.error = error;
                console.error('Error fetching course info:', error);
            });
    }
}