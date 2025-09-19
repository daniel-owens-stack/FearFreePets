import { LightningElement, track } from 'lwc';
import searchListings from '@salesforce/apex/SearchAccountsController.searchListings';
import { loadStyle } from 'lightning/platformResourceLoader';
import extraStyles from '@salesforce/resourceUrl/extraStyles';
import mapStyles from '@salesforce/resourceUrl/mapStyles';

export default class DirectoryListingsLWC extends LightningElement {
    searchTerm = '';
    radius; // Default radius value
    previousRadius;
    listings;
    errorMessage;
    loading = false; // Track loading state
    locationButtonDisabled = false;
    searchButtonDisabled = false;
    selectedListItem;
    showSettingsModal = false; // Track the state of the settings modal
    selectedSpeciesTypes = []; // Track selected member types
    selectedSpeciesTypesOnApply = [];
    selectedContactTypes = [];
    selectedContactTypesOnApply = [];
    selectedCareTypes = [];
    selectedCareTypesOnApply = [];
    filteredListings = [];
    finalListings = [];

    //load map styles
    connectedCallback() {
        loadStyle(this, extraStyles);
        loadStyle(this, mapStyles);

        // Check if URL parameters exist
        const urlParams = new URLSearchParams(window.location.search);
        const query = urlParams.get('query');
        const radius = urlParams.get('radius');

        // If both query and radius parameters exist, set searchTerm and radius, then trigger handleSearch
        if (query && radius) {
            // Remove leading/trailing spaces from the query
            const sanitizedQuery = query.trim();
            // Replace space with + or %20 in the query
            const formattedQuery = sanitizedQuery.replace(/ /g, '+');
            this.searchTerm = formattedQuery;
            this.radius = radius.trim();
            this.handleSearch();
        }

    }

    // Define radius options
    radiusOptions = [
        { label: '5', value: '5' },
        { label: '10', value: '10' },
        { label: '25', value: '25' },
        { label: '50', value: '50' },
        { label: '100', value: '100' }
    ];

    // Define member type options for filter
    speciesTypeOptions = [
        { label: 'Dog', value: 'Directory_Species_Dog__c' },
        { label: 'Cat', value: 'Directory_Species_Cat__c' },
        { label: 'Bird', value: 'Directory_Species_Avian__c' },
        { label: 'Horse', value: 'Directory_Species_Equine__c' }
    ];

    // Define member type options for filter
    careTypeOptions = [
        { label: 'Veterinary', value: 'Veterinary' },
        { label: 'Veterinary - Emergency', value: 'Veterinary - Emergency' },
        { label: 'Veterinary - Mobile', value: 'Veterinary - Mobile' },
        { label: 'Trainer', value: 'Trainer' },
        { label: 'Groomer', value: 'Groomer' },
        { label: 'Pet Sitter', value: 'Pet Sitter' },
        { label: 'Boarding & Daycare', value: 'Boarding & Daycare' },
        { label: 'Behavior Graduate', value: 'Behavior' }
    ];

    // Define contact type options
    contactTypeOptions = [
        { label: 'Certified Practice', value: 'Certified Practice' },
        { label: 'Practice', value: 'Practice' },
        { label: 'Individual', value: 'Individual' },
    ];

    handleSearchTermChange() {
        // this.searchTerm = event.target.value;
        this.searchTerm = this.template.querySelector('.search-box').value;
    }

    handleRadiusChange(event) {
        // this.previousRadius = this.radius;
        this.radius = event.detail.value;
    }

    handleKeyDown(event) {
        if (event.keyCode === 13) { // 13 is the key code for Enter key
            this.handleSearchTermChange();
            this.handleSearch();
        }
    }

    // Method to handle settings icon button click
    handleSettingsClick() {
        this.showSettingsModal = !this.showSettingsModal; // Toggle the state of the settings modal
    }

    handleSpeciesTypeChange(event) {
        // Handle the change event from the lightning-checkbox-group
        const selectedValues = event.detail.value;
        this.selectedSpeciesTypes = [...selectedValues];
        console.log(this.selectedSpeciesTypes);
    }

    handleCareTypeChange(event) {
        // Handle the change event from the lightning-checkbox-group
        const selectedValues = event.detail.value;
        this.selectedCareTypes = [...selectedValues];
        console.log(this.selectedCareTypes);
    }

