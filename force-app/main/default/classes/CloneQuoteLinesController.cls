/**************************************************************************************
* @Description  This class runs from the CloneQuoteLines aura component
*               This method class all the quote lines & groups
* @Param		Id - Quote id
* @Return       String -  success (or) error 
* Change Log	
* Date Modified		  Modified By 		    Description 
* ---------------------------------------------------------------------
* [19.Apr.2022]	    [Niki - Fluido]	 [initial development]
**************************************************************************************/ 
public class CloneQuoteLinesController {
    public static final String FIELDS_LIST = 'Id,SBQQ__Quote__r.SBQQ__Account__c,Approved__c,Comments__c,SBQQ__ProductCode__c,SBQQ__Product__c,ProductGroupCode__c,ProductGroupName__c,CurrencyIsoCode,Product_Discount_Group__c, SBQQ__Quantity__c, LastYearQty__c, Base_Net_Price__c,Revised_Discount__c, SBQQ__ListPrice__c,Final_Discount__c,Product_Price__c, Ropes_Amount__c, Pricing_approval_condition__c,Sales_USD_Amount__c,Test_Discount__c , Volume_Discount_with_Transition_Discount__c,SBQQ__ProductOption__c,NVD_eligible__c, SBQQ__VolumeDiscount__c, NewTransitionDiscount__c,Ropes_Revised_Discount__c, Ropes_Discount__c, Ropes_Base_Net_Price__c,OppRecType__c,CylinderProduct__c,SecurityFee__c,CylinderBalance__c ,BonusApplies__c,RopesBonusApplies__c,BonusPercent__c,EstimatedBonus__c,PGApprovalANonFormula__c,PGApprovalBNonFormula__c,PGApprovalCNonFormula__c,PGApprovalDNonFormula__c,PGApprovalENonFormula__c,MCR2__c,RedCorridor__c,YellowCorridor__c,GreenCorridor__c,PricingType__c,Scope__c,SBQQ__CustomerPrice__c,SBQQ__NetPrice__c,SBQQ__UnitCost__c, SBQQ__ComponentTotal__c, SBQQ__Renewal__c, SBQQ__Existing__c , SBQQ__PriorQuantity__c, SBQQ__EffectiveQuantity__c ,KP1Qty__c,KP2Qty__c,KP3Qty__c,KP4Qty__c,KP5Qty__c,KP6Qty__c,KP7Qty__c,KP8Qty__c,KP9Qty__c,KP10Qty__c,WWQty__c,KP1Disc__c,KP2Disc__c,KP3Disc__c,KP4Disc__c,KP5Disc__c,KP6Disc__c,KP7Disc__c,KP8Disc__c,KP9Disc__c,KP10Disc__c,KP1Cost__c,KP2Cost__c,KP3Cost__c,KP4Cost__c,KP5Cost__c,KP6Cost__c,KP7Cost__c,KP8Cost__c,KP9Cost__c,KP10Cost__c,WWCost__c,KP10ListPrice__c,KP9ListPrice__c,KP8ListPrice__c,KP7ListPrice__c,KP6ListPrice__c,KP5ListPrice__c,KP4ListPrice__c,KP3ListPrice__c,KP2ListPrice__c,KP1ListPrice__c,KP10Price__c,KP9Price__c,KP8Price__c,KP7Price__c,KP6Price__c, KP5Price__c,KP4Price__c,KP3Price__c,KP2Price__c,KP1Price__c,Zone1Price__c,Zone2Price__c,Zone3Price__c,Zone4Price__c,Group1Price__c,Group2Price__c,Group3Price__c,Group4Price__c,Group5Price__c,Group6Price__c,Group7Price__c, Group8Price__c, Group9Price__c, Group10Price__c,Group1Cost__c,Group2Cost__c,Group3Cost__c,Group4Cost__c,Group5Cost__c,Group6Cost__c,Group7Cost__c,Group8Cost__c,Group9Cost__c,Group10Cost__c, IsProductGroup__c,InitialPriceSet__c ,RefreshManualPrices__c, WorldWideDiscount__c,SBQQ__Hidden__c,GroupNet__c,GroupDiscount__c,ZoneNet__c,ZoneDiscount__c,ParentProduct2Id__c,SBQQ__Number__c,RefreshPurchaseHistory__c,SBQQ__OptionLevel__c,SBQQ__Discount__c,SBQQ__AdditionalDiscountAmount__c,SBQQ__Incomplete__c,Amended_Quote_Line__c,SBQQ__SubscriptionTerm__c,SBQQ__MarkupRate__c,SBQQ__MarkupAmount__c ,Product_Already_Exist_in_Master_Contract__c,SBQQ__ChargeType__c, SBQQ__AdditionalDiscount__c, SBQQ__AdditionalQuantity__c, SBQQ__AllowAssetRefund__c, SBQQ__BatchQuantity__c, SBQQ__BlockPrice__c, SBQQ__Bundle__c, SBQQ__Bundled__c, SBQQ__BundledQuantity__c, SBQQ__CarryoverLine__c, SBQQ__ComponentCost__c, SBQQ__ComponentDiscountedByPackage__c, SBQQ__ComponentListTotal__c, SBQQ__ComponentSubscriptionScope__c, SBQQ__ComponentUpliftedByPackage__c, SBQQ__ComponentVisibility__c, SBQQ__CompoundDiscountRate__c, SBQQ__ConfigurationRequired__c, SBQQ__ContractedPrice__c, SBQQ__Cost__c, SBQQ__CostEditable__c, SBQQ__CustomerTotal__c, SBQQ__DefaultSubscriptionTerm__c, SBQQ__Description__c, SBQQ__Dimension__c, SBQQ__DiscountSchedule__c, SBQQ__DiscountScheduleType__c, SBQQ__DiscountTier__c, SBQQ__DistributorDiscount__c, SBQQ__DynamicOptionId__c, SBQQ__EarliestValidAmendmentStartDate__c, SBQQ__EffectiveEndDate__c, SBQQ__EffectiveStartDate__c, SBQQ__EffectiveSubscriptionTerm__c, SBQQ__EndDate__c, SBQQ__Favorite__c, SBQQ__GenerateContractedPrice__c, SBQQ__GrossProfit__c, SBQQ__Guidance__c, SBQQ__HasConsumptionSchedule__c, SBQQ__ListTotal__c, SBQQ__Markup__c, SBQQ__MaximumPrice__c, SBQQ__MinimumPrice__c, SBQQ__NetTotal__c, SBQQ__NonDiscountable__c, SBQQ__NonPartnerDiscountable__c, SBQQ__Optional__c, SBQQ__OptionDiscount__c, SBQQ__OptionDiscountAmount__c, SBQQ__OptionType__c, SBQQ__OriginalPrice__c, SBQQ__OriginalQuoteLineId__c, SBQQ__OriginalUnitCost__c, SBQQ__PackageCost__c, SBQQ__PackageListTotal__c, SBQQ__PackageProductCode__c, SBQQ__PackageProductDescription__c, SBQQ__PackageTotal__c, SBQQ__PartnerDiscount__c, SBQQ__PartnerPrice__c, SBQQ__PartnerTotal__c, SBQQ__PreviousSegmentPrice__c, SBQQ__PreviousSegmentUplift__c, SBQQ__PricebookEntryId__c, SBQQ__PriceEditable__c, SBQQ__PricingMethod__c, SBQQ__PricingMethodEditable__c, SBQQ__ProductFamily__c, SBQQ__ProductName__c, SBQQ__ProductSubscriptionType__c, SBQQ__ProratedListPrice__c, SBQQ__ProratedPrice__c, SBQQ__ProrateMultiplier__c, SBQQ__RegularPrice__c, SBQQ__RegularTotal__c, SBQQ__RenewedAsset__c, SBQQ__RenewedSubscription__c, SBQQ__SegmentIndex__c, SBQQ__SegmentKey__c, SBQQ__SegmentLabel__c, SBQQ__Source__c, SBQQ__SpecialPrice__c, SBQQ__SpecialPriceDescription__c, SBQQ__SpecialPriceType__c, SBQQ__StartDate__c, SBQQ__SubscribedAssetIds__c, SBQQ__SubscriptionBase__c, SBQQ__SubscriptionCategory__c, SBQQ__SubscriptionPercent__c, SBQQ__SubscriptionPricing__c, SBQQ__SubscriptionScope__c, SBQQ__SubscriptionTargetPrice__c, SBQQ__SubscriptionType__c, SBQQ__Taxable__c, SBQQ__TaxCode__c, SBQQ__TermDiscount__c, SBQQ__TermDiscountSchedule__c, SBQQ__TermDiscountTier__c, SBQQ__TotalDiscountAmount__c, SBQQ__TotalDiscountRate__c, SBQQ__UnproratedNetPrice__c, SBQQ__UpgradedAsset__c, SBQQ__UpgradedQuantity__c, SBQQ__UpgradedSubscription__c, SBQQ__Uplift__c, SBQQ__UpliftAmount__c,IncludeHelperField__c,Included__c, Base_Net_Price_Selected__c,Revised_Discount_Selected__c';
    public static final String FIELDS_LIST_QLG = 'Id, Name,SBQQ__Number__c,SBQQ__SubscriptionTerm__c,SBQQ__AdditionalDiscountRate__c,SBQQ__MarkupRate__c,SBQQ__Account__c,CurrencyIsoCode,SBQQ__ListTotal__c,SBQQ__CustomerTotal__c,SBQQ__NetTotal__c,SBQQ__TargetCustomerAmount__c,SBQQ__StartDate__c,SBQQ__Source__c,SBQQ__SolutionGroup__c,SBQQ__QuoteProcess__c,SBQQ__Optional__c,SBQQ__Favorite__c,SBQQ__EndDate__c,SBQQ__Description__c,SBQQ__BillingFrequency__c';
    public static final String GROUP_AD_HOK_PRODUCTS = 'Ad hoc Products';
    public static final String GROUP_GASES_REFRIGERANTS = 'Gases & Refrigerants';
    public static final String GROUP_PRODUCTS = 'Products';
    public static final String GROUP_ROPES = 'Ropes';
    public static final String GROUP_STAR_PRODUCTS = 'Star Products';
    
