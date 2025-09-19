import { LightningElement, api } from 'lwc';
export default class MemberHomeCardChild extends LightningElement {
    @api cardDescription ='description text';
    @api cardTitle ='title text';     
    @api cardLinkUrl ='';
    @api cardColor ='';
    @api openInNewTab = false; // Default behavior: open in the same tab    

    get cardClasses() {
        return `home_page_card ${this.cardColor}`;
    }
    get linkTarget() {
        return this.openInNewTab ? '_blank' : '_self';
    }
}