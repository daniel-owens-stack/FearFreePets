import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class PicklistAutoNext extends LightningElement {
    @api picklistVals = [];
    @api selectedVal;
    @api availableActions = [];

    get options() {
        return this.picklistVals.map(v => ({
            label: v,
            value: v
        }));
    }

    handleChange(event) {
        this.selectedVal = event.detail.value;
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedVal', event.detail.value));
        
        if (this.availableActions.find((action) => action === 'NEXT')) {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
        else if (this.availableActions.find((action) => action === 'FINISH')) {
            const navigateFinishEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateFinishEvent);
        }
        else {
            console.log('Error: NEXT or FINISH navigation not available on this flow screen');
        }
        
    }
}