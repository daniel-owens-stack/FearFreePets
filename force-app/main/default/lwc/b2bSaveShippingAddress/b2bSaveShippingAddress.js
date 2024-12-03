import LightningModal from "lightning/modal";
import { api } from "lwc";
import saveShippingAddress from "@salesforce/apex/B2BWelcomeKitController.saveShippingAddress";

export default class B2bSaveShippingAddress extends LightningModal {
    @api isEdit;
    @api existingShippingAddress;
    showForm = true;
    disable = true;
    isLoading;

    async connectedCallback() {
        if(this.isEdit) {
            this.shippingAddress.street = this.existingShippingAddress.street;
            this.shippingAddress.city = this.existingShippingAddress.city;
            this.shippingAddress.state = this.existingShippingAddress.state;
            this.shippingAddress.postalCode = this.existingShippingAddress.postalCode;

            this.validateFieldValues();
        }
    }

    async saveAddress() {
        this.isLoading = true;
        await saveShippingAddress({
            shippingAddress: this.shippingAddress
        })
        .then(async () => {
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent("formsubmit"));
            this.close("okay");
        })
        .catch(async (error) => {
            this.isLoading = false;
            console.log("Error in saveShippingAddress: " + error);
        });

        this.validateFieldValues();
    }

    shippingAddress = {
        street: "",
        city: "",
        state: "",
        postalCode: "",
        country: "US"
    };

    handleAddressChange(event) {
        const fieldName = event.target.name;
        if (fieldName === "street") {
        this.shippingAddress.street = event.target.value;
        } else if (fieldName === "city") {
        this.shippingAddress.city = event.target.value;
        } else if (fieldName === "state") {
        this.shippingAddress.state = event.target.value;
        } else if (fieldName === "postalCode") {
        this.shippingAddress.postalCode = event.target.value;
        } 

        this.validateFieldValues();
    }

    stateOptions = [
        { label: "Alabama", value: "AL" },
        { label: 'Alaska', value: 'AK' },
        { label: "Arizona", value: "AZ" },
        { label: "Arkansas", value: "AR" },
        { label: "California", value: "CA" },
        { label: "Colorado", value: "CO" },
        { label: "Connecticut", value: "CT" },
        { label: "Delaware", value: "DE" },
        { label: "District of Columbia", value: "DC" },
        { label: "Florida", value: "FL" },
        { label: "Georgia", value: "GA" },
        { label: 'Hawaii', value: 'HI' },
        { label: "Idaho", value: "ID" },
        { label: "Illinois", value: "IL" },
        { label: "Indiana", value: "IN" },
        { label: "Iowa", value: "IA" },
        { label: "Kansas", value: "KS" },
        { label: "Kentucky", value: "KY" },
        { label: "Louisiana", value: "LA" },
        { label: "Maine", value: "ME" },
        { label: "Maryland", value: "MD" },
        { label: "Massachusetts", value: "MA" },
        { label: "Michigan", value: "MI" },
        { label: "Minnesota", value: "MN" },
        { label: "Mississippi", value: "MS" },
        { label: "Missouri", value: "MO" },
        { label: "Montana", value: "MT" },
        { label: "Nebraska", value: "NE" },
        { label: "Nevada", value: "NV" },
        { label: "New Hampshire", value: "NH" },
        { label: "New Jersey", value: "NJ" },
        { label: "New Mexico", value: "NM" },
        { label: "New York", value: "NY" },
        { label: "North Carolina", value: "NC" },
        { label: 'North Dakota', value: 'ND' },
        { label: "Ohio", value: "OH" },
        { label: "Oklahoma", value: "OK" },
        { label: "Oregon", value: "OR" },
        { label: "Pennsylvania", value: "PA" },
        { label: 'Puerto Rico', value: 'PR'},
        { label: "Rhode Island", value: "RI" },
        { label: "South Carolina", value: "SC" },
        { label: "South Dakota", value: "SD" },
        { label: "Tennessee", value: "TN" },
        { label: "Texas", value: "TX" },
        { label: "Utah", value: "UT" },
        { label: "Vermont", value: "VT" },
        { label: "Virginia", value: "VA" },
        { label: "Washington", value: "WA" },
        { label: "West Virginia", value: "WV" },
        { label: "Wisconsin", value: "WI" },
        { label: "Wyoming", value: "WY" }
    ];

    validateFieldValues() {
        if (
        this.shippingAddress.street != "" &&
        this.shippingAddress.street != null &&
        this.shippingAddress.city != "" &&
        this.shippingAddress.city != null &&
        this.shippingAddress.state != "" &&
        this.shippingAddress.state != null &&
        this.shippingAddress.postalCode != "" &&
        this.shippingAddress.postalCode != null
        ) {
        this.disable = false;
        } else {
        this.disable = true;
        }
    }
}