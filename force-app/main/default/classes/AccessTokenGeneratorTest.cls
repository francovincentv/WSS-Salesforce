@isTest
public class AccessTokenGeneratorTest {
   
    static testMethod void testGetAccessToken(){
        API_Keys__c apikey = new API_Keys__c();
        apikey.Name = 'Quote_PDF';
        apikey.End_Point__c = 'https://wilhelmsen.azure-api.net/pricing-simulation/v1/pdf';
        apikey.API_key__c = 'wertyuiop3456fghjktyuio';
        insert apikey;

        AccessTokenGenerator__c atg = new AccessTokenGenerator__c();
        atg.Name = 'QuotePdf';
        atg.EndPoint__c = 'test';
        atg.Scope__c = 'test';
        atg.Clinet_Id__c = 'test';
        atg.Client_Secrect__c = 'test';
        insert atg;
        
        HttpMockFactory mock = new HttpMockFactory(200, 'OK', 'Success!', new Map<String,String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        AccessTokenGenerator.getAccessToken('QuotePdf');
        Test.stopTest();
    }
}