trigger OrderProcessExceptionConditionTrigger on OrderProcessExceptionCondition__c (before insert, before update,after insert, after update, after delete, before delete, after undelete) {
    TriggerDispatcher.run(new OPEConditionTriggerHandler() , 'OrderProcessExceptionCondition__c');
}