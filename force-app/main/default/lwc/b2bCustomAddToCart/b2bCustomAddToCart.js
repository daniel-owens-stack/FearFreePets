import { LightningElement, api, wire } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ToastContainer from 'lightning/toastContainer';
import {addItemToCart} from 'commerce/cartApi';
import isVariantProduct from '@salesforce/apex/B2BCustomAddToCartController.isVariantProduct';
import getProductGroup from '@salesforce/apex/B2BCustomAddToCartController.getProductGroup';
import isAdminAccount from '@salesforce/apex/B2BCustomAddToCartController.isAdminAccount';
import getPracticeLevelMemberships from '@salesforce/apex/B2BCustomAddToCartController.getPracticeLevelMemberships';
import getIndividualLevelMemberships from '@salesforce/apex/B2BCustomAddToCartController.getIndividualLevelMemberships';
import isProductPresentInCart from '@salesforce/apex/B2BCustomAddToCartController.isProductPresentInCart';
import modalWindow from 'c/b2bCustomModalWindow';

export default class B2bCustomAddToCart extends NavigationMixin(LightningElement) {

    @api academiaMembership;
    @api individualMembership;
    @api practiceMembership;
    @api addToCartButtonLabel;
    @api addToCartSuccessMessage;
    @api addToCartSuccessTitle;
    @api addToCartErrorMessage;
    @api addToCartErrorTitle;
    @api checkboxText_TOS;
    @api contentText_TOS;
    @api modalSize;
    @api continueButton;
    @api viewCartButton;
    @api headingLabel;
    @api flowApiName;
    productId;
    isVariant = false;
    isLoading = false;
    definedQuantity = 1;
    isQtyOne = true;
    showQtySelector = false;
    showAddToCart = false;
    errorMessage = '';
    productGroup;
    isAdmin = false;
    isPreview = false;
    showTermsOfService = false;
    termsAgreed = false;
    disableBtn = false;
    showFlowScreen = false;

    connectedCallback() {
        this.isPreview = this.isInSitePreview();
        if(this.isPreview){
            this.showQtySelector = true;
            this.showAddToCart = true;
            this.showTermsOfService = true;
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

    @wire(CurrentPageReference)
    async getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.productId = currentPageReference.attributes.recordId;

            const toastContainer = ToastContainer.instance();
            toastContainer.maxToasts = 5;
            toastContainer.toastPosition = 'top-center';

            await this.checkvariationProduct();

        } 
        else {
            console.error('Product Id not found');
            this.isLoading = false;
        }
    }

    async checkvariationProduct() {
        isVariantProduct({productId: this.productId})
            .then(result => {
                this.isLoading = false;
                this.isVariant = result;
                if(this.isVariant) {
                    this.isLoading = true;
                    if(isGuest) {
                        this.showAddToCart = true;
                        this.showQtySelector = false;
                        this.isLoading = false;
                    }
                    else {
                        this.checkProductGroup();
                    }
                }
            })
            .catch(error => {
                console.log('Error in checkvariationProduct: ', error);
                this.isLoading = false;
            });
    }

    checkProductGroup() {
        getProductGroup({productId : this.productId})
        .then(result => {
            this.productGroup = result;

            if(this.productGroup === this.academiaMembership) {
                this.checkifAccountHasAcademiaMembership();
            } 
            else {
                this.checkIsAdminAccount();
            }
        })
        .catch(error => {
            console.log('Error in checkProductGroup: ', error);
            this.isLoading = false;
        });
    }

    checkifAccountHasPracticeLevelMembership() {
        getPracticeLevelMemberships({
            productId : this.productId
        })
        .then(result => {
            if(result.length > 0) {
                this.showQtySelector = false;
                this.showAddToCart = false;
                this.showTermsOfService = false;
                this.isLoading = false;
            }
            else {
                this.checkifProductIsInCart();
            }
        })
        .catch(error => {
            console.log('Error in checkifAccountHasPracticeLevelMembership: ', error);
            this.isLoading = false;
        })
    }

    checkifAccountHasAcademiaMembership() {
        getIndividualLevelMemberships({
            productId : this.productId
        })
        .then(result => {
            if(result.length > 0) {
                this.showQtySelector = false;
                this.showAddToCart = false;
                this.showTermsOfService = false;
                this.isLoading = false;
            }
            else {
                this.checkifProductIsInCart();
            }
        })
        .catch(error => {
            console.log('Error in checkifAccountHasAcademiaMembership: ', error);
            this.isLoading = false;
        })
    }

