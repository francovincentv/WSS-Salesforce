trigger updateQuoteCorridorsAccount on Account (after update) {
    Set<Id> AccIds = new Set<Id>();
    for (Account Acc: Trigger.new){
        if(Trigger.oldmap.get(Acc.ID).Type != Trigger.newmap.get(Acc.ID).Type ||
        Trigger.oldmap.get(Acc.ID).Primary_Market_Segment__c != Trigger.newmap.get(Acc.ID).Primary_Market_Segment__c){
            AccIds.add(Acc.id);
        }
    }
    if(AccIds.size()==0){
        return;
    }
    List<SBQQ__Quote__c> quotes = [SELECT Id,
                                                SBQQ__Account__c,
                                                CorridorLevelTransfer__c,
                                                AppliedCorridor__c,
                                                 CorridorAllowanceTransfer__c,
                                                 AdditionalCorridorAllowance__c
                                    FROM SBQQ__Quote__c 
                                    WHERE SBQQ__Account__c = :AccIds
                                    AND SBQQ__Status__c= ''];
    if(quotes.size()>0){        
        for(SBQQ__Quote__c quote : quotes){
            quote.CorridorLevelTransfer__c = quote.AppliedCorridor__c;
            quote.CorridorAllowanceTransfer__c = quote.AdditionalCorridorAllowance__c;
        }
        update quotes;
    }
}