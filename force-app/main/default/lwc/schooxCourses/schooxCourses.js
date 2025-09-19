import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getFieldValue } from 'lightning/uiRecordApi';
import { handleError, showToast } from 'c/customToast';

import ID_FIELD from '@salesforce/schema/SX_Enrollment__c.Id';
import COURSE_ID_FIELD from '@salesforce/schema/SX_Enrollment__c.SX_Course__c';
import COURSE_NAME_FIELD from '@salesforce/schema/SX_Enrollment__c.SX_Course__r.Name';
import COURSE_URL_FIELD from '@salesforce/schema/SX_Enrollment__c.SX_Course__r.SX_Course_URL__c';
import COURSE_STATUS_FIELD from '@salesforce/schema/SX_Enrollment__c.Course_Status__c';
import COURSE_ENROLLMENT_DATE_FIELD from '@salesforce/schema/SX_Enrollment__c.SX_Enrollment_Date__c';
import COURSE_COMPLETED_DATE_FIELD from '@salesforce/schema/SX_Enrollment__c.SX_Completed_Date__c';
import COURSE_COMPLETED_PERCENTAGE_FIELD from '@salesforce/schema/SX_Enrollment__c.SX_percent_Completed__c';
import COURSE_IMAGE_URL_FIELD from '@salesforce/schema/SX_Enrollment__c.SX_Course__r.SX_Course_Image_URL__c';

export default class SchooxCourses extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    enrolledCourses = [];
    enrolledCoursesData = [];

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'SX_Enrollments__r',
        fields: ['SX_Enrollment__c.Id', 'SX_Enrollment__c.SX_Course__c','SX_Enrollment__c.SX_Course__r.Name','SX_Enrollment__c.Course_Status__c', 'SX_Enrollment__c.SX_Course__r.SX_Course_URL__c', 'SX_Enrollment__c.SX_Enrollment_Date__c', 'SX_Enrollment__c.SX_Completed_Date__c', 'SX_Enrollment__c.SX_percent_Completed__c', 'SX_Enrollment__c.SX_Course__r.SX_Course_Image_URL__c'],
        sortBy: ['SX_Enrollment__c.SX_Course__r.Name']
    }) listInfo( value ) {
        this.enrolledCoursesData = value; //To use in refresh cache
        const {data, error} = value;
        if (data) {
            this.enrolledCourses = [];
            data.records.forEach( obj => {
                let tempBuyer = {
                    // sObjectType                 : 'SX_Enrollment__c',
                    Id                          : obj.id,                    
                    courseId                    : this.getCourseId(obj),
                    Name                        : this.getCourseName(obj),
                    Course_URL                  : this.getCourseUrl(obj),
                    Course_Status               : this.getCourseStatus(obj),
                    Enrollment_Date             : this.getEnrollmentDate(obj),
                    Completed_Date              : this.getCompletedDate(obj),
                    Completed_Percentage        : this.getCompletedPercentage(obj),
                    Course_Image_URL_Link       : this.getCourseImage(obj)
                };
                tempBuyer.courseURL = `/${tempBuyer.courseId}`;
                this.enrolledCourses.push(tempBuyer);
            });
            // console.log("🚀 ~ file: schooxCourses.js ~ line 47~ SchooxCourses ~ this.enrolledCourses", this.enrolledCourses);
        } else if (error) {
            this.enrolledCourses = undefined;
            handleError(error);
        }
    }

    get enrolledCoursesSize() {
        return this.enrolledCourses.length;
    }
    getId(enrolledCourse) {
        return getFieldValue(enrolledCourse, ID_FIELD);
    }
    getCourseId(enrolledCourse) {
        return getFieldValue(enrolledCourse, COURSE_ID_FIELD);
    }
    getCourseName(enrolledCourse) {
        return getFieldValue(enrolledCourse, COURSE_NAME_FIELD);
    }    
    getCourseUrl(enrolledCourse) {
        return getFieldValue(enrolledCourse, COURSE_URL_FIELD);
    }
    getCourseStatus(enrolledCourse) {
        return getFieldValue(enrolledCourse, COURSE_STATUS_FIELD);
    }
    getEnrollmentDate(enrolledCourse) {
        return getFieldValue(enrolledCourse, COURSE_ENROLLMENT_DATE_FIELD);
    }
    getCompletedDate(enrolledCourse) {
        return getFieldValue(enrolledCourse, COURSE_COMPLETED_DATE_FIELD);
    }
    getCompletedPercentage(enrolledCourse) {
        return getFieldValue(enrolledCourse, COURSE_COMPLETED_PERCENTAGE_FIELD) / 100.0;
    }
    getCourseImage(enrolledCourse) {
        return getFieldValue(enrolledCourse, COURSE_IMAGE_URL_FIELD);
    }

    handleOnLaunch(event) {
        let selectedItem = event.target.dataset.item;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: selectedItem
            }
        });
    }

    handleOnClick(event) {
        let selectedId = event.target.dataset.item;
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: selectedId,
                objectApiName: 'SX_Course__c',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

}