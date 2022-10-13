@isTest

public class CPQ_Pricing_Test {
    
    @testSetup static void setupData() {
        

        Trigger_Setting__c quoteTriggerSetting = TestFactory.createTriggerSetting('SBQQ__Quote__c', false);
        quoteTriggerSetting.Disabled__c = true;
        insert quoteTriggerSetting;

        Trigger_Setting__c quoteLineTriggerSetting = TestFactory.createTriggerSetting('SBQQ__QuoteLine__c', false);
        quoteLineTriggerSetting.Disabled__c = true;
        insert quoteLineTriggerSetting;

        API_Keys__c apikey = new API_Keys__c();
        apikey.Name = 'CPQ_Pricing';
        apikey.End_Point__c = 'https://wilhelmsen.azure-api.net/pricing-simulation/v1/impact/v2';
        apikey.API_key__c = 'rtytrwertqsdfggfewertytrew';
        insert apikey;
       
        List<Account> accList = new List<Account>();
        
        //create account
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Account_Number__c = '6000000000';
        accList.add(acc);
        
        //create account
        Account acc2 = new Account();
        acc2.Name = 'Test Account2';
        acc2.Account_Number__c = '6000000002';
        accList.add(acc2);
        
        insert accList;

        Opportunity opp  = TestFactory.createOppForAccounts(1, new List<Account>{accList[0]}, '', false)[0];
        opp.sbaa__ApprovalStatus__c = 'Approved';
        insert opp;

        //Id wssRecordType = Schema.SObjectType.ContractParty__c.getRecordTypeInfosByName().get('WSS').getRecordTypeId();
        Id cusRecordType = Schema.SObjectType.ContractParty__c.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        
        ContractParty__c conParty = new ContractParty__c();
        conParty.Account__c = acc.Id;
        conParty.Opportunity__c = opp.Id;
        conParty.RecordTypeId = cusRecordType;
        
        ContractParty__c conParty2 = new ContractParty__c();
        conParty2.Account__c = acc2.Id;
        conParty2.Opportunity__c = opp.Id;
        conParty2.RecordTypeId = cusRecordType;
        
        insert new List<ContractParty__c>{conParty, conParty2};
        
        Product2 Pro1 = new Product2();
        Pro1.Name = 'SLA: Bronze';
        pro1.isActive = True;
        insert pro1;
        
        Id pricebookId = Test.getStandardPricebookId();        

        PricebookEntry StandardPriceBookEntry = new PricebookEntry();
        StandardPriceBookEntry.Pricebook2Id = pricebookId;
        StandardPriceBookEntry.Product2Id = pro1.Id;
        StandardPriceBookEntry.UnitPrice = 10000;
        StandardPriceBookEntry.IsActive =True;        
        insert StandardPriceBookEntry;
        
        SBQQ__Quote__c Quo1 = new SBQQ__Quote__c(); 
        Quo1.SBQQ__Opportunity2__c = opp.Id;
        Quo1.SBQQ__PricebookId__c = pricebookId;
        Quo1.Order_Size_Improvement__c = 12; 
        Quo1.SBQQ__Primary__c = true;
        Quo1.SBQQ__Status__c = 'Accepted';
        Quo1.Predictability_Improvement__c = 11;
        insert Quo1;
        system.debug('insert Quo1 success');

        SBQQ__QuoteLine__c QLI  = new SBQQ__QuoteLine__c();
        QLI.SBQQ__Product__c = pro1.Id;
        QLI.SBQQ__Quote__c = Quo1.Id;
        QLI.SBQQ__PricebookEntryId__c = StandardPriceBookEntry.Id;
        QLI.SBQQ__Quantity__c = 2;
        QLI.SBQQ__UnitCost__c = 150000.0;
        insert QLI;
        system.debug('insert QLI is success');
        
    }
    
    static testMethod void postExternalPricing_test() {
        
        Test.setMock(HttpCalloutMock.class, new CPQ_External_HttpCalloutMock());
        
        List<String> quoteLineId = new List<String>();
        
        for(SBQQ__QuoteLine__c ql : [SELECT Id FROM SBQQ__QuoteLine__c]) {
            quoteLineId.add(ql.Id);
        }
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/pricing'; 
        req.httpMethod = 'Post';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res; 
        Test.startTest();
        String response = CPQ_Pricing.postExternalPricing(quoteLineId);
        System.debug('response'+ response);
        Test.stopTest();  
        System.assertEquals('{"impact": 0.02}', response);
    }
    
}