import { LightningElement } from 'lwc';
import Toast from 'lightning/toast';
import getOrderSummaryItems from '@salesforce/apex/B2BOrderHistoryListController.getOrderSummaryItems';

export default class B2bOrderDetail extends LightningElement {

    orderSummaryId;
    orderSummaryItems;
    shippingMethod;
    shippingSubTotal;
    formattedAddress;

    shippingAddress = {};
    osDetailSection = {};
    osTotalSection = {};

    showShipping = false;
    showSpinner = false;
    isPreview = false;

    connectedCallback() {
        this.isPreview = this.isInSitePreview();
        
        if(!this.isPreview) {
            var url = window.location.href;
            var searchParams = new URLSearchParams(new URL(url).search);
            this.orderSummaryId = searchParams.get('orderSummaryId');
            this.handleGetOrderProductsData();
        }
    }

    handleGetOrderProductsData() {
        this.showSpinner = true;
        getOrderSummaryItems({
            orderSummaryId: this.orderSummaryId
        })
            .then(result => {
                this.showSpinner = false;

                if (result.orderProductWrap.length > 0) {
                    this.orderSummaryItems = result.orderProductWrap;
                }

                //Details
                this.osDetailSection['orderNumber'] = result.osDetails.orderNumber;
                this.osDetailSection['orderedDate'] = result.osDetails.orderedDate;
                this.osDetailSection['accountName'] = result.osDetails.accountName;
                this.osDetailSection['orderPlacedBy'] = result.osDetails.orderPlacedBy;
                this.osDetailSection['orderStatus'] = result.osDetails.orderStatus;
                this.osDetailSection['productCount'] = result.osDetails.productCount;

                //Totals
                this.osTotalSection['subtotal'] = result.osTotals.subtotal;
                this.osTotalSection['shipping'] = result.osTotals.shipping;
                this.osTotalSection['tax'] = result.osTotals.tax;
                this.osTotalSection['total'] = result.osTotals.total; 
                this.osTotalSection['refundedAmount'] = result.osTotals.refundedAmount;
                this.osTotalSection['showRefundedAmount'] = result.osTotals.showRefundedAmount;
                this.osTotalSection['totalAmountAfterRefund'] = result.osTotals.totalAmountAfterRefund;
                
                //Shipping 
                this.shippingAddress['street'] = result.shippingAddress.deliverToStreet;
                this.shippingAddress['city'] = result.shippingAddress.deliverToCity;
                this.shippingAddress['state'] = result.shippingAddress.deliverToState;
                this.shippingAddress['postalCode'] = result.shippingAddress.deliverToPostalCode;
                this.shippingAddress['country'] = result.shippingAddress.deliverToCountry;
                this.shippingMethod = result.shippingAddress.deliveryMethod;
                this.shippingSubTotal = result.osTotals.shippingSubTotal;

                //Handle Shipping Section Visibility
                this.showShipping = result.osDetails.hasShippableProducts;
                if(this.showShipping) {
                    this.formattedAddress = this.formatAddress();
                }

            }).catch((error) => {
                console.error('Error in getOrderSummaryItems: ', error);

                Toast.show({
                    label: 'Something went wrong !',
                    message: 'Please Contact Administrator',
                    mode: 'dismissable',
                    variant: 'error'
                }, this);
            })
    }

    formatAddress() {
        const { street, city, state, postalCode, country } = this.shippingAddress;
    
        const addressParts = [
            street,
            city,
            state ? `${state} ${postalCode || ''}`.trim() : postalCode,
            country
        ].filter(part => part);
    
        return addressParts.join(', ');
    }

    isInSitePreview() {
        let url = document.URL;
        
        return (url.indexOf('sitepreview') > 0 
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0 
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }
}