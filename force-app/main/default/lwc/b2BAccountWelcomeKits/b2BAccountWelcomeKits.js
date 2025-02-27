import { LightningElement, wire } from 'lwc';
import {addItemToCart} from 'commerce/cartApi';
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

    @wire(GET_UNCLAIMED_KITS)
    unclaimedList({ error, data }) {
      if (data) {
        this.showComponent = (data != null || data.length > 0) ? true : false;
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
            window.location.reload();
        })
        .catch(error => {
            console.error('Error adding kit to cart:', error);
        });
}
}