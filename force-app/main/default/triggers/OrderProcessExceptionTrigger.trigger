trigger OrderProcessExceptionTrigger on OrderProcessException__c (before insert, before update, after insert, after update, after delete, before delete, after undelete) {
    //System.debug('*OrderProcessExceptionTrigger*');
    TriggerDispatcher.run(new OrderProcessExceptionTriggerHandler() , 'OrderProcessException__c');

}