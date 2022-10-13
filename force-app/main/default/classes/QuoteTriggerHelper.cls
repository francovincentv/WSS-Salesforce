public inherited sharing class QuoteTriggerHelper {
    
    /**************************************************************************************
    * @Description  helper method for QuoteTriggerHandler runs beforeInsert() and beforeUpdate()
    *               This method will set Quote Status should be Draft when Approval Status is not Approved.
    * @Param		Id - Quote Id
    * @Return       Integer 
    **************************************************************************************/ 
    public static void setQuoteStatusToDraft(List<SBQQ__Quote__c> newQuoteList) {
        for(SBQQ__Quote__c quote : newQuoteList) {
            if(quote.ApprovalStatus__c != 'Approved') {
                quote.SBQQ__Status__c = 'Draft';
            }
        }
    }
}