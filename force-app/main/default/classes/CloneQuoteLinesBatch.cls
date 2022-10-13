/*************************************************************************
 * Class       :   CloneQuoteLinesBatch
 * References  :   CloneQuoteLinesBatch_Test.cls, CloneQuoteLinesController
 * Description :   This batch is triggered by the Aura component CloneQuoteLines, 
 *                  This batch will clone the quote lines of the primary Quote of the related opportunity. For the newly created lines the Amended_Quote_Line__c
 *                  will be marked as true and for the lines that have been coppied the LineHasBeenCloned__c will be true.
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [19.Apr.2022]	    [Niki - Fluido]	    [initial development]
 **************************************************************************/
global without sharing class CloneQuoteLinesBatch implements Database.Batchable<sObject>{
 
    public final Id quoteId;
    public List<SBQQ__QuoteLine__c> quoteLinesList = new List<SBQQ__QuoteLine__c>();
    
    //Constructor
    public CloneQuoteLinesBatch(Id quoteIdPar, List<SBQQ__QuoteLine__c> quoteLinesListPar) {
        this.quoteId = quoteIdPar;
        this.quoteLinesList = quoteLinesListPar;
    }

    public List<SBQQ__QuoteLine__c> start(Database.BatchableContext context)
    {
        return quoteLinesList;
    }

    global void execute(Database.BatchableContext bc, List<SBQQ__QuoteLine__c> quoteLinesList ) {
        SBQQ.TriggerControl.disable();
        System.debug('@@Execute method');
        try {
            List<SBQQ__QuoteLine__c> unifiedListToUpsert = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> quoteLinesClonedList = new List<SBQQ__QuoteLine__c>();

            //Query for the Product group ids. Make a map with key: discount group name and value:group Id.
            List<SBQQ__QuoteLineGroup__c> productGroupList = [SELECT Id, Name FROM SBQQ__QuoteLineGroup__c where SBQQ__Quote__c =: quoteId];// AND Name != 'Group1'];
            Map<String, Id> productGroupMap = new Map<String, Id>();
            for(SBQQ__QuoteLineGroup__c pg : productGroupList){
                productGroupMap.put(pg.Name, pg.Id);
            }
            //within for: clonedql.groupId = map.get(ql.discount group name)
            for(SBQQ__QuoteLine__c ql : quoteLinesList) {
                //create the clone and update the Quote Id with the primary Quote
                SBQQ__QuoteLine__c clonedQL = ql.clone(false, false, false, false);
                clonedQL.SBQQ__Quote__c = (Id)quoteId;
                clonedQL.Amended_Quote_Line__c = true;
                //if there is only 1 group (Group1), assign hat to all the lines
                if(productGroupMap.size()==1 && productGroupList[0].Name=='Group1') {
                    clonedQL.SBQQ__Group__c = productGroupMap.get('Group1');
                }else{
                    clonedQL.SBQQ__Group__c = productGroupMap.get(ql.Product_Discount_Group__c);
                }
                quoteLinesClonedList.add(clonedQL);

                //update the line that was cloned from the primary quote as LineHasBeenCloned__c = true, so that it wont be edited/deleted after creation
                ql.LineHasBeenCloned__c = true;
            }

            unifiedListToUpsert.addAll(quoteLinesClonedList);
            unifiedListToUpsert.addAll(quoteLinesList);

            if(unifiedListToUpsert.size()>0) upsert unifiedListToUpsert;
            else{
                throw new CustomException('There are no lines to be cloned. Either because they ahve already been cloned, or because there are no available ones.');
            }   
            System.debug('**Total Items Cloned ' + quoteLinesClonedList.size());            
        } catch (Exception e) {
            System.debug('CloneQuoteLinesBatch error' + e.getMessage());
            System.debug('CloneQuoteLinesBatch error stack' + e.getStackTraceString());        
        } finally {
            SBQQ.TriggerControl.enable();
        }
    }

    global void finish(Database.BatchableContext bc) {
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob 
                        WHERE Id = :BC.getJobId()];

        System.debug('The CloneQuoteLinesBatch has Finished. '+a);
    }
}