import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getEligibleMemberships from '@salesforce/apex/FFAddPracCertProdToCart.getEligibleMemberships';
import getProductIdForAssignmentAndDvmCount from '@salesforce/apex/FFAddPracCertProdToCart.getProductIdForAssignmentAndDvmCount';
import isProductInCart from '@salesforce/apex/FFAddPracCertProdToCart.isProductInCart';
import updateDVMCount from '@salesforce/apex/FFAddPracCertProdToCart.updateDVMCount';
import assignPLMAToCartItem from '@salesforce/apex/FFAddPracCertProdToCart.assignPLMAToCartItem';
import getProductPriceForUser from '@salesforce/apex/FFAddPracCertProdToCart.getProductPriceForUser';
import { addItemToCart } from 'commerce/cartApi';
import USER_ID from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TERMS_PDF from '@salesforce/resourceUrl/practice_terms';

export default class ffAddPracCertProduct extends LightningElement {
  @track isModalOpen = false;
  @track membershipAssignments = [];
  @track loading = false;
  @track error;
  isButtonDisabled = true;
  showRenewButton = false;
  buttonDisabledMap = {};
  accountId;
  termsUrl = TERMS_PDF;

  @wire(getRecord, { recordId: USER_ID, fields: ['User.AccountId'] })
  wiredUser({ error, data }) {
    if (data) {
      this.accountId = data.fields.AccountId.value;
      updateDVMCount({ accountId: this.accountId });
      this.loadMemberships();
    } else if (error) {
      this.showToast('Error', 'Error fetching user account ID', 'error');
    }
  }

  goToCart() {
  window.location.href = '/store/cart'; 
  }

  loadMemberships() {
    getEligibleMemberships({ accountId: this.accountId })
      .then(result => {
        this.buttonDisabledMap = {};
        this.membershipAssignments = result.map(record => {
          this.buttonDisabledMap[record.Id] = true;
          return {
            ...record,
            isButtonDisabled: true,
            isChecked: false,
            statusMessage: '',
            showGoToCart: false
          };
        });
        this.showRenewButton = result.length > 0;
      })
      .catch(err => {
        this.showToast('Error', err.body?.message || 'Error checking memberships', 'error');
      });
  }

  handleCheckboxChange(event) {
    const recordId = event.target.dataset.id;
    const checked = event.target.checked;
    this.buttonDisabledMap[recordId] = !checked;

    this.membershipAssignments = this.membershipAssignments.map(record => {
      if (record.Id === recordId) {
        return {
          ...record,
          isButtonDisabled: this.buttonDisabledMap[record.Id],
          isChecked: checked
        };
      }
      return record;
    });
  }

async openModal() {
  this.isModalOpen = true;
  this.loading = true;
  this.error = null;

  try {
    const result = await getEligibleMemberships({ accountId: this.accountId });
    this.buttonDisabledMap = {};
    this.membershipAssignments = await Promise.all(
      result.map(async (record) => {
        const productId = await getProductIdForAssignmentAndDvmCount({ assignmentId: record.Id });
        const price = await getProductPriceForUser({ accountId: this.accountId, productId });
        console.log('price: ' + price);
        return {
          ...record,
          productPrice: price,
          isButtonDisabled: true,
          isChecked: false,
          statusMessage: '',
          showGoToCart: false
        };
      })
    );
  } catch (err) {
    this.showToast('Error', err.body?.message || 'Error fetching records', 'error');
    this.error = err;
  } finally {
    this.loading = false;
  }
}


  closeModal() {
    this.isModalOpen = false;
    this.membershipAssignments = [];
  }

  async handleRenew(event) {
    const assignmentId = event.target.dataset.id;
    if (!assignmentId) {
      this.showToast('Error', 'Assignment ID not found', 'error');
      return;
    }

    this.loading = true;
    try {
      const productId = await getProductIdForAssignmentAndDvmCount({ assignmentId });
      if (!productId) {
        this.showToast('Error', 'Invalid product ID', 'error');
        return;
      }

      const already = await isProductInCart({ productId });
      if (already) {
        this.showToast('Warning', 'This product is already in your cart.', 'warning');
        return;
      }

      await addItemToCart(productId, 1);

      // Update record in UI
      this.membershipAssignments = this.membershipAssignments.map(record => {
        if (record.Id === assignmentId) {
          return {
            ...record,
            isButtonDisabled: true,
            statusMessage: 'The product has been successfully added to your cart!',
            showGoToCart: true
          };
        }
        return record;
      });

      // Delay before assigning PLMA
      setTimeout(async () => {
        try {
          await assignPLMAToCartItem({ productId, PLMAId: assignmentId });
        } catch (err) {
          this.showToast('Error', 'Linked to cart but failed to assign membership', 'error');
        }
      }, 1000);

    } catch (err) {
      console.error('Error during renewal:', err);
      this.showToast('Error', err.body?.message || err.message || 'Renewal failed', 'error');
    } finally {
      this.loading = false;
    }
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}