/**
 * Created by Andrej Tazky on 14-Jan-22.
 */

@IsTest
private class OrderExceptionsControllerTest {
    @IsTest
    static void testProcess() {
        Boolean doInsert = true;

        Trigger_Setting__c settings =TestFactory.createTriggerSetting('OrderProcessException__c',doInsert);
        Trigger_Setting__c settings2 =TestFactory.createTriggerSetting('OrderProcessExceptionCondition__c',doInsert);

        List<Account> accounts=TestFactory.createAccounts(2,doInsert);
        List<Case> cases=TestFactory.createCases(1,doInsert,accounts[0].Id);
        List<Quote__c> quotes=TestFactory.createQuotes(1,doInsert,accounts[1].Id,cases[0].Id);
        List<Order> orders=TestFactory.createOrders(1,doInsert,accounts[1].Id,cases[0].Id);

        List<Port__c> ports=TestFactory.createPorts(1,doInsert);
        List<Vessel__c> vessels=TestFactory.createVessels(1,doInsert);

        List<OrderProcessExceptionType__c> types=TestFactory.createExceptionTypes(1,doInsert);
        List<OrderProcessException__c> exceptions=TestFactory.createExceptions(2,doInsert,types[0].Id);

        Id subId=SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Sub_Account').getRecordTypeId();

        accounts[1].RecordTypeId=subId;
        accounts[1].Country_of_Domicile__c='Slovakia';
        update accounts[1];

        orders[0].Order_Value__c=10000;
        orders[0].Vessel_IMO__c='0000';
        update orders[0];

        vessels[0].Ship_Type__c='Bulk';
        update vessels[0];

        OrderProcessExceptionCondition__c junction=new OrderProcessExceptionCondition__c();
        junction.OrderProcessException__c=exceptions[0].Id;
        junction.Account__c=accounts[1].Id;
        insert junction;

        OrderProcessExceptionCondition__c junction2=new OrderProcessExceptionCondition__c();
        junction2.OrderProcessException__c=exceptions[0].Id;
        junction2.Vessel__c=vessels[0].Id;
        insert junction2;

        exceptions[0].OrderValueLogic__c=OrderExceptionUtils.OPERATOR_EQUAL_TO;
        exceptions[0].OrderValue__c=10000;

        exceptions[0].CountryOfCustomerLogic__c=OrderExceptionUtils.OPERATOR_APPLIES_TO;
        exceptions[0].CountryOfCustomerList__c='Slovakia';

        exceptions[0].VesselLogic__c=OrderExceptionUtils.OPERATOR_APPLIES_TO;
        exceptions[0].Vessel__c='0000';

//        exceptions[0].VesselTypeLogic__c=OrderExceptionUtils.OPERATOR_APPLIES_TO;
//        exceptions[0].VesselType__c='Bulk';

        update exceptions[0];


//        OrderProcessExceptionCondition__c junction3=new OrderProcessExceptionCondition__c();
//        junction3.OrderProcessException__c=exceptions[1].Id;
//        junction3.Account__c=accounts[1].Id;
//        insert junction3;

//        OrderProcessExceptionCondition__c junction4=new OrderProcessExceptionCondition__c();
//        junction4.OrderProcessException__c=exceptions[1].Id;
//        junction4.Port__c=ports[0].Id;
//        insert junction4;

        exceptions[1].OrderValueLogic__c=OrderExceptionUtils.OPERATOR_LESS_THAN;
        exceptions[1].OrderValue__c=10000;
        exceptions[1].CountryOfCustomerList__c='Slovakia';
        exceptions[1].CountryOfCustomerLogic__c=OrderExceptionUtils.OPERATOR_APPLIES_TO;
        exceptions[1].Status__c='Active';
        exceptions[1].ReviewDate__c=Date.today()+1;

//        exceptions[1].CountryOfCustomerLogic__c=OrderExceptionUtils.OPERATOR_DOES_NOT_APPLY_TO;
//        exceptions[1].CountryOfCustomerList__c='Slovakia';
//
//        exceptions[1].PortOfDeliveryLogic__c=OrderExceptionUtils.OPERATOR_DOES_NOT_APPLY_TO;
//        exceptions[1].PortOfDelivery__c='00';
//
//        exceptions[1].VesselTypeLogic__c=OrderExceptionUtils.OPERATOR_DOES_NOT_APPLY_TO;
//        exceptions[1].VesselType__c='Bulk';

        update exceptions[1];

        Test.startTest();
        OrderExceptionsController.getExceptionsDataWrapperForCase(cases[0].id);
        OrderExceptionsController.loadExceptions('["'+exceptions[0].Id+'"]');

        PageReference pageRef = Page.ExtendReviewDate;
        Test.setCurrentPage(pageRef);

        ApexPages.StandardSetController standardSetController=new ApexPages.StandardSetController(exceptions);
        standardSetController.setSelected(exceptions);
        OrderExceptionsController controller = new OrderExceptionsController(standardSetController);
        controller.extendReviewDate();
        controller.createConfirmationMessage();
        controller.closePopup();

        Test.stopTest();


    }
}