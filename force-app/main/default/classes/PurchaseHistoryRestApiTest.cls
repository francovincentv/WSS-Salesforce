@isTest
public with sharing class PurchaseHistoryRestApiTest {

    @TestSetup
    static void makeData(){
        List<Account> accList = TestFactory.createAccounts(2, false);
        accList[0].Account_Number__c = '8000095100';
        accList[1].Account_Number__c = '8000095101';
        insert accList;

        Product2 prod = TestFactory.createProducts(1, false)[0];
        prod.ProductCode = '765018';
        insert prod;

        Product2 prod2 = TestFactory.createProducts(1, false)[0];
        prod2.ProductCode = '765019';
        insert prod2;

        Parent_PHB__c parentPHB = new Parent_PHB__c();
        parentPHB.Account__c = accList[0].Id;
        insert parentPHB;

        PurchaseHistoryBucket__c phb = new PurchaseHistoryBucket__c();
        phb.Account__c = [SELECT Id FROM Account WHERE Account_Number__c = '8000095100'].Id;
        phb.Product__c = prod2.Id;
        phb.Row_Id__c = accList[0].Account_Number__c + '-' +prod2.ProductCode;
        phb.Parent_PHB__c = parentPHB.Id;
        insert phb;

        
    }
    
    /* 
     * Test method to test when there is PHB exit and no PHBL found
     */
    static testMethod void purchaseHistoryRestApiTestCase1(){
        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/purchasehistory';
        request.httpMethod = 'POST';
        String body = '[{"id": "f19d5e17","eventTime": "2020-07-01T15:50:56.2644280Z","eventType": "sales.order","dataVersion": "2.0","metadataVersion": "1","topic": "test","subject": "SalesOrderUpdated","data": {"modifiedOn": "2020-07-01T15:50:56.2644280Z","orderNo": "A10112854","site": "POR","port": "EGEDK","vessel": "9635468","salesActivity": "OPR","payer": "8000095100","orderType": "PRO","orderLines": ';
        body += '[{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765018","lineNo": "3","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"},{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765018","lineNo": "3","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"},';
        body += '{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765019","lineNo": "2","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"},{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765018","lineNo": "3","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"}]}}]';
        //PurchaseHistoryRestApiWrapper requestBody = PurchaseHistoryRestApiWrapper.parse(body);
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;

        PurchaseHistoryRestApi.doPost();

        System.assertEquals(2, [SELECT count() FROM Purchase_History_Bucket_Lines__c]);
        System.assertEquals(1, [SELECT count() FROM Parent_PHB__c]);
        System.assertEquals(1, [SELECT count() FROM PurchaseHistoryBucket__c WHERE ProductCode__c = '765018']);
    }

    /* 
     * Test method to test when both PHB & PHBL not exit
     */
    static testMethod void purchaseHistoryRestApiTestCase2(){
        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/purchasehistory';
        request.httpMethod = 'POST';
        String body = '[{"id": "f19d5e17","eventTime": "2020-07-01T15:50:56.2644280Z","eventType": "sales.order","dataVersion": "2.0","metadataVersion": "1","topic": "test","subject": "SalesOrderUpdated","data": {"modifiedOn": "2020-07-01T15:50:56.2644280Z","orderNo": "A10112854","site": "POR","port": "EGEDK","vessel": "9635468","salesActivity": "OPR","payer": "8000095101","orderType": "PRO","orderLines": ';
        body += '[{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765018","lineNo": "3","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"},{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765018","lineNo": "3","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"},';
        body += '{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765019","lineNo": "2","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"},{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765018","lineNo": "3","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"}]}}]';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;

        PurchaseHistoryRestApi.doPost();

        System.assertEquals(3, [SELECT count() FROM PurchaseHistoryBucket__c]);
        System.assertEquals(2, [SELECT count() FROM Purchase_History_Bucket_Lines__c]);
        System.assertEquals(2, [SELECT count() FROM Parent_PHB__c]);
    }


    /* 
     * Test method to test error use case
     */
    static testMethod void purchaseHistoryRestApiTestCase3(){
        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/purchasehistory';
        request.httpMethod = 'POST';
        String body = '{"id": "f19d5e17","eventTime": "2020-07-01T15:50:56.2644280Z","eventType": "sales.order","dataVersion": "2.0","metadataVersion": "1","topic": "test","subject": "SalesOrderUpdated","data": {"modifiedOn": "2020-07-01T15:50:56.2644280Z","orderNo": "A10112854","site": "POR","port": "EGEDK","vessel": "9635468","salesActivity": "OPR","payer": "8000095101","orderType": "PRO","orderLines": ';
        body += '[{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765018","lineNo": "3","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"},{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765018","lineNo": "3","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"},';
        body += '{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765019","lineNo": "2","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"},{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765018","lineNo": "3","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"}]}}';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;

        try {
            PurchaseHistoryRestApi.doPost();
        } catch(Exception e) {
            System.assertEquals('Attempt to de-reference a null object', e.getMessage());
        }
    }


    /* 
     * Test method to test when both PHB & PHBL found
     */
    static testMethod void purchaseHistoryRestApiTestCase4(){

        PurchaseHistoryBucket__c phb = [SELECT Id FROM PurchaseHistoryBucket__c LIMIT 1];
        //Product2 prod = [SELECT Id, ProductCode FROM Product2 WHERE productCode = '765019'];

        Purchase_History_Bucket_Lines__c phbLine = new Purchase_History_Bucket_Lines__c();
        phbLine.Purchase_History_Bucket__c = phb.Id;
        phbLine.Amount__c = 200;
        phbLine.relNo__c = '1';
        phbLine.qty__c = 2;
        phbLine.productId__c = '765019';
        phbLine.port__c = 'EGEDK';
        phbLine.payer__c = Decimal.valueOf('8000095100');
        phbLine.orderType__c = 'PRO';
        phbLine.orderNo__c =  'A10112854';
        phbLine.lineItemNo__c = 0;
        phbLine.lineNo__c = '2';
        phbLine.invoiceNo__c = '1685518';
        phbLine.invoiceSeries__c ='CD';
        phbLine.invoiceDate__c = System.now();
        //phbLine.deliveryDate__c = 
        phbLine.CurrencyIsoCode = 'USD';
        phbLine.accountSalesIncome__c = true;

        insert phbLine;

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/purchasehistory';
        request.httpMethod = 'POST';
        String body = '[{"id": "f19d5e17","eventTime": "2020-07-01T15:50:56.2644280Z","eventType": "sales.order","dataVersion": "2.0","metadataVersion": "1","topic": "test","subject": "SalesOrderUpdated","data": {"modifiedOn": "2020-07-01T15:50:56.2644280Z","orderNo": "A10112854","site": "POR","port": "EGEDK","vessel": "9635468","salesActivity": "OPR","payer": "8000095100","orderType": "PRO","orderLines": ';
        body += '[{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765018","lineNo": "3","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "75.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"},';
        body += '{"modifiedOn": "2020-07-01T15:50:56.2644280Z","productId": "765019","lineNo": "2","relNo": "1","lineItemNo": 0,"createdDate": "2020-07-01T15:50:56.2644280Z","deliveryDate": "2020-07-01T15:50:56.2644280Z","invoiceNo": "1685518","invoiceDate": "2020-07-01T15:50:56.2644280Z","qty": "123.0000000000","qtyRefr": null,"transactionCurrencyId": "USD","amount": "475.12","accountSalesIncome": "Y","invoiceSeries":"CD"}]}}]';
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;

        PurchaseHistoryRestApi.doPost();

        System.assertEquals(123, [SELECT qty__c FROM Purchase_History_Bucket_Lines__c WHERE Id =: phbLine.Id].qty__c);
        System.assertEquals(1, [SELECT count() FROM Parent_PHB__c]);
    }
}