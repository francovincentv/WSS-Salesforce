public inherited sharing class OPEConditionTriggerHandler implements TriggerInterface{
    private static final String STATUS_UNDER_APPROVAL = 'Under Approval';
    private static final String STATUS_ACTIVE = 'Active';
    private static final String STATUS_REJECTED = 'Rejected';
    private static final String APPROVAL_PROCESS = 'OPE_Sub_Accounts_Created';
    private static Id subAccsRTId;
    static{
        Map<String,Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.OrderProcessExceptionCondition__c.getRecordTypeInfosByDeveloperName();
        subAccsRTId = rtInfos.get('SubAccounts').getRecordTypeId();
    }
    
    public void beforeInsert(List<sObject> newRecordsList){}

    public void afterInsert(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap){
        
        /* If Sub-Account conditions are being added to a Starlist Exception (OPE) in 'Active' status, these need to be sent for Approval */
        // Check that Approval Process is active, do not proceed if not active
        Boolean approvalIsActive = OPEDataValidation.getActiveApprovalProcessId(APPROVAL_PROCESS) != null;
        if(!approvalIsActive)
            return;       
        
        List<OrderProcessExceptionCondition__c> conditionsToSendForApproval = new List<OrderProcessExceptionCondition__c>();
        // Get Ids of OPEs with Sub-Accounts Under Approval
        Set<Id> opeIdsToUpdate = new Set<Id>();
        Map<Id,List<String>> opesWithSubAccountsUnderApproval = new Map<Id,List<String>>();
        
        for(SObject newRecord : newRecordsList){
            OrderProcessExceptionCondition__c condition = (OrderProcessExceptionCondition__c)newRecord;
            Id opeId = condition.OrderProcessException__c;
            // This only applies to Sub-Account Record Type
            if(condition.RecordTypeId == subAccsRTId){
                if(OPEDataValidation.OPE_STATUS_ACTIVE_LIST.contains(condition.ExceptionStatus__c)){
                    conditionsToSendForApproval.add(condition);
                    opeIdsToUpdate.add(opeId);
                }else if(condition.ExceptionStatus__c != 'Draft'){
                    newRecord.addError('You cannot add Sub-Accounts to an Exception in Status '+condition.ExceptionStatus__c);
                }
            }
        }

        System.debug('conditionsToSendForApproval:\n'+JSON.serializePretty(conditionsToSendForApproval));
        if(!conditionsToSendForApproval.isEmpty()){
            for(OrderProcessExceptionCondition__c opec : conditionsToSendForApproval){
                Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                approvalRequest.setComments('Submitting request for approval for adding new SubAccount to an active Starlist Exception.');
                approvalRequest.setObjectId(opec.Id);
                // Submit on behalf of a specific submitter
                approvalRequest.setSubmitterId(UserInfo.getUserId());
                // Submit the record to specific process
                approvalRequest.setProcessDefinitionNameOrId(APPROVAL_PROCESS);
                // Submit the approval request for the account
                Approval.ProcessResult result = Approval.process(approvalRequest);
                System.debug('succcess: '+ result.isSuccess());
                System.debug('errors: '+ result.getErrors());
            }
        }
        
        System.debug('opesWithSubAccountsUnderApproval:\n'+JSON.serializePretty(opeIdsToUpdate));
        updateUnderApprovalList(opeIdsToUpdate);
    }

    public void afterUpdate(List<sObject> newRecordsList, List<sObject> oldRecordsList, Map<Id, sObject> newRecordsMap,  Map<Id, sObject> oldRecordsMap){
        Map<Id,List<String>> opeAccountListToRemoveMap = new Map<Id,List<String>>();
        Map<Id,List<String>> opeAccountListToAddMap = new Map<Id,List<String>>();
        Set<Id> opeIdsToUpdate = new Set<Id>();
		
        for(Id recordId : newRecordsMap.keySet()){
            OrderProcessExceptionCondition__c newConditionRecord = (OrderProcessExceptionCondition__c)newRecordsMap.get(recordId);
            OrderProcessExceptionCondition__c oldConditionRecord = (OrderProcessExceptionCondition__c)oldRecordsMap.get(recordId);
            System.debug('newConditionRecord:\n'+JSON.serializePretty(newConditionRecord));
            System.debug('Old Status: ' + oldConditionRecord.Status__c);
            System.debug('New Status: ' + newConditionRecord.Status__c);
            Id opeId = newConditionRecord.OrderProcessException__c;
            Boolean wasApproved = oldConditionRecord.Status__c != newConditionRecord.Status__c && oldConditionRecord.Status__c == STATUS_UNDER_APPROVAL && newConditionRecord.Status__c == STATUS_ACTIVE;
            Boolean wasRejected = oldConditionRecord.Status__c != newConditionRecord.Status__c && oldConditionRecord.Status__c == STATUS_UNDER_APPROVAL && newConditionRecord.Status__c == STATUS_REJECTED;

            if(wasApproved){
                if(!opeAccountListToAddMap.containsKey(opeId))
                    opeAccountListToAddMap.put(opeId,new List<String>());
                opeAccountListToAddMap.get(opeId).add(newConditionRecord.Code__c);
            }
            if(wasRejected){
                if(!opeAccountListToRemoveMap.containsKey(opeId))
                    opeAccountListToRemoveMap.put(opeId,new List<String>());
                opeAccountListToRemoveMap.get(opeId).add(newConditionRecord.Code__c);
            }
            if(wasApproved||wasRejected)
                opeIdsToUpdate.add(opeId);
        }
        System.debug('opeAccountListToAddMap:\n'+JSON.serializePretty(opeAccountListToAddMap));
        System.debug('opeAccountListToRemoveMap:\n'+JSON.serializePretty(opeAccountListToRemoveMap));
        List<OrderProcessException__c> opesToUpdate = new List<OrderProcessException__c>();
        for(OrderProcessException__c ope : [SELECT Id, Sub_Account_Ids__c, SubAccountsUnderApproval__c FROM OrderProcessException__c WHERE Id IN :opeIdsToUpdate]){
            Set<String> subAccountIds = new Set<String>(OPEDataValidation.splitCSVString(ope.Sub_Account_Ids__c));
            Set<String> subAccountsUnderApproval = new Set<String>(OPEDataValidation.splitCSVString(ope.SubAccountsUnderApproval__c));
            if(opeAccountListToAddMap.containsKey(ope.Id)){
                subAccountsUnderApproval.removeAll(opeAccountListToAddMap.get(ope.Id));
                ope.SubAccountsUnderApproval__c = ';'+String.join(new List<String>(subAccountsUnderApproval), ';')+';';
            }
            if(opeAccountListToRemoveMap.containsKey(ope.Id)){
                subAccountIds.removeAll(opeAccountListToRemoveMap.get(ope.Id));
                ope.Sub_Account_Ids__c = String.join(new List<String>(subAccountIds), ';');
            }
            opesToUpdate.add(ope);
        }
        System.debug('opesToUpdate:\n'+JSON.serializePretty(opesToUpdate));
        if(!opesToUpdate.isEmpty())
            update opesToUpdate;
    }

    // NOT Used handler methods //
    public void beforeUpdate(List<sObject> newRecordsList, List<sObject> oldRecordsList, Map<Id, sObject> newRecordsMap, Map<Id, sObject> oldRecordsMap){}
    public void beforeDelete(List<sObject> oldRecordsList , Map<Id, sObject> oldRecordsMap){}
    public void afterDelete(Map<Id, sObject> oldRecordsMap){
        // Remove from Under Approval List if deleted
        Set<Id> opeIdsToUpdate = new Set<Id>();
        for(Id recordId : oldRecordsMap.keySet()){
            OrderProcessExceptionCondition__c oldConditionRecord = (OrderProcessExceptionCondition__c)oldRecordsMap.get(recordId);
            if(oldConditionRecord.Status__c == STATUS_UNDER_APPROVAL){
                opeIdsToUpdate.add(oldConditionRecord.OrderProcessException__c);
            }
        }
        updateUnderApprovalList(opeIdsToUpdate);
    }
    public void afterUnDelete(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap){}

    private static void updateUnderApprovalList(Set<Id> opeIds){
        List<OrderProcessException__c> opesToUpdate = new List<OrderProcessException__c>();
        for(OrderProcessException__c ope : [SELECT Id, SubAccountsUnderApproval__c, (SELECT Code__c FROM Conditions__r WHERE RecordTypeId = :subAccsRTId AND Status__c = :STATUS_UNDER_APPROVAL) FROM OrderProcessException__c WHERE Id IN :opeIds]){
            System.debug(ope.Conditions__r);
            //ope.SubAccountsUnderApproval__c
            Set<String> codes = new Set<String>();
            for(OrderProcessExceptionCondition__c c : ope.Conditions__r)
                codes.add(c.Code__c);
            ope.SubAccountsUnderApproval__c = ';'+String.join(new List<String>(codes), ';')+';';
            opesToUpdate.add(ope);
        }
        System.debug('opesToUpdate:\n'+JSON.serializePretty(opesToUpdate));
        if(!opesToUpdate.isEmpty())
            update opesToUpdate;
    }
}