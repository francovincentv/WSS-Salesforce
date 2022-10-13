@isTest
public class updateQuoteCorridorsTest {
    
      @isTest static void testMethod1() {
            
        Account testAccount = new Account(name='Test Account');
        testAccount.Type = 'Anchor';
        testAccount.Primary_Market_Segment__c ='Other';
        insert testAccount;
            
        Opportunity testOpportunity = new Opportunity(name='Test Opportunity');
        testOpportunity.StageName = 'Contact Made';
        Date x = Date.valueOf('2015-12-31');
        testOpportunity.CloseDate = x;
        testOpportunity.TargetedSegment__c = 'Cruise';
        testOpportunity.No_of_Ships_Targeted__c = 1;
        testOpportunity.Activity__c = 'Operating';
        testOpportunity.Amount = 10;
		insert testOpportunity;
        
        ContractParty__c testContractParty1 = new ContractParty__c ();
        testContractParty1.Account__c = testAccount.id;
        testContractParty1.Opportunity__c = testOpportunity.id;   
        
        ContractParty__c testContractParty2 = new ContractParty__c ();
        testContractParty2.Account__c = testAccount.id;
        testContractParty2.Opportunity__c = testOpportunity.id;   
        insert new List<ContractParty__c> {testContractParty1, testContractParty2};
       
        Test.startTest();
            
	 	SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
        Id quoteType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
		quote1.RecordTypeId=quoteType;
        quote1.TermType__c = 'Evergreen';
        quote1.ContractScope__c='Key Port Prices';
        quote1.SBQQ__Account__c=testAccount.id;
        quote1.SBQQ__Opportunity2__c=testOpportunity.id;
        quote1.SBQQ__Status__c='Draft';
                                               
        insert quote1;
        Test.stopTest();   
          
        
        Opportunity opportunityUpdate = [select id, TargetedSegment__c, No_of_Ships_Targeted__c ,Activity__c from Opportunity  where name='Test Opportunity' and StageName = 'Contact Made' and TargetedSegment__c = 'Cruise' limit 1];
        opportunityUpdate.TargetedSegment__c = 'Tanker';
        opportunityUpdate.No_of_Ships_Targeted__c = 2;
        opportunityUpdate.Activity__c = 'New Building';   
        update opportunityUpdate;

        SBQQ__Quote__c  []  quotes1 = [Select id, CorridorLevelTransfer__c, CorridorAllowanceTransfer__c from SBQQ__Quote__c where id =: quote1.id limit 1];
		System.assertEquals('Green', quotes1[0].CorridorLevelTransfer__c);
        System.assertEquals(10.00, quotes1[0].CorridorAllowanceTransfer__c);
        }

}