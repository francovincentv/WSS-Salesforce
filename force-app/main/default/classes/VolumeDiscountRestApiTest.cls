@isTest
public class VolumeDiscountRestApiTest {
    

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
    static testMethod void testCase1() {
        String jsonString = '[{' +
            '"id": "123",'+
            '"data" : { '+
                '"productNumber": "764420",'+
                '"modifiedOn" : "2020-09-04T06:10:24.2549110Z", '+
                '"discountThresholds": [{'+
                    '"id": "feds0",'+
                    '"quantity": 0,'+
                    '"discountPercentage": 0.637'+
                '}, {'+
                    '"id": "feds1",'+
                    '"quantity": 100,'+
                    '"discountPercentage": 0.642'+
                '}, {'+
                    '"id": "feds2",'+
                    '"quantity": 200,'+
                    '"discountPercentage": 0.65'+
                '}, {'+
                    '"id": "feds3",'+
                    '"quantity": 300,'+
                    '"discountPercentage": 0.656'+
                '}, {'+
                    '"id": "feds4",'+
                    '"quantity": 400,'+
                    '"discountPercentage": 0.637'+
                '}, {'+
                    '"id": "feds5",'+
                    '"quantity": 500,'+
                    '"discountPercentage": 0.637'+
                '}]'+
            '}'+
        '}]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/volumeDiscount';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonString);

        RestContext.Request = request;

        Test.startTest();
        VolumeDiscountRestApi.doPost();
        Test.stopTest();

        System.assertEquals(6, [SELECT Count() FROM Volume_Discount__c], 'No.of Volume discount inserted is wrong');
    }

    //when product not found in salesforce
    static testMethod void testCase2() {
        String jsonString = '[{' +
            '"id": "123",'+
            '"data": {'+
                '"productNumber": "764421",'+
                '"modifiedOn" : "2020-09-04T06:10:24.2549110Z", '+
                '"discountThresholds": [{'+
                    '"discountId": "feds0",'+
                    '"lowQty": 0,'+
                    '"discountPercentage": 0.637'+
                '}, {'+
                    '"discountId": "feds1",'+
                    '"lowQty": 100,'+
                    '"discountPercentage": 0.642'+
                '}, {'+
                    '"discountId": "feds2",'+
                    '"lowQty": 200,'+
                    '"discountPercentage": 0.65'+
                '}, {'+
                    '"discountId": "feds3",'+
                    '"lowQty": 300,'+
                    '"discountPercentage": 0.656'+
                '}, {'+
                    '"discountId": "feds4",'+
                    '"lowQty": 400,'+
                    '"discountPercentage": 0.637'+
                '}]'+
            '}'+
        '}]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/volumeDiscount';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonString);

        RestContext.Request = request;

        Test.startTest();
        try {
            VolumeDiscountRestApi.doPost();
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Volume_Discount__c], 'No volume discount should exist, since product is not found');
    }
}