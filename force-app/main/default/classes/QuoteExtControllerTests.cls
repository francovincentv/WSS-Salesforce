@isTest
private class QuoteExtControllerTests {
    
    testMethod static void testSubmit() {
        
        Account testAccount = new Account(name='Test Account');
        insert testAccount;
        
        Opportunity testOpportunity = new Opportunity(name='Test Opportunity');
        testOpportunity.StageName = 'Contact Made';
        Date x = Date.valueOf('2015-12-31');
        testOpportunity.CloseDate = x;
        testOpportunity.Amount = 10;
        insert testOpportunity;
        
        ContractParty__c testContractParty1 = new ContractParty__c ();
        testContractParty1.Account__c = testAccount.id;
        testContractParty1.Opportunity__c = testOpportunity.id;   
        
        ContractParty__c testContractParty2 = new ContractParty__c ();
        testContractParty2.Account__c = testAccount.id;
        testContractParty2.Opportunity__c = testOpportunity.id;   
        insert new List<ContractParty__c> {testContractParty1, testContractParty2};
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        Id quoteType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
        quote.RecordTypeId=quoteType;
        quote.TermType__c = 'Evergreen';
        quote.ContractScope__c='Key Port Prices';
        quote.SBQQ__Account__c=testAccount.id;
        quote.SBQQ__Opportunity2__c=testOpportunity.id;
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', quote.ApprovalStatus__c);
    }
    
    testMethod static void testRecall() {
        Account testAccount = new Account(name='Test Account');
        insert testAccount;
        
        Opportunity testOpportunity = new Opportunity(name='Test Opportunity');
        testOpportunity.StageName = 'Contact Made';
        Date x = Date.valueOf('2015-12-31');
        testOpportunity.CloseDate = x;
        testOpportunity.Amount = 10;
        insert testOpportunity;
        
        ContractParty__c testContractParty1 = new ContractParty__c ();
        testContractParty1.Account__c = testAccount.id;
        testContractParty1.Opportunity__c = testOpportunity.id;   
        
        ContractParty__c testContractParty2 = new ContractParty__c ();
        testContractParty2.Account__c = testAccount.id;
        testContractParty2.Opportunity__c = testOpportunity.id;   
        insert new List<ContractParty__c> {testContractParty1, testContractParty2};
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        Id quoteType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
        quote.RecordTypeId=quoteType;
        quote.TermType__c = 'Evergreen';
        quote.ContractScope__c='Key Port Prices';
        quote.SBQQ__Account__c=testAccount.id;
        quote.SBQQ__Opportunity2__c=testOpportunity.id;
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', quote.ApprovalStatus__c);
    }
}