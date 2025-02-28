import { LightningElement, wire } from 'lwc';
import {addItemToCart} from 'commerce/cartApi';
import { refreshApex } from '@salesforce/apex';
import GET_UNCLAIMED_KITS from '@salesforce/apex/B2BWelcomeKitController.getUnclaimedKits';

const columns = [
    { label: 'Product Name', fieldName: 'productName' },
    {
        label: 'Welcome Kit', initialWidth: 100, type: "button",
        typeAttributes: {
            label: 'Claim Kit',
            name: 'claimKit',
            title: 'Claim Kit',
            disabled: false,
            value: 'claimKit',
            variant:'brand'
        }
    }
];
export default class B2BAccountWelcomeKits extends LightningElement {

  showComponent = false;
  columns = columns;
  unclaimedKits = [];
  quantity = 1;
  wiredKits;

    @wire(GET_UNCLAIMED_KITS)
    unclaimedList(result) {
      this.wiredKits = result; 
      if (result.data) {
        let data = result.data;
        this.showComponent = (data != null || data.length > 0) ? true : false;
        if(this.showComponent == true) {
          this.unclaimedKits = data;
        }
      } 
      else if (result.error) {
        console.error('Error in getUnclaimedKits : ', result.error);
      }
    }


    handleClick(event) {
      const actionName = event.detail.action.name;
      const row = event.detail.row;
      
      if (actionName === 'claimKit') {
          this.addKitToCart(row.productId);
      }
    }

    addKitToCart(productId) {
        addItemToCart(productId, this.quantity)
            .then(() => {
                this.unclaimedKits = this.unclaimedKits.filter((kit, index) => {
                    return index !== this.unclaimedKits.findIndex(k => k.productId === productId);
                });
                if(this.unclaimedKits.length === 0) {
                  this.showComponent = false;
                }
                return refreshApex(this.wiredKits);
            })
            .catch(error => {
                console.error('Error adding kit to cart:', error);
            });
    }
}