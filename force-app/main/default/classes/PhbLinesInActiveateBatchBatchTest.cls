@isTest
public with sharing class PhbLinesInActiveateBatchBatchTest {
    
    @testSetup
    static void madeData() {

        List<Account> accList = TestFactory.createAccounts(1, true);

            Product2 prod = TestFactory.createProducts(1, true)[0];

            Parent_PHB__c parentPhb = new Parent_PHB__c();
            parentPhb.Account__c = accList[0].Id;
            insert parentPhb;

            PurchaseHistoryBucket__c phb = new PurchaseHistoryBucket__c();
            phb.Account__c = accList[0].Id;
            phb.Product__c = prod.Id;
            phb.Parent_PHB__c = parentPhb.Id;
            phb.Row_Id__c = accList[0].Account_Number__c + '-' +prod.ProductCode;
            insert phb;

            List<Purchase_History_Bucket_Lines__c> phbLines = new List<Purchase_History_Bucket_Lines__c>();

            //add 100 phbLines where invoiceDate__c is belong to last months
            phbLines.addAll(createPhbLines(phb.Id, 100, System.now().addDays(-30)));
            
			//add 100 phbLines where invoiceDate__c is belong to early months
            phbLines.addAll(createPhbLines(phb.Id, 100, System.now().addDays(-340)));

            //add 100 phbLines where invoiceDate__c is belong to future month
            phbLines.addAll(createPhbLines(phb.Id, 100, System.now().addDays(60)));

            //add 250 phbLines where invoiceDate__c is belong to current month
            phbLines.addAll(createPhbLines(phb.Id, 210, System.now()));

            //add 100 phbLines where invoiceDate__c is belong to next year
            phbLines.addAll(createPhbLines(phb.Id, 100, System.now().addDays(370)));


            //add 320 phbLines where invoiceDate__c is lessthan last 12 months
            phbLines.addAll(createPhbLines(phb.Id, 100, System.now().addDays(-400)));
            
            insert phbLines;
    }

    static testMethod void testPhbLinesInactiveBatch(){
        User user = TestFactory.createTestUser();
    
        system.runAs(user) {

            //run in-activate batch
            Test.startTest();
            String sch = '0 0 23 * * ?';
            System.schedule('test inactive', sch, new PhbLinesInActiveateBatch());

            PhbLinesInActiveateBatch batchable = new PhbLinesInActiveateBatch();
            Database.executeBatch(batchable, 2000);
            Test.stopTest();

            System.assertEquals(200, [SELECT Count() FROM Purchase_History_Bucket_Lines__c WHERE isActive__c = true], 'No. of Active Purchase_History_Bucket_Lines__c record count is wrong');
            System.assertEquals(510, [SELECT Count() FROM Purchase_History_Bucket_Lines__c WHERE isActive__c = false], 'No. of InActive Purchase_History_Bucket_Lines__c record count is wrong');

            PurchaseHistoryBucket__c phb = [SELECT L12M_Qty_Rollup__c, Sales_L12M_Rollup__c FROM PurchaseHistoryBucket__c LIMIT 1];
            
            //Amount(we kept 200 as defult amount) should be total of all active Purchase_History_Bucket_Lines__c
            System.assertEquals(200*200, phb.Sales_L12M_Rollup__c);

            //Amount(we kept 2 as defult quantity) should be total of all active Purchase_History_Bucket_Lines__c
            System.assertEquals(200*2, phb.L12M_Qty_Rollup__c);
        }
    }
    
    static testMethod void testPhbLinesActiveBatch(){
        User user = TestFactory.createTestUser();
    
        system.runAs(user) {
            
            List<Purchase_History_Bucket_Lines__c> updateList = new List<Purchase_History_Bucket_Lines__c>();
            
            for(Purchase_History_Bucket_Lines__c phbLine : [SELECT Id, isActive__c FROM Purchase_History_Bucket_Lines__c]) {
                phbLine.isActive__c = false;
                updateList.add(phbLine);
            }
            
            update updateList;
            
            //run activate batch
            Test.startTest();
            String sch = '0 0 23 * * ?';
            System.schedule('test inactive', sch, new PhbLinesActivateBatch());

            PhbLinesActivateBatch batchable = new PhbLinesActivateBatch();
            Database.executeBatch(batchable, 2000);
            Test.stopTest();

            System.assertEquals(210, [SELECT Count() FROM Purchase_History_Bucket_Lines__c WHERE isActive__c = true]);
         
            PurchaseHistoryBucket__c phb = [SELECT L12M_Qty_Rollup__c, Sales_L12M_Rollup__c FROM PurchaseHistoryBucket__c LIMIT 1];
            
            //Amount(we kept 200 as defult amount) should be total of all active Purchase_History_Bucket_Lines__c
            System.assertEquals(210*200, phb.Sales_L12M_Rollup__c);

            //Amount(we kept 2 as defult quantity) should be total of all active Purchase_History_Bucket_Lines__c
            System.assertEquals(210*2, phb.L12M_Qty_Rollup__c);
        }
    }

    public static List<Purchase_History_Bucket_Lines__c> createPhbLines(Id phbId, Integer count, DateTime invoiceDate) {
        List<Purchase_History_Bucket_Lines__c> phbLines = new List<Purchase_History_Bucket_Lines__c>();

        for(Integer i=0; i<count; i++) {
            Purchase_History_Bucket_Lines__c phbLine = TestFactory.generatePHBL();
            phbLine.Purchase_History_Bucket__c = phbId;
            phbLine.productId__c = '765019';
            phbLine.payer__c = Decimal.valueOf('8000095100');
            phbLine.invoiceDate__c = invoiceDate;
            phbLines.add(phbLine);
        }
        return phbLines;
    }
}