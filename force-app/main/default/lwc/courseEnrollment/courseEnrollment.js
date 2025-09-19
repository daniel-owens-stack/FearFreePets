import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { handleError, showToast } from 'c/customToast';
import { CloseActionScreenEvent } from 'lightning/actions';

import getStudents from "@salesforce/apex/Enrollment_CTRL.getStudents";
import enrollStudent from "@salesforce/apex/Enrollment_CTRL.enrollStudent";
import updateEnrollment from "@salesforce/apex/Enrollment_CTRL.updateEnrollment";

import SX_COURSE_ID_FIELD from '@salesforce/schema/SX_Courses__c.SX_Course_ID__c';

const STUDENT_DATA_COLUMNS = [
    {   label: "Name",
        fieldName: "studentUrl",
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'LMS_User_Name__c' },
            tooltip: { fieldName: 'LMS_User_Name__c' },
            target: '_blank'
        }
    },
    { label: "User Id", fieldName: "SX_User_ID__c", type: 'text' },
    { label: "User Type", fieldName: "recordTypeName", type: 'text' }
];
const RESULT_DATA_COLUMNS = [
    {   label: "Name",
        fieldName: "studentUrl",
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'LMS_User_Name__c' },
            tooltip: { fieldName: 'LMS_User_Name__c' },
            target: '_blank'
        }, initialWidth: 220
    },
    { label: "User Id", fieldName: "SX_User_ID__c", type: 'text' },
    { label: "Message", fieldName: "message", type: 'text'}
];

export default class CourseEnrollment extends LightningElement {
    @api recordId;
    isLoadingSpinner = false;
    isEnrollDisabled = false;
    @track studentList = [];

    @track studentColumns = STUDENT_DATA_COLUMNS;

    connectedCallback() {
        this.getStudentData('');
    }

    @wire(getRecord, { recordId: '$recordId', fields: [SX_COURSE_ID_FIELD] }) currentCourse;

    get sxCourseId() {
        return getFieldValue(this.currentCourse.data, SX_COURSE_ID_FIELD);
    }

    // @wire(getStudents, {recordId: '$recordId'})
    // getCourseList({ data, error }){
    //     if(data){
    //         let courseArray = data.map(row => { 
    //             let studentUrl = `/${row.Id}`;
    //             let recordTypeName = row.RecordType.Name;
    //             return {...row, studentUrl, recordTypeName};
    //         });
    //         this.studentList = courseArray;
    //     } else if(error){
    //         handleError(error);
    //     }
    // }
    

    getStudentData(studentName) {
        this.isLoadingSpinner = true;
        console.log('91-> Getting Product Data');
        getStudents({ recordId: this.recordId, searchTerm: studentName })
            .then((data) => {
                if (data) {
                    // this.processPreselectedRow();
                    let studentArray = data.map(row => { 
                        let studentUrl = `/${row.Id}`;
                        let recordTypeName = row.RecordType.Name;
                        return {...row, studentUrl, recordTypeName};
                    });
                    if(studentArray.length == 0) {
                        this.studentList = undefined;
                    } else {
                        this.studentList = studentArray;
                    }
                    this.isLoadingSpinner = false;
                }
            })
            .catch((error) => {
                this.studentList = undefined;
                handleError(error);
                this.isLoadingSpinner = false;
            });        
    }

    handleProductKeyUp(event) {		
		const isEnterKey = event.keyCode === 13;
		if (isEnterKey) {
			let studentName = event.target.value;
			this.getStudentData(studentName);
		}
	}

    async handleOnEnrollClick(event) {
        console.log('handleOnEnrollClick');
        let studentTable = this.template.querySelector('[data-id="studentTable"]');
        let selectedUserList = studentTable.getSelectedRows();
        if (selectedUserList.length > 0) {
            let messageByUserId = await this.enrollCourseStudent(selectedUserList);
            let studentIds = [];
            let lmsUserArray = selectedUserList.map(row => { 
                let message = messageByUserId.get(row.SX_User_ID__c);
                if (message === 'User successfully assigned') {
                    studentIds.push(row.SX_User_ID__c);
                }
                return {...row, message};
            });
            this.studentList = lmsUserArray;
            this.studentColumns = RESULT_DATA_COLUMNS;
            this.isEnrollDisabled = true;
            if (studentIds.length > 0) {
                updateEnrollment({ courseId: this.sxCourseId, studentIds: studentIds })
                    .then(result => {
                        console.log("🚀 ~ file: courseEnrollment.js ~ line 85 ~ CourseEnrollment ~ handleOnEnrollClick ~ result", result);                        
                        this.updateRecordView();
                    })
                    .catch(error => {
                        handleError(error);
                    });
            } else {
                console.log("🚀 ~ file: courseEnrollment.js ~ line 87 ~ CourseEnrollment ~ handleOnEnrollClick ~ studentIds", studentIds.length);
            }
        } else {
            showToast(true, 'You must select a course to enroll');
        }
    }

    async enrollCourseStudent(selectedCourseList){
        const promises = selectedCourseList.map( row => enrollStudent({ courseId: this.sxCourseId, studentId: row.SX_User_ID__c }));
        const lmsMessageArray = await Promise.all(promises);
        let messageByUserId = new Map();
        for (let index = 0; index < selectedCourseList.length; index++) {
            messageByUserId.set(selectedCourseList[index].SX_User_ID__c, lmsMessageArray[index]);
        }
        return messageByUserId;
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