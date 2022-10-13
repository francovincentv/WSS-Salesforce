@isTest
public  class VolumeDiscountAmountRestApiTest {
    @TestSetup
    static void makeData(){
        Product2 product = TestFactory.createProducts(1, false)[0];
        product.Product_Code__c = '764420';
        product.ProductCode = '764420';
        insert product;
        
        String dateTimeString = '2020-09-23T00:00:00Z';
        for(Integer i=0; i<5; i++) {
            Volume_Discount__c vd = new Volume_Discount__c();
            vd.Product__c = product.Id;
            vd.Volume_Discount__c = i;
            vd.Product_Code__c = product.Product_Code__c;
            vd.discountId__c = 'feds'+i;
            vd.Min_Qty__c = i*100;
            vd.createdOn_Discount__c = (DateTime)JSON.deserialize('"' + dateTimeString + '"', DateTime.class);
        }
    }

    //when product found in salesforce
    static testMethod void testProductExist() {
        String jsonString = '[{' +
            '"id": "123",'+
            '"eventType": "",' +
            '"dataVersion" : "",'+
            '"eventTime" : "",'+
            '"metadataVersion" : "",'+
            '"topic" : "",'+
            '"data" : { '+
                '"productGroupId": "764420",'+
                '"modifiedOn" : "2020-09-04T06:10:24.2549110Z", '+
                '"discountThresholds": [{'+
                    '"id": "feds0",'+
                    '"amount": 0,'+
                    '"discountPercentage": 0.637,'+
                    '"currencyCode" : "USD"' +
                '}, {'+
                    '"id": "feds1",'+
                    '"amount": 100,'+
                    '"discountPercentage": 0.642,'+
                    '"currencyCode" : "USD"' +
                '}, {'+
                    '"id": "feds2",'+
                    '"amount": 200,'+
                    '"discountPercentage": 0.65,'+
                    '"currencyCode" : "USD"' +
                '}, {'+
                    '"id": "feds3",'+
                    '"amount": 300,'+
                    '"discountPercentage": 0.656,'+
                    '"currencyCode" : "USD"' +
                '}, {'+
                    '"id": "feds4",'+
                    '"amount": 400,'+
                    '"discountPercentage": 0.637,'+
                    '"currencyCode" : "USD"' +
                '}, {'+
                    '"id": "feds5",'+
                    '"amount": 500,'+
                    '"discountPercentage": 0.637,'+
                    '"currencyCode" : "USD"' +
                '}]'+
            '}'+
        '}]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/volumeDiscountAmount';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonString);

        RestContext.Request = request;

        Test.startTest();
        VolumeDiscountAmountRestApi.doPost();
        Test.stopTest();

        System.assertEquals(6, [SELECT Count() FROM Volume_Discount__c], 'No.of Volume discount inserted is wrong');
    }

    //when product not found in salesforce
    static testMethod void testProductNotExist() {
        String jsonString = '[{' +
            '"id": "123",'+
            '"eventType": "",' +
            '"dataVersion" : "",'+
            '"eventTime" : "",'+
            '"metadataVersion" : "",'+
            '"topic" : "",'+
            '"data": {'+
                '"productGroupId": "764421",'+
                '"modifiedOn" : "2020-09-04T06:10:24.2549110Z", '+
                '"discountThresholds": [{'+
                    '"id": "feds0",'+
                    '"amount": 0,'+
                    '"discountPercentage": 0.637,'+
                    '"currencyCode" : "USD"' +
                '}, {'+
                    '"id": "feds1",'+
                    '"amount": 100,'+
                    '"discountPercentage": 0.642,'+
                    '"currencyCode" : "USD"' +
                '}, {'+
                    '"id": "feds2",'+
                    '"amount": 200,'+
                    '"discountPercentage": 0.65,'+
                    '"currencyCode" : "USD"' +
                '}, {'+
                    '"id": "feds3",'+
                    '"amount": 300,'+
                    '"discountPercentage": 0.656,'+
                    '"currencyCode" : "USD"' +
                '}, {'+
                    '"id": "feds4",'+
                    '"amount": 400,'+
                    '"discountPercentage": 0.637,'+
                    '"currencyCode" : "USD"' +
                '}]'+
            '}'+
        '}]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/volumeDiscountAmount';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonString);

        RestContext.Request = request;

        Test.startTest();
        VolumeDiscountAmountRestApi.doPost();
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Volume_Discount__c], 'No volume discount should exist, since product is not found');
    }

}