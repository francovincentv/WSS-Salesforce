@isTest
private class OPEReportExceptionPanelControllerTest {
    @TestSetup
    static void makeData(){
        

        Trigger_Setting__c opeTriggerSetting = TestFactory.createTriggerSetting('OrderProcessException__c', false);
        opeTriggerSetting.Prevent_Recursion__c = 'PortOfDelivery__c,Vessel__c,Product__c,Sub_Account_Ids__c,Status__c,Reviewer__c';
        Trigger_Setting__c opecTriggerSetting = TestFactory.createTriggerSetting('OrderProcessExceptionCondition__c', false);
        opecTriggerSetting.Prevent_Recursion__c = 'Status__c, Code__c';
        List<Trigger_Setting__c> settings = new List<Trigger_Setting__c>{opeTriggerSetting,opecTriggerSetting};
        insert settings;

        Integer count = 3;
        String[] accountNumbers = new List<String>();
        String[] portCodes = new List<String>();
        String[] productCodes = new List<String>();
        String[] vesselNumbers = new List<String>();
        // Sub-Accounts
        Id subAccountRecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Sub_Account').getRecordTypeId();
        List<Account> subAccounts = new List<Account>();
        for(Account a : TestFactory.createAccounts(count,false)){
            a.RecordTypeId = subAccountRecordTypeId;
            subAccounts.add(a);
            accountNumbers.add(a.Account_Number__c);
        }
        insert subAccounts;
        // Ports
        List<Port__c> portsList = TestFactory.createPorts(count, true);
        for(Port__c prt : portsList){
            portCodes.add(prt.Port_Code__c);
        }
        // Products
        List<Product2> products = TestFactory.createProducts(count, false);
        for(Integer i=0; i<products.size(); i++){
            products[i].Product_Code__c = 'PROD-00'+i;
            products[i].ProductCode = products[i].Product_Code__c;
            productCodes.add(products[i].ProductCode);
        }
        insert products;
        // Vessels
        List<Vessel__c> vessels = TestFactory.createVessels(count,true);
        for(Vessel__c vessel : vessels){
            vesselNumbers.add(vessel.IMO_Number__c);
        }

        // Create OPE
        List<OrderProcessExceptionType__c> opeTypes = TestFactory.createExceptionTypes(1, true, 'No', 'None');
        OrderProcessException__c ope = TestFactory.createExceptions(1, false, opeTypes[0].Id)[0];
        ope.CustomerRole__c = 'Any';
        ope.PortOfDeliveryLogic__c = 'Applies to';
        ope.ProductLogic__c = 'Applies to';
        ope.VesselLogic__c = 'Applies to';
        ope.Sub_Account_Ids__c = String.join(accountNumbers,';');
        ope.PortOfDelivery__c = String.join(portCodes,';');
        ope.Product__c = String.join(productCodes,';');
        ope.Vessel__c = String.join(vesselNumbers,';');
        insert ope;

    }
    @isTest
    static void getStarlistExceptionDetails_Test() {
        OrderProcessException__c ope = [SELECT ID FROM OrderProcessException__c LIMIT 1];

        List<OrderProcessException__c> results;
        Test.startTest();
            results = OPEReportExceptionPanelController.getStarlistExceptionDetails(String.valueOf(ope.Id));
        Test.stopTest();

        //System.debug(JSON.serializePretty(results,true));
        System.assertEquals(1,results.size());
        List<OrderProcessExceptionCondition__c> conditions = (List<OrderProcessExceptionCondition__c>)results[0].Conditions__r;
        System.assertEquals(12,conditions.size()); //count: 3 * 4
    }

    @isTest
    static void getOPEFieldLabels_Test(){
        
        Map<String,String> labelsMap = OPEReportExceptionPanelController.getOPEFieldLabels();
        //System.debug(labelsMap);
        System.assertEquals('Application Area',labelsMap.get('ApplicationArea__c'));

    }
}