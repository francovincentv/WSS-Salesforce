@isTest
public with sharing class ContractRenewalOpportunityHelper_Test {
   
    @IsTest
    static void createRenewalOpportunityTest(){

        User u = TestFactory.createTestUser();
        System.runAs(u) {

            List<Account> accList = TestFactory.createAccounts(1, true);
          
            List<Opportunity> oppList = TestFactory.createOppForAccounts(1, accList,'', false);
            oppList[0].sbaa__ApprovalStatus__c = 'Approved';
            insert oppList;
            
            Contract contract = new Contract();
            contract.SBQQ__Opportunity__c = oppList[0].Id;
            contract.Deal_Value_per_annum__c = 250;
            contract.AccountId = accList[0].Id;
            insert contract;
        

            ContractParty__c cp = new ContractParty__c ();
            cp.Account__c = accList[0].Id;
            cp.Opportunity__c = oppList[0].Id;    
            insert cp;
            
            List<ContractParty__c> cpList = [SELECT Id, Account__c FROM ContractParty__c WHERE Opportunity__c=:oppList[0].Id];

            //Contract contract = [SELECT Id, ContractNumber, SBQQ__Opportunity__c, SBQQ__ExpirationDate__c, Deal_Value_per_annum__c FROM Contract];
        
            Test.startTest();
            Id clonedOppId = LWC_ContractRenewalOpportunityHelper.createRenewalOpportunity(contract).Id;
            Test.stopTest();
        
            Opportunity clonedOpp = [SELECT Id, CloseDate, StageName, AccountId, Previous_Opportunity_OfRenewal__c, Amount, Legal_Approval__c FROM Opportunity WHERE Previous_Opportunity_OfRenewal__c =: oppList[0].Id];
            List<ContractParty__c> cpClonedList = [SELECT Id, Account__c, Opportunity__c FROM ContractParty__c WHERE Opportunity__c=:clonedOpp.Id];
            
            System.assertEquals(clonedOppId, clonedOpp.Id);
            System.assertEquals(2, [SELECT Count() FROM Opportunity]);
            System.assertEquals(cpList.size(), cpClonedList.size());

            System.assertEquals(System.today().addDays(30), clonedOpp.CloseDate);
            System.assertEquals(oppList[0].AccountId, clonedOpp.AccountId);
            System.assertEquals(oppList[0].StageName, clonedOpp.StageName);
            System.assertEquals(contract.Deal_Value_per_annum__c, clonedOpp.Amount);
            System.assertEquals(true, clonedOpp.Legal_Approval__c);
        }
    }
}