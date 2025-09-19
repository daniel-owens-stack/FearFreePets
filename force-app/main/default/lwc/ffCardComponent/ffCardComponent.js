import { LightningElement, api } from 'lwc';

export default class FfCardComponent extends LightningElement {
    @api imageContentId;
    @api fileContentId;
    @api backgroundColor;
    @api titleText;
    @api descriptionText;
    @api buttonLabel; // Button text from the builder
    @api showButton; // Boolean to show/hide the button
    @api externalUrl;
    @api target;

     // Compute the image URL from the CMS content ID, matching your site's structure
     get imageUrl() {
        if (!this.imageContentId || this.imageContentId.trim().length === 0) {
            console.warn('imageContentId is empty or undefined. No image URL generated.');
            return '/store/sfsites/c/cms/delivery/media/MC6XWCTRKW5VFQ3N3J53B37CSM34?version=1.1&amp;channelId=0apTR000000039B&amp;width=640'; // Default image
        }

        // Use the observed URL structure for your Experience Cloud site
        const baseUrl = '/store/sfsites/c/cms/delivery/media/';
        // const url = `${baseUrl}${this.imageContentId}?version=1.1&channelId=0apTR000000039B`;
        const url = `${baseUrl}${this.imageContentId}`;

        // Log the URL for debugging (check browser console for 404 or 403 errors)
        console.log('Generated image URL:', url);

        return url;
    }

    get fileUrl() {
        // URL to access the CMS file
        return this.fileContentId ? `/store/sfsites/c/cms/delivery/media/${this.fileContentId}` : '';
    }

     // Compute the card's background style
     get cardStyle() {
        return `background-color: ${this.backgroundColor || '#FFFFFF'};`;
    }

    get hasTitle() {
        return this.titleText && this.titleText.trim().length > 0;
    }

    get hasDescription() {
        return this.descriptionText && this.descriptionText.trim().length > 0;
    }

    get showDownloadButton() {
        if(this.fileContentId && !this.externalUrl) {
            return true;
        } else {
            return false;
        }
    }

    get openInANewTab() {
        let targetValue = this.target ? '_blank' : '_self';
        return targetValue;
    }

}