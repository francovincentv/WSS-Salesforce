@isTest
private class OPEConditionTriggerHandler_Test {
    static Id cond_subAccsRTId = Schema.SObjectType.OrderProcessExceptionCondition__c.getRecordTypeInfosByName().get('Sub-Accounts').getRecordTypeId();
    static Id subAccsRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Sub-Account').getRecordTypeId();  

    @TestSetup
    static void makeData(){
        

        Trigger_Setting__c opeTriggerSetting = TestFactory.createTriggerSetting('OrderProcessException__c', false);
        opeTriggerSetting.Prevent_Recursion__c = 'PortOfDelivery__c,Vessel__c,Product__c,Sub_Account_Ids__c,Status__c,Reviewer__c';
        Trigger_Setting__c opecTriggerSetting = TestFactory.createTriggerSetting('OrderProcessExceptionCondition__c', false);
        opecTriggerSetting.Prevent_Recursion__c = 'Status__c, Code__c';
        List<Trigger_Setting__c> settings = new List<Trigger_Setting__c>{opeTriggerSetting,opecTriggerSetting};
        insert settings;

        List<Account> acc = TestFactory.createAccounts(2, false);
        acc[0].Account_Number__c = '1000000027';
        acc[0].RecordTypeId = subAccsRTId;
        acc[1].Account_Number__c = '1000000028';
        acc[1].RecordTypeId = subAccsRTId;
        insert acc;

        List<Port__c> portsList = TestFactory.createPorts(2, true);
        String portCodes;
        for(Port__c prt : portsList){
            portCodes = prt.Port_Code__c +';';
        }
        
        List<OrderProcessExceptionType__c> opeType = TestFactory.createExceptionTypes(1, true);
		opeType[0].PortOfDelivery__c= true;
        update opeType;

        List<OrderProcessException__c> opException = TestFactory.createExceptions(1, true, opeType[0].Id);
        opException[0].PortOfDeliveryLogic__c = 'Applies to';
        opException[0].PortOfDelivery__c = portCodes.removeEnd(';');
        opException[0].Status__c ='Active';
        update opException;
/*
        OrderProcessExceptionCondition__c accountCond= new OrderProcessExceptionCondition__c();
        accountCond.OrderProcessException__c = opException[0].id;
        accountCond.Account__c =  acc[0].id;
        accountCond.Status__c = 'Under Approval';
        accountCond.RecordTypeId = cond_subAccsRTId;
        insert accountCond; 
        */
    }
    static testMethod void afterInsertTest() {
        System.debug('@afterInsertTest');
        System.debug([SELECT ID, NAME, Object_Name__c FROM Trigger_Setting__c WHERE Object_Name__c = 'OrderProcessExceptionCondition__c']);
        Account acc = [SELECT Id, Account_Number__c FROM Account WHERE Account_Number__c = '1000000027'];
        OrderProcessExceptionType__c starlistType = [SELECT Id FROM OrderProcessExceptionType__c WHERE  Title__c='Exc type 0' LIMIT 1];
        OrderProcessException__c starlistExc = [SELECT Id,Sub_Account_Ids__c,Name FROM OrderProcessException__c WHERE Exception__c=: starlistType.Id LIMIT 1];

        Test.startTest();
        starlistExc.Sub_Account_Ids__c = acc.Account_Number__c;
        update starlistExc;
        Test.stopTest();
        OrderProcessException__c starlistAfterExc = [SELECT Id,Sub_Account_Ids__c,Name, (SELECT Id, Status__c, Code__c FROM Conditions__r) FROM OrderProcessException__c WHERE Exception__c=: starlistType.Id LIMIT 1];
        System.debug(JSON.serializePretty(starlistAfterExc));
        System.assertEquals(acc.Account_Number__c, starlistExc.Sub_Account_Ids__c);
    }

    static testMethod void afterDeleteTest() {
        Account acc = [SELECT Id, Account_Number__c FROM Account WHERE Account_Number__c = '1000000027'];
        OrderProcessExceptionType__c starlistType = [SELECT Id FROM OrderProcessExceptionType__c WHERE Title__c='Exc type 0' LIMIT 1];
        OrderProcessException__c starlistExc = [SELECT Id,Sub_Account_Ids__c FROM OrderProcessException__c WHERE Exception__c=: starlistType.Id LIMIT 1];
        
        starlistExc.Sub_Account_Ids__c = acc.Account_Number__c;
        update starlistExc;

        Test.startTest();
        starlistExc.Sub_Account_Ids__c = null;
        update starlistExc;
        Test.stopTest();

        OrderProcessException__c starlistAfterExc = [SELECT Id,Sub_Account_Ids__c,Name, (SELECT Id, Status__c, Code__c FROM Conditions__r) FROM OrderProcessException__c WHERE Exception__c=: starlistType.Id LIMIT 1];
        System.debug(JSON.serializePretty(starlistAfterExc));
        System.assertEquals(null, starlistExc.Sub_Account_Ids__c);
    }

    static testMethod void afterUpdateTest() {
        List<String> acctNums = new List<String>{'1000000027','1000000028'};
        OrderProcessException__c starlistExc = [SELECT Id,Sub_Account_Ids__c FROM OrderProcessException__c LIMIT 1];
        starlistExc.Sub_Account_Ids__c = String.join(acctNums,';');
        update starlistExc;
        
        Test.startTest();
        List<OrderProcessExceptionCondition__c> starlistCond = [SELECT Id, Status__c FROM OrderProcessExceptionCondition__c WHERE OrderProcessException__c = :starlistExc.Id AND RecordTypeId = :cond_subAccsRTId];
        starlistCond[0].Status__c = 'Rejected';
        starlistCond[1].Status__c = 'Active';
        update starlistCond;
        Test.stopTest();
        System.assertEquals('1000000028', [SELECT Id,Sub_Account_Ids__c FROM OrderProcessException__c LIMIT 1].Sub_Account_Ids__c);
    }
}