    public class InvalidCloningException extends Exception {}

    @InvocableMethod
    public static void cloneQuoteLines(List<List<Id>> quoteId){
		System.debug('Method Start: CloneQuoteLinesController.cloneQuoteLines');
        try {
            //Retrieve the related Opportunity Id
            Id oppRecordId = [SELECT SBQQ__Opportunity2__r.PreviousOpportunity__c FROM SBQQ__Quote__c WHERE Id =: quoteId.get(0)[0]].SBQQ__Opportunity2__r.PreviousOpportunity__c;
            //Retrieve the related Original Quote
            Id primaryQuoteId = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c =: oppRecordId AND SBQQ__Primary__c=true LIMIT 1].Id;
            //System.debug('Original Oppty: '+oppRecordId+' Related Prim Quote: '+primaryQuoteId);

            //Retrieve the Quote Lines
            String queryQL = 'SELECT ' + FIELDS_LIST + ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: primaryQuoteId';
            List<SBQQ__QuoteLine__c> quoteLinesList = Database.query(queryQL);
            
            if( quoteLinesList.isEmpty()) throw new InvalidCloningException ('There are no Quote lines to be cloned.');

            Map<Id,SBQQ__QuoteLine__c> qlMap = new Map<Id,SBQQ__QuoteLine__c>(quoteLinesList);

            //Query for the Quote.AccountId to pass it to the Product Groups
            Id accId = [SELECT SBQQ__Account__c FROM SBQQ__Quote__c WHERE id =: quoteId[0]].SBQQ__Account__c;

            //Retrieve the Quote Line Groups & clone
            String queryQLG = 'SELECT '+ FIELDS_LIST_QLG + ' FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: primaryQuoteId '; 
            List<SBQQ__QuoteLineGroup__c> quoteLineGroupsList = Database.query(queryQLG);
            //System.debug('Quote Line Group List size: ' + quoteLineGroupsList.size());
                                      
			System.debug('Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

            cloneQuoteLineGroups(quoteLineGroupsList, quoteId.get(0)[0]);

            //Call Batch Class for the cloning
            CloneQuoteLinesBatch myBatchObject = new CloneQuoteLinesBatch(quoteId.get(0)[0], new List<SBQQ__QuoteLine__c>(quoteLinesList));
            Id batchId = Database.executeBatch(myBatchObject, 200);   
            
        } catch (Exception e) {
            throw new InvalidCloningException('Something went wrong: ' + e.getMessage());
        }
    }

    
    /**************************************************************************************
    * @Description  This method clones the product groups for the quote
    * @Param		List<SBQQ__QuoteLineGroup__c> quoteLineGroupsList
                    Id - QuoteId
    * @Return       void
    **************************************************************************************/   
    public static void cloneQuoteLineGroups(List<SBQQ__QuoteLineGroup__c> quoteLineGroupsList, Id quoteId){
		try {
            List<SBQQ__QuoteLineGroup__c> qlgListToCreate = new List<SBQQ__QuoteLineGroup__c>();
            for(SBQQ__QuoteLineGroup__c qlg : quoteLineGroupsList) {
                //create the clone and update the Quote Id with the primary Quote
                SBQQ__QuoteLineGroup__c clonedQLG = qlg.clone(false, false, false, false);
                clonedQLG.SBQQ__Quote__c = (Id)quoteId;
                qlgListToCreate.add(clonedQLG);
            }

            //Update SBQQ__LineItemsGrouped__c on quote as true
            SBQQ__Quote__c currentQuote= [SELECT Id, SBQQ__LineItemsGrouped__c FROM SBQQ__Quote__c WHERE ID =: quoteId];
            currentQuote.SBQQ__LineItemsGrouped__c = true;
            update currentQuote;
            //System.debug('SBQQ__LineItemsGrouped__c '+currentQuote.SBQQ__LineItemsGrouped__c);

            if(qlgListToCreate.size()>0) insert qlgListToCreate;
            else{
                throw new InvalidCloningException('There has been an error while cloning the Quote Line Groups. Please contact the System Administrator.');
            }   
            //System.debug('**Total Groups Cloned ' + qlgListToCreate.size());            
        } catch (InvalidCloningException e) {
            System.debug('CloneQuoteLinesController error' + e.getMessage());
            System.debug('CloneQuoteLinesController error stack' + e.getStackTraceString());        
        }
        
    }
}