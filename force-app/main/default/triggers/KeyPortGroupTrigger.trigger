trigger KeyPortGroupTrigger on KeyPortGroup__c (
    before insert, after insert, before delete, after delete
    //after update,after delete,before delete,after undelete,before update
    ) {
    if (Trigger.isBefore) 
    {
           /* if (Trigger.isInsert)
                {                    
                    system.debug('KeyPortGroupTrigger_Before_Insert');
                    //KeyPortGroupName.nameKeyPortGroup(Trigger.new);

                }
                 else if (Trigger.isUpdate)
                {                   
                    system.debug('KeyPortGroupTrigger_Before_Update');
                         
                } 
                else */
                if (Trigger.isDelete)
                {                   
                    system.debug('KeyPortGroupTrigger_Before_Delete');
                    DeleteQuoteKeyportGroupZoneString.deleteQuoteKeyportGroupZoneString(Trigger.old);

                }       
    }
    else if (Trigger.isAfter) 
    {
            if (Trigger.isInsert)
              {
                    system.debug('KeyPortGroup_After_Insert');
                    KeyPortGroupName.nameKeyPortGroup(Trigger.new);
                    DeleteQuoteKeyportGroupZoneString.deleteQuoteKeyportGroupZoneString(Trigger.new);


       
              }
        
        /*
              else if (Trigger.isUpdate)
              {
                    system.debug('KeyPortGroupTrigger_After_Update');             

              }*/
              else if (Trigger.isDelete)
              {
                 system.debug('KeyPortGroup_After_Delete');
                 KeyPortGroupName.nameKeyPortGroup(Trigger.old);


              }
      /*
              else if (Trigger.isUndelete)
              {
      
              }*/
    }
}