@isTest
public class OpportunityProcessApx_Test {
    public static Map<String,Schema.RecordTypeInfo> accRecordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
    Id contractCus = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Deal').getRecordTypeId();


    @TestSetup
	static void testData() {
        Trigger_Setting__c quoteTriggerSetting = TestFactory.createTriggerSetting('SBQQ__Quote__c', false);
        quoteTriggerSetting.Disabled__c = false;
        insert quoteTriggerSetting;

        Trigger_Setting__c quoteLineTriggerSetting = TestFactory.createTriggerSetting('SBQQ__QuoteLine__c', false);
        quoteLineTriggerSetting.Disabled__c = true;
        insert quoteLineTriggerSetting;
        
        //create account
        List<Account> accList = TestFactory.createAccounts(2, false);
        accList[0].Type = 'Transactional';
        accList[0].RecordTypeId = accRecordTypeInfo.get('Customer_Sub_Account').getRecordTypeId();
        insert accList;
        
        List<Opportunity> oppList = TestFactory.createOppForAccounts(2, accList, 'PoC_Opportunity', false);
        oppList[0].sbaa__ApprovalStatus__c = 'Approved';
        oppList[0].No_of_Ships_Targeted__c = 22;
        oppList[0].KP_Net_Prices__c = true;
        oppList[0].Net_Prices_WW__c = true;
        oppList[0].Extra_Discount__c = true;
        
        oppList[1].sbaa__ApprovalStatus__c = 'Approved';
        oppList[1].No_of_Ships_Targeted__c = 2;
        oppList[1].KP_Net_Prices__c = true;
        oppList[1].Net_Prices_WW__c = true;
        oppList[1].Extra_Discount__c = true;
        oppList[1].Amount = 1000000;
		insert oppList[0];
        		insert oppList[1];

        
        ContractParty__c testContractParty1 = new ContractParty__c ();
        testContractParty1.Account__c = accList[0].id;
        testContractParty1.Opportunity__c = oppList[0].id;
        testContractParty1.SignstheContract__c = true;
        
        ContractParty__c testContractParty2 = new ContractParty__c ();
        testContractParty2.Account__c = accList[1].id;
        testContractParty2.Opportunity__c = oppList[0].id;
        testContractParty2.SignstheContract__c = true;
                
        insert new List<ContractParty__c> {testContractParty1,testContractParty2};
        
                
        ContractParty__c testContractParty3 = new ContractParty__c ();
        testContractParty3.Account__c = accList[0].id;
        testContractParty3.Opportunity__c = oppList[1].id;
        testContractParty3.SignstheContract__c = true;
        insert testContractParty3;
            
        //create contract
        Contract contract = new Contract();
        contract.Status = 'Planned';
        contract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Deal').getRecordTypeId();
        contract.SBQQ__Opportunity__c = oppList[0].id;
        contract.StartDate = System.today();
        contract.EndDate = System.today().addDays(10);
        contract.AccountId = accList[0].id;
        insert contract;

        //create sub deals for the contract
        List<Sub_Deal__c> sdList = new List<Sub_Deal__c>();
        for(Integer i=0; i<2; i++) {
            Sub_Deal__c sd = new Sub_Deal__c();
            sd.Customer_Sub_Account__c = accList[0].id;
            sd.To_Date__c = System.today().addDays(2);
            sd.Activation_Date__c = System.today();
            sd.Deal__c = contract.Id;
            sd.From_Date__c = System.today();
            sdList.add(sd);
        }
        insert sdList;
    }
    @isTest 
    static void testName() {
        List<Id> opps = new List<Id>();
    	Opportunity oppRec = [SELECT Id,Signers_Scenario_3__c, Amount FROM Opportunity WHERE Name = 'Test Opportunity 0' LIMIT 2];
        opps.add(oppRec.id);
        
        Test.startTest();
        List<Opportunity> ret= OpportunityProcessApx.contractPartiesClass(opps);

        System.assertEquals(1, ret.size());
		Test.stopTest();
	}
}