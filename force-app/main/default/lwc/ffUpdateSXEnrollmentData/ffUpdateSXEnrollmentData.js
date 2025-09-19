import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import CONTACT_ID from '@salesforce/schema/User.ContactId';
import SX_USER_ID from '@salesforce/schema/Contact.SX_User_Id__c';
import getSchooxCourseData from '@salesforce/apex/FFGetUserCourseWrapper.getSchooxCourseData';

export default class SchooxCourse extends LightningElement {
    @track contactId;
    @track sxUserId;
    @track courseInfo;
    @track error;

    // Step 1: Get the current user's ContactId
    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    wiredUser({ error, data }) {
        if (data) {
            this.contactId = data.fields.ContactId.value;
            console.log('ContactId fetched:', this.contactId);
        } else if (error) {
            this.error = error;
            console.error('Error fetching User record:', error);
        }
    }

    // Step 2: Get SX_User_Id__c from Contact
    @wire(getRecord, { recordId: '$contactId', fields: [SX_USER_ID] })
    wiredContact({ error, data }) {
        if (data) {
            this.sxUserId = data.fields.SX_User_Id__c.value;
            console.log('SX_User_Id__c fetched:', this.sxUserId);

            // Once we have sxUserId, fetch course data imperatively
            this.fetchCourseData();
        } else if (error) {
            this.error = error;
            console.error('Error fetching Contact record:', error);
        }
    }

    // Step 3: Call Apex imperatively to fetch course data
    fetchCourseData() {
        if (!this.sxUserId) {
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