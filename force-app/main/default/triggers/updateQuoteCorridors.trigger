trigger updateQuoteCorridors on Opportunity (after update) {

    Set<Id> oppoIds = new Set<Id>();
    for (Opportunity oppo: Trigger.new){
        if( Trigger.oldmap.get(oppo.ID).TargetedSegment__c != Trigger.newmap.get(oppo.ID).TargetedSegment__c || 
            Trigger.oldmap.get(oppo.ID).No_of_Ships_Targeted__c != Trigger.newmap.get(oppo.ID).No_of_Ships_Targeted__c || 
            Trigger.oldmap.get(oppo.ID).Activity__c  != Trigger.newmap.get(oppo.ID).Activity__c
           ){
            oppoIds.add(oppo.Id);
        }
    }
    
    if(oppoIds.isEmpty()){
        return;
    }

    List<SBQQ__Quote__c> quotes = [SELECT Id,
                                    CorridorLevelTransfer__c,
                                    AppliedCorridor__c,
                                    CorridorAllowanceTransfer__c,
                                    AdditionalCorridorAllowance__c
                                    FROM SBQQ__Quote__c
                                    WHERE SBQQ__Opportunity2__c
                                    IN : oppoIds AND SBQQ__Status__c= 'Draft'];

    if(quotes.size()>0){
        for(SBQQ__Quote__c quote : quotes){
            quote.CorridorLevelTransfer__c = quote.AppliedCorridor__c;
            quote.CorridorAllowanceTransfer__c = quote.AdditionalCorridorAllowance__c;
        }  
        update quotes;
    }
}