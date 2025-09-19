/*
 * Last Modified: 2024-08-17 12:55:14
 */

import { LightningElement, api, wire } from 'lwc';
import {getRecord, getFieldValue, notifyRecordUpdateAvailable} from 'lightning/uiRecordApi';
import { handleError, showToast } from 'c/customToast';
import getCourse from "@salesforce/apex/ContactCourses_CTRL.getCourse";

import CONTACT_FIRST_NAME_FIELD from '@salesforce/schema/Contact.FirstName';
import CONTACT_LAST_NAME_FIELD from '@salesforce/schema/Contact.LastName';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import CONTACT_SX_USER_ID_FIELD from '@salesforce/schema/Contact.SX_User_Id__c';

import ACCOUNT_IS_PERSON_ACCOUNT_FIELD from '@salesforce/schema/Account.IsPersonAccount';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_CONTACT_ID_FIELD from '@salesforce/schema/Account.PersonContactId';
import ACCOUNT_CONTACT_EMAIL_FIELD from '@salesforce/schema/Account.PersonContact.Email';
import ACCOUNT_SX_USER_ID_FIELD from '@salesforce/schema/Account.PersonContact.SX_User_Id__c';

export default class ContactCourses extends LightningElement {
    @api recordId;
    @api objectApiName;
    isLoadingSpinner = false;

    @wire(getRecord, { recordId: '$recordId', fields: [CONTACT_FIRST_NAME_FIELD, CONTACT_LAST_NAME_FIELD, CONTACT_EMAIL_FIELD, CONTACT_SX_USER_ID_FIELD] }) currentContact;
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_IS_PERSON_ACCOUNT_FIELD, ACCOUNT_NAME_FIELD, ACCOUNT_CONTACT_ID_FIELD, ACCOUNT_CONTACT_EMAIL_FIELD, ACCOUNT_SX_USER_ID_FIELD] }) currentAccount;

    get contactEmail() {
        return getFieldValue(this.currentContact.data, CONTACT_EMAIL_FIELD);
    }
    get contactFirstName() {
        return getFieldValue(this.currentContact.data, CONTACT_FIRST_NAME_FIELD);
    }
    get contactLastName() {
        return getFieldValue(this.currentContact.data, CONTACT_LAST_NAME_FIELD);
    }
    get contactSXUserId() {
        return getFieldValue(this.currentContact.data, CONTACT_SX_USER_ID_FIELD);
    }
    get contactFullName() {
        return this.contactFirstName + ' ' + this.contactLastName;
    }

    get isPersonAccount(){
        return getFieldValue(this.currentAccount.data, ACCOUNT_IS_PERSON_ACCOUNT_FIELD);
    }
    get accountName() {
        return getFieldValue(this.currentAccount.data, ACCOUNT_NAME_FIELD);
    }
    get accountContactId() {
        return getFieldValue(this.currentAccount.data, ACCOUNT_CONTACT_ID_FIELD);
    }
    get accountContactEmail() {
        return getFieldValue(this.currentAccount.data, ACCOUNT_CONTACT_EMAIL_FIELD);
    }
    get accountSXUserId() {
        return getFieldValue(this.currentAccount.data, ACCOUNT_SX_USER_ID_FIELD);
    }

    get name() {
        return this.isPersonAccount ? this.accountName : this.contactFullName;
    } get sxUserId() {
        return this.isPersonAccount ? this.accountSXUserId : this.contactSXUserId;
    } get email() {
        return this.isPersonAccount ? this.accountContactEmail : this.contactEmail;
    } get contactId() {
        return this.isPersonAccount ? this.accountContactId : this.recordId;
    }

    @api invoke() {
        if (this.sxUserId) {
            this.isLoadingSpinner = true;
            getCourse({ contactId: this.contactId, sxUserId: this.sxUserId })
                .then((result) => {
                    if (result) {
                        showToast(false, result + ' Courses has been added to ' + this.objectApiName + ' : ' + this.name);
                    } else {
                        showToast(false, 'No Courses has been added to ' + this.objectApiName + ' : ' + this.name);
                    }
                    this.updateRecordView();
                })
                .catch((error) => {
                    this.isLoadingSpinner = false;
                    handleError(error);
                });
        } else {
            showToast(true, 'SX User Id is not defined for this ' + this.objectApiName + ' : ' + this.name);
        }
    }

    updateRecordView() {
        this.isLoadingSpinner = false;
        notifyRecordUpdateAvailable([{recordId: this.recordId}]).then(result => {
            eval("$A.get('e.force:refreshView').fire();");
        });
    }
}