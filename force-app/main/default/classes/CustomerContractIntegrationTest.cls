@isTest
public class CustomerContractIntegrationTest {
    public static Map<String,Schema.RecordTypeInfo> accRecordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
	public static Id amendmendQuote_RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Locked Amendment').getRecordTypeId();


    static testMethod void testContractIntegration(){
        
        User u = TestFactory.createTestUser();
        System.runAs(u) {
            SBQQ.TriggerControl.disable();
            SBQQ__Quote__c splQuote = createDataAndReturnQuote(true);
           
            Id contractId = [SELECT Id FROM Contract LIMIT 1].Id;
                       
            Test.startTest();

            HttpMockFactory mock = new HttpMockFactory(200, 'OK', 'Success!', new Map<String,String>());
            Test.setMock(HttpCalloutMock.class, mock);       
            //test case 1 with no error and callout from quote 
            Integer result = CustomerContractIntegration.initiateCalloutFromQuote(splQuote.Id);
            system.assertEquals(200, result);
            CustomerContractIntegration.initiateCalloutFromFlow(new List<Id>{contractId});
            Test.stopTest();

            SBQQ.TriggerControl.enable();
        }
    }
 
    static testMethod void testContractIntegrationWithBadData(){
        User u = TestFactory.createTestUser();
        System.runAs(u) {
            SBQQ.TriggerControl.disable();
            createDataAndReturnQuote(false);
            Contract cntrct = [SELECT Id FROM Contract LIMIT 1];
            Test.startTest();
            HttpMockFactory mock = new HttpMockFactory(500, 'Bad Data', 'Error!', new Map<String,String>());
            Test.setMock(HttpCalloutMock.class, mock);
            Integer result = CustomerContractIntegration.initiateCalloutFromContract(new List<Id>{cntrct.Id});
            system.assertEquals(500, result);
            Test.stopTest();
            SBQQ.TriggerControl.enable();
        }
    }

