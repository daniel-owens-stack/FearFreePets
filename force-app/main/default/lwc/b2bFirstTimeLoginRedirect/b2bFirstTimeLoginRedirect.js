import { LightningElement, api} from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import {NavigationMixin} from 'lightning/navigation';
import isFirstTimeLogin from '@salesforce/apex/B2BUtils.isFirstTimeLogin';

export default class B2bFirstTimeLoginRedirect extends NavigationMixin(LightningElement) {

    @api pageType;
    @api objectApiName;
    @api categoryId;

    isPreview = false;
    recordId;

    connectedCallback() {
        this.isPreview = this.isInSitePreview();
        if(!isGuest && !this.isPreview) {
            this.checkLoginHistory();
        }

        if(isGuest && !this.isPreview) {
            this.redirectToCategoryPage();
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
            if(result == 'LoggedInMoreThanOnce' || result == 'No Account') {
                return;
            } else {
                let productId = result;

                if(productId == null) {
                    this.redirectToCategoryPage();
                }
                else if(productId != null) {
                    this.recordId = productId;
                    this.redirectToProductPage();
                }
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

    redirectToCategoryPage() {
        this[NavigationMixin.Navigate]({
            type: this.pageType,
            attributes: {
                objectApiName: this.objectApiName,
                actionName: 'view',
                recordId: this.categoryId
            }
        });
    }
}