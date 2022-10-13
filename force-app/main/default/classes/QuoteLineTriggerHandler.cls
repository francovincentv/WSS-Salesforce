/*************************************************
* Class                 : QuoteLineTriggerHandler
* References            : QuoteLineTrigger
* Description           : This is the helper class forQuoteLineTrigger
*                           This class is used to orginize the trigger event logic's to execute
* Change Log    
* Date Modified     Modified By             Description of the update
* ----------------------------------------------------------------
* [10.Aug.2020]     [Lokesh - Fluido]       [Initial development]
*************************************************/
public with sharing class QuoteLineTriggerHandler implements TriggerInterface{

    /**************************************************************************************
    * @Description  This method runs before SBQQ__QuoteLine__c are inserted 
    * @Param		List<SBQQ__QuoteLine__c> - new SBQQ__QuoteLine__c
    * @Return       void
    **************************************************************************************/ 
    public void beforeInsert(List<SObject> newItems) {
        QuoteLineTriggerHelper.setQlDiscountGroup((List<SBQQ__QuoteLine__c>)newItems);
        QuoteLineTriggerHelper.setSPGImpact((List<SBQQ__QuoteLine__c>)newItems, new Map<Id, SBQQ__QuoteLine__c>());
        QuoteLineTriggerHelper.setSalesUsd((List<SBQQ__QuoteLine__c>)newItems, new Map<Id, SBQQ__QuoteLine__c>());
    }

    /**************************************************************************************
    * @Description  This method runs after SBQQ__QuoteLine__c are inserted 
    * @Param		List<SBQQ__QuoteLine__c> - new SBQQ__QuoteLine__c as a list
    * @Param        Map<Id, SBQQ__QuoteLine__c> newMap - new SBQQ__QuoteLine__c as a map
    * @Return       void
    **************************************************************************************/ 
    public void afterInsert(List<sObject> newRecordsList , Map<Id, SObject> newItems) {
        //Try{
        //}Catch(System.Exception ex){
            /* Call the TransactionLogHandler class method to create a log 
               parameters need to pass in the method are System.Exception and the Handler ClassName
            */
            //TransactionLogHandler.doHandleException(ex ,'', 'QuoteLineTriggerHandler', '', true, false);
        //}
    }

    /**************************************************************************************
    * @Description  This method runs before SBQQ__QuoteLine__c are updated 
    * @Param		List<SBQQ__QuoteLine__c> - new SBQQ__QuoteLine__c as a list
    * @Param        Map<Id, SBQQ__QuoteLine__c> - new SBQQ__QuoteLine__c as a map
    * @Param		List<SBQQ__QuoteLine__c> - old version of SBQQ__QuoteLine__c as a list
    * @Param        Map<Id, SBQQ__QuoteLine__c> - old version of SBQQ__QuoteLine__c as a map
    * @Return       void
    **************************************************************************************/ 
    public void beforeUpdate(List<SObject> newItems, List<SObject> oldItems, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
    //public static void OnBeforeUpdate(List<SBQQ__QuoteLine__c> newList, Map<Id, SBQQ__QuoteLine__c> newMap, List<SBQQ__QuoteLine__c> oldList, Map<Id, SBQQ__QuoteLine__c> oldMap) {
        QuoteLineTriggerHelper.setQuoteLineGroupForTopLevelQL((List<SBQQ__QuoteLine__c>)newItems);
        QuoteLineTriggerHelper.setQlDiscountGroup((List<SBQQ__QuoteLine__c>)newItems);
        QuoteLineTriggerHelper.setSPGImpact((List<SBQQ__QuoteLine__c>)newItems, (Map<Id, SBQQ__QuoteLine__c>)oldItemsMap);
        QuoteLineTriggerHelper.setSalesUsd((List<SBQQ__QuoteLine__c>)newItems, (Map<Id, SBQQ__QuoteLine__c>)oldItemsMap);
    }

    /**************************************************************************************
    * @Description  This method runs after SBQQ__QuoteLine__c are updated 
    * @Param		List<SBQQ__QuoteLine__c> - new SBQQ__QuoteLine__c as a list
    * @Param        Map<Id, SBQQ__QuoteLine__c> - new SBQQ__QuoteLine__c as a map
    * @Param		List<SBQQ__QuoteLine__c> - old version of SBQQ__QuoteLine__c as a list
    * @Param        Map<Id, SBQQ__QuoteLine__c> - old version of SBQQ__QuoteLine__c as a map
    * @Return       void
    **************************************************************************************/ 
    public void afterUpdate(List<sObject> newRecords, List<sObject> oldRecords, Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap) {
 
        //Try{           
            
        //}Catch(System.Exception ex){
            /* Call the TransactionLogHandler class method to create a log 
               parameters need to pass in the method are System.Exception and the Handler ClassName
            */
            //TransactionLogHandler.doHandleException(ex ,'', 'QuoteLineTriggerHandler', '', true, false);
        //}
    }

    public void beforeDelete(List<sObject> oldRecordsList , Map<Id, SObject> oldItems) {}

    public void afterDelete(Map<Id, SObject> oldItems) {}
 
    public void afterUndelete(List<sObject> newRecordsList , Map<Id, sObject> newItems) {}

}