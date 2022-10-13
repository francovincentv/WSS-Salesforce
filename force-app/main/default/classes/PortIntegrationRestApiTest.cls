@isTest
public class PortIntegrationRestApiTest {
    
    @TestSetup
    static void makeData(){
        Location__c location = new Location__c(
            Name = 'Netherlands',
            isocode__c = 'NL'
        );
        insert location;

        String dateTimeString = '2020-08-19T02:22:30Z';

        Port__c port = new Port__c();
        port.Port_Code__c = 'NLRTM';
        port.Country_Code__c = 'NL';
        port.Name = 'Netherlands';
        port.ModifiedOn__c = (DateTime)JSON.deserialize('"' + dateTimeString + '"', DateTime.class); 
        port.Location__c = location.Id;
        insert port;
    }   

    //test case: if one port and location exist and one port and location not exit
    static testMethod void testCase1(){

        String jsonBody = '[{' +
            '"$schema": "../jsonschema/events/PortCreatedEvent.json",' +
            '"data": {' +
                '"portId": "NLRTM",' +
                '"portCountryCode": "NL",' +
                '"portCountryName": "Netherlands",' +
                '"portName": "Rotterdam",' +
                '"modifiedOn": "2020-07-19T02:22:30Z"' +
            '},' +
            '"subject": "supplychain.port.created",' +
            '"id": "D605343 Specail Offer 2020-08-19T02:22:30Z",' +
            '"eventType": "supplychain.port",' +
            '"dataVersion": "1",' +
            '"metadataVersion": "1",' +
            '"eventTime": "2020-08-19T02:22:30Z",' +
            '"topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG_WSS-INTEGRATION-FINANCE_SOL_WE_TEST/providers/Microsoft.EventGrid/domains/EGD-INTEGRATION-SALES-SOL-WE-TEST/topics/Currency"' +
        '},' +
        '{' +
            '"$schema": "../jsonschema/events/PortCreatedEvent.json",' +
            '"data": {' +
                '"portId": "SWEDE",' +
                '"portCountryCode": "SE",' +
                '"portCountryName": "Sweden",' +
                '"portName": "Swe",' +
                '"modifiedOn": "2020-07-19T02:22:30Z"' +
            '},' +
            '"subject": "supplychain.port.created",' +
            '"id": "D605343 Specail Offer 2020-08-19T02:22:30Z",' +
            '"eventType": "supplychain.port",' +
            '"dataVersion": "1",' +
            '"metadataVersion": "1",' +
            '"eventTime": "2020-08-19T02:22:30Z",' +
            '"topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG_WSS-INTEGRATION-FINANCE_SOL_WE_TEST/providers/Microsoft.EventGrid/domains/EGD-INTEGRATION-SALES-SOL-WE-TEST/topics/Currency"' +
        '}]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/port';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonBody);

        RestContext.Request = request;

        Test.startTest();
        PortIntegrationRestApi.doPost();
        Test.stopTest();

