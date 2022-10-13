/*************************************************************************
 * Class       :   AccessTokenGenerator
 * References  :   VolumeDiscountRestApi.cls, PriceListRestApi.cls
 * Description :   This class will generate the access_token for based on the client details mentioned in  'AccessTokenGenerator__c' custom settings
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [23.Sep.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
public with sharing class AccessTokenGenerator {

    public static String getAccessToken(String endPoint) {

        //get the details from the AccessTokenGenerator__c custom setting
        AccessTokenGenerator__c accessDetails = AccessTokenGenerator__c.getInstance(endPoint);

        String accessToken ; 
        String clientId = accessDetails.Clinet_Id__c;
        String clientSecret =  accessDetails.Client_Secrect__c;
        String accessEndPath =  accessDetails.EndPoint__c;
        String scope =  accessDetails.Scope__c;
        String body = 'grant_type = client_credentials&client_secret='+ clientSecret +'&client_id='+clientId+'&scope=' +scope;

        Map<String,String> mapHeaders = new Map<String,String>(); 
        mapHeaders.put('Content-Type', 'application/x-www-form-urlencoded');
        mapHeaders.put('body', body);

        //initiate request
        HttpResponse objResponse = sendCallout(accessEndPath,'POST',mapHeaders); 

        //deserialize the response
        Map<String,Object> deconstructedResponse = Test.isRunningTest() ? new Map<String,Object>() : (Map<String,Object>) JSON.deserializeUntyped(objResponse.getBody());

        //get the access token
        if(deconstructedResponse.containsKey('access_token')) {
            accessToken = (String) deconstructedResponse.get('access_token'); 
        }
        return accessToken ; 
    }

    private static HttpResponse sendCallout(String endPoint , String methodType , Map<String,String> mapHeaders) {
        HttpRequest request = new HttpRequest(); 
        request.setEndpoint(endpoint); 
        request.setMethod(methodType); 

        if(mapHeaders.containsKey('body')){
            request.setBody(mapHeaders.get('body')); 
            mapHeaders.remove('body');
        }

        for(String key : mapHeaders.keySet()) {
            request.setHeader(key, mapHeaders.get(key));
        }
       
        Http objHttp = new Http();
        HttpResponse objResponse = objHttp.send(request); 

        return objResponse ; 
    }
}