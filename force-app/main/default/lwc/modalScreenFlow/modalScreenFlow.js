import LightningModal from 'lightning/modal';
import { api } from 'lwc';

export default class ModalScreenFlow extends LightningModal {

    @api label;
    @api flowApiName;

    handleStatusChange(event) 
    {
        if (event.detail.status === 'FINISHED') 
        {
            this.close();
        }
        else if(event.detail.status === 'STARTED' && this.flowNotRunning == false)
        {
            console.log('flow started ' + event.detail.status);
        }
    }
}