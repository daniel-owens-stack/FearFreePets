import { LightningElement, wire } from 'lwc';
import getUserCourse from '@salesforce/apex/B2BEnrollmentSyncController.getUserEnrollments';

export default class B2bSyncEnrollmentsOnRender extends LightningElement {
    sxUserId = 'someUserId'; // Replace this with the actual value or make it dynamic

    connectedCallback() {
        this.syncEnrollments();
    }

    syncEnrollments() {
        getUserCourse({ sxUserId: this.sxUserId })
            .then(() => {
                console.log('Courses synced successfully');
            })
            .catch((error) => {
                console.error('Error syncing courses:', error);
            });
    }
}