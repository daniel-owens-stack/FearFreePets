import { LightningElement, api } from 'lwc';

export default class ffReloadPage extends LightningElement {
    @api shouldReload;     // Flow input
    @api status;           // Flow output (optional)

    connectedCallback() {
        if (this.shouldReload) {
            this.status = 'Reload triggered';
            setTimeout(() => {
                window.location.reload();
            }, 100);
        } else {
            this.status = 'Reload skipped';
        }
    }
}