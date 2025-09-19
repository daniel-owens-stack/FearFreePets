import { LightningElement, api } from 'lwc';
    // cardComponent.js
export default class MemberHomeCard extends LightningElement {
    @api cardTitle;     // Editable title
    @api cardBody;      // Editable body
    @api backgroundColor = 'white'; // Default color, editable in Experience Builder

    // Computed style for inline background color
    get cardStyle() {
        return `background-color: ${this.backgroundColor};`;
    }
}