    checkifProductIsInCart() {
        isProductPresentInCart({
            productId : this.productId
        })
        .then(result => {
            if(result) {
                this.showQtySelector = false;
                this.showAddToCart = false;
                this.showTermsOfService = false;
                this.isLoading = false;
            }
            else {
                this.handleVisibility();
            }
        })
        .catch(error => {
            console.log('Error in checkifProductIsInCart: ', error);
            this.isLoading = false;
        })
    }

    checkIsAdminAccount() {
        isAdminAccount({})
        .then(result => {
            this.isAdmin = result;
            if(this.isAdmin === false && this.productGroup === this.individualMembership) {
                this.checkifProductIsInCart();
            }
            else if(this.isAdmin && this.productGroup === this.practiceMembership) {
                this.checkifAccountHasPracticeLevelMembership();
            }
            else {
                this.handleVisibility();               
            }
        })
        .catch(error => {
            console.log('Error in checkIsAdminAccount: ', error);
            this.isLoading = false;
        })
    }

    handleVisibility() {
        if((this.productGroup === this.academiaMembership) || (this.productGroup === this.practiceMembership && this.isAdmin) || 
           (this.productGroup === this.individualMembership && this.isAdmin === false)) {
                this.showQtySelector = false;
                this.showAddToCart = true;
                this.showTermsOfService = this.productGroup === this.practiceMembership;
                this.disableBtn = this.showTermsOfService;
        }
        else if( this.productGroup === this.practiceMembership && !this.isAdmin) {
            this.showQtySelector = false;
            this.showAddToCart = false;
            this.showTermsOfService = false;
        }
        else {
            this.showQtySelector = true;
            this.showAddToCart = true;
            this.showTermsOfService = false;
        }
        this.isLoading = false;
    }

    handleAddToCart() {
        if(isGuest) {
            this.showFlowScreen = true;
        }
        else {
            addItemToCart(
                this.productId, this.definedQuantity
            )
            .then(async () => {
                if((this.productGroup === this.academiaMembership) || (this.productGroup === this.practiceMembership) || 
                    (this.productGroup === this.individualMembership && this.isAdmin === false)) {
                        this.showQtySelector = false;
                        this.showAddToCart = false;
                        this.showTermsOfService = false;
                }
                //Open Modal Window
                await modalWindow.open({
                    size: this.modalSize,
                    modalHeading: this.addToCartSuccessTitle,
                    modalContent: this.addToCartSuccessMessage,
                    button1Label: this.continueButton,
                    button2Label: this.viewCartButton,
                    onselectedbutton: (event) => {
                        this.handleSelectedButton(event);
                    }
                });
            })
            .catch(error => {
                console.log('Error in AddToCart : ', error);
                this.addToCartErrorMessage = error.body.message;
                this.fireToastMsg('error', this.addToCartErrorTitle, this.addToCartErrorMessage);
            });
        }
    }

    handleSelectedButton = (event) => {
        const selectedButton = event.detail;
        if (selectedButton === 'viewCart') {
            //Redirect to Cart Page
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Current_Cart',
                },
            });
        }
    }

    fireToastMsg(variant, title, message) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            message: message,
            mode: 'dismissible'
        });
        this.dispatchEvent(event);
    }

    handleDecrement() {
        if(this.definedQuantity == 1) {
            this.isQtyOne = true;
        } 
        else if(this.definedQuantity > 1) {
            this.definedQuantity--;
        }
    }

    handleIncrement() {
        this.definedQuantity++;
        this.isQtyOne = false;
    }

    handleQuantityChange(event) {
        this.definedQuantity = event.target.value;
        if(this.definedQuantity < 0 || this.definedQuantity == '') {
            this.definedQuantity = 1;
        }
    }

    handleTOSChange(event) {
        this.termsAgreed = event.detail.isChecked;
        this.disableBtn = this.termsAgreed ? false : true;
    }

    handleFlowFinish(event) {
        if(event.detail.interviewStatus === 'FINISHED_SCREEN') {
            this.showFlowScreen = false;
        }
    }

    get flowInputVariables() {
        return [
            { name: 'varProductId', type: 'String', value: this.productId}
        ];
    }
}