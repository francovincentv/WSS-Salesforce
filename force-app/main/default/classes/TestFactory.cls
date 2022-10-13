@isTest
public with sharing class TestFactory {
    public static Map<String,Schema.RecordTypeInfo> oppRecordTypeInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();


    public static Trigger_Setting__c createTriggerSetting(String objectApiName, Boolean doInsert) {
        Trigger_Setting__c setting = new Trigger_Setting__c(
            Name = objectApiName,
            Disabled__c = false,
            Object_Name__c = objectApiName,
            Before_Update__c = true,
            Before_Insert__c = true,
            Before_Delete__c = true,
            After_Update__c = true,
            After_Undelete__c = true,
            After_Insert__c = true,
            After_Delete__c = true,
            Prevent_Recursion__c = ''
        );

        if(doInsert) {
            insert setting;
        }

        return setting;
    }

    public static List<Account> createAccounts(Integer count , Boolean doInsert) {
        List<Account> accList = new List<Account>();
        for(Integer i=0; i<count; i++) {
            Account acc = new Account();
            acc.Name = 'Test Account '+ i;
            acc.Account_Number__c = '609900000'+i;
            accList.add(acc);
        }
        
        if(doInsert)
            insert accList;

        return accList;
    }

    public static List<Opportunity> createOppForAccounts(Integer count, List<Account> accList, String recordTypeDevName, Boolean doInsert) {
        List<Opportunity> oppList = new List<Opportunity>();
        for(Account acc : accList) {
            for(Integer i=0; i<count; i++) {
                Opportunity opp = new Opportunity();
                opp.Name = 'Test Opportunity ' + i;
                opp.AccountId = acc.Id;
                opp.StageName = 'Generate Interest';
                opp.CloseDate = system.today().addDays(5);
                if(!String.isBlank(recordTypeDevName)) {
                    opp.RecordTypeID = oppRecordTypeInfo.get(recordTypeDevName).getRecordTypeId();
                }
                oppList.add(opp);
            }
        }
        
        if(doInsert)
            insert oppList;
        return oppList;
    }

    public static List<Product2> createProducts(Integer count , Boolean doInsert) {
        List<Product2> prodList = new List<Product2>();
        for(Integer i=0; i<count; i++) {
            Product2  prod = new Product2(); 
            prod.Name = 'Test Product ' + i;
            prod.IsActive = true;
            prodList.add(prod);
        }
        
        if(doInsert)
            insert prodList;

        return prodList;
    }

    public static List<ProductGroup__c> createProductGroups(Integer count , Boolean doInsert) {
        List<ProductGroup__c> records = new List<ProductGroup__c>();
        for(Integer i=0; i<count; i++) {
            String rand = String.valueOf(Math.random()*1000).left(3);
            ProductGroup__c  pgroup = new ProductGroup__c(); 
            pgroup.Name = rand+' Test Product Group ' + i;
            records.add(pgroup);
        }
        if(doInsert)
            insert records;

        return records;
    }    
    
    public static SBQQ__Quote__c createQuote(Id accId, Id oppId, Boolean doInsert) {
        SBQQ__Quote__c  quote = new SBQQ__Quote__c(); 
        quote.TermType__c = 'Evergreen';
        quote.ContractScope__c ='Key Port Prices';
        quote.SBQQ__Account__c = accId;
        quote.SBQQ__Opportunity2__c = oppId;
        quote.SBQQ__StartDate__c = System.Today().addDays(-3);
        quote.SBQQ__ExpirationDate__c = System.Today().addDays(3);
        
        if(doInsert)
            insert quote;

        return quote;
    }

    public static Contract createContractForOpp(Opportunity opp, SBQQ__Quote__c quote, Boolean doInsert) {
        Contract cont = new Contract(
            Status = 'Planned',                                           // Status
            Name = 'Demo Account 123 - Master Supply Agreement - 10/2019',  // Contract Name
            StartDate = System.today().addDays(-20),                         // Contract Start Date
            EndDate = System.today().addDays(20),
            SBQQ__Opportunity__c = opp.Id,                       // Opportunity
            Deal_Type__c = 'Master Supply Agreement',                       // Contract Type
            Delivery_Terms__c = 'FAS',                                    // Delivery Terms
            Customer_Rebate_bonus_included__c = 'No',                       // Customer Rebate (bonus) included
            OECD_notification_period__c = '30 days',                        // Price Adjustment notification period
            Deal_Currency__c = 'USD',                                       // Contract Value per annum                                              // M&R
            Credit_Review_conducted__c = 'No',                              // Credit Review conducted
            Is_the_Contract_signed_by_both_parties__c = 'Yes',              // Is the Contract signed by both parties?
            Is_the_Contract_in_English__c = 'Yes',                          // Is the Contract in English?
            SBQQ__Quote__c = quote.Id,
            AccountId = opp.AccountId,
            MSA_Version__c = 'MSA V3 for cylinders only, no pricing'				//MSA 
            );
        if(doInsert) { insert cont; } 

        return cont;
    }

    public static List<SBQQ__QuoteLine__c> createQuoteLineForProducts(Id quoteId, List<Product2> prodList, Boolean doInsert ) {
        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        //create quote line item for each product
        for(Product2 prod : prodList) {
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Product__c = prod.Id;
            ql.SBQQ__Quantity__c = 3;
            ql.SBQQ__Quote__c = quoteId;
            quoteLineList.add(ql);
        }
        
        if(doInsert)
            insert quoteLineList;

        return quoteLineList;
    }

    public static RebateThreshold__c generateRebateThresholds(Boolean doInsert){
        RebateThreshold__c rebateThresh = new RebateThreshold__c();
        rebateThresh.RebatePercentage__c = 0;
        rebateThresh.RebateThresholdId__c = 'unique-rebate-threshold-id';
        rebateThresh.SalesProductGroupCount__c = 0;

        if(doInsert)
            insert rebateThresh;

        return rebateThresh;
    }

    public static List<SpgThreshold__c> generateSPGThresholds(Boolean doInsert){
        List<SpgThreshold__c> spgs = new List<SpgThreshold__c>();
        //1st Biochemichals SPG
        SpgThreshold__c spgBioch = new SpgThreshold__c();
        spgBioch.CurrencyCode__c = 'USD';
        spgBioch.SalesProductGroupName__c = 'Biochemicals';
        spgBioch.SalesProductGroupId__c = 'SG330';
        spgs.add(spgBioch);

        //2nd Refrigerants SPG
        SpgThreshold__c spgRefr = new SpgThreshold__c();
        spgRefr.CurrencyCode__c = 'USD';
        spgRefr.SalesProductGroupName__c = 'Refrigerants';
        spgRefr.SalesProductGroupId__c = 'SG220';
        spgs.add(spgRefr);

        if(doInsert)
            insert spgs;
        
        return spgs;
    }

    public Static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standardusertest93938@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest93938@testorg.com',
            Sales_Area__c = 'Northern Europe', SM_Territory__c='Russia');
        insert u;
        return u;
    }

    public static List<User> createUsers(Integer count, Boolean doInsert, String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name=:profileName]; 
        List<User> users = new List<User>();
        for (Integer i = 0; i < count; i++) {
            User u = new User(
                Alias = 'user'+i, Email='user'+i+'@example.com', 
                FirstName='Test', LastName='User '+i,
                EmailEncodingKey='UTF-8', 
                LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', 
                TimeZoneSidKey='America/Los_Angeles', 
                ProfileId = p.Id, 
                UserName='testuser'+i+'@wilhelmsen.com'
            );
            users.add(u);
        }
        
        if(doInsert)
            insert users;
        return users;
    }

    public static Purchase_History_Bucket_Lines__c generatePHBL() {
        Purchase_History_Bucket_Lines__c phbLine = new Purchase_History_Bucket_Lines__c();
        phbLine.Amount__c = 200;
        phbLine.relNo__c = '1';
        phbLine.qty__c = 2;
        phbLine.productId__c = '765019';
        phbLine.port__c = 'EGEDK';
        phbLine.payer__c = Decimal.valueOf('8000095100');
        phbLine.orderType__c = 'PRO';
        phbLine.orderNo__c =  'A10112854';
        phbLine.lineItemNo__c = 0;
        phbLine.lineNo__c = '2';
        phbLine.invoiceNo__c = '1685518';
        phbLine.invoiceSeries__c ='CD';
        phbLine.invoiceDate__c = System.now();
        phbLine.CurrencyIsoCode = 'USD';
        phbLine.accountSalesIncome__c = true;
        
        return phbLine;
    }

    public static List<Port__c> createPorts(Integer count , Boolean doInsert) {
        List<Port__c> portList = new List<Port__c>();
        for(Integer i=0; i<count; i++) {
            Port__c port = new Port__c();
            port.Name = 'Test Port '+ i;
            port.Country_Code__c = '0'+i;
            port.Port_Code__c = 'P0'+i;
            portList.add(port);
        }

        if(doInsert)
            insert portList;

        return portList;
    }

    public static List<Vessel__c> createVessels(Integer count , Boolean doInsert) {
        List<Vessel__c> vesselList = new List<Vessel__c>();
        for(Integer i=0; i<count; i++) {
            Vessel__c vessel = new Vessel__c();
            vessel.Name = 'Test Vessel '+ i;
            vessel.IMO_Number__c = '000'+i;
            vesselList.add(vessel);
        }

        if(doInsert)
            insert vesselList;

        return vesselList;
    }

    public static List<Case> createCases(Integer count , Boolean doInsert, Id accId) {
        List<Case> caseList = new List<Case>();
        for(Integer i=0; i<count; i++) {
            Case testCase = new Case();
            testCase.AccountId = accId;
            caseList.add(testCase);
        }

        if(doInsert)
            insert caseList;

        return caseList;
    }

    public static List<Order> createOrders(Integer count , Boolean doInsert, Id accId,Id caseId) {
        List<Order> orderList = new List<Order>();
        for(Integer i=0; i<count; i++) {
            Order order = new Order();
            order.AccountId = accId;
            order.Status = 'Blenda';
            order.EffectiveDate=System.today();
            order.Case_Number__c=caseId;
            orderList.add(order);
        }

        if(doInsert)
            insert orderList;

        return orderList;
    }

    public static List<Quote__c> createQuotes(Integer count , Boolean doInsert, Id accId, Id caseId) {
        List<Quote__c> quoteList = new List<Quote__c>();
        for(Integer i=0; i<count; i++) {
            Quote__c quote = new Quote__c();
            quote.Account__c = accId;
            quote.Case_Number__c=caseId;
            quoteList.add(quote);
        }

        if(doInsert)
            insert quoteList;

        return quoteList;
    }


    public static List<OrderProcessExceptionType__c> createExceptionTypes(Integer count , Boolean doInsert) {
        List<OrderProcessExceptionType__c> orderProcessExceptionTypeList = new List<OrderProcessExceptionType__c>();
        for(Integer i=0; i<count; i++) {
            OrderProcessExceptionType__c orderProcessExceptionType = new OrderProcessExceptionType__c();
            //orderProcessExceptionType.Name='Exc type '+i;
            orderProcessExceptionType.AdditionalDetailsAllowed__c='No';
            orderProcessExceptionType.ValidationDataEntity__c='None';
            orderProcessExceptionType.OrderValue__c=true;
            orderProcessExceptionType.Title__c='Exc type '+i;
            orderProcessExceptionType.ExceptionCategory__c='Communication Preferences';
            orderProcessExceptionType.ExceptionReason__c='Customer Preference';
            orderProcessExceptionType.ApplicationArea__c='Quote';
            orderProcessExceptionType.Type__c='Basic';
            orderProcessExceptionTypeList.add(orderProcessExceptionType);
            orderProcessExceptionType.ProductCategory__c = true;
            orderProcessExceptionType.Product__c = true;
            orderProcessExceptionType.VesselFlag__c = true;
            orderProcessExceptionType.Vessel__c = true;
            orderProcessExceptionType.VesselType__c = true;
            orderProcessExceptionType.CountryOfCustomer__c = true;
            orderProcessExceptionType.CountryOfDelivery__c = true;
            orderProcessExceptionType.CustomerSegment__c = true;
            orderProcessExceptionType.OrderValue__c = true;
            orderProcessExceptionType.PortOfDelivery__c = true;
            orderProcessExceptionType.Other__c = true;
            orderProcessExceptionType.SalesTerritory__c = true;
            orderProcessExceptionType.CSTeam__c = true;
        }

        if(doInsert)
            insert orderProcessExceptionTypeList;

        return orderProcessExceptionTypeList;
    }
    //Exception Type with AdditionalDetailsAllowed__c = Yes or List.
    public static List<OrderProcessExceptionType__c> createExceptionTypes(Integer count , Boolean doInsert, String detailsAllowed, String validationDataEntity) {
        List<OrderProcessExceptionType__c> orderProcessExceptionTypeList = createExceptionTypes(count,false);
        for(OrderProcessExceptionType__c opet : orderProcessExceptionTypeList){
            opet.AdditionalDetailsAllowed__c = detailsAllowed;
            if(detailsAllowed== 'Yes') opet.ValidationDataEntity__c= validationDataEntity;
            else if(detailsAllowed== 'List') {
                opet.Details__c='input 1'+'\n'+'input 2';
                opet.ValidationDataEntity__c= 'None';
            }
        }

        if(doInsert)
            insert orderProcessExceptionTypeList;

        return orderProcessExceptionTypeList;
    }

    public static List<OrderProcessException__c> createExceptions(Integer count , Boolean doInsert,Id typeId) {
        List<OrderProcessException__c> orderProcessExceptionList = new List<OrderProcessException__c>();
        for(Integer i=0; i<count; i++) {
            OrderProcessException__c orderProcessException = new OrderProcessException__c();
            orderProcessException.Exception__c=typeId;
            orderProcessException.CustomerRole__c='Payer';
            //orderProcessException.ExceptionCategory__c='Communication Preferences';
            orderProcessException.ExceptionReason__c='Customer Preference';
            orderProcessException.ReviewDate__c=System.today()+1;
            orderProcessException.OrderValueLogic__c=OrderExceptionUtils.OPERATOR_EQUAL_TO;
           // orderProcessException.CustomerRole__c='requester';
            orderProcessExceptionList.add(orderProcessException);
        }

        if(doInsert)
            insert orderProcessExceptionList;

        return orderProcessExceptionList;
    }

    public static Map<String,String> getPicklistValues(SObjectType sObjType, String fieldName){
        Map<String,String> picklistValues;
        String fieldNameLower = fieldName.toLowerCase();
        Schema.DescribeSObjectResult sObjDesc = sObjType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = sObjDesc.fields.getMap();
        if(fieldMap.containsKey(fieldNameLower)){
            Schema.DescribeFieldResult field = fieldMap.get(fieldNameLower).getDescribe();
            System.debug(field.GetType());
            if(field.GetType() == Schema.DisplayType.Picklist || field.GetType() == Schema.DisplayType.MultiPicklist){
                picklistValues = new  Map<String,String>();
                for(Schema.PicklistEntry pe :field.getPicklistValues()){
                    if(pe.isActive())
                        picklistValues.put(pe.getValue(),pe.getLabel());
                }
            }
        }
        //System.debug(JSON.serializePretty(picklistValues));
        return picklistValues;
    }

    public static void activateCustomPerm(Id userId, String permissionName) {
        PermissionSet ps = new PermissionSet(
          Name = 'CustomPermissionEnabled',
          Label = 'Custom Permisison Enabled'
          );
        insert ps;
      
        SetupEntityAccess sea = new SetupEntityAccess(
          ParentId = ps.Id,
          SetupEntityId = [
            SELECT Id
            FROM CustomPermission
            WHERE DeveloperName = :permissionName
            LIMIT 1
          ].Id
        );
      
        PermissionSetAssignment psa = new PermissionSetAssignment(
          AssigneeId = userId,
          PermissionSetId = ps.Id
        );
      
        insert new List<SObject>{ sea, psa };
      }

}