trigger BonusAgreementTrigger on BonusAgreement__c(
    before insert, before update,
    after update
    //after insert, 
    //after delete,before delete,after undelete
    ) {
    if (Trigger.isBefore) 
    {
             if (Trigger.isInsert)
                {                    
                    BonusAgreementAutomations.generateProductGroupString(Trigger.new,null,'update');                         
                }
                else
                    if (Trigger.isUpdate)
                {                   
                    system.debug('BonusAgreement_Before_Update');
                    BonusAgreementAutomations.generateProductGroupString(Trigger.new,Trigger.OldMap,'update');                         
                } 
    }
    else if (Trigger.isAfter) 
    {
           /* if (Trigger.isInsert)
              {
                    system.debug('BonusAgreementTrigger_After_Insert');
       
              }*/
               if (Trigger.isUpdate)
              {
                    system.debug('BonusAgreement_After_Update');
                     BonusAgreementAutomations.updateBonusInformationtoQuote(Trigger.new,Trigger.OldMap,'update');             

              }
             /* else if (Trigger.isDelete)
              {
      
              }
      
              else if (Trigger.isUndelete)
              {
      
              }*/
    }
}