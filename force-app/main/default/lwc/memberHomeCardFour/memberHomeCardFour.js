import { LightningElement, api } from 'lwc';

export default class MemberHomeCardFour extends LightningElement {
    // Card 1
    @api cardOneTitle;
    @api cardOneDescription;
    @api cardOneLinkUrl;
    @api cardOneOpenInNewTab;
    @api cardOneColor;

    // Card 2
    @api cardTwoTitle;
    @api cardTwoDescription;
    @api cardTwoLinkUrl;
    @api cardTwoOpenInNewTab;
    @api cardTwoColor;

    // Card 3
    @api cardThreeTitle;
    @api cardThreeDescription;
    @api cardThreeLinkUrl;
    @api cardThreeOpenInNewTab;
    @api cardThreeColor;

    // Card 4
    @api cardFourTitle;
    @api cardFourDescription;
    @api cardFourLinkUrl;
    @api cardFourOpenInNewTab;
    @api cardFourColor;
}