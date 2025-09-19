import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrderItems from '@salesforce/apex/StripeRefundController.getOrderItems';
import refundSelectedItems from '@salesforce/apex/StripeRefundController.refundSelectedItems';

export default class RefundModal extends LightningElement {
  @api recordId;
  @track items = [];
  @track showModal = false;
  @track totalRefund = 0;
  @track refundReason = '';
  @track isLoading = false;
  @track _disableSubmit = true;

  get isSubmitDisabled() {
    return this._disableSubmit;
  }

  // show “Membership Account” column only if any row has a value
  get showMembershipCol() {
    return (this.items || []).some(i => !!i.IlmaAccountName);
  }

  // ---------- Modal ----------
  openModal() {
    this.showModal = true;
    this.loadItems();
  }
  closeModal() {
    this.showModal = false;
  }

  // ---------- Data load ----------
  loadItems() {
    this.isLoading = true;
    getOrderItems({ orderSummaryId: this.recordId })
      .then(data => {
        this.items = data.map(i => {
          const total = Number(i.TotalAmtWithTax) || 0;
          const already = Number(i.RefundedAmount) || 0;
          const qty = Number(i.Quantity) || 0;
          const alreadyQty = Number(i.AlreadyRefundedQty) || 0;

          const remainingQty = Math.max(qty - alreadyQty, 0);
          const unitPrice = qty > 0 ? total / qty : 0;
          const rowDisabled = total <= 0 || total - already <= 0 || remainingQty === 0;

          return {
            ...i, // includes IlmaAccountName/Id
            alreadyRefunded: already,
            unitPrice,
            qtyToRefund: 0,
            partialAmount: 0,
            partialMax: Math.max(0, +(total - already).toFixed(2)),
            qtyOptions: Array.from({ length: remainingQty + 1 }, (_, n) => ({ label: n.toString(), value: n })),
            disabledCombobox: rowDisabled,
            disabledPartial: rowDisabled,
            rowClass: rowDisabled ? 'slds-text-color_weak' : ''
          };
        });
        this.updateTotal();
      })
      .catch(err => this.showError('Error loading items', err?.body?.message || err?.message))
      .finally(() => (this.isLoading = false));
  }

  // ---------- Handlers ----------
  handleReasonChange(e) {
    this.refundReason = e.target.value || '';
    this.updateTotal();
  }

  handleQtyChange(e) {
    const itemId = e.target.dataset.id;
    const selected = parseInt(e.detail.value, 10) || 0;

    this.items = this.items.map(it => {
      if (it.Id !== itemId) return it;

      const next = { ...it, qtyToRefund: selected, partialAmount: 0 };

      const rowDisabled = next.TotalAmtWithTax <= 0 ||
                          (next.TotalAmtWithTax - next.alreadyRefunded) <= 0;
      next.disabledCombobox = rowDisabled || false;
      next.disabledPartial  = rowDisabled || selected > 0;

      const qtyRefundAmt = (selected || 0) * (next.unitPrice || 0);
      next.partialMax = Math.max(0, +((next.TotalAmtWithTax - next.alreadyRefunded) - qtyRefundAmt).toFixed(2));
      next.rowClass = (rowDisabled ? 'slds-text-color_weak' : '');

      return next;
    });

    this.updateTotal();
  }

  handlePartialChange(e) {
    const itemId = e.target.dataset.id;
    let value = parseFloat(e.target.value);
    if (isNaN(value) || value < 0) value = 0;

    this.items = this.items.map(it => {
      if (it.Id !== itemId) return it;

      const max = Number(it.partialMax) || 0;
      const clamped = Math.min(value, max);

      const next = {
        ...it,
        partialAmount: +clamped.toFixed(2),
        qtyToRefund: 0
      };

      const rowDisabled = (it.TotalAmtWithTax <= 0) ||
                          (it.TotalAmtWithTax - it.alreadyRefunded <= 0);
      next.disabledCombobox = rowDisabled || clamped > 0;
      next.disabledPartial  = rowDisabled || false;
      next.rowClass = (rowDisabled ? 'slds-text-color_weak' : '');

      return next;
    });

    this.updateTotal();
  }

  // ---------- Totals / submit state ----------
  updateTotal() {
    const sum = this.items.reduce((acc, it) => {
      const qtyAmt = (Number(it.qtyToRefund) || 0) * (it.unitPrice || 0);
      const partialAmt = Number(it.partialAmount) || 0;
      return acc + qtyAmt + partialAmt;
    }, 0);

    this.totalRefund = +sum.toFixed(2);
    this._disableSubmit = this.isLoading || !this.refundReason || this.totalRefund <= 0;
  }

  // ---------- Submit ----------
  submitRefund() {
    this.isLoading = true;

    const linePayload = this.items
      .filter(i => (i.qtyToRefund > 0) || (i.partialAmount > 0))
      .map(i => ({
        itemId: i.Id,
        qtyToRefund: i.qtyToRefund > 0 ? Number(i.qtyToRefund) : 0,
        partialAmount: i.qtyToRefund > 0 ? 0 : (Number(i.partialAmount) || 0)
      }));

    const payload = {
      orderSummaryId: this.recordId,
      refundReason: this.refundReason,
      itemRefundsRaw: linePayload
    };

    refundSelectedItems(payload)
      .then(() => {
        this.showSuccess('Refund processed successfully.');
        return this.loadItems();
      })
      .catch(err => this.showError('Refund failed', err?.body?.message || err?.message))
      .finally(() => {
        this.isLoading = false;
        this.updateTotal();
        this.closeModal();
        setTimeout(() => { window.location.reload(); }, 2000);
      });
  }

  // ---------- Toast helpers ----------
  showSuccess(message) {
    this.dispatchEvent(new ShowToastEvent({ title: 'Success', message, variant: 'success' }));
  }
  showError(title, message) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
  }
}