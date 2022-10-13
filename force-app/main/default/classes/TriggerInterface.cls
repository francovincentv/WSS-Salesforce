/*********************************************
TriggerInterface
The apex interface which contains the methods that needs to be implemented while developing the handler class even if there is no logic for those methods. Using the interface we are assuring that developer will follow all the best practice.
*********************************************/

public interface TriggerInterface{
   
    void beforeInsert(List<sObject> newRecordsList);
    
    void afterInsert(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap);
    
    void beforeUpdate(List<sObject> newRecordsList, List<sObject> oldRecordsList, Map<Id, sObject> newRecordsMap, Map<Id, sObject> oldRecordsMap);

    void afterUpdate(List<sObject> newRecordsList, List<sObject> oldRecordsList, Map<Id, sObject> newRecordsMap,  Map<Id, sObject> oldRecordsMap);
               
    void beforeDelete(List<sObject> oldRecordsList , Map<Id, sObject> oldRecordsMap);
    
    void afterDelete(Map<Id, sObject> oldRecordsMap);
    
    void afterUnDelete(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap);
}