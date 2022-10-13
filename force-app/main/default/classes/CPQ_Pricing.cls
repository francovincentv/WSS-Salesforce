/*************************************************
* Class       	: CPQ_Pricing
* References  	: CPQ_PricingTest.cls
* Description 	: This rest resouce is developed to use in CPQ custom quote calculator plugin. 
*				  This classe is used in the Custom Script record called "Custom_QCP"
*				  This class will make a call out to external system when the use clicks the calculate button on the edit lines page of a quote

Reqest body:
-----------------------------------------------
{
  "customers": [
    "string" --> Account.Account_Number__c
  ],
  "volume_overrides": [
    {
      "product_code": "string", --> SBQQ__QuoteLine__c.SBQQ__ProductCode__c
      "qty": 0 --> SBQQ__QuoteLine__c.SBQQ__Quantity__c
    }
  ],
  "order_size_override": 0, --> SBQQ__Quote__c.Order_Size_Improvement__c
  "predictability_override": 0 --> SBQQ__Quote__c.Predictability_Improvement__c
}
-----------------------------------------------

* Change Log	
* Date Modified		Modified By 		Description of the update
* [02.Mar.2020]	    [Lokesh - Fluido]	[initial development]
*************************************************/

@RestResource(urlMapping='/pricing/*')
global without sharing class CPQ_Pricing {
    
    @HttpPost
    global static String postExternalPricing(List<String> quoteLineIds) {
        System.debug('CPQB_ExtPricing | postExternalPricing');
        System.debug(quoteLineIds);
        
        Id oppId; 
        Integer orderSize;
        Integer predictability;
        RequestBody requestBody = new RequestBody();
        List<RequestBody.volume_override> volumeOverrideList = new List<RequestBody.volume_override>();
        List<String> accountNumbers = new List<String>();
        
        for(SBQQ__QuoteLine__c qli : [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.Order_Size_Improvement__c,SBQQ__Quote__r.Predictability_Improvement__c , 
                                      SBQQ__Product__c,SBQQ__ProductCode__c,SBQQ__Quantity__c, SBQQ__Quote__r.SBQQ__Opportunity2__c
                                      FROM SBQQ__QuoteLine__c
                                      WHERE Id =: quoteLineIds]){
                                          
                                          //to add volume override
                                          RequestBody.volume_override volumeOverride =  new RequestBody.volume_override();
                                          volumeOverride.product_code = qli.SBQQ__ProductCode__c;
                                          volumeOverride.qty = (Integer) qli.SBQQ__Quantity__c;
                                          volumeOverrideList.add(volumeOverride);
                                          
                                          //
                                          orderSize = (Integer) qli.SBQQ__Quote__r.Order_Size_Improvement__c;
                                          predictability = (Integer) qli.SBQQ__Quote__r.Predictability_Improvement__c;
                                          
                                          //store the opportunity id
                                          oppId = qli.SBQQ__Quote__r.SBQQ__Opportunity2__c;
                                          
                                      }
        
        //fetch the account numbers
        for(Opportunity opp : [SELECT Id, (SELECT Id, Account__r.Account_Number__c  FROM Contract_Parties__r) FROM Opportunity WHERE Id =: oppId]) {
            for(ContractParty__c cp : opp.Contract_Parties__r) {
                accountNumbers.add(cp.Account__r.Account_Number__c);
            }
        }
        
        requestBody.customers = accountNumbers;
        requestBody.volume_overrides = volumeOverrideList;
        requestBody.order_size_override = (orderSize == null ? 0 : orderSize);
        requestBody.predictability_override = (predictability == null ? 0 : predictability);
        
        //get the api key and endpoint from the custom setting
        API_Keys__c api = API_Keys__c.getInstance('CPQ_Pricing');
        
        // Set up the HTTP request to the external service
        HttpRequest req = new HttpRequest();
        req.setEndpoint(api.End_Point__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Ocp-Apim-Subscription-Key', api.API_key__c);
        
        //generate the JSON string
        String json = JSON.serialize(requestBody);
        System.debug('json::'+json);
        
        // Set the Body and send the request
        req.setBody(json);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        // Get the response from the external system and return it
        String returnValue = res.getBody();
        System.debug(res);
        System.debug(res.getBody());
        
        return returnValue;
    }
}