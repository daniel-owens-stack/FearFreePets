import { LightningElement, api } from 'lwc';
import checkMembershipStatus from '@salesforce/apex/AccountMembershipController.checkMembershipStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * @slot Content-Region-Has-Membership
 * @slot Content-Region-No-Membership
 */

export default class MembershipCheck extends LightningElement {
    // Check flags (from page builder)
    @api checkAccountMembership = false;
    @api checkPracticeMembership = false;
    @api checkPracticeMembershipGP = false;
    @api checkPracticeMembershipER = false;
    @api checkPracticeMembershipHC = false;
    @api checkVetProMembership = false;
    @api checkAcademiaMembership = false;
    @api checkGroomerMembership = false;
    @api checkSitterMembership = false;
    @api checkTrainerMembership = false;
    @api checkBoardingMembership = false;
    @api checkCertification = false;
    @api checkIsExpired = false;
    @api checkAnyStatus = false;

    // Exclude flags
    @api excludeGroomer = false;
    @api excludeSitter = false;
    @api excludeTrainer = false;
    @api excludeBoarding = false;
    @api excludeAcademia = false;
    @api excludeVetPro = false;
    @api excludePracticeMembership = false;
    @api excludePracticeMembershipGP = false;
    @api excludePracticeMembershipER = false;
    @api excludePracticeMembershipHC = false;

    // Membership status
    hasMembership = false;
    hasVetProMembership = false;
    hasAcademiaMembership = false;
    hasPracticeLevelMembership = false;
    hasPracticeLevelMembershipGP = false;
    hasPracticeLevelMembershipER = false;
    hasPracticeLevelMembershipHC = false;
    hasGroomerMembership = false;
    hasSitterMembership = false;
    hasTrainerMembership = false;
    hasBoardingMembership = false;
    isAdmin = false;
    error;

    connectedCallback() {
        this.checkMembership();
    }

    checkMembership() {
        checkMembershipStatus({
            checkAccountMembership: this.checkAccountMembership,
            checkVetProMembership: this.checkVetProMembership,
            checkAcademiaMembership: this.checkAcademiaMembership,
            checkPracticeMembership: this.checkPracticeMembership,
            checkPracticeMembershipGP: this.checkPracticeMembershipGP,
            checkPracticeMembershipER: this.checkPracticeMembershipER,
            checkPracticeMembershipHC: this.checkPracticeMembershipHC,
            checkGroomerMembership: this.checkGroomerMembership,
            checkSitterMembership: this.checkSitterMembership,
            checkTrainerMembership: this.checkTrainerMembership,
            checkBoardingMembership: this.checkBoardingMembership,
            certifiedStatus: this.checkCertification,
            isExpired: this.checkIsExpired,
            anyStatus: this.checkAnyStatus,

            excludeGroomer: this.excludeGroomer,
            excludeSitter: this.excludeSitter,
            excludeTrainer: this.excludeTrainer,
            excludeBoarding: this.excludeBoarding,
            excludeAcademia: this.excludeAcademia,
            excludeVetPro: this.excludeVetPro,
            excludePracticeMembership: this.excludePracticeMembership,
            excludePracticeMembershipGP: this.excludePracticeMembershipGP,
            excludePracticeMembershipER: this.excludePracticeMembershipER,
            excludePracticeMembershipHC: this.excludePracticeMembershipHC
        })
        .then(result => {
            console.log('Apex result:', result);
            this.hasMembership = result.hasActiveAccountMembership || false;
            this.hasVetProMembership = result.hasActiveVetProLevelMembership || false;
            this.hasAcademiaMembership = result.hasActiveAcademiaLevelMembership || false;
            this.hasPracticeLevelMembership = result.hasActivePracticeLevelMembership || false;
            this.hasPracticeLevelMembershipGP = result.hasActivePracticeLevelGPMembership || false;
            this.hasPracticeLevelMembershipER = result.hasActivePracticeLevelERMembership || false;
            this.hasPracticeLevelMembershipHC = result.hasActivePracticeLevelHCMembership || false;
            this.hasGroomerMembership = result.hasActiveGroomerLevelMembership || false;
            this.hasSitterMembership = result.hasActiveSitterLevelMembership || false;
            this.hasTrainerMembership = result.hasActiveTrainerLevelMembership || false;
            this.hasBoardingMembership = result.hasActiveBoardingLevelMembership || false;
            this.isAdmin = result.isAdmin || false;
            this.error = null;

                console.log('Resolved values:', {
        showMemberContent: this.showMemberContent,
        showNonMemberContent: this.showNonMemberContent,
        hasMembership: this.hasMembership,
        hasVetProMembership: this.hasVetProMembership,
        hasAcademiaMembership: this.hasAcademiaMembership,
        hasPracticeLevelMembership: this.hasPracticeLevelMembership,
        hasPracticeLevelMembershipGP: this.hasPracticeLevelMembershipGP,
        hasPracticeLevelMembershipER: this.hasPracticeLevelMembershipER,
        hasPracticeLevelMembershipHC: this.hasPracticeLevelMembershipHC,
        hasGroomerMembership: this.hasGroomerMembership,
        hasSitterMembership: this.hasSitterMembership,
        hasTrainerMembership: this.hasTrainerMembership,
        hasBoardingMembership: this.hasBoardingMembership,
        isAdmin: this.isAdmin
    });
        })
        .catch(error => {
            console.error('Error:', error);
            this.error = error?.body?.message || 'An unexpected error occurred';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: this.error,
                variant: 'error'
            }));
        });
    }

    get showMemberContent() {
    if (this.error) return false;
    if (this.isAdmin) return true;
    return (
        (this.checkAccountMembership && this.hasMembership) ||
        (this.checkVetProMembership && this.hasVetProMembership) ||
        (this.checkAcademiaMembership && this.hasAcademiaMembership) ||
        (this.checkPracticeMembership && this.hasPracticeLevelMembership) ||
        (this.checkPracticeMembershipGP && this.hasPracticeLevelMembershipGP) ||
        (this.checkPracticeMembershipER && this.hasPracticeLevelMembershipER) ||
        (this.checkPracticeMembershipHC && this.hasPracticeLevelMembershipHC) ||
        (this.checkGroomerMembership && this.hasGroomerMembership) ||
        (this.checkSitterMembership && this.hasSitterMembership) ||
        (this.checkTrainerMembership && this.hasTrainerMembership) ||
        (this.checkBoardingMembership && this.hasBoardingMembership)
    );
    }

    get showNonMemberContent() {
        if (this.error) return true; // fallback if something fails
        if (this.isAdmin) return true;
    return (
        (this.checkAccountMembership && !this.hasMembership) ||
        (this.checkVetProMembership && !this.hasVetProMembership) ||
        (this.checkAcademiaMembership && !this.hasAcademiaMembership) ||
        (this.checkPracticeMembership && !this.hasPracticeLevelMembership) ||
        (this.checkPracticeMembershipGP && !this.hasPracticeLevelMembershipGP) ||
        (this.checkPracticeMembershipER && !this.hasPracticeLevelMembershipER) ||
        (this.checkPracticeMembershipHC && !this.hasPracticeLevelMembershipHC) ||
        (this.checkGroomerMembership && !this.hasGroomerMembership) ||
        (this.checkSitterMembership && !this.hasSitterMembership) ||
        (this.checkTrainerMembership && !this.hasTrainerMembership) ||
        (this.checkBoardingMembership && !this.hasBoardingMembership)
    );
  }
}