/*************************************************
* Class                 : CustomerContractIntegrationHelper
* References            : CustomerContractIntegration.cls
* Description           : This is the helper class for CustomerContractIntegration.cls
*                           This class handles the process of generating request body from different records
* Change Log    
* Date Modified     Modified By         Description of the update
* [10.Aug.2020]     [Lokesh - Fluido]   [Initial development]
* [02.Jul.2021]     [Niki - Fluido]     [Add Rebate and SPG Thresholds]
*************************************************/
public with sharing class CustomerContractIntegrationHelper{
    
    //public static Map<Id, Map<Id, Set<String>>> quoteWithQlAndPricingZones = new Map<Id, Map<Id, Set<String>>>();
    public static Map<Id, Map<String, Set<String>>> quoteWithKeyPortsMap = new Map<Id, Map<String, Set<String>>>();
    public static Map<String, String> kpFieldsMap = new Map<String, String>{'KP1Price__c'=>'Tier 1', 'KP2Price__c'=>'Tier 2', 'KP3Price__c'=>'Tier 3'};
    public static Map<String, Map<String,Schema.SObjectField>> fieldLabelsByObject = new Map<String, Map<String,Schema.SObjectField>>();

    /**************************************************************************************
     * @Description  Helper method for CustomerContractIntegration.cls
     *               This method query the quote related to the contract 
     * @Param		 contractId - the contract id
     * @Return       Map<Id, SBQQ__Quote__c> - the quote related contract 
     **************************************************************************************/ 
    public static Map<Id, SBQQ__Quote__c> getSplOfferOpptyQuotes(Id contractId) {
        return new Map<Id, SBQQ__Quote__c>([
            SELECT Id, CurrencyIsoCode, CreatedDate, SBQQ__Opportunity2__c, SBQQ__Account__c,
                SBQQ__Opportunity2__r.Related_Contract__c, LastModifiedDate, Name, SBQQ__StartDate__c, SBQQ__ExpirationDate__c,
                (SELECT Name, SBQQ__Discount__c, SBQQ__Quantity__c, SBQQ__ProductCode__c, KP1Price__c, KP2Price__c, KP3Price__c, Final_base_net_price__c,
                    SBQQ__Product__r.IsProductGroup__c, Final_Discount__c,Revised_Discount__c,Ropes_Revised_Discount__c,Ropes_Discount_Formula__c,Product_Discount_Group__c,
                    SBQQ__StartDate__c, IsProductGroup__c, SBQQ__Quote__r.SBQQ__StartDate__c,SBQQ__Quote__c,SBQQ__Quote__r.Refrigerant_Bonus__c   
                FROM SBQQ__LineItems__r)
            FROM SBQQ__Quote__c 
            WHERE SBQQ__Opportunity2__r.Related_Contract__c =:contractId 
            AND SBQQ__Opportunity2__r.RecordType.DeveloperName = 'Special_Offer'
            AND SBQQ__StartDate__c <= TODAY AND SBQQ__ExpirationDate__c >= TODAY
        ]);
    }

    @AuraEnabled
    public static SBQQ__Quote__c getOppRecordtypeFromQuote(Id quoteId){
        return [SELECT Opportunity_Record_Type_Name__c, SBQQ__Status__c, Contract_Integrated__c FROM SBQQ__Quote__c WHERE Id =:quoteId];
    }

    @AuraEnabled
    public static Contract getContract(Id contractId){
        return [SELECT Contract_Integrated__c, Status, ActivatedDate, SBQQ__Quote__r.SBQQ__StartDate__c FROM Contract WHERE Id =:contractId];
    }

    /**************************************************************************************
     * @Description  Helper method for CustomerContractIntegration.cls
     *               This method get the contact id related to a the quote passed as a parameter
     * @Param		 quoteId - the quote id
     * @Return       ID - the Id of the contract
     **************************************************************************************/
    public static Id getContractIdFromQuote(Id quoteId) {
        return [SELECT SBQQ__Opportunity2__r.Related_Contract__c FROM SBQQ__Quote__c WHERE Id =:quoteId].SBQQ__Opportunity2__r.Related_Contract__c;
    }

    /**************************************************************************************
     * @Description  Helper method for CustomerContractIntegration.cls
     *               This method will get query the necessary information related to the contract and generate the intital body structure
     * @Param		 List<Id> contractIds - the contracts id's to generate the body of the integration
     * @Return       Map<Id, CustomerContractBodyWrapper> - body of the integration with related contact id as a key
     **************************************************************************************/
    public static Map<Id, CustomerContractBodyWrapper> generateBody(List<Id> contractIds) {
        Map<Id, CustomerContractBodyWrapper> contractIdToBodyMap = new Map<Id, CustomerContractBodyWrapper>();
        Map<Id,Id> contractIdOppIdMap = new Map<Id,Id>();
        Map<Id,Id> oppIdQuoteIdMap = new Map<Id,Id>();
        Map<Id,Id> quoteIdBonusAgreementId = new Map<Id,Id>();
        Map<Id, List<ContractParty__c>> oppIdContractPartiesMap = new Map<Id, List<ContractParty__c>>();

        //query the contact with related Applies_to_Sub_Accounts__r recoreds
        List<Contract > contractList = [SELECT Id, ContractNumber, CurrencyIsoCode,CreatedDate, LastModifiedDate, ActivatedDate,
                                            EndDate, Name, AccountId,Account.Account_Number__c, SBQQ__Opportunity__c, 
                                            SBQQ__Opportunity__r.No_of_Ships_Targeted__c, SBQQ__Opportunity__r.Portifolio_Rebate_included__c,
                                            (SELECT Id, Name, CurrencyIsoCode, Customer_Sub_Account__c, Customer_Sub_Account__r.Account_Number__c, Activation_Date__c,CreatedDate, To_Date__c 
                                             FROM Applies_to_Sub_Accounts__r)
                                        FROM Contract WHERE Id =: contractIds];
        //map the contact id with related opportunity id
        for (Contract contract: contractList) {
            contractIdOppIdMap.put(contract.Id, contract.SBQQ__Opportunity__c);
        }

        //query the opportunities(with contract parties and quotes) related to the contract  
        for (Opportunity opp: [SELECT Id, Name, 
                                (SELECT Id, Name, CurrencyIsoCode, Account__r.CurrencyIsoCode, Account__c, CreatedDate, Activation_Date__c, Expiration_Date__c 
                                    FROM Contract_Parties__r),
                                (SELECT Id, BonusAgreement__c FROM SBQQ__Quotes2__r WHERE SBQQ__StartDate__c <= TODAY AND SBQQ__ExpirationDate__c >= TODAY order by SBQQ__Primary__c asc) 
                                FROM Opportunity WHERE Id IN: contractIdOppIdMap.values()]) {
            for (SBQQ__Quote__c quote: opp.SBQQ__Quotes2__r) {
                //map the opportunity and it's active quote
                oppIdQuoteIdMap.put(opp.Id, quote.Id);
                //if quote has bonus Agreement the map the value
                if(quote.BonusAgreement__c != null) {
                    quoteIdBonusAgreementId.put(quote.Id, quote.BonusAgreement__c);
                }
            }

            //map the oppotunty id with related contract parties
            oppIdContractPartiesMap.put(opp.Id, opp.Contract_Parties__r);
        }

        //query bonus Agreement records related to the opportunity related quote
        Map<Id, BonusAgreement__c> bonusAgreementMap = new Map<Id, BonusAgreement__c>([SELECT Id, Sales_Product_Group__c, Tier1Limit__c, Tier1Bonus__c, Tier2Limit__c, Tier2Bonus__c, 
                                                                                        Tier3Limit__c, Tier3Bonus__c, RopesBonus__c, Ropes_Product_Groups_New__c
                                                                                        FROM BonusAgreement__c WHERE Id IN: quoteIdBonusAgreementId.values()]);
        //if the Opp is Contractual, only get the quote lines where included=true. else retrieve all
        Set<Id> relatedOppList = oppIdQuoteIdMap.keySet();
        String currentOppRT;
        if(!relatedOppList.isEmpty()) {
            Id oppId = null;
            for (Id setElement : relatedOppList) {
                oppId = setElement;
                break;
            }
            currentOppRT = [SELECT RecordType.DeveloperName FROM Opportunity WHERE Id =: oppId].RecordType.DeveloperName;
        }
        Map<Id, SBQQ__Quote__c > quoteIdQuoteMap = new Map<Id, SBQQ__Quote__c >();
        if(currentOppRT == 'PoC_Opportunity') {
            //query the quote with related quote lines where included = true
            quoteIdQuoteMap = new Map<Id, SBQQ__Quote__c > ([SELECT Id, CurrencyIsoCode, CreatedDate,SBQQ__Opportunity2__c, Purchasing_Alliance_Discount__c,
                                                            Purchasing_Alliance_Discount__r.Purchasing_Alliance_Bonus__c, Ship_Manager__c,
                                                            LastModifiedDate, Name, SBQQ__StartDate__c, SBQQ__ExpirationDate__c, SBQQ__Account__c, 
                                                                (SELECT Name, SBQQ__Discount__c, SBQQ__Quantity__c, SBQQ__ProductCode__c, KP1Price__c, KP2Price__c, KP3Price__c, Final_base_net_price__c,
                                                                    SBQQ__Product__r.IsProductGroup__c, SBQQ__Product__r.Product_Discount_Group__c, Final_Discount__c,Revised_Discount__c,Ropes_Revised_Discount__c,SBQQ__Quote__r.Refrigerant_Bonus__c,   
                                                                    SBQQ__StartDate__c, IsProductGroup__c, SBQQ__Quote__r.SBQQ__StartDate__c , SBQQ__Quote__c ,Ropes_Discount_Formula__c,Product_Discount_Group__c
                                                                FROM SBQQ__LineItems__r // WHERE Included__c = TRUE
                                                                ) 
                                                            FROM SBQQ__Quote__c WHERE Id IN: oppIdQuoteIdMap.values()]);
            System.debug('quoteIdQuoteMap filtered ' + quoteIdQuoteMap);
        } else {
            //query the quote with related quote lines
            quoteIdQuoteMap = new Map<Id, SBQQ__Quote__c > ([SELECT Id, CurrencyIsoCode, CreatedDate,SBQQ__Opportunity2__c, Purchasing_Alliance_Discount__c,
                                                            Purchasing_Alliance_Discount__r.Purchasing_Alliance_Bonus__c, Ship_Manager__c,
                                                            LastModifiedDate, Name, SBQQ__StartDate__c, SBQQ__ExpirationDate__c, SBQQ__Account__c, 
                                                                (SELECT Name, SBQQ__Discount__c, SBQQ__Quantity__c, SBQQ__ProductCode__c, KP1Price__c, KP2Price__c, KP3Price__c, Final_base_net_price__c,
                                                                    SBQQ__Product__r.IsProductGroup__c, SBQQ__Product__r.Product_Discount_Group__c, Final_Discount__c,Revised_Discount__c,Ropes_Revised_Discount__c,SBQQ__Quote__r.Refrigerant_Bonus__c,   
                                                                    SBQQ__StartDate__c, IsProductGroup__c, SBQQ__Quote__r.SBQQ__StartDate__c , SBQQ__Quote__c ,Ropes_Discount_Formula__c,Product_Discount_Group__c
                                                                    FROM SBQQ__LineItems__r
                                                                    ) 
                                                            FROM SBQQ__Quote__c WHERE Id IN: oppIdQuoteIdMap.values()]);
            System.debug('quoteIdQuoteMap' + quoteIdQuoteMap);
        }
        
        generateKeyPortDetails(quoteIdQuoteMap.KeySet());
        for (Contract contract: contractList) {
            CustomerContractBodyWrapper body = new CustomerContractBodyWrapper();
            addInitialValuesToBody(body);
            addContractInfoToBody(body, contract);                              //adding contract information to body
            addSubDealsInfoToBody(body, contract.Applies_to_Sub_Accounts__r);   //Sub_Deal__c information - customers[] 
            if (quoteIdQuoteMap.get(oppIdQuoteIdMap.get(contract.SBQQ__Opportunity__c)) != null) {
                //get th active quote related to the contract
                SBQQ__Quote__c quote = quoteIdQuoteMap.get(oppIdQuoteIdMap.get(contract.SBQQ__Opportunity__c));

                //validate the quote start_Date__c should be within the contract activte and end date
                validateQuoteData(quote, contract);

                //add bonus percentage if applicable
                if(quote.Purchasing_Alliance_Discount__c != null) {
                    body.data.customerBonus.brokerageFee.bonusPercentage = quote.Purchasing_Alliance_Discount__r.Purchasing_Alliance_Bonus__c;
                }

                Id bonusAgreeId = quoteIdBonusAgreementId.get(quote.Id);

                //if quote had ship manager enabled then add bonus aggreement
                if(quote.Ship_Manager__c && bonusAgreeId != null) {
                    BonusAgreement__c ba = bonusAgreementMap.get(bonusAgreeId);
                    if(ba != null ){
                        addBonusAgreementInfoToBody(body, ba);
                    }
                }

                addQuoteLinesInfoToBody(body, quote.SBQQ__LineItems__r);        //quotelines information - customerList[]
                //if quote.quantity >0, for each of the mdt label, 
            }
            //Query for all the Rebate Threshold Records & SPG Records
            List<SpgThreshold__c> spgRecords = [SELECT SPGId__c,id,SalesProductGroupName__c,SalesProductGroupId__c,Amount__c,CurrencyCode__c  FROM SpgThreshold__c];
            List<RebateThreshold__c> rTRecords = [SELECT Id, RebatePercentage__c, RebateThresholdId__c, SalesProductGroupCount__c FROM RebateThreshold__c];
            addSPGandRebateThresholds(body, rTRecords, spgRecords, contractIds) ;

            contractIdToBodyMap.put(contract.Id, body);
        }
        return contractIdToBodyMap;
    }

    /**************************************************************************************
     * @Description  Helper method for generateBody method
     *               This method will initial the CustomerContractBodyWrapper values
     * @Param		 body - the structure of the request body
     * @Return       void
     **************************************************************************************/ 
    public static void addInitialValuesToBody(CustomerContractBodyWrapper body) {
        body.eventTime = getFormatedDate(System.now());
        body.eventType = 'sales.customercontract.created';
        body.subject = 'sales/customercontract';
        body.dataVersion = '1';
        body.topic = 'customercontract';
        body.data = new CustomerContractBodyWrapper.Data();
        body.data.customerBonus = new CustomerContractBodyWrapper.CustomerBonus();
        body.data.customerBonus.brokerageFee = new CustomerContractBodyWrapper.BrokerageFee();
        body.data.customers = new List<CustomerContractBodyWrapper.Customers>();
        body.data.contractLines = new List<CustomerContractBodyWrapper.ContractLines>();
        body.data.specialCommitmentOffer = new List<CustomerContractBodyWrapper.SpecialCommitmentOffer>();
        body.data.customerBonus.portfolioRebateScheme = new CustomerContractBodyWrapper.PortfolioRebateScheme();
        body.data.customerBonus.portfolioRebateScheme.rebateThresholds = new List<CustomerContractBodyWrapper.RebateThresholds>();
        body.data.customerBonus.portfolioRebateScheme.spgThresholds = new List<CustomerContractBodyWrapper.SpgThresholds_z>();
    }

    /**************************************************************************************
     * @Description  Helper method for generateBody method
     *               This method will add the contract information to the request body
     * @Param		 body - the structure of the request body
     * @Param		 contract - contract to add in the request body
     * @Return       void
     **************************************************************************************/ 
    public static void addContractInfoToBody(CustomerContractBodyWrapper body, Contract contract) {
        
        //validate if all key information's is not null
        validateRequiredFields(contract);
        
        //contract information 
        body.id = String.valueOf(contract.Name + ' ' +body.eventTime).deleteWhitespace();
        body.data.contractNumber = contract.ContractNumber;
        body.data.currencyId = contract.CurrencyIsoCode;
        body.data.createdOn = getFormatedDate(contract.CreatedDate);
        body.data.modifiedOn = getFormatedDate(contract.LastModifiedDate);
        body.data.activeOn = getFormatedDate(contract.ActivatedDate);
        body.data.expiresOn = getFormatedDate(contract.EndDate);
        body.data.title = contract.Name;
        body.data.accountId = contract.Account.Account_Number__c;
        body.data.contractedFleet = Integer.valueOf(contract.SBQQ__Opportunity__r.No_of_Ships_Targeted__c);
        body.data.customerBonus.applicableForRebateScheme = contract.SBQQ__Opportunity__r.Portifolio_Rebate_included__c == 'Yes' ? true : false;

        Contract contrInfo = [SELECT id, name, SBQQ__Opportunity__r.Related_Contract__r.ContractNumber, SBQQ__Quote__r.New_Parties_Added__c,SBQQ__Quote__r.Opportunity_Record_Type_Name__c FROM Contract WHERE Id =: contract.Id];
        //added 14.10 
        body.data.customerBonus.oppRecType = contrInfo.SBQQ__Quote__r.Opportunity_Record_Type_Name__c;
        body.data.customerBonus.newPartiesAdded = contrInfo.SBQQ__Quote__r.New_Parties_Added__c;
        body.data.customerBonus.relatedContr = contrInfo.SBQQ__Opportunity__r.Related_Contract__r.ContractNumber;
    }

    /**************************************************************************************
     * @Description  Helper method for generateBody method
     *               This method will add the sub_Deal__c(relaated to main contract) info to the request body
     * @Param		 body - the structure of the request body
     * @Param		 subDeals - the sub_Deal__c records related to the main contract in the request body
     * @Return       void
     **************************************************************************************/ 
    public static void addSubDealsInfoToBody(CustomerContractBodyWrapper body, List<Sub_Deal__c> subDeals) {
        //Sub_Deal__c information
        for (Sub_Deal__c subDeal: subDeals) {
            //validate if all key information's is not null
            validateRequiredFields(subDeal);

            CustomerContractBodyWrapper.Customers customer = new CustomerContractBodyWrapper.Customers();
            customer.currencyId = subDeal.CurrencyIsoCode;
            customer.customerId = subDeal.Customer_Sub_Account__r.Account_Number__c;
            customer.activeOn = getFormatedDate(subDeal.Activation_Date__c);
            customer.createdOn = getFormatedDate(subDeal.CreatedDate);
            customer.expiresOn = getFormatedDate(subDeal.To_Date__c);

            body.data.customers.add(customer);
        }
    }

   /**************************************************************************************
     * @Description  Helper method for generateBody method
     *               This method will add all tier limit & bonus values from bonusagreement__c to request body
     *               also we will add ropes bonus value from bonusagreement__c to request body
     * @Param		 body - the structure of the request body
     * @Param		 ba - BonusAgreement__c record related to active quote of the main contract
     * @Return       void
     **************************************************************************************/ 
    public static void addBonusAgreementInfoToBody(CustomerContractBodyWrapper body, BonusAgreement__c ba) {
        body.data.customerBonus.shipManagerBonus = new CustomerContractBodyWrapper.ShipManagerBonus();
        addSpgsThresHolds(body, ba);
        addProductGroupThresholds(body, ba);
    }

    /**************************************************************************************
     * @Description  Helper method for generateBody method
     *               This method will add all tier limit & bonus values from bonusagreement__c(relaated to main contract->opportunity->quote) to request body
     * @Param		 body - the structure of the request body
     * @Param		 ba - BonusAgreement__c record related to active quote of the main contract
     * @Return       void
     **************************************************************************************/ 
    public static void addSpgsThresHolds(CustomerContractBodyWrapper body, BonusAgreement__c ba) {
        List<CustomerContractBodyWrapper.SpgThresholds> spgThresholds = new List<CustomerContractBodyWrapper.SpgThresholds>();
        CustomerContractBodyWrapper.SpgThresholds spgThreshold = new CustomerContractBodyWrapper.SpgThresholds();

        List<String> spgsList = ba.Sales_Product_Group__c != null ? ba.Sales_Product_Group__c.split(';') : new List<String>();
        spgThreshold.spgs = new List<String>();
        
        //get the spgs related is value from the custom setting Sales_Prod_Group_Map__c
        for(String spgs : spgsList) {
            Sales_Prod_Group_Map__c salesGroup = Sales_Prod_Group_Map__c.getInstance(spgs);
            if(salesGroup == null) {
                throw new CustomException('Please add the the following sales product group(\"'+ spgs +'\") and its related ID value in the custom setting \"Sales_Prod_Group_Map__c\"');
            } else {
                spgThreshold.spgs.add(salesGroup.Group_Id__c);
            }
        }

        //add tier 1 detials
        CustomerContractBodyWrapper.Thresholds tier1Threshold = new CustomerContractBodyWrapper.Thresholds();
        tier1Threshold.lowAmount = ba.Tier1Limit__c;
        tier1Threshold.bonusPercentage = ba.Tier1Bonus__c;

        //add tier 2 detials
        CustomerContractBodyWrapper.Thresholds tier2Threshold = new CustomerContractBodyWrapper.Thresholds();
        tier2Threshold.lowAmount = ba.Tier2Limit__c;
        tier2Threshold.bonusPercentage = ba.Tier2Bonus__c;

        //add tier 3 detials
        CustomerContractBodyWrapper.Thresholds tier3Threshold = new CustomerContractBodyWrapper.Thresholds();
        tier3Threshold.lowAmount = ba.Tier3Limit__c;
        tier3Threshold.bonusPercentage = ba.Tier3Bonus__c;

        //add it to spgs thresholds
        spgThreshold.thresholds = new List<CustomerContractBodyWrapper.Thresholds>{tier1Threshold, tier2Threshold, tier3Threshold};

        //group the spgs threshold
        spgThresholds.add(spgThreshold);

        //add the information to body
        body.data.customerBonus.shipManagerBonus.spgThresholds = spgThresholds;
    }

    /**************************************************************************************
     * @Description  Helper method for generateBody method
     *               This method will add ropes bonus value values from bonusagreement__c(relaated to main contract->opportunity->quote) to request body
     * @Param		 body - the structure of the request body
     * @Param		 ba - BonusAgreement__c record related to active quote of the main contract
     * @Return       void
     **************************************************************************************/ 
    public static void addProductGroupThresholds(CustomerContractBodyWrapper body, BonusAgreement__c ba) {
        List<CustomerContractBodyWrapper.ProductGroupThresholds> productGroupThresholds = new List<CustomerContractBodyWrapper.ProductGroupThresholds>();
        CustomerContractBodyWrapper.productGroupThresholds productGroupThreshold = new CustomerContractBodyWrapper.productGroupThresholds();

        //if Ropes_Product_Groups_New__c on bonusagreement is null, then skip adding null values to body
        if(ba.Ropes_Product_Groups_New__c != null && !String.isBlank(ba.Ropes_Product_Groups_New__c)) {
            productGroupThreshold.productGroupIds = ba.Ropes_Product_Groups_New__c.split(';');

            //add ropes 1 detials
            CustomerContractBodyWrapper.Thresholds ropeThresHold = new CustomerContractBodyWrapper.Thresholds();
            ropeThresHold.bonusPercentage = ba.RopesBonus__c;

            //add it to thresholds
            productGroupThreshold.thresholds = new List<CustomerContractBodyWrapper.Thresholds>{ropeThresHold};

            //group the prod groupd threshold
            productGroupThresholds.add(productGroupThreshold);
        }

        //add the information to body
        body.data.customerBonus.shipManagerBonus.productGroupThresholds = productGroupThresholds;
    }
    /**************************************************************************************
     * @Description  Helper method for generateBody method
     *               This method adds the rebate and spg thresholds to the request body
     * @Param		 body - the structure of the request body
     * @Param		 rebateThList all the rebate thresholds in the db & spgThList all the spg thresholds in the db
     * @Return       void
     **************************************************************************************/ 
    public static void addSPGandRebateThresholds(CustomerContractBodyWrapper body, List<RebateThreshold__c> rebateThList, List<SPGThreshold__c> spgThList, List<Id> contrIds){
        //Built the Rebate Threshold
        List<CustomerContractBodyWrapper.RebateThresholds> rebateThresholds = new List<CustomerContractBodyWrapper.RebateThresholds>(); 
        for(RebateThreshold__c rt : rebateThList) {
            CustomerContractBodyWrapper.RebateThresholds rebateThreshold = new CustomerContractBodyWrapper.RebateThresholds(); 
            rebateThreshold.id = rt.RebateThresholdId__c;
            rebateThreshold.rebatePercentage = rt.RebatePercentage__c;
            rebateThreshold.salesProductGroupCount = rt.SalesProductGroupCount__c;

            rebateThresholds.add(rebateThreshold);
        }
        body.data.customerBonus.portfolioRebateScheme.rebateThresholds = rebateThresholds;
        body.data.customerBonus.portfolioRebateScheme.minimumSales = 50000;

        //Built the SPG Threshold
        //07.09 i am commenting out this spg integration for now. It has been decided that it will not used soon, but the below logic is applicable for now
        /*List<CustomerContractBodyWrapper.SpgThresholds_z> spgThresholds = new List<CustomerContractBodyWrapper.SpgThresholds_z>(); 
        for(SPGThreshold__c spg : spgThList) {
            CustomerContractBodyWrapper.SpgThresholds_z spgThreshold = new CustomerContractBodyWrapper.SpgThresholds_z(); 
            spgThreshold.id = spg.SPGId__c;
            spgThreshold.amount = spg.Amount__c;
            spgThreshold.currencyCode = spg.CurrencyCode__c;
            spgThreshold.salesProductGroupId = spg.SalesProductGroupId__c;
            spgThreshold.salesProductGroupName = spg.SalesProductGroupName__c;

            spgThresholds.add(spgThreshold);       
        }
        body.data.customerBonus.portfolioRebateScheme.spgThresholds = spgThresholds;
        */

        //delete these lines when they decide the integration should be used
        List<CustomerContractBodyWrapper.SpgThresholds_z> spgThresholds = new List<CustomerContractBodyWrapper.SpgThresholds_z>(); 
        Decimal ships = [SELECT SBQQ__Opportunity__r.No_of_Ships_Targeted__c FROM Contract WHERE Id =: contrIds].SBQQ__Opportunity__r.No_of_Ships_Targeted__c;
        for(SPGThreshold__c spg : spgThList) {
            CustomerContractBodyWrapper.SpgThresholds_z spgThreshold = new CustomerContractBodyWrapper.SpgThresholds_z(); 
            //spgThreshold.id = spg.SPGId__c; this attribute is not needed any more. i have removed it from the wrapper, but the field is still there in case it is needed for the future 22.10
            spgThreshold.currencyCode = spg.CurrencyCode__c;
            spgThreshold.salesProductGroupId = spg.SalesProductGroupId__c;
            spgThreshold.salesProductGroupName = spg.SalesProductGroupName__c;

            //set the final amount based on the spgId , which depends on the formula fields on Quote Obj
            if(spg.SalesProductGroupId__c=='SG330' || spg.SalesProductGroupId__c=='SG320' ) spgThreshold.amount = ships * 300;
            else if(spg.SalesProductGroupId__c=='SG360' || spg.SalesProductGroupId__c=='SG520' || spg.SalesProductGroupId__c=='SG220' || spg.SalesProductGroupId__c=='SG610') spgThreshold.amount = ships * 1000;
            else if(spg.SalesProductGroupId__c=='SG310' || spg.SalesProductGroupId__c=='SG510' || spg.SalesProductGroupId__c=='SG210' || spg.SalesProductGroupId__c=='SG420' || spg.SalesProductGroupId__c=='SG410' || spg.SalesProductGroupId__c=='SG230') spgThreshold.amount = ships * 500;
            spgThresholds.add(spgThreshold);    

        }
        body.data.customerBonus.portfolioRebateScheme.spgThresholds = spgThresholds;

    }
    /**************************************************************************************
     * @Description  Helper method for generateBody method
     *               This method quoteline info to the request body
     * @Param		 body - the structure of the request body
     * @Param		 quoteLines - SBQQ__Quoteline__c records related to the active quote of the main contract
     * @Return       vlid
     **************************************************************************************/ 
    public static void addQuoteLinesInfoToBody(CustomerContractBodyWrapper body, List<SBQQ__QuoteLine__c> quoteLines) {
        //02.06.2021 Added: For the Refrigerant products a discount should be applied to the final List Price Unit
        List<RefrigerantsDiscount__mdt> retrievedMDT = new List<RefrigerantsDiscount__mdt>();
        retrievedMDT = [SELECT id, MasterLabel,ProductName__c FROM RefrigerantsDiscount__mdt];

        List<String> refrigerantCodes = new List<String>();
        for(RefrigerantsDiscount__mdt refrigerantCode : retrievedMDT) {
            refrigerantCodes.add(refrigerantCode.MasterLabel);
        }
        System.debug('** Custom MDT Records: '+refrigerantCodes);
        Decimal refrigerantsBon = 0 ;
        Date quoteStartDate;
        for (SBQQ__QuoteLine__c quoteLine: quoteLines) {
            //if quote line is product group, but not ropes, and final discount is 0, then skip that quote line
            if(quoteLine.SBQQ__Product__r.IsProductGroup__c && quoteLine.Final_Discount__c == 0 && quoteLine.SBQQ__Product__r.Product_Discount_Group__c!='Ropes') {
                continue;
            }
            //Apply the discount if product is refrigerant 
            if( refrigerantCodes.size()>0 && refrigerantCodes.contains(quoteLine.SBQQ__ProductCode__c)  && quoteLine.SBQQ__ListPrice__c!=null) {
                System.debug('**ProductCode '+quoteLine.SBQQ__ProductCode__c);
                System.debug('**Refrigerant Bonus '+quoteLine.SBQQ__Quote__r.Refrigerant_Bonus__c);
                System.debug('**Refrigerant QTY '+quoteLine.SBQQ__Quote__r.PHB_Refrigerants_Qty__c);
                System.debug('**List Price Before Discount '+ quoteLine.SBQQ__ListPrice__c);
                quoteLine.SBQQ__ListPrice__c = quoteLine.SBQQ__ListPrice__c - (quoteLine.SBQQ__ListPrice__c * quoteLine.SBQQ__Quote__r.Refrigerant_Bonus__c)/100 ;
                System.debug('**List Price After Discount '+ quoteLine.SBQQ__ListPrice__c);            
            }
            //retrieving qty value to check it below if it is >0
            refrigerantsBon = quoteLine.SBQQ__Quote__r.Refrigerant_Bonus__c;
            quoteStartDate = quoteLine.SBQQ__Quote__r.SBQQ__StartDate__c;
            //get each quote in info with related object structure 
            CustomerContractBodyWrapper.ContractLines contractLine = generateContractLine(quoteLine);
            
            //if the quoteline info is valid then add it to body
            if(contractLine != null) { body.data.contractLines.add(contractLine); }
        }

        //if refrigerantsBon>o, include all the refrigerant products that are in MTD in the payload, but do not insert them
        if(!quoteLines.isEmpty() && refrigerantsBon>0) {
            for(RefrigerantsDiscount__mdt refrigerantsList : retrievedMDT) {
                CustomerContractBodyWrapper.ContractLines contractLine = new CustomerContractBodyWrapper.ContractLines();
                contractLine.productOrGroupNumber = refrigerantsList.MasterLabel;
                contractLine.activeOn = getFormatedDate(quoteStartDate);
                //contractLine.additionalDiscountPercentage = refrigerantsBon;
                contractLine.isProductGroup = false;
                //Built product prices
                contractLine.productPrices = new List<CustomerContractBodyWrapper.ProductPrice>();
                CustomerContractBodyWrapper.ProductPrice prodPrice = new CustomerContractBodyWrapper.ProductPrice();
                prodPrice.validForAllPorts = true;
                prodPrice.discountPercentage = refrigerantsBon;
                contractLine.productPrices.add(prodPrice);

                if(contractLine != null) { body.data.contractLines.add(contractLine); }
            }
        }
    }

    /**************************************************************************************
     * @Description  Helper method for generateBody method
     *               This method will add the specail offer quot details to the request body
     * @Param		 quotesMap - the contract id
     * @Return       void
     **************************************************************************************/ 
    public static void addSplOfferOpptyQuotesToBody(CustomerContractBodyWrapper body, Map<Id, SBQQ__Quote__c> quotesMap) {
        List<CustomerContractBodyWrapper.specialCommitmentOffer> specialCommitmentOffer = new List<CustomerContractBodyWrapper.specialCommitmentOffer>();
        //formQuoteWithLineItems(quotesMap);  
        generateKeyPortDetails(quotesMap.KeySet());

        Set<Id> specailOfferOppIds = new Set<Id>();
        for(SBQQ__Quote__c quote : quotesMap.values()) {
            specailOfferOppIds.add(quote.SBQQ__Opportunity2__c);
        }
        Map<Id, List<ContractParty__c>> oppIdContractPartiesMap = new Map<Id, List<ContractParty__c>>();
        for (Opportunity opp: [SELECT Id, Name, 
                                (SELECT Id,Name,Account__r.CurrencyIsoCode,Account__r.Account_Number__c ,Account__c, CreatedDate, Activation_Date__c, Expiration_Date__c 
                                 FROM Contract_Parties__r),
                                (SELECT Id FROM SBQQ__Quotes2__r WHERE SBQQ__StartDate__c <= TODAY AND SBQQ__ExpirationDate__c >= TODAY) 
                               FROM Opportunity WHERE Id IN: specailOfferOppIds]) {
            oppIdContractPartiesMap.put(opp.Id, opp.Contract_Parties__r);
        }
        for(SBQQ__Quote__c quote : quotesMap.values()) {
            //validate if all key information's is not null
            validateRequiredFields(quote);

            CustomerContractBodyWrapper.specialCommitmentOffer specialOffer = new CustomerContractBodyWrapper.specialCommitmentOffer();
            specialOffer.currencyId = quote.CurrencyIsoCode;
            specialOffer.createdOn = getFormatedDate(quote.CreatedDate);
            specialOffer.modifiedOn = getFormatedDate(quote.LastModifiedDate);
            specialOffer.activeOn = getFormatedDate(quote.SBQQ__StartDate__c);
            specialOffer.expiresOn = getFormatedDate(quote.SBQQ__ExpirationDate__c);
            specialOffer.title = quote.Name;
            specialOffer.accountId = quote.SBQQ__Account__c;
            specialOffer.commitmentId = quote.Name;

            List<CustomerContractBodyWrapper.Customers> specialOfferCustomers = new List<CustomerContractBodyWrapper.Customers>();
             
            for(ContractParty__c cp : oppIdContractPartiesMap.get(quote.SBQQ__Opportunity2__c)) {
                //validate if all key information's is not null
                validateRequiredFields(cp);

                CustomerContractBodyWrapper.Customers cust = new CustomerContractBodyWrapper.Customers();
                cust.currencyId = cp.Account__r.CurrencyIsoCode;
                cust.customerId = cp.Account__r.Account_Number__c;
                cust.createdOn = getFormatedDate(cp.CreatedDate);
                cust.expiresOn = getFormatedDate(cp.Expiration_Date__c);
                cust.activeOn = getFormatedDate(cp.Activation_Date__c);
                specialOfferCustomers.add(cust);
            }
            specialOffer.customers = specialOfferCustomers;

            List<CustomerContractBodyWrapper.ContractLines> specialOfferCustomerLines = new List<CustomerContractBodyWrapper.ContractLines>();

            for (SBQQ__QuoteLine__c quoteLine: quote.SBQQ__LineItems__r) {
            //if quote line is product group, but not ropes, and final discount is 0, then skip that quote line
                if(quoteLine.SBQQ__Product__r.IsProductGroup__c && quoteLine.Final_Discount__c == 0 && quoteLine.SBQQ__Product__r.Product_Discount_Group__c!='Ropes') {
                    continue;
                }
                //get each quote in info with related object structure 
                CustomerContractBodyWrapper.ContractLines contractLine = generateContractLine(quoteLine);
                
                //if the quoteline info is valid then add it to body
                if(contractLine != null) { specialOfferCustomerLines.add(contractLine); }
            }
            specialOffer.contractLines = specialOfferCustomerLines;
            specialCommitmentOffer.add(specialOffer);
        }
        body.data.specialCommitmentOffer = specialCommitmentOffer;
    } 


    public static CustomerContractBodyWrapper.ContractLines generateContractLine(SBQQ__QuoteLine__c quoteLine) {
        //validate if all key information's is not null
        validateRequiredFields(quoteLine);

        CustomerContractBodyWrapper.ContractLines contractLine = new CustomerContractBodyWrapper.ContractLines();
        contractLine.additionalDiscountPercentage = quoteLine.Revised_Discount__c == null ? quoteLine.Revised_Discount__c : quoteLine.Ropes_Revised_Discount__c;
        contractLine.qty = Integer.valueOf(quoteLine.SBQQ__Quantity__c);
        contractLine.productOrGroupNumber = quoteLine.SBQQ__ProductCode__c;
        contractLine.activeOn = getFormatedDate(quoteLine.SBQQ__Quote__r.SBQQ__StartDate__c);
        contractLine.IsproductGroup = quoteLine.SBQQ__Product__r.IsProductGroup__c;
        contractLine.productPrices = new List<CustomerContractBodyWrapper.ProductPrice>();

        //add product pirce details based on the keyports selected
        Boolean kpFieldsNotFilled = true;
        for(String field : kpFieldsMap.keySet()) {
            CustomerContractBodyWrapper.ProductPrice prodPrice = new CustomerContractBodyWrapper.ProductPrice();
            if(quoteLine.get(field) != null) {
                Map<String, Set<String>> keyGroupAndPorts = quoteWithKeyPortsMap.get(quoteLine.SBQQ__Quote__c);
                if(keyGroupAndPorts != null) {
                    Set<String> ports = keyGroupAndPorts.get(kpFieldsMap.get(field));
                    if(ports != null) {
                        kpFieldsNotFilled = false;
                        prodPrice.productPrice = (Decimal)quoteLine.get(field);
                        prodPrice.validForAllPorts = false;
                        prodPrice.validPorts = ports;
                        prodPrice.discountPercentage = null;
                        contractLine.productPrices.add(prodPrice);
                    }
                }
            }
        }
        
        //if no ports are selected for prices
        if(kpFieldsNotFilled) {
            //if quote Final_Discount__c and Final_base_net_price__c is 0, then skip adding that quote line info
            if((quoteLine.Final_Discount__c == 0 || quoteLine.Final_Discount__c  == null) && (quoteLine.Final_base_net_price__c == 0 || quoteLine.Final_base_net_price__c == null) && quoteLine.Product_Discount_Group__c != 'Ropes') {
                contractLine = null;
            } else {
                CustomerContractBodyWrapper.ProductPrice prodPrice = new CustomerContractBodyWrapper.ProductPrice();
                prodPrice.validForAllPorts = true;
                
                if(quoteLine.Final_base_net_price__c == 0 || quoteLine.Final_base_net_price__c == null) {
                    prodPrice.productPrice = null;
                    if (quoteLine.Product_Discount_Group__c == 'Ropes') {
                        prodPrice.discountPercentage = quoteLine.Ropes_Discount_Formula__c; //this works only for ropes product group
                    }else if(quoteLine.Product_Discount_Group__c == 'Ad hoc Products' || quoteLine.Product_Discount_Group__c == 'Gases & Refrigerants' ||
                        quoteLine.Product_Discount_Group__c == 'Products' || quoteLine.Product_Discount_Group__c == 'Star Products'){

                        prodPrice.discountPercentage = quoteLine.Final_Discount__c; // this is 0 - and this works only all the rest product groups 
                    }
                } else {
                    prodPrice.productPrice = quoteLine.Final_base_net_price__c;
                    prodPrice.discountPercentage = null;
                }
                contractLine.productPrices.add(prodPrice);
            }
        }

        return contractLine;
    }

    /**************************************************************************************
     * @Description  this method will formate the datetime values to string format
     * @Param		 dt - the datetime value
     * @Return       string
     **************************************************************************************/ 
    public static String getFormatedDate(DateTime dt) {
        if(dt != null) {
            return String.valueOf(dt.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\''));
        }
        return '';
    }

    public static void updateIntegrationStatus(String response,List<Id> contractIds) {
        System.debug('Updating contact ' + contractIds + ' with response  '+ response);
        List<Contract> contractUpdatList = new List<Contract>();
        for(Id id : contractIds) {
            Contract contract = new Contract();
            contract.Id = id;
            contract.Integration_Status__c = response;
            contractUpdatList.add(contract);
        }
        if(contractUpdatList.size() > 0) { update contractUpdatList; }
    }

    public static Map<Id, Map<String, Set<String>>> generateKeyPortDetails(Set<Id> quoteIds) {

        for(KeyPortGroup__c kpg :  [SELECT Id, Quote__c,Key_Port_Group_Tier__c, (SELECT Port__c, Port__r.Port_Code__c, Port__r.Key_Port_Group_Tier__c FROM Key_Ports__r) FROM KeyPortGroup__c WHERE Quote__c =: quoteIds]) {
            Map<String, Set<String>> keyGroupWithPorts = quoteWithKeyPortsMap.get(kpg.Quote__c);
            if(keyGroupWithPorts == null) {
                keyGroupWithPorts = new Map<String, Set<String>>();
                //keyGroupWithPorts.put(kpt.KeyPortGroupType__c, new List<String>());
            }
            for(KeyPort__c kp : kpg.Key_Ports__r) {
                
                Set<String> ports = keyGroupWithPorts.get(kpg.Key_Port_Group_Tier__c);
                if(ports == null) {
                    ports = new Set<String>();
                }
                ports.add(kp.Port__r.Port_Code__c);
                keyGroupWithPorts.put(kpg.Key_Port_Group_Tier__c, ports);
            }
            quoteWithKeyPortsMap.put(kpg.Quote__c, keyGroupWithPorts);
        }
        return quoteWithKeyPortsMap;
    }

    
    public static void validateRequiredFields(sObject sObj) {
        try{
            String objectApiName = String.valueOf(sObj.getSObjectType());
            loadFieldApiNames(objectApiName);
            String allFields = ContractIntegrationRequiredFields__c.getValues(objectApiName).RequiredFields__c;
            if(allFields != null && allFields != '') {
                for(String field : allFields.split(',')) {
                    Boolean error = false;
                    //for relationship fields
                    if(field.contains('.')){
                        List<String> fields = field.split('\\.');
                        if(sObj.getSObject(fields[0]).get(fields[1]) == null || sObj.getSObject(fields[0]).get(fields[1]) == '') {
                            error = true;
                        }
                    }
                    else if(sObj.get(field) == null || sObj.get(field)== '') {
                        error = true;
                    }

                    if(error) {
                        String fieldLabel = field;
                        if(fieldLabelsByObject.get(objectApiName).get(field) != null)
                            fieldLabel = fieldLabelsByObject.get(objectApiName).get(field).getDescribe().getlabel();

                        //don't change this exception message, this is referenced in lwc component - CustomerContractIntegration
                        throw new CustomException('Required field information is missing in '+objectApiName+' , Please fill value for \''+ fieldLabel +'\' and submit again. Record Details : {\"Name\":\"' +sObj.get('Name') +'\",\"Id\":\"'+ sObj.get('Id') + '\"}');
                    }
                }
            }
        } catch(CustomException e){
            throw new CustomException(e.getMessage());
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
       }
    }

     
    public static void loadFieldApiNames(String objectApiName) {
        if(fieldLabelsByObject.get(objectApiName) == null) {
            Map<String,Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
            fieldLabelsByObject.put(objectApiName, fieldsMap);
        }
    }


    //method to check the quote start date that should be betweeen the contract active and end date
    public static void validateQuoteData(SBQQ__Quote__c quote, Contract cntrct) {
        if(quote.SBQQ__StartDate__c < cntrct.ActivatedDate.date() || quote.SBQQ__StartDate__c > cntrct.EndDate) {
            //don't change this exception message, this is referenced in lwc component - CustomerContractIntegration
            throw new CustomException('Following quote \"Active On\" date should be between related contract ('+ cntrct.ContractNumber +') \"Activeated Date\" and \"End Date\". Record Details : {\"Name\": \"' + quote.Name +' \", \"Id\":\"'+ quote.Id + '\"}');
        }
    }
}