import { LightningElement } from 'lwc';

export default class SchooxAppRedirect extends LightningElement {
  renderedCallback() {
    if (this.hasRendered) return;

    const button = this.template.querySelector('button');
    button.addEventListener('click', this.handleClick.bind(this));
    this.hasRendered = true;
  }

  handleClick(event) {
    event.preventDefault();
  
    const appUrl = 'sigma://academies/courses.php?acadId=827540346&mine=1';
  
    // Detect OS and set fallback URL
    const userAgent = navigator.userAgent.toLowerCase();
    const fallbackUrl = /iphone|ipad|ipod/.test(userAgent)
      ? 'https://apps.apple.com/us/app/schoox/id6456941393'
      : /android/.test(userAgent)
      ? 'https://play.google.com/store/apps/details?id=schoox.sigma&hl=en_US'
      : false;
  
    const anchor = this.template.querySelector('.hidden-app-link');
    anchor.setAttribute('href', appUrl);
  
    let appOpened = false;
  
    const markAppOpened = () => {
      appOpened = true;
    };
  
    // Add multiple handlers to detect if app opened
    document.addEventListener('visibilitychange', markAppOpened, { once: true });
    window.addEventListener('blur', markAppOpened, { once: true });
    window.addEventListener('pagehide', markAppOpened, { once: true });
  
    // Trigger app open via hidden anchor
    anchor.click();
  
    // After delay, redirect to fallback if app didn't open
    setTimeout(() => {
      if (!appOpened) {
        if (fallbackUrl) {
          window.location.href = fallbackUrl;
        } else {
          window.alert('You must be on a mobile device to launch the app');
        }
      }
  
      // Clean up listeners
      document.removeEventListener('visibilitychange', markAppOpened);
      window.removeEventListener('blur', markAppOpened);
      window.removeEventListener('pagehide', markAppOpened);
    }, 2500); 
  }
}