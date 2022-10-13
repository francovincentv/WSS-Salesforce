public with sharing class LightningFlowHelper {
    @InvocableMethod
    public static List<Decimal> methodName(List<String> accountIds){
        //we will only receive one value in the liist
        List<String> accIds = accountIds[0].split(';');
        List<Decimal> sumRefrigents = new List<Decimal>();
        List<AggregateResult> arList = [SELECT Sum(Refrigerants__c) FROM Parent_PHB__c WHERE Account__c =: accIDs];
        if(arList.size() > 0){
            sumRefrigents.add((Decimal)arList[0].get('expr0'));
        } else {
            sumRefrigents.add(0);
        }

        return sumRefrigents;
    }
}