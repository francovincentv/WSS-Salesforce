@isTest
private class OPEDataValidation_Test {
    @TestSetup
    static void createTestData(){
        // Setup Triggers
        Trigger_Setting__c opeTriggerSetting = TestFactory.createTriggerSetting('OrderProcessException__c', false);
        opeTriggerSetting.Prevent_Recursion__c = 'PortOfDelivery__c,Vessel__c,Product__c,Sub_Account_Ids__c,Status__c,Reviewer__c';
        Trigger_Setting__c opecTriggerSetting = TestFactory.createTriggerSetting('OrderProcessExceptionCondition__c', false);
        opecTriggerSetting.Prevent_Recursion__c = 'Status__c, Code__c';
        List<Trigger_Setting__c> settings = new List<Trigger_Setting__c>{opeTriggerSetting,opecTriggerSetting};
        insert settings;

        User advisor = TestFactory.createUsers(1, false, 'WSS - Customer Services')[0];
        advisor.Alias = 'advisor';
        advisor.Function__c = 'Customer Coordinator';
        insert advisor;
        
        System.runAs(new User(Id=UserInfo.getUserId())){
            TestFactory.activateCustomPerm(UserInfo.getUserId(), 'Is_OPEL_Admin');
        }

        /* CONDITION-RELATED RECORDS */
        
        // 10 Products within 5 Product Groups
        List<ProductGroup__c> pGroups = TestFactory.createProductGroups(5,true);
        Formula.recalculateFormulas(pGroups);
        System.debug(JSON.serializePretty(pGroups));

        List<Product2> products = TestFactory.createProducts(10, false);
        for(Integer i=0; i<products.size(); i++){
            Integer groupIndex = Integer.valueOf(i/2);
            products[i].ProductGroup__c = pGroups[groupIndex].Id;
            products[i].Product_Code__c = pGroups[groupIndex].Code__c+String.valueOf(i).leftPad(3, '0');
            products[i].ProductCode = products[i].Product_Code__c;
            
        }
        insert products;
        System.debug(JSON.serializePretty(products));
        
        // 10 Sub-Accounts
        Id subAccountRecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Sub_Account').getRecordTypeId();
        List<Account> subAccounts = new List<Account>();
        for(Account a : TestFactory.createAccounts(10,false)){
            a.RecordTypeId = subAccountRecordTypeId;
            a.Customer_Coordinator__c = advisor.Id;
            subAccounts.add(a);
        }
        insert subAccounts;
        
        // 10 Vessels
        List<Vessel__c> vessels = TestFactory.createVessels(10,true);

        // 10 Ports with Locations
        String[] countries = new List<String>{'JP','CN','SA','NL','IT'};
        Map<String,String> countryPicklist = TestFactory.getPicklistValues(OrderProcessException__c.getSObjectType(), 'CountryofDeliveryList__c');
        List<Location__c> locations = new List<Location__c>();
        for(String country : countries){
            Location__c loc = new Location__c(Type__c='Country');
            loc.isocode__c = country;
            loc.Name = countryPicklist.get(country);
            locations.add(loc);
        }
        insert locations;
        List<Port__c> ports = new List<Port__c>();
        Integer count = 0;
        for (Port__c p : TestFactory.createPorts(10,false)) {
            Integer locIndex = Integer.valueOf(count/2);
            p.Location__c = locations[locIndex].Id;
            p.Country_Code__c = locations[locIndex].isocode__c;
            ports.add(p);
        }
        insert ports;

        /* STARLIST RECORDS */
        // Exception Types
        // No Details - Delivery Preferences
        // Details Allowed - Product Preferences
        // List - Payment Preferences

        List<OrderProcessExceptionType__c> exceptionTypes = new List<OrderProcessExceptionType__c>();
        exceptionTypes.add(TestFactory.createExceptionTypes(1,false)[0]);
        exceptionTypes.add(TestFactory.createExceptionTypes(1,false,'Yes','Product Number')[0]);
        exceptionTypes.add(TestFactory.createExceptionTypes(1,false,'Yes','Sub-Account Number')[0]);
        exceptionTypes.add(TestFactory.createExceptionTypes(1,false,'List',null)[0]);
        exceptionTypes[0].Title__c = 'No';
        exceptionTypes[1].Title__c = 'Yes_Product';
        exceptionTypes[2].Title__c = 'Yes_Sub-Account';
        exceptionTypes[3].Title__c = 'List';
        insert exceptionTypes;
        
    }

