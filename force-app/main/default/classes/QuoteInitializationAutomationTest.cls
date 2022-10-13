@isTest
public class QuoteInitializationAutomationTest {

    @TestSetup
    static void makeData(){

        Trigger_Setting__c quoteTriggerSetting = TestFactory.createTriggerSetting('SBQQ__Quote__c', false);
        quoteTriggerSetting.Disabled__c = true;
        insert quoteTriggerSetting;

        Trigger_Setting__c quoteLineTriggerSetting = TestFactory.createTriggerSetting('SBQQ__QuoteLine__c', false);
        quoteLineTriggerSetting.Disabled__c = true;
        insert quoteLineTriggerSetting;

        List<Account> accList = TestFactory.createAccounts(1, false);
        insert accList;

        List<Opportunity> oppList = TestFactory.createOppForAccounts(1, accList, '', false);
        oppList[0].sbaa__ApprovalStatus__c = 'Approved';
        insert oppList;

        ContractParty__c cp = new ContractParty__c ();
        cp.Account__c = accList[0].Id;
        cp.Opportunity__c = oppList[0].Id;    
        insert cp;

        //create parent product
        List<Product2> parentProdList = TestFactory.createProducts(1, false);
        parentProdList[0].Sales_Product_Group__c = 'Biochemicals';
        parentProdList[0].ProductCode = '778865';
        parentProdList[0].CurrencyIsoCode = 'USD';
        insert parentProdList;

        Id pricebookId = Test.getStandardPricebookId();
 
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = parentProdList[0].Id,
            UnitPrice = 10000, 
            IsActive = true);
        insert standardPrice;

        SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c();
        productOption.SBQQ__ConfiguredSKU__c = parentProdList[0].id;
        productOption.SBQQ__Number__c =1;
        insert productOption;

        List<Product2> childProdList = TestFactory.createProducts(1, false);
        integer i=0;
        for(Product2 childProd : childProdList) {
            childProd.Sales_Product_Group__c = 'Biochemicals';
            childProd.MainProductOption__c  = productOption.id;
            childProd.ProductCode = '77886'+i;
            childProd.CurrencyIsoCode = 'USD';
            i++;
        }
        insert childProdList;

        PricebookEntry standardPriceChild = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = childProdList[0].Id,
            UnitPrice = 10000, 
            IsActive = true);
        insert standardPriceChild;

        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;
        
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = childProdList[0].Id,
            UnitPrice = 12000, IsActive = true);
        insert customPrice;

        Parent_PHB__c parentPHB = new Parent_PHB__c();
        parentPHB.Account__c = accList[0].Id;
        insert parentPHB;

        List<PurchaseHistoryBucket__c> phbList = new List<PurchaseHistoryBucket__c>();

        //create PurchaseHistoryBucket__c for each child record
        for(Product2 childProd : childProdList) {
            PurchaseHistoryBucket__c phb = new PurchaseHistoryBucket__c ();
            phb.Account__c =  accList[0].id;   
            phb.Product__c =  childProd.id;
            phb.Quantity__c = 30;
            phb.Row_Id__c = '803027-739466';
            phb.Parent_PHB__c = parentPHB.Id;
            phbList.add(phb);
        }
        insert phbList;

        List<Purchase_History_Bucket_Lines__c> phblList = new List<Purchase_History_Bucket_Lines__c>();
        for(PurchaseHistoryBucket__c phb : phbList) {
            for(Product2 childProd : childProdList) {
                Purchase_History_Bucket_Lines__c phbl = TestFactory.generatePHBL();
                phbl.productId__c = childProd.ProductCode;
                phbl.payer__c = Decimal.valueOf(accList[0].Account_Number__c);
                phbl.Purchase_History_Bucket__c = phb.Id;
                phblList.add(phbl);
            }
        }

        insert phblList;

        SBQQ__Quote__c quote = TestFactory.createQuote(accList[0].Id, oppList[0].Id, false);
        quote.SBQQ__Type__c = 'Amendment';
        quote.SBQQ__Primary__c = true;
        insert quote;
    }
    
   
    static testMethod void testInsertQuoteLinesQueueable() {
        
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        InsertQuoteLinesQueueable queueable = new InsertQuoteLinesQueueable(quote);
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();

        System.assertEquals(2, [SELECT Count() FROM SBQQ__QuoteLine__c]);
        System.assertEquals(1, [SELECT Count() FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: quote.Id]);

        quote = QuoteInitializationAutomation.getQuoteDetails(quote.Id);

        System.assert(quote!=null);
    }
}