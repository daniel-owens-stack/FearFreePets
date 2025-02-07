import { LightningElement, wire, api } from 'lwc';
import GET_INVOICES from '@salesforce/apex/B2BInvoiceHelper.getInvoices';

export default class B2bInvoiceTable extends LightningElement {

    columns;
    invoices;
    error;
    noInvoices;
    activeSections = [];
    @api recordId;
    @api labelInvoiceNumber;
    @api labelAmountCharged;
    @api labelBillingEmail;
    @api labelPeriod;
    @api labelCreatedDate;
    @api labelPaidDate;
    @api buttonLabelDownloadLink;
    @api buttonLablePayNow;
    @api noInvoicesMessage;
    @api invoiceHeading;


    @wire(GET_INVOICES, {})
    wiredInvoices({ data, error }) {
        this.noInvoices = data != undefined ? false : true;
        if (data) {
            this.invoices = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.invoices = undefined;
            this.noInvoices = true;
            console.error('Error in get invoices: ', this.error);
        }
    }

    handleDownload(event) {
        const downloadLink = event.currentTarget.dataset.url;
        if(downloadLink) {
            window.open(downloadLink, '_blank');
        }
    }

    handlePayNow(event) {
        const paymentLink = event.currentTarget.dataset.url;
        if(paymentLink) {
            window.open(paymentLink, '_blank');
        }
    }
}