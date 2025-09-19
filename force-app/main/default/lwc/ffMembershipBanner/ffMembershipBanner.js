import { LightningElement } from 'lwc';
import getMembershipStatus from '@salesforce/apex/FFMembershipStatusController.getMembershipStatus';

export default class MembershipStatus extends LightningElement {
    membershipStatus;
    isDismissable = true; // Enable dismiss functionality
    isDismissed = false;
    error;

    connectedCallback() {
        this.fetchMembershipStatus();
    }

    fetchMembershipStatus() {
        console.log('fetchMembershipStatus called at ' + new Date().toISOString());
        getMembershipStatus()
            .then(result => {
                this.membershipStatus = result;
                this.error = undefined;
                console.log('Fetched membershipStatus:', JSON.stringify(result));
            })
            .catch(error => {
                this.error = error;
                this.membershipStatus = undefined;
                console.error('Error fetching membership status:', error);
                if (error.body && error.body.message) {
                    console.error('Error message:', error.body.message);
                } else {
                    console.error('Unknown error structure:', error);
                }
            });
    }

    get showPLMAMessage() {
        const result = !this.isDismissed && this.membershipStatus?.isAdmin && this.membershipStatus?.hasExpiredPLMA && !this.membershipStatus?.hasActiveVPC;
        return result;
    }

    get showFallbackMessage() {
    if (this.isDismissed || !this.membershipStatus) {
        console.log('showFallbackMessage skipped: isDismissed:', this.isDismissed, 'membershipStatus:', this.membershipStatus);
        return false;
    }

    const {
        hasExpiredAcademia, hasExpiredVet, hasExpiredVPC,
        hasExpiredGroomer, hasExpiredBDC, hasExpiredSitter, hasExpiredTrainer,
        hasActiveAcademia, hasActiveVet, hasActiveVPC,
        hasActiveGroomer, hasActiveSitter, hasActiveBDC, hasActiveTrainer,
        hasExpiredPLMA, isAdmin
    } = this.membershipStatus;

    const result = (
        (hasExpiredAcademia && !hasActiveVet && !hasActiveVPC && !hasActiveGroomer && !hasActiveBDC && !hasActiveSitter && !hasActiveTrainer) ||
        (hasExpiredVPC && !hasActiveVet && !hasActiveAcademia && !isAdmin && !hasActiveVPC && !hasActiveGroomer && !hasActiveBDC && !hasActiveSitter && !hasActiveTrainer) ||
        (hasExpiredVet && !hasActiveAcademia && !hasActiveVPC && !hasActiveVet && !hasActiveGroomer && !hasActiveBDC && !hasActiveSitter && !hasActiveTrainer && !(hasExpiredPLMA && isAdmin)) ||
        ((hasExpiredGroomer || hasExpiredBDC || hasExpiredSitter || hasExpiredTrainer) && !hasActiveGroomer && !hasActiveSitter && !hasActiveTrainer && !hasActiveBDC && !hasActiveAcademia && !hasActiveVPC && !hasActiveVet && !(hasExpiredPLMA && isAdmin))
    );

    console.log('showFallbackMessage result:', result, 
                'Conditions:', { hasExpiredAcademia, hasExpiredVet, hasExpiredVPC, hasActiveAcademia, hasActiveVet, hasActiveVPC });
    return result;
}


    handleDismiss() {
        this.isDismissed = true;
        console.log('Banner dismissed, isDismissed:', this.isDismissed);
        // Optional: Persist dismissal state
        // window.localStorage.setItem('membershipBannerDismissed', 'true');
    }
}