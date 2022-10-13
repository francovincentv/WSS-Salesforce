trigger KeyPortTrigger on KeyPort__c (
    after insert, after delete
    //after update,after delete,before delete,after undelete,before update
    ) {
   /* if (Trigger.isBefore) 
    {
             if (Trigger.isInsert)
                {                    
                    system.debug('KeyPortTrigger_Before_Insert');

                }
                else if (Trigger.isUpdate)
                {                   
                    system.debug('KeyPortTrigger_Before_Update');
                         
                } 
         		else if (Trigger.isDelete)
                {                   
                    system.debug('KeyPortTrigger_Before_Update');
                         
                } 
    }
    else*/ 
			if (Trigger.isAfter) 
  			  {		
            if (Trigger.isInsert)
              {
                    system.debug('KeyPort_After_Insert');
                                      UpdateQuoteGroupZoneString.updateQuoteGroupZoneString(Trigger.new);

       
              }
             /* else if (Trigger.isUpdate)
              {
                    system.debug('KeyPortTrigger_After_Update');             

              }*/
              else if (Trigger.isDelete)
              {
                 system.debug('KeyPort_Before_Delete');
				 UpdateQuoteGroupZoneString.updateQuoteGroupZoneString(Trigger.old);

              }
      /*
              else if (Trigger.isUndelete)
              {
      
              }*/
    }
}