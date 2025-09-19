import HEART_LOGO from '@salesforce/resourceUrl/heartLogo';
import CERT_PRO_MAP_MARKER from '@salesforce/resourceUrl/certProMapMarker';
import CERT_PRO_INDV_MAP_MARKER from '@salesforce/resourceUrl/certProIndvMapMarker';
import { LightningElement, api } from 'lwc';
import CERT_PRO_LOGO from '@salesforce/resourceUrl/certProLogo';
import CP_LOGO from '@salesforce/resourceUrl/cpLogo';
import CP_LOGO_ER from '@salesforce/resourceUrl/cpLogoER';
import CP_LOGO_HC from '@salesforce/resourceUrl/cpLogoHC';
import getChildAccounts from '@salesforce/apex/directoryMembersController.getChildAccounts';

export default class DirectoryListing extends LightningElement {
    @api listing; // Declare listing as an @api property

    certProLogoUrl = CERT_PRO_LOGO;
    childAccounts;
    certProMapMarkerUrl = CERT_PRO_MAP_MARKER;
    certProIndvMapMarkerUrl = CERT_PRO_INDV_MAP_MARKER;
    heartLogoUrl = HEART_LOGO;
    gpPracCertLogoUrl = CP_LOGO;
    erPracCertLogoUrl = CP_LOGO_ER;
    hcPracCertLogoUrl = CP_LOGO_HC;
    gpPracLogo = false;
    erPracLogo = false;
    hcPracLogo = false;


    get listingName() {
        if (this.listing && this.listing.acc && this.listing.acc.Name) {
            return this.listing.acc.Name
                .replace(/\(Team\)/gi, '')
                .replace(/\(New\)/gi, '')
                .replace(/FTE/gi, '')
                .trim();
        }
        return '';
    }

    get listingStreet() {
        if (this.listing && this.listing.acc && this.listing.acc.Directory_Address__c) {
            return this.listing && this.listing.acc && this.listing.acc.Directory_Address__c.street ? this.listing.acc.Directory_Address__c.street : '';
        } else {
            return '';
        }
    }

    get listingCity() {
        if (this.listing && this.listing.acc && this.listing.acc.Directory_Address__c) {
            return this.listing && this.listing.acc && this.listing.acc.Directory_Address__c.city ? this.listing.acc.Directory_Address__c.city + ', ' : '';
        } else {
            return '';
        }
    }

    get listingState() {
        if (this.listing && this.listing.acc && this.listing.acc.Directory_Address__c) {
            return this.listing && this.listing.acc && this.listing.acc.Directory_Address__c.stateCode ? this.listing.acc.Directory_Address__c.stateCode + ', ' : '';
        } else {
            return '';
        }
    }

    get listingPostalCode() {
        if (this.listing && this.listing.acc && this.listing.acc.Directory_Address__c) {
            return this.listing && this.listing.acc && this.listing.acc.Directory_Address__c.postalCode ? this.listing.acc.Directory_Address__c.postalCode + ', ' : '';
        } else {
            return '';
        }
    }

    get listingCountryCode() {
        if (this.listing && this.listing.acc && this.listing.acc.Directory_Address__c) {
            return this.listing && this.listing.acc && this.listing.acc.Directory_Address__c.countryCode ? this.listing.acc.Directory_Address__c.countryCode : '';
        } else {
            return '';
        }
    }

    get googleMapsDirectionsUrl() {
        if (
            this.listing &&
            this.listing.acc &&
            this.listing.acc.Directory_Address__c
        ) {
            const addr = this.listing.acc.Directory_Address__c;
            const parts = [
                addr.street,
                addr.city,
                addr.stateCode,
                addr.postalCode,
                addr.countryCode
            ];
    
            const fullAddress = parts.filter(Boolean).join(', ');
            const encodedAddress = encodeURIComponent(fullAddress);
            return `https://www.google.com/maps/dir/?api=1&destination=${encodedAddress}`;
        }
    
        return '';
    }

    get listingPhone() {
        if(this.listing && this.listing.acc && this.listing.acc.Directory_Phone__c) {
        const phoneNumber = this.listing.acc.Directory_Phone__c;
        return phoneNumber	? `tel:(${phoneNumber.slice(0, 3)}) ${phoneNumber.slice(3, 6)}-${phoneNumber.slice(6)}` : '';
        } else {
            return '';
        }
    }

    get listingEmail() {
        return this.listing && this.listing.acc && this.listing.acc.Directory_Email__c	? `mailto:${this.listing.acc.Directory_Email__c}` : '';
    }

    get listingURL() {
        return this.listing && this.listing.acc && this.listing.acc.Directory_URL__c ? this.listing.acc.Directory_URL__c : '';
    }

    get listingFaceBook() {
        return this.listing && this.listing.acc && this.listing.acc.Directory_Facebook__c ? this.listing.acc.Directory_Facebook__c : '';
    }

    get listingInstagram() {
        return this.listing && this.listing.acc && this.listing.acc.Directory_Instagram__c ? this.listing.acc.Directory_Instagram__c : '';
    }

    get listingTwitter() {
        return this.listing && this.listing.acc && this.listing.acc.Directory_Twitter__c ? this.listing.acc.Directory_Twitter__c : '';
    }

    get listingLinkedIn() {
        return this.listing && this.listing.acc && this.listing.acc.Directory_LinkedIn__c ? this.listing.acc.Directory_LinkedIn__c : '';
    }

    //https://x.com/

    get listingId() {
        return this.listing && this.listing.acc && this.listing.acc ? this.listing.acc.Id : ''; // Access Id property of listing
    }

    get distance() {
        return this.listing && this.listing.acc && this.listing ? this.listing.distance : '';
    }

    get hasChildAccounts() {
        return this.listing && this.listing.acc && this.childAccounts && this.childAccounts.length > 0;
    }

    get certProLogo() {
        return this.listing && this.listing.acc && !this.listing.cp;
    }

    connectedCallback() {
        if (this.listing && this.listing.acc && !this.listing.acc.IsPersonAccount) {
        this.getChildAccounts();
        }
        if (
            this.listing &&
            this.listing.acc &&
            this.listing.cp &&
            this.listing.acc.Account_Team_Memberships1__r &&
            Array.isArray(this.listing.acc.Account_Team_Memberships1__r)
        ) {
            for (let i = 0; i < this.listing.acc.Account_Team_Memberships1__r.length; i++) {
                if (this.listing.acc.Account_Team_Memberships1__r[i].Membership_Name__c === 'Veterinary Practice Certification - General Practice Membership') {
                    this.gpPracLogo = this.gpPracCertLogoUrl;
                }
                if (this.listing.acc.Account_Team_Memberships1__r[i].Membership_Name__c === 'Veterinary Practice Certification - ER/Urgent Care Membership') {
                    this.erPracLogo = this.erPracCertLogoUrl;
                }
                if (this.listing.acc.Account_Team_Memberships1__r[i].Membership_Name__c === 'Veterinary Practice Certification - House Call Membership') {
                    this.hcPracLogo = this.hcPracCertLogoUrl;
                }
            }
        }
    }

    async getChildAccounts() {
        try {
            this.childAccounts = await getChildAccounts({ parentId: this.listingId });
            console.log('childaccounts:' + this.childAccounts);
        } catch (error) {
            console.error('Error retrieving child accounts:', error);
        }
    }

}