import { LightningElement, wire, api } from 'lwc';
import GET_INVOICES from '@salesforce/apex/B2BInvoiceHelper.getInvoices';

export default class B2bInvoiceTable extends LightningElement {

    columns;
    invoices;
    error;
    @api recordId;
    @api labelInvoiceNumber;
    @api labelTotal;
    @api labelAmountCharged;
    @api labelPeriod;
    @api labelCreatedDate;
    @api labelPaidDate;
    @api labelDownloadLink;
    @api labelPayNow;
    @api buttonLabelDownloadLink;
    @api buttonLablePayNow;
    @api billingEmail;

    connectedCallback() {
        this.setTableColumns();
    }

    setTableColumns() {
        this.columns = [
            { label: this.labelInvoiceNumber, fieldName: 'invoiceNumber', type: 'text' },
            { label: this.labelTotal, fieldName: 'total', type: 'currency', 
                typeAttributes: { currencyCode: 'USD' },
                cellAttributes: { alignment: 'left' }
            },
            { label: this.labelAmountCharged, fieldName: 'amountCharged', type: 'currency', 
                typeAttributes: { currencyCode: 'USD' },
                cellAttributes: { alignment: 'left' }
            },
            { label: this.labelPeriod, fieldName: 'period', type: 'text' },
            { label: this.labelCreatedDate, fieldName: 'createdDate', type: 'date' },
            { label: this.labelPaidDate, fieldName: 'paidDate', type: 'date' },
            { label: this.labelDownloadLink, type: 'button',
                typeAttributes:
                {
                    label: this.buttonLabelDownloadLink,   
                    name: 'download',
                    variant: 'brand',
                    title: 'Download',
                    iconName: 'utility:download',
                    iconPosition: 'right'
                },
                fieldName: 'downloadLink'
            },
            {
                label: this.labelPayNow, type: 'button',
                typeAttributes: {
                    label: this.buttonLablePayNow,
                    name: 'pay_now',
                    variant: 'brand',
                    title: 'Pay',
                    disabled: {fieldName: 'disablePayNow'}
                },
                fieldName: 'paymentLink'
            },
            { label: this.billingEmail, fieldName: 'billingEmail', type: 'text' },
        ];
    }

    @wire(GET_INVOICES, {})
    wiredInvoices({ data, error }) {
        console.log('Invoices: ', data);
        if (data) {
            this.invoices = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.invoices = undefined;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        if (actionName === 'pay_now') {
            window.open(event.detail.row.paymentLink, '_blank');
        }
        else if(actionName === 'download') {
            window.open(event.detail.row.downloadLink, '_blank');
        }
    }

    renderedCallback() {
        let style = document.createElement('style');    
        style.innerText = '.slds-table tr:first-child td{border-top: 1px solid var(--slds-g-color-border-base-1, #e5e5e5) !important;}';   
        this.template.querySelector('lightning-datatable').appendChild(style);
    }
}