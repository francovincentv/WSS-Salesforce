@isTest
public class InsertQuoteLinesQueueableTest {
    
    static testMethod void testQuoteLinesQueue(){

        User u = TestFactory.createTestUser();
        System.runAs(u){
            //disable SBQQ__Quote__c trigger
            Trigger_Setting__c quoteTriggerSetting = TestFactory.createTriggerSetting('SBQQ__Quote__c', false);
            quoteTriggerSetting.Disabled__c = true;
            insert quoteTriggerSetting;

            //disable SBQQ__QuoteLine__c trigger
            Trigger_Setting__c quoteLineTriggerSetting = TestFactory.createTriggerSetting('SBQQ__QuoteLine__c', false);
            quoteLineTriggerSetting.Disabled__c = true;
            insert quoteLineTriggerSetting;
        
            SBQQ.TriggerControl.disable(); 
            List<Account> accList = TestFactory.createAccounts(1, false);
            accList[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Sub_Account').getRecordTypeId();
            insert accList;

            List<Opportunity> oppList = TestFactory.createOppForAccounts(1, accList, '',false);
            oppList[0].sbaa__ApprovalStatus__c = 'Approved';
            insert oppList;

            ContractParty__c cp = new ContractParty__c ();
            cp.Account__c = accList[0].Id;
            cp.Opportunity__c = oppList[0].Id;    
            insert cp;

            ProductGroup__c prodGroup = new ProductGroup__c();
            prodGroup.Name = '593-Retrofit Refrigerant Fillings';
            insert prodGroup;

            //create parent product
            List<Product2> parentProdList = TestFactory.createProducts(1, false);
            parentProdList[0].Sales_Product_Group__c = 'Biochemicals';
            parentProdList[0].ProductCode = '778865';
            parentProdList[0].CurrencyIsoCode = 'USD';
            parentProdList[0].ProductGroup__c= prodGroup.Id;
            parentProdList[0].Product_Discount_Group__c = 'Products';
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
                childProd.ProductGroup__c= prodGroup.Id;
                childProd.Product_Discount_Group__c = 'Products';
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

            PurchaseHistoryBucket__c phb2 = new PurchaseHistoryBucket__c ();
            phb2.Account__c = accList[0].id;   
            phb2.Product__c = parentProdList[0].id;
            phb2.Quantity__c = 30;
            phb2.Parent_PHB__c = parentPHB.Id;
            phb2.Row_Id__c = '803027-739465';
            phbList.add(phb2);

            //create PurchaseHistoryBucket__c for each child record
            for(Product2 childProd : childProdList) {
                PurchaseHistoryBucket__c phb = new PurchaseHistoryBucket__c ();
                phb.Account__c = accList[0].id;   
                phb.Product__c = childProd.id;
                phb.Quantity__c = 30;
                phb.Parent_PHB__c = parentPHB.Id;
                phb.Row_Id__c = '803027-739466';
                phbList.add(phb);
            }
            insert phbList;

            List<Purchase_History_Bucket_Lines__c> phbLineList = new List<Purchase_History_Bucket_Lines__c>();
            for(PurchaseHistoryBucket__c phb : phbList) {
                Purchase_History_Bucket_Lines__c phbl = TestFactory.generatePHBL();
                phbl.Purchase_History_Bucket__c = phb.Id;
                phbl.isActive__c = true;
                phbLineList.add(phbl);
            }

            insert phbLineList;

            SBQQ__Quote__c quote = TestFactory.createQuote(accList[0].Id, oppList[0].Id, false);
            quote.SBQQ__Type__c = 'Amendment';
            quote.SBQQ__Primary__c = true;
            insert quote;
            SBQQ.TriggerControl.enable(); 
            Test.startTest();
            //InsertQuoteLinesQueueable queueable = new InsertQuoteLinesQueueable(quote);
            //System.enqueueJob(queueable);

            QuoteInitializationAutomation.initializeQuoteLines(quote);
            Test.stopTest();

            System.AssertEquals(1, [SELECT Count() FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: quote.Id]);
            
        }
    }
}