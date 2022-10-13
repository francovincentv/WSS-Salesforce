trigger QuoteTrigger on SBQQ__Quote__c (before insert, before update,after insert, after update,  after delete, before delete, after undelete) {
    Integer queriesUsed = Limits.getQueries();
    System.debug('Quote Trigger START>>>> query count'+Limits.getQueries());
    TriggerDispatcher.run(new QuoteTriggerHandler() , 'SBQQ__Quote__c');

    
    /*
    if (Trigger.isBefore) 
    {
        if (Trigger.isInsert)
        {                    
            system.debug('QuoteTrigger_Before_Insert');
            SBQQ_Quote_Sync.updateCorridors(Trigger.new,null,'insert');
        }
        else if (Trigger.isUpdate)
        {                   
            system.debug('QuoteTrigger_Before_Update');
            SBQQ_Quote_Sync.temporaryEditLinesFieldSetNameSelector(Trigger.new,Trigger.OldMap,'update');   
            BonusAgreementAutomations.updateBonusInformationAgreementChanged(Trigger.new,Trigger.OldMap,'update');                          
        } 
    }
    else if (Trigger.isAfter) 
    {
        if (Trigger.isInsert)
        {
            system.debug('QuoteTrigger_After_Insert');
            //QuoteInitializationAutomation.initializeQuoteLines(Trigger.new,null,'insert');
   
        }
        else if (Trigger.isUpdate)
        {
            system.debug('QuoteTrigger_After_Update');  
            keyPortStringOnKPGChange.changekeyPortStringOnquote(Trigger.new,Trigger.OldMap,'update');  
             
           
        }
        /*     else if (Trigger.isDelete)
{

}

else if (Trigger.isUndelete)
{

}*/
   // }
    
    System.debug('Quote Trigger END>>>> query count'+Limits.getQueries());
}