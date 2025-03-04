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
      const { data, error } = result;
      this.wiredKits = result; 
      this.showComponent = data != null ? true : false;
      if (data) {
        if(this.showComponent == true) {
          this.unclaimedKits = data;
        }
      } 
      else if (error) {
        console.error('Error in getUnclaimedKits : ', error);
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
                setTimeout(() => {
                  refreshApex(this.wiredKits)
                }, 3000)
            })
            .catch(error => {
                console.error('Error adding kit to cart:', error);
            });
    }
}