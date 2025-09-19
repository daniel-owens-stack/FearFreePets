import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import updateStripeCustomer from '@salesforce/apex/B2B_StripeSyncController.updateStripeCustomer';

export default class B2bStripeDataSync extends LightningElement {

    _recordId;

    @api
    set recordId(value) {
        this._recordId = value;
        console.log('recordId set:', value);
        if(this._recordId){
            this.updateStripeCustomer();
        }
    }
    get recordId() {
        return this._recordId;
    }

    updateStripeCustomer(){
        let mapParams = {};
        mapParams.recordId = this.recordId;
        updateStripeCustomer({mapParams: mapParams})
        .then(result => {
            console.log('result: ' + result);
            if(result.isSuccess){
                console.log('result 2: ' + JSON.stringify(result));
                this.dispatchEvent(new CloseActionScreenEvent());
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Account data updated in Stripe",
                        variant: "success",
                    }),
                );
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: result.message,
                        variant: "error",
                    }),
                );
            }
        })
        .catch(error => {
            console.log('error: ' + error);
        });
    }
}