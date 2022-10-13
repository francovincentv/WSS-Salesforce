public class SBQQ_Quote_Sync {

    public static void updateCorridors(list<SBQQ__Quote__c> TriggerNew, Map<Id,SBQQ__Quote__c> TriggerOldMap,string event){
	    for (SBQQ__Quote__c q: TriggerNew){
		    q.CorridorAllowanceTransfer__c = q.AdditionalCorridorAllowance__c;
		    q.CorridorLevelTransfer__c = q.AppliedCorridor__c;
	    }
    }

    // Written by SKu, 20.2.2018, check whether this is OK
    //This could be done by workflow as well, but would need to create 14 workflows since the picklist value cannot be assigned by a formula. :( 
    public static void temporaryEditLinesFieldSetNameSelector(list<SBQQ__Quote__c> TriggerNew, Map<Id,SBQQ__Quote__c> TriggerOldMap,string event){
	    for (SBQQ__Quote__c q: TriggerNew){
		    q.EditLinesFieldSetName__c = q.EditLinesFieldSetFormula__c;
	    }
    }
}