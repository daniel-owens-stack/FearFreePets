import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Toast from 'lightning/toast';
import getHistoricalOrders from '@salesforce/apex/B2BHistoricalOrdersListController.getHistoricalOrders';

export default class B2bHistoricalOrdersList extends NavigationMixin(LightningElement) {

    @api offsetValue;
    @api defaultSortingValue;
    
    parametersToPass = {};
    orderSummaryList = [];
    rowOffset = 0;

    orderSummaries;
    startDate;
    endDate;
    numberOfItems;
    
    hasOrders = false;
    showSpinner = false;
    visbleShowMore = false;
    isApplyBtnDisable = true;
    isPreview = false;
    isRendered = false;

    get noOrdersFound() {
        return !this.hasOrders && !this.showSpinner;
    }

    get sortOptions() {
        return [
            { label: 'Newest to Oldest', value: 'DESC' },
            { label: 'Oldest to Newest', value: 'ASC' }
        ];
    }

    connectedCallback() {
        this.isPreview = this.isInSitePreview();
        if(this.isPreview){
            this.noOrdersFound;
        } else {
            this.showSpinner = true;
            this.parametersToPass['sortingOrder'] = this.defaultSortingValue;
            this.handleGetOrderData();
        }
    }

    handleGetOrderData() {
        this.showSpinner = true;
        getHistoricalOrders({ 
            inputParameters: this.parametersToPass 
        })
        .then(result => {
            this.showSpinner = false;
            this.hasOrders = result.length > 0 ? true : false;

            if (this.hasOrders) {
                this.orderSummaries = result;
                this.orderSummaryList = this.orderSummaries.slice(0, parseInt(this.offsetValue));
                this.rowOffset = parseInt(this.offsetValue);
                this.numberOfItems = this.orderSummaryList.length;
                this.handleShowMoreButton();
            } else {
                this.visbleShowMore = false;
            }
        }).catch(error => {
                this.visbleShowMore = false;
                console.error('Error in getHistoricalOrders: ' + JSON.parse(JSON.stringify(error)));
                this.showToastMessage();
        })
    }

    handleShowMoreButton() {
        if (this.orderSummaryList[0].ordersCount === this.numberOfItems) {
            this.visbleShowMore = false;
        } else {
            this.visbleShowMore = true;
        }
    }

    handleStartDate(event) {
        this.startDate = event.target.value;
        this.parametersToPass['startDate'] = this.startDate;
        this.validateDateFields();
    }

    handleEndDate(event) {
        this.endDate = event.target.value;
        this.parametersToPass['endDate'] = this.endDate;
        this.validateDateFields();
    }

    validateDateFields() {
        let endDate = this.template.querySelector('[data-id="histEndDate"]');
        let startDate = this.template.querySelector('[data-id="histStartDate"]');

        if (this.endDate != undefined && this.startDate > this.endDate) {
            startDate.setCustomValidity("Start Date Should be less than end date");
            this.isApplyBtnDisable = true;
            this.removeCustomStyle();
        } else if (this.startDate <= this.endDate) {
            startDate.setCustomValidity("");
            this.isApplyBtnDisable = false;
            this.appendCustomStyle();
        }
        startDate.reportValidity();

        if (this.startDate != undefined && this.endDate < this.startDate) {
            endDate.setCustomValidity("End Date Should be greater than start date");
            this.isApplyBtnDisable = true;
            this.removeCustomStyle();
        } else if (this.endDate >= this.startDate) {
            endDate.setCustomValidity("");
            this.isApplyBtnDisable = false;
            this.appendCustomStyle();
        }
        endDate.reportValidity();
    }


    handleSortingChange(event) {
        let sortingOrder = event.target.value;
        this.parametersToPass['sortingOrder'] = sortingOrder;

        this.orderSummaryList.sort((a, b) => {
            if (sortingOrder == 'ASC') {
                return new Date(a.orderedDate) - new Date(b.orderedDate);
            } else if (sortingOrder == 'DESC') {
                return new Date(b.orderedDate) - new Date(a.orderedDate);
            }

        });
        this.handleGetOrderData();
    }

    handleShowMore() {
        this.orderSummaries.slice(this.rowOffset, parseInt(this.offsetValue) + this.rowOffset).forEach(itm => {
            this.orderSummaryList.push(itm);
        });
        this.numberOfItems = this.orderSummaryList.length;
        this.rowOffset = parseInt(this.offsetValue) + this.rowOffset;
        this.handleShowMoreButton();
    }

    handleApplyButton() {
        this.handleGetOrderData();
    }

    handleReset() {
        this.startDate = undefined;
        this.endDate = undefined;
        this.isApplyBtnDisable = true;

        delete this.parametersToPass['startDate'];
        delete this.parametersToPass['endDate'];

        this.handleGetOrderData();
    }

    handleViewOrderDetail(event) {
        let baseUrl = window.location.origin;
        let pathName = '/store/historical-order-detail?historicalOrderId=' + event.currentTarget.dataset.id;
        window.location.href = baseUrl + pathName;
    }

    showToastMessage() {
        Toast.show({
            label: 'Something went wrong !',
            message: 'Please Contact Administrator',
            mode: 'dismissable',
            variant: 'error'
        }, this);
    }

    isInSitePreview() {
        let url = document.URL;
        
        return (url.indexOf('sitepreview') > 0 
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0 
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }

    renderedCallback() {
        if(!this.isRendered) {
            this.appendCustomStyle();
            this.isRendered = true;
        }
    }

    appendCustomStyle() {
        let style = document.createElement('style');    
        style.innerText = '.slds-form-element__help {display: none !important;}';   
        this.template.querySelector('.dateFormatHelp').appendChild(style);
    }

    removeCustomStyle() {
        let style = document.createElement('style');    
        style.innerText = '.slds-form-element__help {display: flex !important;}';   
        this.template.querySelector('.dateFormatHelp').appendChild(style);
    }
}