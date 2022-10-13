trigger QuoteLineTrigger on SBQQ__QuoteLine__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerDispatcher.run(new QuoteLineTriggerHandler() , 'SBQQ__QuoteLine__c');
}