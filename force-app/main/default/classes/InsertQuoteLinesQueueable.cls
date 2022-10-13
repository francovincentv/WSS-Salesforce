/*************************************************************************
 * Class       :   InsertQuoteLinesQueueable
 * References  :   InsertQuoteLinesQueueableTest, QuoteInitializationAutomation
 * Description :   Helper class for QuoteInitializationAutomation with all necessary the logic 
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [14.Aug.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
public  class InsertQuoteLinesQueueable implements Queueable,Database.AllowsCallouts{
    Private SBQQ__Quote__c quote;

    /* 
     * Constructor
     */
    public InsertQuoteLinesQueueable(SBQQ__Quote__c quote) {
        this.quote = quote;
    }


    /**************************************************************************************
     * @Description  Execute method that will executed when the class executed
     * @Param		QueueableContext - context
     * @Return       void
     **************************************************************************************/ 
    public void execute(QueueableContext context) {
        SBQQ.TriggerControl.disable();
        try {
            insertQuoteLines(quote.Id);

            //if eveything run fine then update the status on quote
            quote.Quote_Line_Insert_Status__c = 'Completed';
            update quote;
        } catch(Exception e) {
            TransactionLogHandler.doHandleException(e, '', 'InsertQuoteLinesQueueable', '', true, false);
            quote.Quote_Line_Insert_Status__c = 'Failed';
            update quote;
        } finally {
            SBQQ.TriggerControl.enable();
        }
    }

    /**************************************************************************************
     * @Description  Helper method for execute, this method will insert quote lines basedon the purchase history bucket records
     * @Param		 Id - Quote Id
     * @Return       void
     **************************************************************************************/
    public static void insertQuoteLines(Id quoteId) {
      
        System.debug('inserting new quotelines from purchase bucket history');
        List<SBQQ__QuoteLine__c> quoteLinetobeUpdated = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> childQuoteLinesToInsert=new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLineGroup__c > defaultGroupToInsert = new List<SBQQ__QuoteLineGroup__c>();
        List<SBQQ__Quote__c> quotesToInsertLineItems=new List<SBQQ__Quote__c>();
        Map<Id,Id> mapQuoteOpportunity=new Map<Id,Id>();    // Map<quoteId,OPPORTUNITYId>
        Map<Id,String> mapProductPriceEntity= new  map<Id,String>();
        Map<Id,set<Id>> contractPartyAccountIds=new Map<Id,set<Id>>();  // Map <opportunityID, List<accountID>>
        Map<Id, Id> mapQuoteQuoteLineGroupstandard = new Map<Id, Id>();  //map of quote Id and Quote Line Group for standard and GF         
        Map<Id,List<PurchaseHistoryBucket__c>> mapPurchaseHistoryLines=new Map<Id,List<PurchaseHistoryBucket__c>>(); //Map<accountId, List<PurchaseHistoryBucket__c>>
        Map<Id,SBQQ__QuoteLine__c> mapProductListNewQuoteLineItemsChild=new Map<Id,SBQQ__QuoteLine__c>();   // Map<productid,List<QuoteLinesTocreateChild>>
        Map<Id,SBQQ__QuoteLine__c> mapProductListNewQuoteLineItemsParent=new Map<Id,SBQQ__QuoteLine__c>();  // Map<productid,List<QuoteLinesTocreateParent>>    
        Map<SBQQ__Quote__c, List<SBQQ__QuoteLine__c>> mapQuoteQuoteLineParent = new Map<SBQQ__Quote__c, List<SBQQ__QuoteLine__c>>(); // Map<Quote,List<SBQQ__QuoteLine__c>> used  for upddaing SBQQ__Number__c
        Map<SBQQ__Quote__c,List<SBQQ__QuoteLine__c>> mapQuoteQuoteLineChild = new Map<SBQQ__Quote__c,List<SBQQ__QuoteLine__c>>();    // Map<Quote,List<SBQQ__QuoteLine__c>> used  for upddaing SBQQ__Number__c
        Set<Id> productId= new Set<Id>();

        SBQQ__Quote__c quote = [SELECT SBQQ__Opportunity2__c, SBQQ__Account__c FROM SBQQ__Quote__c WHERE Id =:quoteId];
        
        if(quote.SBQQ__Opportunity2__c!=null && quote.SBQQ__Account__c!=null){
            mapQuoteOpportunity.put(quote.id,quote.SBQQ__Opportunity2__c);
            quotesToInsertLineItems.add(quote);
        }

        List<SBQQ__QuoteLineGroup__c> qlDefaultGroup = [SELECT Id, Name, SBQQ__Account__c, SBQQ__Quote__c FROM SBQQ__QuoteLineGroup__c WHERE Name =:System.Label.Default_Quote_Line_Group AND SBQQ__Quote__c =:quote.Id LIMIT 1];

        if(qlDefaultGroup.size() == 0){
            //create Default, Quote Line Group 
            for(SBQQ__Quote__c singleQuote :quotesToInsertLineItems){
                SBQQ__QuoteLineGroup__c qlGroup = new SBQQ__QuoteLineGroup__c ();
                qlGroup.Name = System.Label.Default_Quote_Line_Group;
                qlGroup.SBQQ__Account__c = singleQuote.SBQQ__Account__c;
                qlGroup.SBQQ__Quote__c = singleQuote.id;
                defaultGroupToInsert.add(qlGroup);
            }
            
            insert defaultGroupToInsert;
        } else {
            defaultGroupToInsert.addAll(qlDefaultGroup);
        }

        for(SBQQ__QuoteLineGroup__c qlGroup : defaultGroupToInsert) {
            mapQuoteQuoteLineGroupstandard.put(qlGroup.SBQQ__Quote__c,qlGroup.id);
        }
        
        // Query ContractParty__c:Junction between opportunity and account, indicating contract parties to quote.
        set<id> accountIds=new set<id>();
        for (ContractParty__c cp:[SELECT id, Opportunity__c, Account__c
                                    FROM ContractParty__c
                                    WHERE Opportunity__c IN: mapQuoteOpportunity.values()
                                    AND Account__c!=null]){
                                        accountIds.add(cp.Account__c);
                                        if (contractPartyAccountIds.get(cp.Opportunity__c) == null)
                                            contractPartyAccountIds.put(cp.Opportunity__c, new set<id>());
                                        contractPartyAccountIds.get(cp.Opportunity__c).add(cp.Account__c);
                                    }
                                    
        //Need to limit the lines , since CPQ cannot handle too large quotes
        for(PurchaseHistoryBucket__c phb : [SELECT Account__c,
                                            ParentProduct2Id__c,// TO USE TO SET REQUIRED BY ON LINE ITEM
                                            ProductCode__c,
                                            Product__c,
                                            MainProductOptionId__c,
                                            L12M_Qty_Rollup__c,
                                            Sales_L12M_Rollup__c,
                                            Quantity__c 
                                            FROM PurchaseHistoryBucket__c
                                            WHERE Account__c IN: accountIds
                                            AND L12M_Qty_Rollup__c>0 AND ProductIsActive__c = TRUE
                                            AND (Product__r.ProductGroupCode__c LIKE '09%' or Product__r.ProductGroupCode__c like '10%' or Product__r.ProductGroupCode__c like '11%'  or Product__r.ProductGroupCode__c like '16%' or Product__r.ProductGroupCode__c like '17%' or   Product__r.ProductGroupCode__c like '19%' or Product__r.ProductGroupCode__c like '24%' or  Product__r.ProductGroupCode__c like '32%' or Product__r.ProductGroupCode__c like '40%' or  Product__r.ProductGroupCode__c like '42%' or Product__r.ProductGroupCode__c like '43%' or  Product__r.ProductGroupCode__c like '44%' or Product__r.ProductGroupCode__c like '48%' or  Product__r.ProductGroupCode__c like '50%' or Product__r.ProductGroupCode__c like '59%' or  Product__r.ProductGroupCode__c like '60%' or Product__r.ProductGroupCode__c like '61%' or  Product__r.ProductGroupCode__c like '63%' or Product__r.ProductGroupCode__c like '64%' or  Product__r.ProductGroupCode__c like '65%' or Product__r.ProductGroupCode__c like '66%' or  Product__r.ProductGroupCode__c like '68%' or Product__r.ProductGroupCode__c like '69%' or  Product__r.ProductGroupCode__c like '71%' or Product__r.ProductGroupCode__c like '77%'  or Product__r.ProductGroupCode__c like '82%' or Product__r.ProductGroupCode__c like '94%')
                                            AND Product__r.Product_Discount_Group__c != 'Gases & Refrigerants'
                                            ORDER BY ProductCode__c ASC
                                            ]){
                                                if(phb.ProductCode__c.length() == 6 || phb.ProductCode__c.length() == 7) {
                                                    if (mapPurchaseHistoryLines.get(phb.Account__c) == null)
                                                        mapPurchaseHistoryLines.put(phb.Account__c, new List<PurchaseHistoryBucket__c>());
                                                    mapPurchaseHistoryLines.get(phb.Account__c).add(phb);
                                                    productId.add(phb.ParentProduct2Id__c);
                                                    productId.add(phb.Product__c);          
                                                }                
                                                
                                            }
        for(Product2 product : [SELECT PricingType__c FROM Product2 WHERE Id IN: productId]){
            mapProductPriceEntity.put(product.id,product.PricingType__c);   
        }

        // CREATE PARENT LINE ITEMS
        for(SBQQ__Quote__c singleQuote :quotesToInsertLineItems){
            set<id> quoteContractPartyAccountIDs=contractPartyAccountIds.get(singleQuote.SBQQ__Opportunity2__c);
            for (id  accountID: quoteContractPartyAccountIDs){
                if(mapPurchaseHistoryLines.get(accountID)!=null){
                    //iterate on all the purchase history buckets
                    if(mapPurchaseHistoryLines.get(accountID)==null){
                        continue;
                    }
                    for(PurchaseHistoryBucket__c phbQuote: mapPurchaseHistoryLines.get(accountID)){
                        //if ParentProduct2Id__c is availble then skip creating the SBQQ__QuoteLine__c for the current PurchaseHistoryBucket__c 
                        if(phbQuote.ParentProduct2Id__c != null) {
                            if(mapProductListNewQuoteLineItemsParent.keyset().contains(phbQuote.ParentProduct2Id__c)==false){
                                //Product was not considered before, create a new quote line item for this product
                                SBQQ__QuoteLine__c newParentQL =  initiateNewQL(phbQuote, singleQuote, mapQuoteQuoteLineGroupstandard.get(singleQuote.Id));
                                newParentQL.SBQQ__Product__c=phbQuote.ParentProduct2Id__c;
                                newParentQL.LastYearQty__c=1;   //Parent Line Items should always have quantity=1

                                mapProductListNewQuoteLineItemsParent.put(phbQuote.ParentProduct2Id__c,newParentQL);
                                mapQuoteQuoteLineParent.put(singleQuote,mapProductListNewQuoteLineItemsParent.values());
                            }
                        }
                        
                    }
                }
            }
        }
        
        System.debug('parent products size >>>' +mapProductListNewQuoteLineItemsParent.values().size() );
        //insert parent quote lines
        if(mapProductListNewQuoteLineItemsParent.values().size()>0){
            insert mapProductListNewQuoteLineItemsParent.values();
        }
        
        
        //History has Product__c and ParentProduct2Id__c
        //Product Hierarchy is 2 levels deeep
        // CREATE CHILD LINE ITEMS
        for(SBQQ__Quote__c singleQuote :quotesToInsertLineItems){
            set<id> quoteContractPartyAccountIDs=contractPartyAccountIds.get(singleQuote.SBQQ__Opportunity2__c);
            for (id  accountID: quoteContractPartyAccountIDs){
                if(mapPurchaseHistoryLines.get(accountID)!=null){
                    if(mapPurchaseHistoryLines.get(accountID)==null){
                        continue;
                    }
                    //iterate on all the purchase history buckets
                    for(PurchaseHistoryBucket__c phbQuote: mapPurchaseHistoryLines.get(accountID)){
                        if(mapProductListNewQuoteLineItemsChild.keyset().contains(phbQuote.Product__c)==false){
                            //Product was not considered before, create a new quote line item for this product
                            SBQQ__QuoteLine__c newChildQL = initiateNewQL(phbQuote, singleQuote, mapQuoteQuoteLineGroupstandard.get(singleQuote.Id));
                            newChildQL.SBQQ__Product__c=phbQuote.Product__c;
                            newChildQL.LastYearQty__c=phbQuote.L12M_Qty_Rollup__c;
                            newChildQL.Sales_L12M__c=phbQuote.Sales_L12M_Rollup__c;
                            newChildQL.SBQQ__OptionLevel__c  = 1;
                            newChildQL.SBQQ__Quantity__c = phbQuote.L12M_Qty_Rollup__c; // update the assumed quantity 
                            // Set the parent line item on the child line item
                            if(phbQuote.ParentProduct2Id__c != null && mapProductListNewQuoteLineItemsParent.get(phbQuote.ParentProduct2Id__c)!=null){
                                newChildQL.SBQQ__RequiredBy__c =  mapProductListNewQuoteLineItemsParent.get(phbQuote.ParentProduct2Id__c).Id;
                            }
                            
                            childQuoteLinesToInsert.add(newChildQL);
                            mapQuoteQuoteLineChild.put(singleQuote,childQuoteLinesToInsert);
                            mapProductListNewQuoteLineItemsChild.put(phbQuote.Product__c,newChildQL);
                        }
                        else{
                            // If Product is already in the map don´t create a new line item but update the existing one
                            SBQQ__QuoteLine__c newQuoteLine=mapProductListNewQuoteLineItemsChild.get(phbQuote.Product__c);
                            if(newQuoteLine!=null && phbQuote.L12M_Qty_Rollup__c!=null){
                                newQuoteLine.LastYearQty__c=newQuoteLine.LastYearQty__c+phbQuote.L12M_Qty_Rollup__c;
                                newQuoteLine.Sales_L12M__c=newQuoteLine.Sales_L12M__c+phbQuote.Sales_L12M_Rollup__c;
                            }
                        }
                    }
                }
            }
        }

        System.debug('child products size >>>' +childQuoteLinesToInsert.size() );
        //insert child quote lines
        if(childQuoteLinesToInsert.size()>0){
            try{
                insert childQuoteLinesToInsert;
            } catch(Exception e){
                TransactionLogHandler.doHandleException(e, '', 'InsertQuoteLinesQueueable', '', true, false);
            }
        }

          
        for(SBQQ__Quote__c singleQuote :quotesToInsertLineItems){
            if(mapPurchaseHistoryLines!=null){
                Integer quoteLineNumber=1;
                if(mapQuoteQuoteLineParent!=null && mapQuoteQuoteLineParent.size() > 0){
                    for(SBQQ__QuoteLine__c quoteline : mapQuoteQuoteLineParent.get(singleQuote)){
                        quoteline.SBQQ__Number__c=quoteLineNumber;
                        quoteLineNumber++;
                        quoteLinetobeUpdated.add(quoteline);
                        for(SBQQ__QuoteLine__c quoteline1 : mapQuoteQuoteLineChild.get(singleQuote)){
                            if (quoteline1.SBQQ__RequiredBy__c==quoteline.id){
                                quoteline1.SBQQ__Number__c=quoteLineNumber;
                                quoteLinetobeUpdated.add(quoteline1);
                                quoteLineNumber++;
                            }
                        }
                    }
                }
            }   
        }
        if(quoteLinetobeUpdated.size()>0) {
            try{
                update quoteLinetobeUpdated; 
            } catch(Exception e){
                TransactionLogHandler.doHandleException(e, '', 'InsertQuoteLinesQueueable', '', true, false);
            }
        }
 
    }

    /**************************************************************************************
    * @Description  This is the helper method for initializeQuoteLines()
    *               This methods initiates new SBQQ__QuoteLine__c to insert
    * @Param		PurchaseHistoryBucket__c - Purchage history bucket information
    * @Param		SBQQ__Quote__c - quote information
    * @Return       SBQQ__QuoteLine__c - new QuoteLine
    **************************************************************************************/
    public static SBQQ__QuoteLine__c initiateNewQL(PurchaseHistoryBucket__c phb, SBQQ__Quote__c quote, Id groupId) {
        SBQQ__QuoteLine__c ql =new SBQQ__QuoteLine__c();
        ql.SBQQ__Quote__c=quote.id;
        ql.SBQQ__ProductOption__c = phb.MainProductOptionId__c;
        ql.SBQQ__ProductSubscriptionType__c  = 'One-time';
        ql.SBQQ__SubscriptionType__c  = 'One-time';
        ql.SBQQ__Group__c = groupId;

        return ql;
    }
}