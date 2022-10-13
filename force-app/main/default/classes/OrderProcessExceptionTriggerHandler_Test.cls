@isTest
private class OrderProcessExceptionTriggerHandler_Test {
    @TestSetup
    static void createTestData(){
        // Setup Triggers
        Trigger_Setting__c opeTriggerSetting = TestFactory.createTriggerSetting('OrderProcessException__c', false);
        opeTriggerSetting.Prevent_Recursion__c = 'PortOfDelivery__c,Vessel__c,Product__c,Sub_Account_Ids__c,Status__c,Reviewer__c';
        Trigger_Setting__c opecTriggerSetting = TestFactory.createTriggerSetting('OrderProcessExceptionCondition__c', false);
        opecTriggerSetting.Prevent_Recursion__c = 'Status__c, Code__c';
        List<Trigger_Setting__c> settings = new List<Trigger_Setting__c>{opeTriggerSetting,opecTriggerSetting};
        insert settings;

        // Setup Approver User
        User approver = TestFactory.createTestUser(); // initial Alias = "standt"

        // Give permissions to users
        Id currentUserId = UserInfo.getUserId();
        System.runAs(new User(Id=currentUserId)){
            Id approverQueueId = OPEDataValidation.getQueueIdByName(OPEDataValidation.APPROVER_QUEUE);
            GroupMember gm = new GroupMember(GroupId = approverQueueId, UserOrGroupId = approver.Id);
            insert gm;
            
            TestFactory.activateCustomPerm(currentUserId, 'Is_OPEL_Admin');
        }
    }

    @isTest
    static void amendOPETest(){
        System.debug('@amendOPETest');
        User approver = [SELECT Id FROM User WHERE Alias = 'standt' LIMIT 1];
        String APPROVAL_PROCESS = 'NewOrderProcessException';

        // Setup a Starlist Exception Generic condition (No Sub-Accounts)
        OrderProcessExceptionType__c opeType = TestFactory.createExceptionTypes(1,true)[0];
        OrderProcessException__c ope = TestFactory.createExceptions(1, true, opeType.Id)[0];
        Map<String,String> countryPicklist = TestFactory.getPicklistValues(OrderProcessException__c.getSObjectType(), 'CountryofCustomerList__c');
        List<String> countryCodeList = new List<String>(countryPicklist.keySet());
        ope.CountryOfCustomerLogic__c = OrderExceptionUtils.OPERATOR_APPLIES_TO;
        ope.CountryofCustomerList__c = countryCodeList[3]+';'+countryCodeList[19];
        update ope;

        // Submit Exception for Approval
        Id instanceId;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Verify we run as OPEL Admin to allow generic exception
            Boolean isStarlistAdmin = FeatureManagement.checkPermission('Is_OPEL_Admin');
            System.debug('isStarlistAdmin: '+isStarlistAdmin);

            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setProcessDefinitionNameOrId(APPROVAL_PROCESS);
            approvalRequest.setObjectId(ope.Id);
            approvalRequest.setSubmitterId(UserInfo.getUserId());
            approvalRequest.setComments('Test');
            Approval.ProcessResult submitResult = Approval.process(approvalRequest);
            instanceId = submitResult.getInstanceId();
            System.debug('succcess: '+ submitResult.isSuccess());
            System.debug('instanceid: '+ submitResult.getInstanceId());

            OrderProcessException__c opeAfterSubmit = [SELECT Id, Name, Status__c, OwnerId FROM OrderProcessException__c WHERE Id = :ope.Id LIMIT 1];
            System.debug(JSON.serializePretty(opeAfterSubmit, true));
        }

        // Approve the Exception
        System.runAs(approver){
            ProcessInstanceWorkitem workItem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :instanceId LIMIT 1];
            Approval.ProcessWorkitemRequest approveReq = new Approval.ProcessWorkitemRequest();
            approveReq.setWorkitemId(workItem.Id);
            approveReq.setAction('Approve');
            approveReq.setComments('OK');
            Approval.ProcessResult approveResult = Approval.process(approveReq);
        }

        OrderProcessException__c opeAfterApprove = [SELECT Id, Name, Status__c, OwnerId, Exception__c,
        CustomerRole__c, ExceptionCategory__c, ExceptionReason__c, ReviewDate__c FROM OrderProcessException__c WHERE Id = :ope.Id LIMIT 1];
        System.debug(JSON.serializePretty(opeAfterApprove, true));

        // Amend the Active Exception
        OrderProcessException__c clonedOPE = opeAfterApprove.clone(false,true,false,false);
        clonedOPE.Status__c = 'Draft';
        clonedOPE.AmendedOPE__c = opeAfterApprove.Id;
        clonedOPE.Other__c = 'Other conditions';

        insert clonedOPE;
        
        // Submit for Approval
        Id amendInstanceId;
        System.runAs(new User(Id = UserInfo.getUserId())) {        
            Approval.ProcessSubmitRequest cloneApprovalRequest = new Approval.ProcessSubmitRequest();
            cloneApprovalRequest.setProcessDefinitionNameOrId(APPROVAL_PROCESS);
            cloneApprovalRequest.setObjectId(clonedOPE.Id);
            cloneApprovalRequest.setSubmitterId(UserInfo.getUserId());
            cloneApprovalRequest.setComments('Test Amend');
            Approval.ProcessResult amendSubmitResult = Approval.process(cloneApprovalRequest);
            amendInstanceId = amendSubmitResult.getInstanceId();
            System.debug('succcess: '+ amendSubmitResult.isSuccess());
            System.debug('instanceid: '+ amendSubmitResult.getInstanceId());
        }

        // Approve Amendment
        System.runAs(approver){
            ProcessInstanceWorkitem amendWorkItem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :amendInstanceId LIMIT 1];
            Approval.ProcessWorkitemRequest amendApproveReq = new Approval.ProcessWorkitemRequest();
            amendApproveReq.setWorkitemId(amendWorkItem.Id);
            amendApproveReq.setAction('Approve');
            amendApproveReq.setComments('OK');
            Approval.ProcessResult amendApproveResult = Approval.process(amendApproveReq);
        }
        OrderProcessException__c amendedAfterApprove = [SELECT Id, Name, Status__c, OwnerId, Exception__c,
        CustomerRole__c, ExceptionCategory__c, ExceptionReason__c, ReviewDate__c FROM OrderProcessException__c WHERE Id = :ope.Id LIMIT 1];
        System.debug(JSON.serializePretty(amendedAfterApprove, true));

        OrderProcessException__c cloneAfterApprove = [SELECT Id, Name, Status__c, OwnerId, Exception__c,
        CustomerRole__c, ExceptionCategory__c, ExceptionReason__c, ReviewDate__c FROM OrderProcessException__c WHERE Id = :clonedOPE.Id LIMIT 1];
        System.debug(JSON.serializePretty(cloneAfterApprove, true));


    }
}