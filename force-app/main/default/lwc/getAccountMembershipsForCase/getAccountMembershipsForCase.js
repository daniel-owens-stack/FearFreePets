import { LightningElement, api, wire } from 'lwc';
import getAccountMembershipsForCase from '@salesforce/apex/B2BILMAFromCaseController.getAccountMembershipsForCase';

export default class B2BCaseAccountMembershipList extends LightningElement {
    @api recordId;
    memberships;
    error;
    isLoading = true;

    columns = [
        {
            label: 'Account Membership Name',
            fieldName: 'membershipUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'name' },
                target: '_blank'
            }
        },
        {
            label: 'Membership',
            fieldName: 'membershipLookupUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'membershipName' },
                target: '_blank'
            }
        },
        {
            label: 'Assignment Date',
            fieldName: 'accountAssignmentDate',
            type: 'date',
        },
        {
            label: 'Status',
            fieldName: 'status',
            type: 'text',
        }
    ];

    @wire(getAccountMembershipsForCase, { caseId: '$recordId' })
    wiredMemberships({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.memberships = data.map(rec => ({
                id: rec.Id,
                name: rec.Name,
                membershipUrl: `/lightning/r/Account_Membership__c/${rec.Id}/view`,
                membershipName: rec.Membership__r?.Name,
                membershipLookupUrl: rec.Membership__c
                    ? `/lightning/r/Membership__c/${rec.Membership__c}/view`
                    : '',
                accountAssignmentDate: rec.Account_Assignment_Date__c,
                status: rec.Status__c
            }));
            this.error = undefined;
        } else if (error) {
            this.error = 'Error loading account memberships.';
            this.memberships = undefined;
            console.error(error);
        }
    }
}