        System.assertEquals(2, [SELECT Count() FROM Port__c]);
        System.assertEquals(2, [SELECT Count() FROM Location__c]);
        System.assertEquals(1, [SELECT Count() FROM Port__c WHERE Port_code__c ='SWEDE']);
        System.assertEquals(1, [SELECT Count() FROM Location__c WHERE isocode__c = 'SE']);
        
    }

    //test case 2: if port lastmodified is same as existing port data
    static testMethod void testCase2(){

        String jsonBody = '[{' +
            '"$schema": "../jsonschema/events/PortCreatedEvent.json",' +
            '"data": {' +
                '"portId": "NLRTM",' +
                '"portCountryCode": "NL",' +
                '"portCountryName": "Netherlands",' +
                '"portName": "Rotterdam",' +
                '"modifiedOn": "2020-08-19T02:22:30Z"' +
            '},' +
            '"subject": "supplychain.port.created",' +
            '"id": "D605343 Specail Offer 2020-08-19T02:22:30Z",' +
            '"eventType": "supplychain.port",' +
            '"dataVersion": "1",' +
            '"metadataVersion": "1",' +
            '"eventTime": "2020-08-19T02:22:30Z",' +
            '"topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG_WSS-INTEGRATION-FINANCE_SOL_WE_TEST/providers/Microsoft.EventGrid/domains/EGD-INTEGRATION-SALES-SOL-WE-TEST/topics/Currency"' +
        '}]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/port';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonBody);

        RestContext.Request = request;

        //before callout lastModifiedDate
        Datetime lastModifiedDate = [SELECT lastModifiedDate FROM Port__c LIMIT 1].lastModifiedDate;

        Test.startTest();
        PortIntegrationRestApi.doPost();
        Test.stopTest();

        //after callout lastModifiedDate should not be changed
        System.assertEquals(lastModifiedDate, [SELECT LastModifiedDate FROM Port__c LIMIT 1].LastModifiedDate);
    }

    //test case 3: if port and locations not found 
    static testMethod void testCase3(){

        String jsonBody = '[{' +
            '"$schema": "../jsonschema/events/PortCreatedEvent.json",' +
            '"data": {' +
                '"portId": "FINLA",' +
                '"portCountryCode": "FL",' +
                '"portCountryName": "Finland",' +
                '"portName": "Finland",' +
                '"modifiedOn": "2020-07-19T02:22:30Z"' +
            '},' +
            '"subject": "supplychain.port.created",' +
            '"id": "D605343 Specail Offer 2020-08-19T02:22:30Z",' +
            '"eventType": "supplychain.port",' +
            '"dataVersion": "1",' +
            '"metadataVersion": "1",' +
            '"eventTime": "2020-08-19T02:22:30Z",' +
            '"topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG_WSS-INTEGRATION-FINANCE_SOL_WE_TEST/providers/Microsoft.EventGrid/domains/EGD-INTEGRATION-SALES-SOL-WE-TEST/topics/Currency"' +
        '},' +
        '{' +
            '"$schema": "../jsonschema/events/PortCreatedEvent.json",' +
            '"data": {' +
                '"portId": "SWEDE",' +
                '"portCountryCode": "SE",' +
                '"portCountryName": "Sweden",' +
                '"portName": "Swe",' +
                '"modifiedOn": "2020-07-19T02:22:30Z"' +
            '},' +
            '"subject": "supplychain.port.created",' +
            '"id": "D605343 Specail Offer 2020-08-19T02:22:30Z",' +
            '"eventType": "supplychain.port",' +
            '"dataVersion": "1",' +
            '"metadataVersion": "1",' +
            '"eventTime": "2020-08-19T02:22:30Z",' +
            '"topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG_WSS-INTEGRATION-FINANCE_SOL_WE_TEST/providers/Microsoft.EventGrid/domains/EGD-INTEGRATION-SALES-SOL-WE-TEST/topics/Currency"' +
        '}]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/port';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonBody);

        RestContext.Request = request;

        Test.startTest();
        PortIntegrationRestApi.doPost();
        Test.stopTest();

        System.assertEquals(3, [SELECT Count() FROM Port__c]);
        System.assertEquals(3, [SELECT Count() FROM Location__c]);
        System.assertEquals(2, [SELECT Count() FROM Port__c WHERE Port_code__c IN ('SWEDE', 'FINLA')]);
        System.assertEquals(2, [SELECT Count() FROM Location__c WHERE isocode__c IN ('SE','FL')]);
        
    }

    //test case 4: exception case 
    static testMethod void testCase4(){

        String jsonBody = '[{' +
            '"$schema": "../jsonschema/events/PortCreatedEvent.json",' +
            '"data": {' +
                '"portId": "FINLA",' +
                '"portCountryCode": "FL",' +
                '"portCountryName": "Finland",' +
                '"portName": "Finland",' +
                '"modifiedOn": ' +System.now() +
            '},' +
            '"subject": "supplychain.port.created",' +
            '"id": "D605343 Specail Offer 2020-08-19T02:22:30Z",' +
            '"eventType": "supplychain.port",' +
            '"dataVersion": "1",' +
            '"metadataVersion": "1",' +
            '"eventTime": "2020-08-19T02:22:30Z",' +
            '"topic": "/subscriptions/64b64c6a-d36b-4e0e-be99-208e9959c2e9/resourceGroups/RG_WSS-INTEGRATION-FINANCE_SOL_WE_TEST/providers/Microsoft.EventGrid/domains/EGD-INTEGRATION-SALES-SOL-WE-TEST/topics/Currency"' +
        '}]';

        RestRequest request = new RestRequest();
        request.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/port';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(jsonBody);

        RestContext.Request = request;

        Test.startTest();
        try{
            PortIntegrationRestApi.doPost();
        } catch (Exception e) {
            System.assertEquals('Attempt to de-reference a null object', e.getMessage());
        }
        Test.stopTest();
    }
}