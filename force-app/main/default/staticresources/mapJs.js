

function getMarkers() {
var rootDom = document.querySelector('c-directory-listings').shadowRoot.querySelector('c-directory-map');

var iframeRoot = rootDom.shadowRoot.querySelector('.map-container > .map-with-markers');

var iframeRootRoot = iframeRoot.shadowRoot.querySelector('.slds-map_container > .slds-map lightning-primitive-iframe').shadowRoot.querySelector('iframe');

var iframeDocument = iframeRootRoot.contentWindow.document;

var rootDom = document.querySelector('c-directory-listings').shadowRoot.querySelector('c-directory-map');

var iframeRoot = rootDom.shadowRoot.querySelector('.map-container > .map-with-markers');

var iframeRootRoot = iframeRoot.shadowRoot.querySelector('.slds-map_container > .slds-map lightning-primitive-iframe').shadowRoot.querySelector('iframe');

var iframeDocument = iframeRootRoot.contentWindow.document;

var marker = iframeDocument.querySelector('#map > div > div.gm-style > div:nth-child(1) > div:nth-child(1) > div:nth-child(4) > *');

console.log(marker);
}