    static testMethod void testContractIntegrationFromContract(){
        User u = TestFactory.createTestUser();
        System.runAs(u) {
            SBQQ.TriggerControl.disable();

            createDataAndReturnQuote(false);
            Contract cntrct = [SELECT Id FROM Contract LIMIT 1];
            HttpMockFactory mock = new HttpMockFactory(200, 'OK', 'Success!', new Map<String,String>());
            Test.setMock(HttpCalloutMock.class, mock);
			Test.startTest();
            Integer result;
            result = CustomerContractIntegration.initiateCalloutFromContract(new List<Id>{cntrct.Id});
            system.assertEquals(200, result);
            Test.stopTest();
            SBQQ.TriggerControl.enable();
        }
    }
    
    
   public static SBQQ__Quote__c createDataAndReturnQuote(Boolean isSpl) {

        API_Keys__c apikey = new API_Keys__c();
        apikey.Name = 'ContractIntegration';
        apikey.End_Point__c = 'https://wilhelmsen.azure-api.net/pricing';
        apikey.API_key__c = 'wertyuiop3456fghjktyuio';
        insert apikey;

        Trigger_Setting__c quoteTriggerSetting = TestFactory.createTriggerSetting('SBQQ__Quote__c', false);
        quoteTriggerSetting.Disabled__c = true;
        insert quoteTriggerSetting;

        Trigger_Setting__c quoteLineTriggerSetting = TestFactory.createTriggerSetting('SBQQ__QuoteLine__c', false);
        quoteLineTriggerSetting.Disabled__c = true;
        insert quoteLineTriggerSetting;

        Sales_Prod_Group_Map__c salesMap = new Sales_Prod_Group_Map__c(Name='Biochemicals', Group_Id__c = 'test');
        insert salesMap;

        List<ContractIntegrationRequiredFields__c> reqFields = new List<ContractIntegrationRequiredFields__c>();
        ContractIntegrationRequiredFields__c cont = new ContractIntegrationRequiredFields__c(name='Contract', RequiredFields__c='ActivatedDate,Name,SBQQ__Opportunity__r.No_of_Ships_Targeted__c');
        reqFields.add(cont);
        ContractIntegrationRequiredFields__c cont1 = new ContractIntegrationRequiredFields__c(name='Sub_Deal__c', RequiredFields__c='');
        reqFields.add(cont1);
        ContractIntegrationRequiredFields__c cont2 = new ContractIntegrationRequiredFields__c(name='SBQQ__QuoteLine__c', RequiredFields__c='');
        reqFields.add(cont2);
        ContractIntegrationRequiredFields__c cont3 = new ContractIntegrationRequiredFields__c(name='SBQQ__Quote__c', RequiredFields__c='');
        reqFields.add(cont3);
        ContractIntegrationRequiredFields__c cont4 = new ContractIntegrationRequiredFields__c(name='ContractParty__c', RequiredFields__c='Activation_Date__c,Expiration_Date__c');
        reqFields.add(cont4);
        insert reqFields; 

        //create account
        List<Account> accList = TestFactory.createAccounts(2, false);
        accList[1].RecordTypeId = accRecordTypeInfo.get('Customer_Sub_Account').getRecordTypeId();
        insert accList;

        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;
        
        //create opportunity
        List<Opportunity> oppList = TestFactory.createOppForAccounts(1, accList, 'PoC_Opportunity', false);
        oppList[0].sbaa__ApprovalStatus__c = 'Approved';
        oppList[0].No_of_Ships_Targeted__c = 22;
        oppList[0].KP_Net_Prices__c = true;
        oppList[0].Net_Prices_WW__c = true;
        oppList[0].Extra_Discount__c = true;
        oppList[0].Pricebook2Id = customPB.Id;
        oppList[0].Signers_Scenario_3__c = false;
		insert oppList[0];
	
        //query contract parties and add activation and expiration date
        List<ContractParty__c> pocCpList = new List<ContractParty__c>();
       
        for(Integer i=0; i<=2 ; i++) {
            ContractParty__c cp = new ContractParty__c();
            cp.Opportunity__c = oppList[0].id;
            cp.Activation_Date__c = System.today();
            cp.Expiration_Date__c = System.today().addDays(10);
            cp.SignstheContract__c = true;
            cp.Account__c = accList[0].Id;
            pocCpList.add(cp);
        }
        insert pocCpList;
       //update oppList[0];
       
        //create products
     //   List<Product2> prodList = TestFactory.createProducts(3, true);

        BonusAgreement__c ba = new BonusAgreement__c(Sales_Product_Group__c = 'Biochemicals;', Tier1Limit__c = 200, Tier1Bonus__c = 10, ProductGroupsPicklist__c= '090-Metal Arc Welding Wire');
        insert ba;

        //create Rebate thresholds 
        RebateThreshold__c rebThresRecord = TestFactory.generateRebateThresholds(false);
        insert rebThresRecord;

        //create SPG thresholds 
        List<SpgThreshold__c> spgThresRecords = TestFactory.generateSPGThresholds(false);
        insert spgThresRecords;

        //create quote for the opportunity
        SBQQ__Quote__c quote = TestFactory.createQuote(accList[0].Id, oppList[0].Id, false);
        quote.SBQQ__StartDate__c = System.today();
        quote.Ship_Manager__c = true;
        quote.SBQQ__ExpirationDate__c = System.today().addDays(2);
        quote.BonusAgreement__c = ba.Id;
        quote.PHB_Refrigerants_Qty__c  = 200000;
        quote.SBQQ__Type__c= 'Amendment';		
        insert quote;

        Purchasing_Alliance_Bonus__c pab = new Purchasing_Alliance_Bonus__c(Quote__c = quote.Id, Purchasing_Alliance_Bonus__c = 2);
        insert pab;       

        //creqate quoteliens for quote
        /*List<SBQQ__QuoteLine__c> quoteLines = TestFactory.createQuoteLineForProducts(quote.Id, prodList, false);
        for(SBQQ__QuoteLine__c ql : quoteLines) {
            ql.KP1Price__c = 20;
            ql.Sales_USD_Amount__c = 20.20;
        }
        insert quoteLines;

        KeyPortGroup__c kpGroup = new KeyPortGroup__c();
        kpGroup.Quote__c = quote.Id;
        kpGroup.Key_Port_Group_Tier__c = 'Tier 1';
        insert kpGroup;

        Port__c port = new Port__c();
        port.Port_Code__c = 'TESTT';
        port.Key_Port_Group_Tier__c = 'Tier 1';
        insert port;

        KeyPort__c kp = new KeyPort__c();
        kp.KeyPortGroupLookup__c = kpGroup.Id;
        kp.Quote__c = quote.Id;
        kp.Port__c = port.Id;
        insert kp;
		*/
       
        //create contract
        Contract contract = TestFactory.createContractForOpp(oppList[0], quote, false);
        contract.Status = 'Planned';
        contract.Evergreen__c = false;
        contract.Description = 'Description';
        contract.ContractTerm = 1;
        contract.Applicable_Terms_Conditions__c = 'Standard WSS Ts&Cs';
        contract.Includes_OECD_clause__c = 'Yes';
        contract.Payment_Term__c = '30';
        contract.Include_Cylinder_Supply__c = 'No';
        contract.Credit_Review_conducted__c = 'No';
        contract.Contract_value_per_annum__c  = 16;
        contract.MSA_Version__c = 'MSA V3 (New Pricing Structure)'	;
        //contract.EndDate =  System.today();
        insert contract;
        contract.ActivatedDate = System.today().addDays(-20);
		update contract;
       
        //create sub deals for the contract
        List<Sub_Deal__c> sdList = new List<Sub_Deal__c>();
        for(Integer i=0; i<2; i++) {
            Sub_Deal__c sd = new Sub_Deal__c();
            sd.Customer_Sub_Account__c = accList[1].Id;
            sd.To_Date__c = System.today().addDays(2);
            sd.Activation_Date__c = System.today();
            sd.Deal__c = contract.Id;
            sd.From_Date__c = System.today();
            sdList.add(sd);
        }
        insert sdList;
	
        if(isSpl) {
            System.debug('****** '+Limits.getDMLStatements());
            //create specail offer opportunity 
            List<Opportunity> splOfferOpp = TestFactory.createOppForAccounts(1, accList, 'Special_Offer', false);
            splOfferOpp[0].sbaa__ApprovalStatus__c = 'Approved';
            splOfferOpp[0].Related_Contract__c = contract.Id;
            splOfferOpp[0].No_of_Ships_Targeted__c = 22;
            splOfferOpp[0].Applicable_Terms_Conditions__c = 'Customer Ts&Cs';
            insert splOfferOpp[0];

            List<ContractParty__c> cpList = new List<ContractParty__c>();

            //insert contract party for special offer opp
            for(ContractParty__c cp : [SELECT Id, RegistrationNumber__c, RegisteredCountry__c, Activation_Date__c,Expiration_Date__c,RegisteredAddress__c FROM ContractParty__c WHERE Opportunity__c =: oppList[0].Id]) {
                ContractParty__c newCp = cp.Clone();
                newCp.Account__c = accList[0].Id;
                newCp.Opportunity__c = splOfferOpp[0].Id;
                newCp.Activation_Date__c = System.today();
                newCp.Expiration_Date__c = System.today().addDays(10); 
                newCp.SignstheContract__c = true;
                cpList.add(newCp);
            }
            insert cpList;

            //create products 
            List<Product2> prodList2 = TestFactory.createProducts(3, true);

            //cerate quote for special offer oppotunity
            SBQQ__Quote__c splQuote = TestFactory.createQuote(accList[0].Id, splOfferOpp[0].Id, false);
            splQuote.SBQQ__StartDate__c = System.today();
            splQuote.SBQQ__ExpirationDate__c = System.today().addDays(2); 
        	splQuote.PHB_Refrigerants_Qty__c  = 200000;
            insert splQuote;

            //create quote lines for special offer quote
            TestFactory.createQuoteLineForProducts(splQuote.Id, prodList2, true);
            
            List<RefrigerantsDiscount__mdt> retrievedMDT = new List<RefrigerantsDiscount__mdt>();
        	retrievedMDT = [SELECT id, MasterLabel,ProductName__c FROM RefrigerantsDiscount__mdt];
            
            return splQuote;
        }

        return quote;
            
    }
    

    
}