import { LightningElement, api, track } from 'lwc';

export default class B2bLoginRedirectButton extends LightningElement {
    @api url;
    @track urlValue;
    isLoading = false;

    connectedCallback() {
        this.urlValue = this.url;
        this.handleClick();
    }

    handleClick() {
        this.isLoading = true;
        if (this.urlValue) {
            window.open(this.urlValue, '_self');
        } else {
            console.error('URL is not set');
        }
    }
}