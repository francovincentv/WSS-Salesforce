@isTest
public class BonusAgreementAutomationsTest {
    @isTest static void testGenerateProductGroupString() {

        Trigger_Setting__c quoteTriggerSetting = TestFactory.createTriggerSetting('SBQQ__Quote__c', false);
        quoteTriggerSetting.Disabled__c = false;
        insert quoteTriggerSetting;

        Trigger_Setting__c quoteLineTriggerSetting = TestFactory.createTriggerSetting('SBQQ__QuoteLine__c', false);
        quoteLineTriggerSetting.Disabled__c = true;
        insert quoteLineTriggerSetting;
        
        Account testAccount = new Account(name='Test Account');
        insert testAccount;
        
        Account testAccount2 = new Account(name='Test Account2');
        insert testAccount2;
        
        BonusAgreement__c testBonusAgreement = new BonusAgreement__c();
        testBonusAgreement.Sales_Product_Group__c = 'Cleaning_Maintenance_Chemicals';
        testBonusAgreement.Account__c= testAccount.id;
        
        BonusAgreement__c testBonusAgreement1 = new BonusAgreement__c();
        testBonusAgreement1.Sales_Product_Group__c  = 'Cleaning_Maintenance_Chemicals';
        testBonusAgreement1.Account__c= testAccount.id;
        insert new List<BonusAgreement__c> {testBonusAgreement, testBonusAgreement1};
        
        Opportunity testOpportunity = new Opportunity(name='Test Opportunity');
        testOpportunity.StageName = 'Contact Made';
        Date x = Date.valueOf('2015-12-31');
        testOpportunity.CloseDate = x;
        testOpportunity.TargetedSegment__c = 'Cruise';
        testOpportunity.No_of_Ships_Targeted__c = 1;
        testOpportunity.Activity__c = 'Operating';
        testOpportunity.Amount = 10;
        testOpportunity.AccountId = testAccount.id;
        testOpportunity.sbaa__ApprovalStatus__c  = 'Approved';
        testOpportunity.Signers_Scenario_3__c = true;
        insert testOpportunity;
        
        ContractParty__c testContractParty1 = new ContractParty__c ();
        testContractParty1.Account__c = testAccount.id;
        testContractParty1.Opportunity__c = testOpportunity.id;
        testContractParty1.SignstheContract__c = true;

                
        insert new List<ContractParty__c> {testContractParty1};
            
        Test.startTest();
            
        SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
        Id quoteType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
        quote1.RecordTypeId=quoteType;
        quote1.TermType__c = 'Evergreen';
        quote1.ContractScope__c='Key Port Prices';
        quote1.SBQQ__Account__c=testAccount.id;
        quote1.SBQQ__Opportunity2__c=testOpportunity.id;
        quote1.BonusAgreement__c = testBonusAgreement.id; 
        quote1.SBQQ__Type__c = 'Amendment';
        insert quote1;
         
		BonusAgreement__c updateBonusAgreement = [Select id, Account__c, Sales_Product_Group__c from BonusAgreement__c where Sales_Product_Group__c ='Cleaning_Maintenance_Chemicals' and Account__c =:testAccount.Id limit 1 ];
        updateBonusAgreement.Sales_Product_Group__c  ='Fuel_Oil';
        update updateBonusAgreement;
        
        BonusAgreement__c  []  updatedBonusAgreement = [Select id, Account__c, Sales_Product_Group__c from BonusAgreement__c where id =: updateBonusAgreement.id limit 1];
        System.assertEquals('Fuel_Oil' ,updatedBonusAgreement[0].Sales_Product_Group__c );
        
        
        SBQQ__Quote__c quoteUpdate = [Select id, BonusAgreement__c from SBQQ__Quote__c where SBQQ__Account__c=:testAccount.id and BonusAgreement__c =: testBonusAgreement.id limit 1];
        quoteUpdate.BonusAgreement__c = testBonusAgreement1.id;
        update quoteUpdate;
        System.debug('Quote Update :'+quoteUpdate.BonusAgreement__c);
        
        SBQQ__Quote__c  []  updateQuotes = [Select id, BonusAgreement__c from SBQQ__Quote__c where id =: quoteUpdate.id limit 1];
        System.assertEquals(testBonusAgreement1.id ,updateQuotes[0].BonusAgreement__c);
        
        
        
       	Test.stopTest();
        
    }
}