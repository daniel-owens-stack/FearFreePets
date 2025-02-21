@isTest
public class B2BTestDataFactory {
    // Create Test WebStore
    public static void createWebStore() {
        WebStore webStore = new WebStore(Name='TestWebStore', DefaultLanguage='en_US');
        insert webStore;

        createBuyerGroup(webStore.Id);
    }

    //Create Buyer Group
    public static void createBuyerGroup(String webStoreId) {
        BuyerGroup bg = new BuyerGroup(
            Name = 'Test Buyer Group'
        );
        insert bg;

        assignBuyerGroupToStore(webStoreId);
    } 

    //Create Test Store Buyer Group
    public static void assignBuyerGroupToStore(String webStoreId) {
        String buyerGroupId = [SELECT Id FROM BuyerGroup WHERE Name = 'Test Buyer Group' LIMIT 1].Id;

        WebstoreBuyerGroup sbg = new WebstoreBuyerGroup(
            BuyerGroupId = buyerGroupId,
            WebStoreId = webStoreId
        );
        insert sbg;
    }

    //Create Test Account
    public static Id createAccount() {
        Account account = new Account(
            Name = 'Test Account'
        );
        insert account;
        return account.Id;
    }

    //Create Test Contact
    public static Id createContact(String accountId) {
        Contact contact = new Contact(
               FirstName = 'Test',
               LastName = 'User',
               AccountId = accountId,
               Email = System.now().millisecond() + 'test@test.com'
        );
        insert contact;
        return contact.Id;   
    }

    //Create B2B Community User
    public static User createCommunityUser(String contactId) {
        List<Contact> contact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id =:contactId];
        String profileId = [SELECT Id FROM Profile WHERE Name = 'Fear Free Community Member' LIMIT 1].Id;

