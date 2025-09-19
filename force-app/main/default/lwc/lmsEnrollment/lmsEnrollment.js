import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { handleError, showToast } from 'c/customToast';
import { CloseActionScreenEvent } from 'lightning/actions';

import getCourses from "@salesforce/apex/Enrollment_CTRL.getCourses";
import enrollCourses from "@salesforce/apex/Enrollment_CTRL.enrollCourses";

import SX_USER_ID_FIELD from '@salesforce/schema/SX_LMS_User__c.SX_User_ID__c';
import USER_FIELD from '@salesforce/schema/SX_LMS_User__c.SF_User__c';
import CONTACT_FIELD from '@salesforce/schema/SX_LMS_User__c.SF_Contact__c';
import RECORDTYPE_FIELD from '@salesforce/schema/SX_LMS_User__c.RecordType.DeveloperName';

const COURSE_DATA_COLUMNS = [
    {   label: "Name", 
        fieldName: "courseUrl", 
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' }, 
            tooltip: { fieldName: 'Name' },
            target: '_blank'
        }, initialWidth: 220
    },
    { label: "Course Id", fieldName: "SX_Course_ID__c", type: 'text', initialWidth: 90 },
    { label: "Course Description", fieldName: "courseDescription", type: 'text' }
];
const RESULT_DATA_COLUMNS = [
    {   label: "Name", 
        fieldName: "courseUrl", 
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' }, 
            tooltip: { fieldName: 'Name' },
            target: '_blank'
        }, initialWidth: 220
    },
    { label: "Course Id", fieldName: "SX_Course_ID__c", type: 'text', initialWidth: 90 },
    { label: "Message", fieldName: "message", type: 'text'}
];

export default class LmsEnrollment extends LightningElement {
    _recordId;
    isLoadingSpinner = false;
    isEnrollDisabled = false;
    preSelectedCourse = [];
    @track courseList = [];
    @track preSelectedCourse = [];
    selectedCourseList = [];

    @track courseColumns = COURSE_DATA_COLUMNS;

    @api set recordId(value) {
        this._recordId = value;
        this.getCourseData('');
    }
    
    get recordId() {
        return this._recordId;
    }

    @wire(getRecord, { recordId: '$recordId', fields: [SX_USER_ID_FIELD, USER_FIELD, CONTACT_FIELD, RECORDTYPE_FIELD] }) lmsUser;

    get sxUserId() {
        return getFieldValue(this.lmsUser.data, SX_USER_ID_FIELD);
    }
    get userId() {
        return getFieldValue(this.lmsUser.data, USER_FIELD);
    }
    get contactId() {
        return getFieldValue(this.lmsUser.data, CONTACT_FIELD);
    }
    get recordType() {
        return getFieldValue(this.lmsUser.data, RECORDTYPE_FIELD);
    }

    getCourseData(courseName) {
        this.isLoadingSpinner = true;
        getCourses({ recordId: this.recordId, searchTerm: courseName })
            .then((data) => {
                if (data) {
                    console.log("🚀 ~ file: lmsEnrollment.js ~ line 81 ~ LmsEnrollment ~ .then ~ data", data);
                    let courseArray = data.map(row => { 
                        let courseUrl = `/${row.Id}`;
                        let courseDescription = row.SX_Course_Description__c && row.SX_Course_Description__c.replace( /(<([^>]+)>)/ig, '');
                        return {...row, courseUrl, courseDescription};
                    });
                    if(courseArray.length == 0) {
                        this.courseList = undefined;
                    } else {
                        this.courseList = courseArray;
                    }
                    this.isLoadingSpinner = false;
                }
            })
            .catch((error) => {
                this.courseList = undefined;
                handleError(error);
                this.isLoadingSpinner = false;
            });        
    }

    handleProductKeyUp(event) {
		const isEnterKey = event.keyCode === 13;
		if (isEnterKey) {
			let courseName = event.target.value;
			this.getCourseData(courseName);
		}
	}

    handleOnEnrollClick(event) {
        console.log('handleOnEnrollClick');
        let courseTable = this.template.querySelector('[data-id="courseTable"]');
        this.selectedCourseList = courseTable.getSelectedRows();
        let selectedIds = [];
        this.selectedCourseList.forEach(row => {
            selectedIds.push(row.SX_Course_ID__c);
        });
        if (selectedIds.length > 0) {
            this.isLoadingSpinner = true;
            enrollCourses({ studentId: this.sxUserId, courseIds: selectedIds })
            .then(result => {
                const resultMap = new Map(Object.entries(result));
                showToast(false, '');
                this.courseColumns = RESULT_DATA_COLUMNS;
                let courseArray = this.selectedCourseList.map(row => { 
                    let message = resultMap.get(row.SX_Course_ID__c).message;
                    return {...row, message};
                });
                this.courseList = courseArray;
                console.log("🚀 ~ file: lmsEnrollment.js ~ line 101 ~ LmsEnrollment ~ handleOnEnrollClick ~ this.courseList", this.courseList);
                this.isEnrollDisabled = true;
                this.updateRecordView();
            })
            .catch(error => {
                handleError(error);
                this.isLoadingSpinner = false;
            });
        } else {
            showToast(true, 'You must select a course to enroll');
        }
    }

    closeModal() {
        this.isLoadingSpinner = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    updateRecordView() {
        this.isLoadingSpinner = false;
        setTimeout(() => {
                eval("$A.get('e.force:refreshView').fire();");
        }, 1000); 
    }
}