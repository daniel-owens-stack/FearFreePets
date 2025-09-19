import { LightningElement } from 'lwc';
import { api } from 'lwc';

import ModalScreenFlow from "c/modalScreenFlow";

export default class ModalScreenFlowParent extends LightningElement 
{
    @api flowApiName;
    @api modalLabel;
    @api buttonLabel;
    @api buttonAllignment;
    @api buttonColor;
    @api buttonTextColor;
    @api buttonIcon;
    @api buttonIconPosition;
    @api buttonFullWidth = false;

    buttonClass = 'button1';

    get buttonClassName()
    {
        return this.buttonClass;
    }

    renderedCallback() 
    {
        this.template.querySelector('.button1').style.setProperty('--buttonColor', this.buttonColor);
        this.template.querySelector('.button1').style.setProperty('--buttonTextColor', this.buttonTextColor);
    }

    openModal()
    {
        ModalScreenFlow.open({
            label: this.modalLabel,
            flowApiName: this.flowApiName
        }).then((result) => {

            /*this.dispatchEvent(
                new ShowToastEvent({
                    title: 'PTM record added.',
                    variant: 'success',
                    mode: 'dismissible'
                })
            );*/

        });
    }
}