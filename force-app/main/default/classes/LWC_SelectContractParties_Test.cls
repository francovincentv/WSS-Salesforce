@isTest
public with sharing class LWC_SelectContractParties_Test {

    public static Map<String,Schema.RecordTypeInfo> accRecordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
    public static Map<String,Schema.RecordTypeInfo> cpRecordTypeInfo = Schema.SObjectType.ContractParty__c.getRecordTypeInfosByDeveloperName();
    public static Id cpCustomer = cpRecordTypeInfo.get('Customer').getRecordTypeId();
    public static Id cpWSS = cpRecordTypeInfo.get('WSS').getRecordTypeId();

    @TestSetup
    static void makeData(){
        Trigger_Setting__c quoteTriggerSetting = TestFactory.createTriggerSetting('SBQQ__Quote__c', false);
        quoteTriggerSetting.Disabled__c = true;
        insert quoteTriggerSetting;

        Trigger_Setting__c quoteLineTriggerSetting = TestFactory.createTriggerSetting('SBQQ__QuoteLine__c', false);
        quoteLineTriggerSetting.Disabled__c = true;
        quoteLineTriggerSetting.Prevent_Recursion__c = 'SBQQ__Type__c';
        insert quoteLineTriggerSetting;
        
        Id accGroup = accRecordTypeInfo.get('Customer_Group').getRecordTypeId();
        Id accCus = accRecordTypeInfo.get('Customer_Account').getRecordTypeId();
        Id accSubId = accRecordTypeInfo.get('Customer_Sub_Account').getRecordTypeId();
        //Id oppPOC = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('PoC_Opportunity').getRecordTypeId();

        Account topAcc = new Account();
        topAcc.Name = 'Parent account';
        topAcc.RecordTypeId = accGroup;
        topAcc.Account_Number__c = '600003';
        insert topAcc;

        Account acc = new Account();
        acc.Name = 'child1';
        acc.ParentId = topAcc.Id;
        acc.RecordTypeId = accCus;
        acc.Account_Number__c = '6000000002';
        insert acc;

        Account accSub = new Account();
        accSub.Name = 'child Sub';
        accSub.ParentId = topAcc.Id;
        accSub.RecordTypeId = accSubId;
        accSub.Account_Number__c = '6000000003';
        accSub.Win_Centre_Account__c = true;
        insert accSub;
        
        List<Opportunity> oppList  = TestFactory.createOppForAccounts(2, new List<Account>{accSub}, 'PoC_Opportunity', false);
        oppList[0].sbaa__ApprovalStatus__c = 'Approved';
        oppList[1].sbaa__ApprovalStatus__c = 'Approved';
        oppList.add(TestFactory.createOppForAccounts(1, new List<Account>{accSub}, 'Amendment_Opportunity', false)[0]);
        oppList[2].sbaa__ApprovalStatus__c = 'Approved';
        insert oppList;

    }
    
    static testMethod void testSimpleMethods() {

        //for getSubAccounts() method
        List<Account> accList = LWC_SelectContractParties.getSubAccounts();
        System.assertEquals(1, accList.size());

        // for getContractParties() method
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<ContractParty__c> cpList = LWC_SelectContractParties.getContractParties(opp.Id);
        //System.assertEquals(2, cpList.size());

        //for insertContractParties() method
        List<ContractParty__c> cpInsertList = new List<ContractParty__c>();
        for(Integer i=0; i<2; i++) {
            ContractParty__c cp = new ContractParty__c();
            cp.Account__c = accList[0].Id;
            cp.Opportunity__c = opp.Id;
            cp.RecordTypeId = cpCustomer;
            cp.SignstheContract__c = true;
            cpInsertList.add(cp);
        }

        List<ContractParty__c> deleteList = [SELECT Id FROM ContractParty__c WHERE RecordTypeId !=: cpWSS LIMIT 2 ];
        LWC_SelectContractParties.commitTheData(deleteList, cpInsertList, opp, false);
        

    }

    static testMethod void getContractAccountsTest() {
        Id contractCus = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Deal').getRecordTypeId();

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Account subAccount = LWC_SelectContractParties.getSubAccounts()[0];

        //create contract
        Contract contract = new Contract();
        contract.Status = 'Planned';
        contract.RecordTypeId = contractCus;
        contract.SBQQ__Opportunity__c = opp.Id;
        contract.StartDate = System.today();
        contract.EndDate = System.today().addDays(10);
        contract.AccountId = acc.Id;
        insert contract;

        //create sub deals for the contract
        List<Sub_Deal__c> sdList = new List<Sub_Deal__c>();
        for(Integer i=0; i<2; i++) {
            Sub_Deal__c sd = new Sub_Deal__c();
            sd.Customer_Sub_Account__c = subAccount.Id;
            sd.To_Date__c = System.today().addDays(2);
            sd.Activation_Date__c = System.today();
            sd.Deal__c = contract.Id;
            sd.From_Date__c = System.today();
            sdList.add(sd);
        }
        insert sdList;

        Contract cont = [SELECT ContractNumber, SBQQ__Opportunity__c  FROM Contract LIMIT 1];

        List<Opportunity> oppList = LWC_SelectContractParties.getContractAccounts(cont.ContractNumber);
        System.assertEquals(opp.Id , oppList[0].Id);
        System.assertEquals(1 , oppList.size());
        //System.assertEquals(2 , oppList[0].Contract_Parties__r.size());


        List<Account> subDealAccts = LWC_SelectContractParties.getSubDealsForContract(contract.Id);
        System.assertEquals(1, subDealAccts.size());
    }

    static testMethod void testAccountHierarchy(){
        Id accSub = accRecordTypeInfo.get('Customer_Sub_Account').getRecordTypeId();

        Account accCus = [SELECT Id, ParentId FROM Account WHERE Name = 'child1' LIMIT 1];

        //create child accounts
        List<Account> accList = new List<Account>();
        for(Integer i=0 ; i<2 ; i++) {
            Account acc = new Account();
            acc.Name= 'Child 1.'+i;
            acc.ParentId = accCus.Id;
            acc.RecordTypeId = accSub;
            acc.Account_Number__c = '600000002'+i;
            accList.add(acc);
        }

        insert accList;

        //create sub child account
        Account subAcc = new Account();
        subAcc.Name= 'Child 1.1.1';
        subAcc.ParentId = accList[0].Id;
        subAcc.RecordTypeId = accSub;
        subAcc.Account_Number__c = '6000000026';
        insert subAcc;

        List<Account> accHierarchyList = LWC_SelectContractParties.getAccountHierarchy(accList[0].Id);

        //the account in the list should be the top parent account
        System.assertEquals(accCus.ParentId, accHierarchyList[0].Id);
        System.assertEquals(6, accHierarchyList.size());

    }

    static testMethod void updateActiveQuoteTest(){

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Recordtype.DeveloperName = 'Amendment_Opportunity' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        ContractParty__c cp = new ContractParty__c();
        cp.Account__c = acc.Id;
        cp.Opportunity__c = opp.Id;
        cp.RecordTypeId = cpCustomer;
        cp.SignstheContract__c = true;
        insert cp;
        
        //cerate quote for special offer oppotunity
        SBQQ__Quote__c quote = TestFactory.createQuote(acc.Id, opp.Id, false);
        quote.SBQQ__Type__c = 'Amendment';
        insert quote;

        Test.startTest();
        LWC_SelectContractParties.updateActiveQuote(opp.Id);
        Test.stopTest();
    }
}