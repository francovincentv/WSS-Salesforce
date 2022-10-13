@isTest
public with sharing class QuotePdfRestAPITest {

    @TestSetup
    static void makeData(){
        Trigger_Setting__c quoteTriggerSetting = TestFactory.createTriggerSetting('SBQQ__Quote__c', false);
        quoteTriggerSetting.Disabled__c = true;
        insert quoteTriggerSetting;

        Trigger_Setting__c quoteLineTriggerSetting = TestFactory.createTriggerSetting('SBQQ__QuoteLine__c', false);
        quoteLineTriggerSetting.Disabled__c = true;
        insert quoteLineTriggerSetting;

        API_Keys__c apikey = new API_Keys__c();
        apikey.Name = 'Quote_PDF';
        apikey.End_Point__c = 'https://wilhelmsen.azure-api.net/pricing-simulation/v1/pdf';
        apikey.Subscription_Key__c = 'wertyuiop3456fghjktyuio';
        insert apikey;

        AccessTokenGenerator__c atg = new AccessTokenGenerator__c();
        atg.Name = 'QuotePdf';
        atg.EndPoint__c = 'test';
        atg.Scope__c = 'test';
        atg.Clinet_Id__c = 'test';
        atg.Client_Secrect__c = 'test';
        insert atg;
        
        //create account
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Account_Number__c = '6000000000';       
        insert acc;

         //create opportunity
         Opportunity opp = TestFactory.createOppForAccounts(1, new List<Account>{acc}, '', false)[0];
         opp.sbaa__ApprovalStatus__c = 'Approved';
         opp.No_of_Ships_Targeted__c = 20;
         insert opp;

         Id wssRecordType = Schema.SObjectType.ContractParty__c.getRecordTypeInfosByName().get('WSS').getRecordTypeId();
         Id cusRecordType = Schema.SObjectType.ContractParty__c.getRecordTypeInfosByName().get('Customer').getRecordTypeId();

        List<ContractParty__c> cpList = new List<ContractParty__c>();

        ContractParty__c conParty = new ContractParty__c();
        conParty.Account__c = acc.Id;
        conParty.Opportunity__c = opp.Id;
        conParty.RecordTypeId = cusRecordType;
        cpList.add(conParty);
        //System.debug('contract party created'+conParty);
        //System.debug('opp'+opp.ContractParties__c);
        
        ContractParty__c conParty2 = new ContractParty__c();
        conParty2.Account__c = acc.Id;
        conParty2.Opportunity__c = opp.Id;
        conParty2.RecordTypeId = cusRecordType;
        cpList.add(conParty2);

        insert cpList;
        System.debug('contract party created'+cpList);

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
    
    static testMethod void getQuotePdfTest(){

        Id quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
        Test.setMock(HttpCalloutMock.class, new GetQuotePdf_HttpCalloutMock());
        Test.startTest();
        String response = QuotePdfRestAPI.getQuotePdf(quoteId);
        Test.stopTest();
        System.debug('response '+ response);
        System.assertEquals('Success', response);
    }
}