    handleContactTypeChange(event) {
        // Handle the change event from the lightning-checkbox-group
        const selectedValues = event.detail.value;
        this.selectedContactTypes = [...selectedValues];
        console.log(this.selectedContactTypes);
    }

    // Method to handle apply button click for filters
    handleApplyFiltersButton() {
        this.selectedSpeciesTypesOnApply = this.selectedSpeciesTypes;
        this.selectedContactTypesOnApply = this.selectedContactTypes;
        this.selectedCareTypesOnApply = this.selectedCareTypes;
        this.showSettingsModal = false;
        if (this.searchTerm != '' && this.radius != null && (this.previousRadius != this.radius)) {
            console.log('running handleSearch');
            this.handleSearch();
        } else {
            console.log('running applyFilters')
            this.applyFilters();
        }
    }

    handleCloseFiltersButton() {
        this.showSettingsModal = false;
    }

    applyFilters() {
        if (this.listings && this.listings.length > 0) {
            console.log('listings at applyFilters' + this.listings);
            this.filteredListings = this.listings.filter(listing => {
                    // Check if the listing is defined before accessing its properties
            if (!listing || !listing.acc) {
                return false; // Skip this listing if it's undefined or missing data
            }
                // Check if any selected contact types match the listing's contact type
                const matchesContactType = this.selectedContactTypesOnApply.length === 0 ? true : this.selectedContactTypesOnApply.some(contactType => {
                    if (contactType === 'Individual') {
                        return listing.acc?.IsPersonAccount === true;
                    } else if (contactType === 'Practice') {
                        return listing.acc?.IsPersonAccount === false && listing.cp === false;
                    } else if (contactType === 'Certified Practice') {
                        return listing.cp === true;
                    }
                    return false; // Safeguard, but should be unreachable if all cases are handled
                });

                // Check if any selected species types match the listing's species type
                const matchesSpeciesType = this.selectedSpeciesTypesOnApply.length === 0 ? true : this.selectedSpeciesTypesOnApply.some(speciesType => listing.acc[speciesType] === true);

                // Check if any selected care types match the listing's care type
                const matchesCareType = this.selectedCareTypesOnApply.length === 0 ? true : this.selectedCareTypesOnApply.some(careType => listing.acc.Care_Type__c ? listing.acc.Care_Type__c.split(';').includes(careType) === true : false);
                console.log('end of applyFilters');
                // Include the listing if it matches the contact type, species type, and care type
                return matchesContactType && matchesSpeciesType && matchesCareType;
            });

            this.finalListings = this.filteredListings;
            this.filteredListings = [];
            this.errorMessage = this.finalListings.length === 0 ? 'Sorry, no listings found for the provided location.' : null;
        } else {
            this.finalListings = this.listings;
            this.filteredListings = [];
            this.errorMessage = this.finalListings.length === 0 ? 'Sorry, no listings found for the provided location.' : null;
        }
    }

    async handleSearch() {
        this.listings = [];
        this.finalListings = [];
        this.filteredListings = [];
        // this.previousRadius = this.radius; // Update previousRadius after search
        if (this.showSettingsModal) {
            this.showSettingsModal = false;
        }
        try {
            this.loading = true; // Show loading spinner
            if (!this.searchTerm.trim()) {
                this.errorMessage = 'Please enter a city+state, or zip code.';
                return;
            }

            const coordinates = await this.getCoordinates(this.searchTerm);
            console.log('cooridinates' + coordinates.latitude + coordinates.longitude);
            if (coordinates) {
                this.radius = this.radius ? this.radius : '25';
                this.listings = await searchListings({
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude,
                    radius: this.radius,
                    // serachTerm: this.searchTerm
                });
                console.log('Listings returned:', this.listings);

                // Filter listings based on selected member types
                if (this.selectedSpeciesTypesOnApply.length > 0 || this.selectedContactTypesOnApply.length > 0 || this.selectedCareTypesOnApply.length > 0) {
                    this.applyFilters();
                } else {
                    this.finalListings = this.listings;
                    this.errorMessage = this.finalListings.length === 0 ? 'Sorry, no listings found for the provided location.' : null;
                }
                this.previousRadius = this.radius;

                // for (var i = 0; i < this.finalListings.length; i++) {
                //     console.log(this.finalListings[i].acc);
                // }
            }
        } catch (error) {
            console.error('Error during search:', error);
            this.errorMessage = 'An error occurred while searching for listings.';
        } finally {
            this.loading = false; // Hide loading spinner
        }
    }