        User u = new User(
            Alias = 'Test',
            CommunityNickname = 'Test',
            ContactId = contactId,
            Email = contact[0].Email,
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            LastName = contact[0].LastName,
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/New_York',
            Username = 'testuser@gmail.com'
        );
        insert u;
        assignPermissions(u);
        return u;
    }

     //Assign Permission Set to the User
     public static void assignPermissions(User user) {
        
        System.runAs(user) {
            String permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Fear_Free_B2B_Store_Buyer' AND IsCustom = true LIMIT 1].Id;
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = user.Id,
                PermissionSetId = permissionSetId
            );
            insert psa;
        }
    }

    //Create Test Product
    public static Id createProduct() {
        Product2 product = new Product2(
            IsActive = true,
            Name = 'Test Product1', 
            Family = 'TestClass',
            StockKeepingUnit = 'Test',
            LengthIn__c = 2.00,
            WidthIn__c = 1.00,
            HeightIn__c = 1.00,
            IsShippingChargeNotApplicable = false
        );
        insert product;
        return product.Id;
    }

    //Create Test Shipping Product
    public static void createShippingProduct() {
        Product2 product = new Product2(
            IsActive = true,
            Name = 'Delivery Charge', 
            Family = 'Shipping',
            StockKeepingUnit = 'Shipping'
        );
        insert product;
    }

    //Create Test Set Product
    public static Id createSetProduct() {

        ProductRelationshipType prt = new ProductRelationshipType(
            AssociatedProductRoleCat = 'SetComponent',
            MainProductRoleCat = 'Set',
            Name = 'Set to Set Component Relationship'
        );
        insert prt;

        Product2 parentProduct = new Product2(
            IsActive = true,
            Name = 'Test Set Product', 
            StockKeepingUnit = 'Parent',
            Type = 'Set',
            Product_Group__c = 'Certification Kit'
        );
        insert parentProduct;

        Product2 childProduct = new Product2(
            IsActive = true,
            Name = 'Test Child Product',
            StockKeepingUnit = 'Child'
        );
        insert childProduct;

        ProductRelatedComponent prc = new ProductRelatedComponent(
            ChildProductId = childProduct.Id,
            ParentProductId = parentProduct.Id,
            Quantity = 1,
            ProductRelationshipTypeId = prt.Id
        );
        insert prc;
        return parentProduct.Id;
    }

    //Create Test Order Delivery Method
    public static Id createOrderDeliveryMethod(String productId) {
        OrderDeliveryMethod orderDeliveryMethod = new OrderDeliveryMethod(
            Name = 'FedEX Priority (AM Delivery)',
            ProductId = productId,
            IsActive = true
        );
        insert orderDeliveryMethod;
        return orderDeliveryMethod.Id;
    }

    //Create Test WebCart
    public static void createWebCart(String webStoreId, String accountId, String userId) {
        WebCart cart = new WebCart(
            Status = 'Active',
            AccountId = accountId,
            OwnerId = userId,
            WebStoreId = webStoreId,
            Name = 'Test Cart'
        );
        insert cart;
    }

    //Create CartDeliveryGroup
    public static void createCartDeliveryGroup(String cartId, String productId) {
        CartDeliveryGroup cdg = new CartDeliveryGroup(
            CartId = cartId,
            Name = 'Test Cart Delivery Group',
            DeliverToCountry = 'US'
        );
        insert cdg;

        createCartItems(cartId, cdg.Id, productId);
    }

    //Create Test CartItems
    public static void createCartItems(String cartId, String cdgId, String productId) {
        Product2 product = [SELECT Id, Name FROM Product2 WHERE Id = :productId LIMIT 1];
        CartItem ci = new CartItem(
            CartId = cartId,
            CartDeliveryGroupId = cdgId,
            Name = product.Name,
            ListPrice = 10,
            Product2Id = productId,
            Quantity = 1
        );
        insert ci;
    }

    //Create Test Order
    public static Id createOrder(String accountId, String productId) {
        Order o = new Order(
            AccountId = accountId,
            Status = 'Draft',
            OrderedDate = System.now(),
            EffectiveDate = System.today()
        );
        insert o;
        createOrderDeliveryGroup(productId, o.Id);
        return o.Id;
    }

    //Create Order Delivery Group
    public static void createOrderDeliveryGroup(String productId, String orderId) {
        String odmId = createOrderDeliveryMethod(productId);
        OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
            DeliverToName = 'Test User',
            DeliverToCountry = 'US',
            OrderDeliveryMethodId = odmId,
            OrderId = orderId
        );
        insert orderDeliveryGroup;
        createOrderItems(productId, orderId, orderDeliveryGroup.Id);
    }

    //Create Order Items for the Test Order
    public static void createOrderItems(String productId, String orderId, String odgId) {
        OrderItem orderItem = new OrderItem(
            Product2Id = productId,
            Type = 'Order Product',
            Quantity = 1,
            ListPrice = 1,
            UnitPrice = 1,
            OrderId = orderId,
            OrderDeliveryGroupId = odgId,
            TotalLineAmount = 1
        );
        insert orderItem;

        //Activate the Order
        Order o = [SELECT Id FROM Order WHERE Id=:orderId];
        o.Status = 'Activated';

        Update o;
    }

    //Create Test Content Version
    public static ContentVersion createContentVersion() {
        String fileName = 'Test File';
        String content = 'Unit Test Attachment Body';
        String base64Content = EncodingUtil.urlDecode(content, 'UTF-8');

        ContentVersion cv = new ContentVersion(
            Title = fileName,
            PathOnClient = '/' + fileName,
            IsMajorVersion = true,
            VersionData = EncodingUtil.base64Decode(base64Content)
        );
        insert cv;
        return cv;
    }

    public static Id createPersonAccount() {
        Id personAccountRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
        Account account = new Account(
            FirstName = 'Test',
            LastName = 'Account',
            RecordTypeId = personAccountRecordTypeId
        );
    
        insert account;
        return account.Id;
    }
}