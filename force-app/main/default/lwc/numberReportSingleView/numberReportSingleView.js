import { LightningElement, api, wire, track } from 'lwc';
import userId from '@salesforce/user/Id';
import getMembershipCount from '@salesforce/apex/NumberReportViewController.getMembershipCount';

export default class NumberReportSingleView extends LightningElement 
{
    @api configurationtype;
    userId = userId;
    @track mapData = [];

    @wire(getMembershipCount, {userId: userId, metaDataApiName: '$configurationtype'}) getMembershipCount({ error, data }) 
    {
        if (data)
        {
            for (let key in data) 
            {
                this.mapData.push({value:data[key], key:key});
            }
            console.log('mapData = ' + JSON.stringify(this.mapData));
        }
        else if (error) 
        {
            console.log('Error is ' + JSON.stringify(error));
        }

    }
}