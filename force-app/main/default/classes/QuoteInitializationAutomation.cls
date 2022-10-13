/*************************************************************************
 * Class       :   QuoteInitializationAutomation
 * References  :   QuoteInitializationAutomationTest, QuoteTrigger
 * Description :   Helper class for QuoteTrigger after insert event
 *                  This class helps to insert quotelines based on the quote information 
 *                  To clone the opportunity and related contract parties 
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [14.Aug.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
public class QuoteInitializationAutomation{
    
    /**************************************************************************************
    * @Description  This method creates new quoteLines based on existing PurchaseHistoryBucket__c records related to the quote
    * @Param		List<SBQQ__Quote__c> - New quotes
    * @Return       void
    **************************************************************************************/ 
    //public static void initializeQuoteLines(List<SBQQ__Quote__c> triggerNew, Map<Id,SBQQ__Quote__c> triggerOldMap,string event){
    @AuraEnabled
    public static Id initializeQuoteLines(SBQQ__Quote__c quote){
        try {
            InsertQuoteLinesQueueable newQlQueue = new InsertQuoteLinesQueueable(quote);
            ID jobID = System.enqueueJob(newQlQueue);
            
            quote.Quote_Line_Insert_Status__c = 'In Progress';
            update quote;
            return jobID;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**************************************************************************************
    * @Description  This method will return the quote information 
    * @Param		Id - quote Id
    * @Return       SBQQ__Quote__c
    **************************************************************************************/ 
    @AuraEnabled
    public static SBQQ__Quote__c getQuoteDetails(String quoteId){
        System.debug('quoteId ' + quoteId);
        return [SELECT Id, SBQQ__Opportunity2__r.RecordType.DeveloperName FROM SBQQ__Quote__c WHERE Id =: quoteId];
    }
}