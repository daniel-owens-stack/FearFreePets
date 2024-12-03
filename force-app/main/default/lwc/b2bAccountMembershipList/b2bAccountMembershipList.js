import { LightningElement, api } from 'lwc';
import getAccountMemberships from '@salesforce/apex/B2BAccontMembershipListController.getAccountMemberships';

const columns = [
    { label: 'Account Name', fieldName: 'accountLink', type:'url',
        typeAttributes: {
            label: { 
                fieldName: 'accountName'
            },
            target : '_self'
        }
    },
    { label: 'Purchase Date', fieldName: 'purchaseDate', type: 'date' },
    { label: 'Assignment Date', fieldName: 'accountAssignmentDate', type: 'date' },
    { label: 'Expiration Date', fieldName: 'expirationDate', type: 'date' },
    { label: 'Certification Status'},
    { label: 'Course Progress'}
];

export default class B2bAccountMembershipList extends LightningElement {

    @api recordId;
    error;
    columns = columns;
    groupedData = [];

    connectedCallback() {
        console.log('record Id: ', this.recordId);
        if(this.recordId != undefined && this.recordId != null) {
            this.getAccountMembershipsList();
        }
    }

    getAccountMembershipsList() {
        getAccountMemberships({
            accountId : this.recordId
        })
        .then((result) => {
            console.log('Account Membership List : ', result);
            if(result != null) {
                this.groupedData = this.groupData(result[0]);
            }
        })
        .catch((error) => {
            this.error = 'No Data Found.';
            console.log('Error in getAccountMemberships : ', error);
        })
    }

    groupData(data) {
        const groupedMap = {};
        data.forEach(record => {
            const fieldValue = record.membershipName;
            if (!groupedMap[fieldValue]) {
                groupedMap[fieldValue] = [];   
            }
            groupedMap[fieldValue].push(record);
        });
        
        return Object.keys(groupedMap).map(key => ({
            Name: key,
            records: groupedMap[key],
            count: this.getAccountCount(groupedMap[key])
        }));
    }

    getAccountCount(records) {
        let unassignedCount = 0;
        let assignedCount = 0;

        records.forEach(row => {
            if (row.accountName === 'Unassigned') {
                unassignedCount++;
            } else {
                assignedCount++;
            }
        });
        return { assigned: assignedCount, unassigned: unassignedCount }
    }
}