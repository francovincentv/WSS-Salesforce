@isTest
public with sharing class QuoteLineTriggerHelperTest {
    
    static testMethod void testQuoteLineGroup(){
        Trigger_Setting__c quoteTriggerSetting = TestFactory.createTriggerSetting('SBQQ__Quote__c', true);

        Trigger_Setting__c quoteLineTriggerSetting = TestFactory.createTriggerSetting('SBQQ__QuoteLine__c', false);
        quoteLineTriggerSetting.Prevent_Recursion__c = 'KP5Disc__c';
        insert quoteLineTriggerSetting;
        
        List<Account> accList = TestFactory.createAccounts(1, true);
        List<Opportunity> oppList = TestFactory.createOppForAccounts(1, accList, '', false);
        oppList[0].sbaa__ApprovalStatus__c = 'Approved';
        insert oppList;

        //create contract party
        ContractParty__c cp = new ContractParty__c ();
        cp.Account__c = accList[0].id;
        cp.Opportunity__c = oppList[0].id;   
        insert cp;

        SBQQ__Quote__c quote = TestFactory.createQuote(accList[0].Id, oppList[0].Id, false);
        quote.SBQQ__Type__c = 'Amendment';
        insert quote;

        List<Product2> prodList = TestFactory.createProducts(2, false);
        //add discount group for one of the products
        prodList[0].Product_Discount_Group__c = 'Gases & Refrigerants';
        insert prodList;

        test.startTest();
        //insert quote lines
        TestFactory.createQuoteLineForProducts(quote.Id, prodList, true);
        test.stopTest();

        //verify the quote line groups, which should be same a product discount group
        for(SBQQ__QuoteLine__c ql :  [SELECT Id, SBQQ__Product__r.Product_Discount_Group__c, SBQQ__Group__r.Name FROM SBQQ__QuoteLine__c]) {
            String prodGroup = ql.SBQQ__Product__r.Product_Discount_Group__c;
            if(prodGroup == null) {
                System.assertEquals(System.Label.Default_Quote_Line_Group , ql.SBQQ__Group__r.Name);
            } else {
                System.assertEquals(prodGroup, ql.SBQQ__Group__r.Name);
            }
        }

        //delete the records for code coverage, since we dont have any logic in delete event
        delete [SELECT Id FROM SBQQ__QuoteLine__c];
        delete quote;
    }
}