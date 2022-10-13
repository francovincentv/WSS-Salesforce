@isTest
public class LightningFlowHelperTest {
    static testMethod void testMethodName(){
        List<Account> accList = TestFactory.createAccounts(2, true);
        List<Parent_PHB__c> parentPhbList = new List<Parent_PHB__c>();
        List<PurchaseHistoryBucket__c> phbList = new List<PurchaseHistoryBucket__c>();
        List<Purchase_History_Bucket_Lines__c> phbLineList = new List<Purchase_History_Bucket_Lines__c>();
        List<String> accIds = new List<String>();

         List<Product2> prodList = TestFactory.createProducts(2, true);

        //for every account create 3 phb with each qty 12
        for(Account acc : accList) {
            accIds.add(acc.Id);
            for(Integer i=0; i<2; i++) {
                Parent_PHB__c parentPHB = new Parent_PHB__c();
                parentPHB.Account__c = acc.Id;
                parentPhbList.add(parentPHB);
            }
        }

        insert parentPhbList;

         //create PurchaseHistoryBucket__c for each product record
         for(integer i=0; i<2; i++) {
            PurchaseHistoryBucket__c phb = new PurchaseHistoryBucket__c ();
            phb.Account__c =  accList[i].id;   
            phb.Product__c =  prodList[i].id;
            phb.Quantity__c = 30;
            phb.Parent_PHB__c = parentPhbList[i].Id;
            phb.SalesProductGroup__c = 'Refrigerants';
            phb.Row_Id__c = '803027-739466'+i;
            phbList.add(phb);
        }
        insert phbList;

        for(PurchaseHistoryBucket__c phb : phbList) {
            Purchase_History_Bucket_Lines__c phbl = TestFactory.generatePHBL();
            phbl.Purchase_History_Bucket__c = phb.Id;
            phbl.isActive__c = true;
            phbLineList.add(phbl);
        }

        insert phbLineList;


        Decimal sumOfQty = LightningFlowHelper.methodName(accIds)[0];
        List<AggregateResult> arResult = [SELECT Sum(qty__c) qty FROM Purchase_History_Bucket_Lines__c];

        System.assertEquals((Decimal)arResult[0].get('qty'), sumOfQty, 'The sum of Refrigerants_Qty__c is not correct');

    }
}