import { LightningElement, wire } from 'lwc';
import GET_UNCLAIMED_KITS from '@salesforce/apex/B2BWelcomeKitController.getUnclaimedKits';
import ADD_KIT_TO_CART from '@salesforce/apex/B2BWelcomeKitController.addWelcomeKitToCart';

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

    @wire(GET_UNCLAIMED_KITS)
    unclaimedList({ error, data }) {
      if (data) {
        console.log('Unclaimed Kits :', data);
        this.showComponent = (data != null || data.length > 0) ? true : false;
        console.log(  this.showComponent);
        if(this.showComponent == true) {
          this.unclaimedKits = data;
          console.log(this.unclaimedKits);
        }
      } 
      
      else if (error) {
        console.error('Error in getUnclaimedKits : ', error);
      }
    }


    handleClick(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    console.log('Action Name: ', actionName);
    console.log('Row Data: ', row);
    if (actionName === 'claimKit') {
        this.addKitToCart(row.productId);
    }
}

addKitToCart(productId) {
    console.log('Adding Product ID to Cart: ', productId);
    ADD_KIT_TO_CART({ productId: productId })
        .then(result => {
            console.log('Kit added to cart successfully:', result);
            window.location.reload();
        })
        .catch(error => {
            console.error('Error adding kit to cart:', error);
        });
}
}