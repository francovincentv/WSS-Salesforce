@isTest
public class QuoteTriggerHelperTest {
    @TestSetup
    static void makeData(){

        Trigger_Setting__c quoteTriggerSetting = TestFactory.createTriggerSetting('SBQQ__Quote__c', true);

        Trigger_Setting__c quoteLineTriggerSetting = TestFactory.createTriggerSetting('SBQQ__QuoteLine__c', false);
        quoteLineTriggerSetting.Disabled__c = true;
        insert quoteLineTriggerSetting;
        

        List<Account> accList = TestFactory.createAccounts(1, true);
        Opportunity opp = TestFactory.createOppForAccounts(1, accList, null, false)[0];
        opp.sbaa__ApprovalStatus__c = 'Approved';
        insert opp;

        Id cusRecordType = Schema.SObjectType.ContractParty__c.getRecordTypeInfosByName().get('Customer').getRecordTypeId();

        ContractParty__c conParty = new ContractParty__c();
        conParty.Account__c = accList[0].Id;
        conParty.Opportunity__c = opp.Id;
        conParty.RecordTypeId = cusRecordType;
        insert conParty;

        SBQQ__Quote__C quote = TestFactory.createQuote(accList[0].Id, opp.Id, false);
        quote.SBQQ__Type__c = 'Amendment';
        insert quote;
    }
    
    static testMethod void testSetQuoteStatusToDraft(){
        
        SBQQ__Quote__c quote = [SELECT Id, ApprovalStatus__c, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        System.assertEquals('Draft', quote.SBQQ__Status__c, 'quote status should be draft when ApprovalStatus__c is not approved');

        quote.ApprovalStatus__c = 'Approved';
        quote.SBQQ__Status__c = 'Approved';

        Test.startTest();
        update quote;
        Test.stopTest();

        System.assertEquals('Approved', [SELECT SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id =: quote.Id].SBQQ__Status__c, 'quote SBQQ__Status__c should be approved');
    }
}