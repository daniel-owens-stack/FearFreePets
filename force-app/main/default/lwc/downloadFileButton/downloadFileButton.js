import { LightningElement, api } from 'lwc';

export default class DownloadFileButton extends LightningElement {
    @api fileContentId; // ContentReference property for selecting a CMS file
    @api buttonLabel = 'Download File'; // Default button label
    @api alignment;

    // Getter to construct the CMS file URL dynamically
    get fileUrl() {
        // CMS delivery URL format (adjust based on your CMS setup)
        return this.fileContentId ? `/store/sfsites/c/cms/delivery/media/${this.fileContentId}` : '';
    }

    // Getter to apply alignment styles dynamically
    get buttonAlignment() {
        return `justify-content: ${this.alignment || 'center'}; display: flex`;
    }

    // Method to handle the download when the button is clicked
    handleDownloadClick(event) {
        event.preventDefault(); // Prevent default anchor behavior

        if (this.fileUrl) {
            // Dynamically create a temporary <a> element to trigger the file download
            const downloadLink = document.createElement('a');
            downloadLink.href = this.fileUrl;
            downloadLink.setAttribute('download', ''); // Optional: suggest a file name
            downloadLink.target = '_blank'; // Open in a new tab

            // Programmatically click the link to start the download
            downloadLink.click();
        } else {
            console.error('File URL is not set!');
        }
    }
}