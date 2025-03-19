import { LightningElement, wire } from 'lwc';
import {addItemToCart} from 'commerce/cartApi';
import { refreshApex } from '@salesforce/apex';
import GET_UNCLAIMED_KITS from '@salesforce/apex/B2BWelcomeKitController.getUnclaimedKits';
import { CartItemsAdapter } from 'commerce/cartApi';

const columns = [
    { label: 'Product Name', fieldName: 'productName' },
    {
        label: 'Welcome Kit', initialWidth: 120, type: "button",
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
  cartItemsCount = 0;

    @wire(CartItemsAdapter, {'cartStateOrId': 'active'}) 
    async getCartItems(wireResult) {
        const { data, error } = wireResult;
        if (data) {
            let productCount = data.cartSummary.totalProductCount;
            if(this.cartItemsCount != productCount)  {
              this.cartItemsCount = productCount;
              setTimeout(() => {
                  refreshApex(this.wiredKits)
              }, 1000)
            }
        } else if (error) {
            console.error('Error in getCartItems : ', error);
        }
    }

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
            .then(() => { })
            .catch(error => {
                console.error('Error adding kit to cart:', error);
            });
    }
}