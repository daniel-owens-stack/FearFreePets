import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
/**
 * @slot mobile-nav ({ locked: false})
 * @slot logo ({ locked: false})
 * @slot desktop-nav ({ locked: false})
 * @slot profile-nav ({ locked: false})
 * @slot cart ({ locked: false})
 */

export default class FfCustomCommerceHeader extends LightningElement {
    pageTitle;
    fontLoaded = false;

    connectedCallback() {
        // Check if the font is available
        document.fonts.ready.then(() => {
            this.fontLoaded = true;
            // Force a re-render
            this.updateTitleVisibility();
        });
    }

    renderedCallback() {
        if (this.fontLoaded) {
            this.updateTitleVisibility();
        }
    }

    updateTitleVisibility() {
        const titleElement = this.template.querySelector('.ff-page-title h1');
        if (titleElement) {
            titleElement.style.visibility = 'visible';
        }
    }

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            window.setTimeout(() => {
                this.pageTitle = document.title || pageRef.state.pageTitle || 'Default Page';
                console.log('Current page title:', this.pageTitle);
            }, 50);
        }
    }
}