    async getCoordinates(searchTerm) {
        try {
            const response = await fetch(`https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(searchTerm)}&key=AIzaSyDR72pjyhyVBimnl-Stk_fmmvEsRWiASXU`);
            if (!response.ok) {
                throw new Error('Geolocation API request failed');
            }
            const data = await response.json();
            if (data.results && data.results.length > 0) {
                const location = data.results[0].geometry.location;
                return { latitude: location.lat, longitude: location.lng };
            } else {
                console.error('No results found for the search term:', searchTerm);
                this.errorMessage = 'Sorry, we could not find any listings for your location.';
                // Clear listings when no results are found
                this.listings = [];
                this.finalListings = [];
                this.filteredListings = [];
                return this.listings;
            }
        } catch (error) {
            console.error('Error fetching coordinates:', error);
            this.errorMessage = 'An error occurred while fetching coordinates.';
            return null;
        }
    }

    handleGetCurrentLocationClick() {
        this.locationButtonDisabled = true;
        this.loading = true; // Show loading spinner
        navigator.geolocation.getCurrentPosition(
            (position) => {
                const latitude = position.coords.latitude;
                const longitude = position.coords.longitude;
                this.getZipCodeFromCoordinates(latitude, longitude);
                this.loading = false; // Stop loading spinner
            },
            (error) => {
                if (error.code == error.PERMISSION_DENIED) {
                    this.errorMessage = 'Location access is required to use this feature';
                    this.loading = false; // Stop loading spinner
                    this.locationButtonDisabled = false;
                } else {
                    console.error('Error getting current location:', error);
                    this.loading = false; // Stop loading spinner
                    this.errorMessage = 'Error getting current location.';
                    this.locationButtonDisabled = false;
                }
            },
            {
                enableHighAccuracy: true
            }
        );
        this.locationButtonDisabled = false;
    }

    async getZipCodeFromCoordinates(latitude, longitude) {
        try {
            console.log('Fetching zip code...');
            const response = await fetch(`https://maps.googleapis.com/maps/api/geocode/json?latlng=${latitude},${longitude}&key=AIzaSyDR72pjyhyVBimnl-Stk_fmmvEsRWiASXU`);
            if (!response.ok) {
                throw new Error('Geocoding API request failed');
            }
            const data = await response.json();
            if (data.results && data.results.length > 0) {
                const addressComponents = data.results[0].address_components;
                const zipCodeComponent = addressComponents.find(component => component.types.includes('postal_code'));
                if (zipCodeComponent) {
                    const zipCode = zipCodeComponent.long_name;
                    this.searchTerm = zipCode; // Set the zip code in the search term
                    this.handleSearch(); // Trigger the search
                } else {
                    this.errorMessage = 'Sorry, no listings found in your current location.';
                }
            } else {
                this.errorMessage = 'Sorry, no listings found in your current location.';
            }
        } catch (error) {
            console.error('Error fetching zip code:', error);
        }
    }

    handleMarkerSelected(event) {
        // Retrieve the selected marker value (e.g., marker ID)
        const selectedMarkerValue = event.detail.markerValue;

        // Find the corresponding listing item in the list view
        const listingItem = this.template.querySelector(`[data-listing-id="${selectedMarkerValue}"]`);

        // If the new listingItem is null or same as current, just return
        if (!listingItem || listingItem === this.selectedListItem) {
            return;
        }

        // Reset the previous selected list item styles, if any
        if (this.selectedListItem) {
            this.selectedListItem.style.setProperty('--slds-c-card-color-border', '#c9c9c9');
            this.selectedListItem.style.setProperty('--sds-c-card-shadow', '0 2px 2px 0 rgba(0,0,0,.1)');
            this.selectedListItem.style.setProperty('--slds-c-card-sizing-border', '1px');
        }

        // Apply the new styles to the currently selected item
        listingItem.style.setProperty('--slds-c-card-color-border', '#123d64f2');
        listingItem.style.setProperty('--sds-c-card-shadow', '0 4px 4px 0 rgba(0,0,0,.1)');
        listingItem.style.setProperty('--slds-c-card-sizing-border', '2px');

        // Set the newly selected item as the current one
        this.selectedListItem = listingItem;

        // Scroll the selected item into view
        listingItem.scrollIntoView({ behavior: 'smooth', block: 'end' });
    }



}