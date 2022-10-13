/*********************************************
OrderProcessExceptionTriggerHandler
The developer needs to develop the handler class and must implement the TriggerInterface with it’s all methods. Here is the sample handler class. Implementation of the TriggerInterface interface is must.
In the handler class method use try and catch where required and in catch method call doHandleException method of TransactionLogHandler class to catch the exception.
*********************************************/
public inherited sharing class OrderProcessExceptionTriggerHandler implements TriggerInterface{
    private static List<String> junctionFields = new List<String>{
        'Sub_Account_Ids__c',
        'PortOfDelivery__c',
        'Vessel__c',
        'Product__c'
    };

    private static List<String> activeStatusList = new List<String>{
        'Active',
        'Under review',
        'Suspended'
    };

    public void beforeInsert(List<sObject> newRecordsList){}
    
    public void beforeUpdate(List<sObject> newRecordsList, List<sObject> oldRecordsList, Map<Id, sObject> newRecordsMap, Map<Id, sObject> oldRecordsMap){
        System.debug('newRecordsMap.size: ' + newRecordsMap.size());
        
        List<String> conditionFields = new List<String>{
            'ProductCategory__c'
        };

        Map<String,String> conditionLogicFieldMap = new Map<String,String>{
            'CustomerSegmentList__c' => 'CustomerSegmentLogic__c',
            'CountryOfCustomerList__c' => 'CountryOfCustomerLogic__c',
            'Vessel__c' => 'VesselLogic__c',
            'VesselFlagList__c' => 'VesselFlagLogic__c',
            'VesselTypeList__c' => 'VesselTypeLogic__c',
            'Product__c' => 'ProductLogic__c',
            'ProductCategory__c' => 'ProductCategoryLogic__c',
            'PortOfDelivery__c' => 'PortOfDeliveryLogic__c',
            'CountryOfDeliveryList__c' => 'CountryOfDeliveryLogic__c',
            'OrderValue__c' => 'OrderValueLogic__c',
            'CSTeam__c' => 'CSTeamLogic__c',
            'SalesTerritory__c' => 'SalesTerritoryLogic__c'
        };
        
        Boolean isStarlistAdmin = FeatureManagement.checkPermission('Is_OPEL_Admin');
        Map<Id,OrderProcessException__c> opesToValidateDetails = new Map<Id,OrderProcessException__c>();
        Map<Id,OrderProcessException__c> opesToValidateConditions = new Map<Id,OrderProcessException__c>();
        Map<Id,OrderProcessException__c> opesToValidateAttachment = new Map<Id,OrderProcessException__c>();
        Map<Id,OrderProcessException__c> opesToValidateSubAccountsPopulated = new Map<Id,OrderProcessException__c>();
        Map<Id,OrderProcessException__c> opesToSetApprover = new Map<Id,OrderProcessException__c>();
        Map<Id,OrderProcessException__c> opesToSetReviewer = new Map<Id,OrderProcessException__c>();
        for(Id opeId : newRecordsMap.keySet()){
            OrderProcessException__c oldRecord = (OrderProcessException__c)oldRecordsMap.get(opeId);
            OrderProcessException__c newRecord = (OrderProcessException__c)newRecordsMap.get(opeId);
            for(String fieldName : junctionFields){
                if(newRecord.get(fieldName) != oldRecord.get(fieldName)){
                    newRecord.put(fieldName, OPEDataValidation.cleanUpCodeList((String)newRecord.get(fieldName)));
                }
            }
            for(String fieldName : conditionFields){
                if(newRecord.get(fieldName) != oldRecord.get(fieldName)){
                    opesToValidateConditions.put(opeId,newRecord);
                }
            }
            // Clear Logic if Condition is emptied
            for(String fieldName : conditionLogicFieldMap.keySet()){
                Object value = newRecord.get(fieldName);
                String logicFieldName = conditionLogicFieldMap.get(fieldName);
                if(value == null)
                    newRecord.put(logicFieldName,null);
                else{
                    if(newRecord.get(logicFieldName)==null){
                        System.debug('Field: '+fieldName+', Logic FieldName:' + logicFieldName);
                        System.debug(OPEDataValidation.getOPEFieldLabelMap());
                        String fieldLabel = OPEDataValidation.getOPEFieldLabelMap().get(fieldName.toLowerCase());
                        String message = 'Please specify if this exception applies or not for the '+fieldLabel+' condition.';
                        if(fieldName.equals('OrderValue__c'))
                            message = 'Please specify a comparison operator for the Order Value condition.';
                        newRecord.addError(logicFieldName, message);
                    }
                }
            }
            // Validate Data Entity when Details change
            if(newRecord.Details__c != oldRecord.Details__c){
                newRecord.DetailsLong__c = newRecord.Details__c;
                opesToValidateDetails.put(opeId,newRecord);
            }
            System.debug(JSON.serializePretty(opesToValidateDetails));
            
            // On Submitting for Approval
            Boolean isSentForApproval = (oldRecord.Status__c == 'Draft' && newRecord.Status__c == 'Under Approval');
            if(isSentForApproval){
                System.debug('** OPE Sent for Approval **');
                
                // Set the current user as the Requester to notify after approval/rejection
                newRecord.Requester__c = UserInfo.getUserId();
                
                // Validate Files when Attachment is required for the OPE Type
                if(newRecord.AttachmentRequired__c)
                    opesToValidateAttachment.put(opeId,newRecord);
                
                // Validate Sub-Accounts are not empty if user is not Starlist Admin
                if(!isStarlistAdmin && String.isEmpty(newRecord.Sub_Account_Ids__c))
                    opesToValidateSubAccountsPopulated.put(opeId,newRecord);

                // Populate Reviewer if empty and Related Sub-Accounts have the same Sales Advisor
                if(newRecord.Reviewer__c == null)
                    opesToSetReviewer.put(opeId,newRecord);
            }
            
            // Set Approver and Owner when OPE becomes Active
            if(oldRecord.Status__c == 'Under Approval' && newRecord.Status__c == 'Active')
                opesToSetApprover.put(opeId,newRecord);

            // Give Ownership to the Reviewer when Set or Changed
            if(activeStatusList.contains(newRecord.Status__c) && oldRecord.Reviewer__c != newRecord.Reviewer__c && newRecord.Reviewer__c != null)
                newRecord.OwnerId = newRecord.Reviewer__c;

        }
        if(!opesToValidateDetails.isEmpty())
            OPEDataValidation.detailsValidation(opesToValidateDetails);
        
        if(!opesToValidateConditions.isEmpty())
            OPEDataValidation.opeConditionInputValidations(opesToValidateConditions);

        if(!opesToValidateAttachment.isEmpty())
            OPEDataValidation.validateAttachments(opesToValidateAttachment);
        
        if(!opesToValidateSubAccountsPopulated.isEmpty()){
            for(Id opeId : opesToValidateSubAccountsPopulated.keySet()){
                opesToValidateSubAccountsPopulated.get(opeId).addError('Sub-Account(s) field cannot be empty. The Exception cannot be submitted for Approval without specifying Sub-Account(s).');
            }
        }
        
        if(!opesToSetApprover.isEmpty())
            OPEDataValidation.setAfterApprovalFields(opesToSetApprover);
        
        if(!opesToSetReviewer.isEmpty())
            OPEDataValidation.setReviewers(opesToSetReviewer);
    }
        
    public void afterInsert(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap){
        OPEDataValidation.conditionsValidation(newRecordsMap);
    }

    public void afterUpdate(List<sObject> newRecordsList, List<sObject> oldRecordsList, Map<Id, sObject> newRecordsMap,  Map<Id, sObject> oldRecordsMap){
        
        Map<Id,OrderProcessException__c> opesToUpdateConditions = new Map<Id,OrderProcessException__c>();
        List<Task> notificationTasks = new List<Task>();
        Id approverQueueId = OPEDataValidation.getQueueIdByName(OPEDataValidation.APPROVER_QUEUE);
        List<Id> amendedOPEIds = new List<Id>();
        for(Id opeId : newRecordsMap.keySet()){
            OrderProcessException__c oldRecord = (OrderProcessException__c)oldRecordsMap.get(opeId);
            OrderProcessException__c newRecord = (OrderProcessException__c)newRecordsMap.get(opeId);
            System.debug('oldRecord.Status__c: ' + oldRecord.Status__c);
            System.debug('newRecord.Status__c: ' + newRecord.Status__c);

            Boolean sentForApproval = (oldRecord.Status__c == 'Draft' && newRecord.Status__c == 'Under Approval');
            Boolean wasApproved = (oldRecord.Status__c == 'Under Approval' && newRecord.Status__c == 'Active');
            
            // After Submitting for Approval
            if(sentForApproval){
                // Create task for Approver Queue
                Task t = new Task(Subject='Starlist Exception Approval');
                t.OwnerId = approverQueueId;
                t.WhatId = opeId;
                t.Priority = 'Normal';
                t.Status = 'Not Started';
                t.Task_Name__c = 'A new Starlist Exception was submitted for approval by '+UserInfo.getName()+'.';
                t.Description = 'You can find the item under Approval Requests or you can directly open the record and use the buttons on Approval History under the Related tab.';
                t.Type = 'Other';
                notificationTasks.add(t);
            }

            // After Exception is approved
            if(wasApproved){
                // Set Approver and Owner when OPE becomes Active
                if(newRecord.AmendedOPE__c != null)
                    amendedOPEIds.add(newRecord.AmendedOPE__c);
            }

            Boolean conditionsChanged = false;
            for(String field : junctionFields)
                conditionsChanged |= (oldRecord.get(field) != newRecord.get(field));
            if(conditionsChanged)
                opesToUpdateConditions.put(newRecord.Id, newRecord);
        }
        System.debug('amendedOPEIds:' + amendedOPEIds);
        if(!amendedOPEIds.isEmpty())
            OPEDataValidation.inactivateAmendedOPEs(amendedOPEIds);
        
        OPEDataValidation.conditionsValidation(opesToUpdateConditions);

        if(!notificationTasks.isEmpty())
            insert notificationTasks;
        
    }
               
    public void beforeDelete(List<sObject> oldRecordsList , Map<Id, sObject> oldRecordsMap){}
    
    public void afterDelete(Map<Id, sObject> oldRecordsMap){}
    
    public void afterUnDelete(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap){}
}