    @isTest
    static void opeConditionInputValidationsTest() {
        System.debug('@opeConditionInputValidationsTest');
        
        // Validate Product Category
        String[] validCodes = new List<String>();
        String[] invalidCodes = new List<String>{'999','888'};
        for(ProductGroup__c grp : [SELECT Code__c FROM ProductGroup__c WHERE Code__c <> NULL]){
            validCodes.add(grp.Code__c);
        }

        OrderProcessExceptionType__c opeType = [SELECT Id FROM OrderProcessExceptionType__c WHERE Title__c = 'No' LIMIT 1];
        OrderProcessException__c ope = TestFactory.createExceptions(1, true, opeType.Id)[0];

        System.debug('# Test: Validate Product Category');
        
        // With Invalid Codes
        ope.ProductCategory__c = String.join(invalidCodes,';');
        
        // Expected fail because Condition needs modifier:
        Database.SaveResult failResult1 = Database.update(ope, false);
        System.assert(!failResult1.isSuccess());
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,failResult1.getErrors()[0].statusCode);
        System.assert(failResult1.getErrors()[0].fields.contains('ProductCategoryLogic__c'));
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,failResult1.getErrors()[1].statusCode);
        System.assert(failResult1.getErrors()[1].message.contains('Product Categories are invalid'));

        // With Valid Codes
        ope.ProductCategoryLogic__c = OrderExceptionUtils.OPERATOR_APPLIES_TO;
        ope.ProductCategory__c = String.join(validCodes,';');
        Database.SaveResult successResult1 = Database.update(ope, false);
        System.assert(successResult1.isSuccess());
        
        //System.debug(JSON.serializePretty(successResult1,true));
        
    }

    @isTest
    static void detailsValidationTest() {
        System.debug('@detailsValidationTest');

        // OPE Type with validation on Product Number
        List<OrderProcessExceptionType__c> opeTypes = [SELECT Id, ValidationDataEntity__c FROM OrderProcessExceptionType__c WHERE Title__c LIKE 'Yes%' ORDER BY Title__c];
        OrderProcessException__c opeProduct = TestFactory.createExceptions(2, true, opeTypes[0].Id)[0];
        OrderProcessException__c opeSubAccount = TestFactory.createExceptions(2, true, opeTypes[1].Id)[0];

        System.debug('# Test: Validate Product Numbers');
        
        String[] validCodes = new List<String>();
        String[] invalidCodes = new List<String>{'999','888'};
        for(Product2 p : [SELECT Product_Code__c FROM Product2 WHERE Product_Code__c <> NULL LIMIT 3]){
            validCodes.add(p.Product_Code__c);
        }

        // With Invalid Codes
        opeProduct.Details__c = String.join(invalidCodes,';');
        
        // Expected fail because Condition needs modifier:
        Database.SaveResult failResult1 = Database.update(opeProduct, false);
        //System.debug(JSON.serializePretty(failResult1,true));

        System.assert(!failResult1.isSuccess());
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,failResult1.getErrors()[0].statusCode);
        System.assert(failResult1.getErrors()[0].fields.contains('Details__c'));

        // With Valid Codes
        opeProduct.Details__c = String.join(validCodes,';');
        Database.SaveResult successResult1 = Database.update(opeProduct, false);
        System.debug(JSON.serializePretty(successResult1,true));
        System.assert(successResult1.isSuccess());
        

        System.debug('# Test: Validate Sub-Accounts');

        String[] validSubAccounts = new List<String>();
        String[] invalidSubAccounts = new List<String>{'99999999','88888888'};
        for(Account a : [SELECT Account_Number__c FROM Account WHERE RecordType.DeveloperName = 'Customer_Sub_Account' AND Account_Number__c <> NULL LIMIT 3]){
            validSubAccounts.add(a.Account_Number__c);
        }
        
        // With Invalid Codes
        opeSubAccount.Details__c = String.join(invalidSubAccounts,';');
        
        // Expected fail because Condition needs modifier:
        Database.SaveResult failResult2 = Database.update(opeSubAccount, false);
        //System.debug(JSON.serializePretty(failResult1,true));

        System.assert(!failResult2.isSuccess());
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,failResult2.getErrors()[0].statusCode);
        System.assert(failResult2.getErrors()[0].fields.contains('Details__c'));

        // With Valid Codes
        opeSubAccount.Details__c = String.join(validSubAccounts,';');
        Database.SaveResult successResult2 = Database.update(opeSubAccount, false);
        System.assert(successResult2.isSuccess());

    }

    @isTest
    static void conditionsValidationTest() {
        System.debug('@opeConditionInputValidationsTest');

        OrderProcessExceptionType__c opeType = [SELECT Id FROM OrderProcessExceptionType__c WHERE Title__c = 'No' LIMIT 1];
        OrderProcessException__c ope = TestFactory.createExceptions(1, true, opeType.Id)[0];

        String[] validPorts = new List<String>();
        for(Port__c p : [SELECT Port_Code__c FROM Port__c WHERE Port_Code__c <> NULL LIMIT 3]){
            validPorts.add(p.Port_Code__c);
        }
        String[] validSubAccounts = new List<String>();
        for(Account a : [SELECT Account_Number__c FROM Account WHERE RecordType.DeveloperName = 'Customer_Sub_Account' AND Account_Number__c <> NULL LIMIT 3]){
            validSubAccounts.add(a.Account_Number__c);
        }

        System.debug('# Test: Add Ports and Sub-Accounts as conditions');

        // Expected fail by adding invalid codes to Condition field:
        // Invalid Ports
        ope.PortOfDeliveryLogic__c = OrderExceptionUtils.OPERATOR_APPLIES_TO;
        ope.PortOfDelivery__c = String.join(validPorts,';')+';WRONGPORT';
        // Invalid Sub-Accounts
        ope.CustomerRole__c = 'Any';
        ope.Sub_Account_Ids__c = String.join(validSubAccounts,';')+';WRONGACCT';

        Database.SaveResult failResult1 = Database.update(ope, false);
        // System.debug(JSON.serializePretty(failResult1,true));

        System.assert(!failResult1.isSuccess());
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION,failResult1.getErrors()[0].statusCode);
        System.assert(failResult1.getErrors()[0].getMessage().contains('WRONGPORT'));
        System.assert(failResult1.getErrors()[0].getMessage().contains('WRONGACCT'));


        // VALID Ports
        ope.PortOfDelivery__c = String.join(validPorts,';');
        // VALID Sub-Accounts
        ope.Sub_Account_Ids__c = String.join(validSubAccounts,';');

        // Update OPE
        Database.SaveResult successResult1 = Database.update(ope, false);
        // System.debug(JSON.serializePretty(successResult1,true));
        System.assert(successResult1.isSuccess());

        List<OrderProcessExceptionCondition__c> conditions = [SELECT Id, RecordTypeId, Status__c, Code__c FROM OrderProcessExceptionCondition__c WHERE OrderProcessException__c = :ope.Id];
        System.assertEquals(6,conditions.size());
        Set<String> conditionCodes = new Set<String>();
        for(OrderProcessExceptionCondition__c c : conditions)
            conditionCodes.add(c.Code__c);
        
        System.assert(conditionCodes.containsAll(validPorts));
        System.assert(conditionCodes.containsAll(validSubAccounts));
        
        System.debug('# Test: Remove conditions');
        
        ope.PortOfDelivery__c = validPorts[0];
        ope.Sub_Account_Ids__c = validSubAccounts[0];
        
        // Update OPE
        Database.SaveResult successResult2 = Database.update(ope, false);
        System.debug(JSON.serializePretty(successResult2,true));
        System.assert(successResult2.isSuccess());
    }

    @isTest
    static void getActiveApprovalProcessIdTest() {
        String CONDITIONS_APPROVAL_PROCESS = 'OPE_Sub_Accounts_Created';

        Test.startTest();
        System.assert(OPEDataValidation.getActiveApprovalProcessId('Unknown_Process') == null);

        System.assert(OPEDataValidation.getActiveApprovalProcessId(CONDITIONS_APPROVAL_PROCESS) != null);
        Test.stopTest();
    }

    @isTest
    static void validateAttachmentsTest() {
        Id currentUserId = UserInfo.getUserId();

        OrderProcessExceptionType__c opeType = [SELECT Id FROM OrderProcessExceptionType__c WHERE Title__c = 'No' LIMIT 1];
        opeType.AttachmentRequired__c = true;
        update opeType;
        OrderProcessException__c ope = TestFactory.createExceptions(1, true, opeType.Id)[0];
        Map<String,String> countryPicklist = TestFactory.getPicklistValues(OrderProcessException__c.getSObjectType(), 'CountryofCustomerList__c');
        List<String> countryCodeList = new List<String>(countryPicklist.keySet());
        ope.CountryOfCustomerLogic__c = OrderExceptionUtils.OPERATOR_APPLIES_TO;
        ope.CountryofCustomerList__c = countryCodeList[4]+';'+countryCodeList[20];
        update ope;

        // Submit for Approval
        String APPROVAL_PROCESS = 'NewOrderProcessException';
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setProcessDefinitionNameOrId(APPROVAL_PROCESS);
        approvalRequest.setObjectId(ope.Id);
        approvalRequest.setSubmitterId(UserInfo.getUserId());
        approvalRequest.setComments('Test');
        System.runAs(new User(Id=currentUserId)){
            try {
                Approval.ProcessResult submitResult = Approval.process(approvalRequest);
            } catch (DmlException e) {
                System.debug(e.getMessage());
                System.assert(e.getMessage().contains('No file attachment'));
            }
        }

        // Insert File
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion'); 
            
        ContentVersion file = new ContentVersion(
            Title='SampleTitle', 
            PathOnClient ='test.txt',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        insert file;
            
        ContentVersion fileDetails = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
            
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = ope.id;
        contentlink.ContentDocumentId = fileDetails.ContentDocumentId;
        contentlink.ShareType = 'V';
        insert contentlink;
        System.runAs(new User(Id=currentUserId)){
            Approval.ProcessResult submitResult = Approval.process(approvalRequest);
            Id instanceId = submitResult.getInstanceId();
            System.debug('succcess: '+ submitResult.isSuccess());
            System.debug('instanceid: '+ submitResult.getInstanceId());
        }

    }

    @isTest
    static void setReviewersTest() {

        OrderProcessExceptionType__c opeType = [SELECT Id FROM OrderProcessExceptionType__c WHERE Title__c = 'No' LIMIT 1];
        OrderProcessException__c ope = TestFactory.createExceptions(1, true, opeType.Id)[0];
        String[] validSubAccounts = new List<String>();
        Id advisorId;
        for(Account a : [SELECT Account_Number__c,Customer_Coordinator__c FROM Account WHERE RecordType.DeveloperName = 'Customer_Sub_Account' AND Account_Number__c <> NULL LIMIT 3]){
            validSubAccounts.add(a.Account_Number__c);
            if(advisorId == null)
                advisorId = a.Customer_Coordinator__c;
        }
        ope.CustomerRole__c = 'Any';
        ope.Sub_Account_Ids__c = String.join(validSubAccounts,';');
        update ope;

        // Submit for Approval
        String APPROVAL_PROCESS = 'NewOrderProcessException';
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setProcessDefinitionNameOrId(APPROVAL_PROCESS);
        approvalRequest.setObjectId(ope.Id);
        approvalRequest.setSubmitterId(UserInfo.getUserId());
        approvalRequest.setComments('Test');
        
        Approval.ProcessResult submitResult = Approval.process(approvalRequest);

        OrderProcessException__c opeSubmitted = [SELECT Id, Name, Status__c, OwnerId, Exception__c, Reviewer__c,
        CustomerRole__c, ExceptionCategory__c, ExceptionReason__c, ReviewDate__c FROM OrderProcessException__c WHERE Id = :ope.Id LIMIT 1];
        System.debug(JSON.serializePretty(opeSubmitted, true));
    }

}