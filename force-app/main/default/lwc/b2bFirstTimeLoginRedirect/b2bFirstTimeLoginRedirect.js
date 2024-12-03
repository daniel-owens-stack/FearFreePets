import { LightningElement} from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import {NavigationMixin} from 'lightning/navigation';
import isFirstTimeLogin from '@salesforce/apex/B2BUtils.isFirstTimeLogin';

export default class B2bFirstTimeLoginRedirect extends NavigationMixin(LightningElement) {

    isPreview = false;
    recordId;

    connectedCallback() {
        this.isPreview = this.isInSitePreview();
        if(!isGuest && !this.isPreview) {
            this.checkLoginHistory();
        }
    }

    isInSitePreview() {
        let url = document.URL;
        
        return (url.indexOf('sitepreview') > 0 
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0 
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }

    checkLoginHistory() {
        isFirstTimeLogin()
        .then(result => {
            if(result != null) {
                this.recordId = result;
                this.redirectToProductPage();
            }
        })
        .catch(error => {
            console.error('Error in checkLoginHistory: ', error);
        })
    }

    redirectToProductPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'Product2',
                actionName: 'view',
                recordId: this.recordId
            },
        });
    }
}