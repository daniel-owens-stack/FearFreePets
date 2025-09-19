public with sharing class SearchAccountsController {
    @AuraEnabled
    public static List<ListingWrapper> searchListings(Double latitude, Double longitude, Integer radius) {
        Integer travelRadius = radius;
        radius = radius + 1; //Adding 1 mile here buecaes we can't do <= in a Distance function
        List<ListingWrapper> listings = new List<ListingWrapper>();
        
        // Separate lists for CP and non-CP wrappers
        List<ListingWrapper> cpListings = new List<ListingWrapper>();
        List<ListingWrapper> nonCpListings = new List<ListingWrapper>();
        
        if (latitude != null && longitude != null) {
            // Query for business accounts
            List<Account> businessAccounts = [SELECT 
                Id, 
                Certified_Practice__c, 
                Name,
                Directory_Email__c, 
                Directory_Phone__c, 
                Directory_Facebook__c, 
                Directory_Instagram__c, 
                Directory_Twitter__c, 
                Directory_LinkedIn__c, 
                Directory_URL__c, 
                Coordinates__c, 
                Directory_Radius__c,
                Directory_Address__c, 
                Directory_Opt_In__c, 
                Directory_Company__c,
                Business__c, 
                Admin_Account__c,
                IsPersonAccount, 
                Care_Type__c, 
                Directory_Species_Avian__c, 
                Directory_Species_Cat__c, 
                Directory_Species_Dog__c, 
                Directory_Species_Equine__c,
                //PLMA
                (SELECT Membership_Name__c, Status__c from Account_Team_Memberships1__r WHERE Certified__c = true AND Status__c = 'Active'),
                //ILMA
                (SELECT Status__c, Certified__c from Parent_Account_Memberships__r WHERE Certified__c = true AND Status__c = 'Active' LIMIT 1) 
            FROM 
                Account
            WHERE
                DISTANCE(Coordinates__c, GEOLOCATION(:latitude, :longitude), 'mi') < :radius
                AND Directory_Opt_In__c = true
                AND IsPersonAccount = false 
            ];
            
            // Separate business accounts into CP and non-CP lists
            for (Account acc : businessAccounts) {
                ListingWrapper wrapper = new ListingWrapper();
                wrapper.acc = acc;
                wrapper.distance = calculateDistance(latitude, longitude, acc.Coordinates__c);
                if (wrapper.acc.Directory_Radius__c == null ||
                (wrapper.acc.Directory_Radius__c != null && wrapper.distance <= wrapper.acc.Directory_Radius__c)) {
                    // Mark as CP only if both conditions are true
                    if (!acc.Account_Team_Memberships1__r.isEmpty()) {
                        wrapper.cp = true;
                        cpListings.add(wrapper);
                    } else if (!acc.Parent_Account_Memberships__r.isEmpty()) {
                        wrapper.cp = false;
                        nonCpListings.add(wrapper);
                    }
                }
            }
            
            // Query person accounts
            List<Account> individualAccounts = [SELECT 
                Id, 
                Name,
                Directory_Email__c, 
                Directory_Phone__c, 
                Directory_Facebook__c, 
                Directory_Instagram__c, 
                Directory_Twitter__c, 
                Directory_LinkedIn__c, 
                Directory_URL__c, 
                Coordinates__c, 
                Directory_Radius__c,
                Directory_Address__c, 
                Directory_Opt_In__c,
                Directory_Company__c,
                Business__c, 
                Admin_Account__c, 
                IsPersonAccount, 
                Care_Type__c, 
                Directory_Species_Avian__c, 
                Directory_Species_Cat__c, 
                Directory_Species_Dog__c, 
                Directory_Species_Equine__c,
                Job_Title__c
            FROM 
                Account 
            WHERE
                DISTANCE(Coordinates__c, GEOLOCATION(:latitude, :longitude), 'mi') < :radius
                //AND (Directory_Radius__c = null OR Directory_Radius__c >= :travelRadius)
                AND Directory_Opt_In__c = true
                AND IsPersonAccount = true 
                AND Business__c = null 
                AND Admin_Account__c = false
                AND Id IN (SELECT Account_Id__c  
                           FROM Account_Membership__c 
                           WHERE Certified__c = true 
                           AND Status__c = 'Active') 
            ];
            
            // Add person accounts to non-CP list
            for (Account acc : individualAccounts) {
                ListingWrapper wrapper = new ListingWrapper();
                wrapper.acc = acc;
                wrapper.distance = calculateDistance(latitude, longitude, acc.Coordinates__c);
                if (wrapper.acc.Directory_Radius__c == null ||
                (wrapper.acc.Directory_Radius__c != null && wrapper.distance <= wrapper.acc.Directory_Radius__c)) {
                    wrapper.cp = false;
                    nonCpListings.add(wrapper); // Add to non-CP list
                }
            }
        }
        
        // Sort the combined listings by distance using custom comparator
        cpListings.sort();
        nonCpListings.sort();
        
        listings.addAll(cpListings);
        listings.addAll(nonCpListings);
        
        return listings;
    }
    
    // Helper method to calculate distance
    private static Decimal calculateDistance(Double latitude, Double longitude, Location accLocation) {
        if (accLocation != null) {
            Location searchLocation = Location.newInstance(latitude, longitude);
            Double distanceLong = Location.getDistance(searchLocation, accLocation, 'mi');
            return Decimal.valueOf(distanceLong).setScale(2, System.RoundingMode.HALF_UP).doubleValue();
        } else {
            return null;
        }
    }
    
    // Inner class to wrap Account records
    public class ListingWrapper implements Comparable {
        @AuraEnabled public Account acc { get; set; }
        @AuraEnabled public Decimal distance { get; set; }
        @AuraEnabled public Boolean cp { get; set; }
        
        // Implement compareTo method for sorting by distance
        public Integer compareTo(Object obj) {
            ListingWrapper other = (ListingWrapper) obj;
            
            // Handle null distances
            if (this.distance == null && other.distance == null) return 0;
            if (this.distance == null) return 1;
            if (other.distance == null) return -1;
            
            // Instead of using Decimal.compareTo(), use basic comparisons
            if (this.distance > other.distance) {
                return 1;
            } else if (this.distance < other.distance) {
                return -1;
            } else {
                return 0;
            }
        }
    }
}