/*********************************************
QuoteTriggerHandler
The developer needs to develop the handler class and must implement the TriggerInterface with it’s all methods. Here is the sample handler class. Implementation of the TriggerInterface interface is must.
In the handler class method use try and catch where required and in catch method call doHandleException method of TransactionLogHandler class to catch the exception.
*********************************************/

public with sharing class QuoteTriggerHandler implements TriggerInterface{
    
    public void beforeInsert(List<SObject> newItems) {
        system.debug('QuoteTrigger_Before_Insert');
        SBQQ_Quote_Sync.updateCorridors((List<SBQQ__Quote__c>)newItems,null,'insert');
        QuoteTriggerHelper.setQuoteStatusToDraft((List<SBQQ__Quote__c>) newItems);
     }
  
    public void beforeUpdate(List<SObject> newItems, List<SObject> oldItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
        system.debug('QuoteTrigger_Before_Update');
        SBQQ_Quote_Sync.temporaryEditLinesFieldSetNameSelector((List<SBQQ__Quote__c>)newItems, (Map<Id, SBQQ__Quote__c>)oldItemsMap,'update');   
        BonusAgreementAutomations.updateBonusInformationAgreementChanged((List<SBQQ__Quote__c>)newItems, (Map<Id, SBQQ__Quote__c>)oldItemsMap,'update');
        QuoteTriggerHelper.setQuoteStatusToDraft((List<SBQQ__Quote__c>) newItems);
    }
 
    public void beforeDelete(List<sObject> oldRecordsList , Map<Id, SObject> oldItems) {}
 
    public void afterInsert(List<sObject> newRecordsList , Map<Id, SObject> newItems) {
        //Try{
        //}Catch(System.Exception ex){
            /* Call the TransactionLogHandler class method to create a log 
               parameters need to pass in the method are System.Exception and the Handler ClassName
            */
            //TransactionLogHandler.doHandleException(ex , '', 'QuoteTriggerHandler', '', true, false);
        //}
    }

    public void afterUpdate(List<sObject> newRecords, List<sObject> oldRecords, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
 
        Try{           
            system.debug('QuoteTrigger_After_Update');

            List<SBQQ__Quote__c> newQuotes = newRecords == null || newRecords.size() == 0 ? new List<SBQQ__Quote__c>() : (List<SBQQ__Quote__c>)newRecords;
            Map<Id, SBQQ__Quote__c> oldQuotesMap = oldItemsMap == null || oldItemsMap.size() == 0 ? new Map<Id, SBQQ__Quote__c>() : (Map<Id, SBQQ__Quote__c>) oldItemsMap; 
            keyPortStringOnKPGChange.changekeyPortStringOnquote(newQuotes, oldQuotesMap,'update'); 
        }Catch(System.Exception ex){
            /* Call the TransactionLogHandler class method to create a log 
               parameters need to pass in the method are System.Exception and the Handler ClassName
            */
            TransactionLogHandler.doHandleException(ex , '', 'QuoteTriggerHandler', '', true, false);
        }
    }
 
    public void afterDelete(Map<Id, SObject> oldItems) {}
 
    public void afterUndelete(List<sObject> newRecordsList , Map<Id, sObject> newItems) {}
}