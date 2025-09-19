import { LightningElement, api, wire } from 'lwc';
import getOrdersForCase from '@salesforce/apex/B2BOrderSummaryFromCaseController.getOrdersForCase';

export default class B2BCaseOrderList extends LightningElement {
    @api recordId;
    orders;
    error;
    isLoading = true;

   columns = [
    {
        label: 'Order Summary Number',
        fieldName: 'orderUrl',
        type: 'url',
        initialWidth: 350,
        typeAttributes: {
            label: { fieldName: 'orderNumber' },
            target: '_blank'
        }
    },
    {
        label: 'Ordered Date',
        fieldName: 'orderedDate',
        type: 'date',
    },
    {
        label: 'Total',
        fieldName: 'totalAmount',
        type: 'currency',
    }
];


    @wire(getOrdersForCase, { caseId: '$recordId' })
    wiredOrders({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.orders = data.map(order => ({
                Id: order.Id,
                orderNumber: order.OrderNumber,
                orderedDate: order.OrderedDate,
                totalAmount: order.TotalAmount,
                orderUrl: `/lightning/r/OrderSummary/${order.Id}/view`
            }));
            this.error = undefined;
        } else if (error) {
            this.error = 'Error loading order summaries.';
            this.orders = undefined;
            console.error(error);
        }
    }
}