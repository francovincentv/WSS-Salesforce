@isTest
public with sharing class ProductUpsertRestApiTest {
    @testSetup
    static void makeData() {
        //Instantiate the Pricebook2 record with StandardPricebookId
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
    }
    
    //if no products and product group available in salesforce
    static testMethod void testProductUpsertCase1(){
        String jsonBody = '[ {"id": "79ab4e0a-b053-4f89-a6bd-78b63267f84d","eventTime": "2020-09-04T06:10:24.2549110Z","eventType": "supplychain.product","dataVersion": "2.0","metadataVersion": "1","topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG-WSS-INTEGRATIONS-SUPPLYCHAIN-SOL/providers/Microsoft.EventGrid/domains/EGD-WSS-INTEGRATIONS-SUPPLYCHAIN-SOL/topics/product","subject": "ProductUpdated","deadLetterReason": "TimeToLiveExceeded","deliveryAttempts": 11,"lastDeliveryOutcome": "GenericError","lastHttpStatusCode": 422,"publishTime": "2020-09-04T06:10:24.5473627Z","lastDeliveryAttemptTime": "2020-09-05T04:57:04.3962355Z","data": {"productId": "778860","classification": "Standard","productName": "Easyclean Oven And Grill(6 Pcs Per Box)","mainProductGroupId": "64","mainProductGroupName": "Chemicals - Offshore & Ind.","productGroupId": "642","productGroupName": "Galley And Accommodation","assetClass": "S-Standard","assetClassName": "Standard","productClass": "Standard","productFamilyCode": "SCM9","productFamilyName": "Galley & Accomodation","salesProductGroup": "Galley & Accomodation","uomId": "PCS","catalogType": "Inventory part","solution": "Cleaning","businessUnitId": "01","partProductCode": null,"partProductName": null,"partStatusCode": "Z","partStatusName": "06 - DEAD","site": "GUA","masterType":"Mastered","replicatedSites": null,"netWeight": 4.32,"netWeightUom": "kg","hazardClassCode": "8","hazardClassName": "CLASS 8 CORROSIVES","modifiedOn": "2020-09-04T03:08:51.975000Z"}   }   ]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/product';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonBody);

        RestContext.Request = request;

        Test.startTest();
        ProductUpsertRestApi.doPost();
        Test.stopTest();

        List<Product2> products = [SELECT Id, Name, Product_Code__c FROM Product2];
        List<ProductGroup__c> prodGroup = [SELECT Id, Name,MainProductGroup__c FROM ProductGroup__c];

        //two product should be created
        System.assertEquals(2, products.size(), 'Only two products should exist');

        //one product group should be created
        System.assertEquals(1, prodGroup.size());
        System.assertEquals(1, [SELECT Count() FROM Product2 WHERE Name =:prodGroup[0].Name], 'Only one product group should be created');

        //four pricebook entries should be created, 2 for each product
        System.assertEquals(4, [SELECT Count() FROM PricebookEntry], 'Only four pricebook entries should be created, 2 for each product');
   
    }

    //if product group exist and prodcut not exist in salesforce
    static testMethod void testProductUpsertCase2(){

        ProductGroup__c pg = new ProductGroup__c(Name='642-Galley And Accommodation', MainProductGroup__c='32-Ropes');
        insert pg;

        String jsonBody = '[ {"id": "79ab4e0a-b053-4f89-a6bd-78b63267f84d","eventTime": "2020-09-04T06:10:24.2549110Z","eventType": "supplychain.product","dataVersion": "2.0","metadataVersion": "1","topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG-WSS-INTEGRATIONS-SUPPLYCHAIN-SOL/providers/Microsoft.EventGrid/domains/EGD-WSS-INTEGRATIONS-SUPPLYCHAIN-SOL/topics/product","subject": "ProductUpdated","deadLetterReason": "TimeToLiveExceeded","deliveryAttempts": 11,"lastDeliveryOutcome": "GenericError","lastHttpStatusCode": 422,"publishTime": "2020-09-04T06:10:24.5473627Z","lastDeliveryAttemptTime": "2020-09-05T04:57:04.3962355Z","data": {"productId": "778860","classification": "Standard","productName": "Easyclean Oven And Grill(6 Pcs Per Box)","mainProductGroupId": "64","mainProductGroupName": "Chemicals - Offshore & Ind.","productGroupId": "642","productGroupName": "Galley And Accommodation","assetClass": "S-Standard","assetClassName": "Standard","productClass": "Standard","productFamilyCode": "SCM9","productFamilyName": "Galley & Accomodation","salesProductGroup": "Galley & Accomodation","uomId": "PCS","catalogType": "Inventory part","solution": "Cleaning","businessUnitId": "01","partProductCode": null,"partProductName": null,"partStatusCode": "Z","partStatusName": "06 - DEAD","site": "GUA","masterType":"Mastered","replicatedSites": null,"netWeight": 4.32,"netWeightUom": "kg","hazardClassCode": "8","hazardClassName": "CLASS 8 CORROSIVES","modifiedOn": "2020-09-04T03:08:51.975000Z"}   }   ]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/product';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonBody);

        RestContext.Request = request;

        Test.startTest();
        ProductUpsertRestApi.doPost();
        Test.stopTest();

        List<Product2> prodList = [SELECT ProductGroup__c FROM Product2];
        List<ProductGroup__c> prodGroup = [SELECT Category__c, MainProductGroup__c FROM ProductGroup__c];

        //only one prouduct should be created
        System.assertEquals(1, prodList.size());
        System.assertEquals(pg.Id, prodList[0].ProductGroup__c);

        //MainProductGroup__c and Category__c should be upated with latest values on ProductGroup__c 
        System.assertEquals('64-Chemicals - Offshore & Ind.', prodGroup[0].MainProductGroup__c);
        System.assertEquals('Cleaning', prodGroup[0].Category__c);

        //two pricebook entries should be created
        System.assertEquals(2, [SELECT Count() FROM PricebookEntry]);
    }

    //json body exception case
    static testMethod void testProductUpsertCase3(){
        String jsonBody = '[ {"id": "79ab4e0a-b053-4f89-a6bd-78b63267f84d","eventTime": "2020-09-04T06:10:24.2549110Z","eventType": "supplychain.product","dataVersion": "2.0","metadataVersion": "1","topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG-WSS-INTEGRATIONS-SUPPLYCHAIN-SOL/providers/Microsoft.EventGrid/domains/EGD-WSS-INTEGRATIONS-SUPPLYCHAIN-SOL/topics/product","subject": "ProductUpdated","deadLetterReason": "TimeToLiveExceeded","deliveryAttempts": 11,"lastDeliveryOutcome": "GenericError","lastHttpStatusCode": 422,"publishTime": "2020-09-04T06:10:24.5473627Z","lastDeliveryAttemptTime": "2020-09-05T04:57:04.3962355Z","data": {"productId": 778860,"classification": "Standard","productName": "Easyclean Oven And Grill(6 Pcs Per Box)","mainProductGroupId": "64","mainProductGroupName": "Chemicals - Offshore & Ind.","productGroupId": "642","productGroupName": "Galley And Accommodation","assetClass": "S-Standard","assetClassName": "Standard","productClass": "Standard","productFamilyCode": "SCM9","productFamilyName": "Galley & Accomodation","salesProductGroup": "Galley & Accomodation","uomId": {},"catalogType": "Inventory part","solution": "Cleaning","businessUnitId": "01","partProductCode": null,"partProductName": null,"partStatusCode": "Z","partStatusName": "06 - DEAD","site": "GUA","masterType":"Mastered","replicatedSites": null,"netWeight": 4.32,"netWeightUom": "kg","hazardClassCode": "8","hazardClassName": "CLASS 8 CORROSIVES","modifiedOn": "2020-09-04T03:08:51.975000Z"}   }   ]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/product';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonBody);

        RestContext.Request = request;

        Test.startTest();
        String error = '';
        try {
            ProductUpsertRestApi.doPost();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }

    //product details exception case
    static testMethod void testProductUpsertCase5(){
        String jsonBody = '[ {"id": "79ab4e0a-b053-4f89-a6bd-78b63267f84d","eventTime": "2020-09-04T06:10:24.2549110Z","eventType": "supplychain.product","dataVersion": "2.0","metadataVersion": "1","topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG-WSS-INTEGRATIONS-SUPPLYCHAIN-SOL/providers/Microsoft.EventGrid/domains/EGD-WSS-INTEGRATIONS-SUPPLYCHAIN-SOL/topics/product","subject": "ProductUpdated","deadLetterReason": "TimeToLiveExceeded","deliveryAttempts": 11,"lastDeliveryOutcome": "GenericError","lastHttpStatusCode": 422,"publishTime": "2020-09-04T06:10:24.5473627Z","lastDeliveryAttemptTime": "2020-09-05T04:57:04.3962355Z","data": {"productId": "778860","classification": "Standaddrd","productName": "Easyclean Oven And Grill(6 Pcs Per Box)","mainProductGroupId": "64","mainProductGroupName": "Chemicals - Offshore & Ind.","productGroupId": "642","productGroupName": "Galley And Accommodation","assetClass": "S-Standard","assetClassName": "Standard","productClass": "Standard","productFamilyCode": "SCM9","productFamilyName": "Galley & Accomodation","salesProductGroup": "Galley & Accomodation","uomId": "PCS","catalogType": "Inventory part","solution": "Cleaning","businessUnitId": "01","partProductCode": null,"partProductName": null,"partStatusCode": "Z","partStatusName": "06 - DEAD","site": "GUA","masterType":"Mastered","replicatedSites": null,"netWeight": 4.32,"netWeightUom": "kg","hazardClassCode": "8","hazardClassName": "CLASS 8 CORROSIVES","modifiedOn": "2020-09-04T03:08:51.975000Z"}   }   ]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/product';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonBody);

        RestContext.Request = request;

        Test.startTest();
        String error = '';
        try {
            ProductUpsertRestApi.doPost();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        Test.stopTest();
    }


    //if both product and product group exist 
    static testMethod void testProductUpsertCase4(){

        ProductGroup__c pg = new ProductGroup__c(Name='642-Galley And Accommodation', MainProductGroup__c='32-Ropes');
        insert pg;

        Product2 prod = TestFactory.createProducts(1, false)[0];
        prod.ProductCode = '778860';
        insert prod;

        String jsonBody = '[ {"id": "79ab4e0a-b053-4f89-a6bd-78b63267f84d","eventTime": "2020-09-04T06:10:24.2549110Z","eventType": "supplychain.product","dataVersion": "2.0","metadataVersion": "1","topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG-WSS-INTEGRATIONS-SUPPLYCHAIN-SOL/providers/Microsoft.EventGrid/domains/EGD-WSS-INTEGRATIONS-SUPPLYCHAIN-SOL/topics/product","subject": "ProductUpdated","deadLetterReason": "TimeToLiveExceeded","deliveryAttempts": 11,"lastDeliveryOutcome": "GenericError","lastHttpStatusCode": 422,"publishTime": "2020-09-04T06:10:24.5473627Z","lastDeliveryAttemptTime": "2020-09-05T04:57:04.3962355Z","data": {"productId": "778860","classification": "Standard","productName": "Easyclean Oven And Grill(6 Pcs Per Box)","mainProductGroupId": "64","mainProductGroupName": "Chemicals - Offshore & Ind.","productGroupId": "642","productGroupName": "Galley And Accommodation","assetClass": "S-Standard","assetClassName": "Standard","productClass": "Standard","productFamilyCode": "SCM9","productFamilyName": "Galley & Accomodation","salesProductGroup": "Galley & Accomodation","uomId": "PCS","catalogType": "Inventory part","solution": "Cleaning","businessUnitId": "01","partProductCode": null,"partProductName": null,"partStatusCode": "Z","partStatusName": "06 - DEAD","site": "GUA","masterType":"Mastered","replicatedSites": null,"netWeight": 4.32,"netWeightUom": "kg","hazardClassCode": "8","hazardClassName": "CLASS 8 CORROSIVES","modifiedOn": "2020-09-04T03:08:51.975000Z"}   }   ]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/product';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonBody);

        RestContext.Request = request;

        Test.startTest();
        ProductUpsertRestApi.doPost();
        Test.stopTest();

        List<Product2> prodList = [SELECT ProductGroup__c FROM Product2];
        List<ProductGroup__c> prodGroup = [SELECT Category__c, MainProductGroup__c FROM ProductGroup__c];

        //only one prouduct should exist
        System.assertEquals(1, prodList.size());
        System.assertEquals(pg.Id, prodList[0].ProductGroup__c);

        //MainProductGroup__c and Category__c should be upated with latest values on ProductGroup__c 
        System.assertEquals('64-Chemicals - Offshore & Ind.', prodGroup[0].MainProductGroup__c);
        System.assertEquals('Cleaning', prodGroup[0].Category__c);

        //Since no products created, PricebookEntry should not exist
        System.assertEquals(0, [SELECT Count() FROM PricebookEntry]);
    }
}