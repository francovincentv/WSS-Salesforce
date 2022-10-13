/*************************************************
* Class                 : QuotePdfRestAPI
* References            : QuotePdfRestAPITest.cls, GetQuotePdf.cmp
* Description           : This class will make a callout to WSS extenal system to get the quote realted PDF and attaches it to the quote
* Change Log    
* Date Modified     Modified By         Description of the update
* ----------------------------------------------------------------
* [10.Aug.2020]     [Lokesh - Fluido]   [Initial development]
*************************************************/
public with sharing class QuotePdfRestAPI {

    public static SBQQ__Quote__c curQuote ; 

    /**************************************************************************************
    * @Description  This method runs from the GetQuotePdf aura component
    *               This method makes callout to extenal system and gets the pdf as response
    * @Param		Id - Quote id
    * @Return       String -  success (or) error 
    **************************************************************************************/ 
    @AuraEnabled
    public static String getQuotePdf(Id quoteId){
        try {
            //generate the request body
            QuotePdfWrapper requestBody = generateBody(quoteId);
        
            //send the request
            String returnVal = sendRequest(JSON.serialize(requestBody), quoteId);
            return returnVal;
        } catch(Exception e) {
            TransactionLogHandler.doHandleException(e,'', 'QuotePdfRestAPI' , quoteId, true, false);
            throw new AuraHandledException('Something went wrong: '
            + e.getMessage());
        }
    }

    /*******************************************************************
     * @desctption  : method to generate the body for the quote
     * @param       : quoteId
     * @return      : QuotePdfWrapper (the body of the request)
     *******************************************************************/
    public static QuotePdfWrapper generateBody(Id quoteId) {
        Id oppId;
        QuotePdfWrapper requestBody = new QuotePdfWrapper();
        List<QuotePdfWrapper.volumeOverride> volumeOverrideList = new List<QuotePdfWrapper.volumeOverride>();
        List<QuotePdfWrapper.salesOverride> salesOverrideList = new List<QuotePdfWrapper.salesOverride>();
        List<String> accountNumbers = new List<String>();

        //generate the request body from quote and quotelines
        for(SBQQ__Quote__c quote : [SELECT Id, Name, Order_Size_Improvement__c,Predictability_Improvement__c,Fleet_size__c, 
                SBQQ__Opportunity2__c, (SELECT Id,SBQQ__ProductCode__c,SBQQ__Quantity__c, ProductGroupCode__c, Final_Discount__c, 
                Sales_USD__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c WHERE Id =: quoteId]) {

                    if(quote.Fleet_size__c == null || quote.Fleet_size__c == 0) {
                        throw new CustomException('Fleet size should be grearthan 0');
                    }

                    curQuote = quote;
                    oppId = quote.SBQQ__Opportunity2__c;

                    //adding data request body
                    requestBody.orderSizeOverride = (quote.Order_Size_Improvement__c == null ? 0 : quote.Order_Size_Improvement__c);
                    requestBody.predictabilityOverride = (quote.Predictability_Improvement__c == null ? 0 : quote.Predictability_Improvement__c);
                    requestBody.fleetSize = (quote.Fleet_size__c == null ? 0 : quote.Fleet_size__c);

                    for(SBQQ__QuoteLine__c quoteLine : quote.SBQQ__LineItems__r) {
                        //to add volume override
                        QuotePdfWrapper.volumeOverride volumeOverride =  new QuotePdfWrapper.volumeOverride();
                        volumeOverride.productId = quoteLine.SBQQ__ProductCode__c;
                        volumeOverride.qty = (Integer) quoteLine.SBQQ__Quantity__c;
                        volumeOverride.finalDiscount = quoteLine.Final_Discount__c == null ? 0 : quoteLine.Final_Discount__c;
                        volumeOverrideList.add(volumeOverride);

                        //to add sales override
                        QuotePdfWrapper.salesOverride salesOverride = new QuotePdfWrapper.salesOverride();
                        salesOverride.productGroup = quoteLine.ProductGroupCode__c == null ? '' : quoteLine.ProductGroupCode__c; 
                        salesOverride.salesUsd = quoteLine.Sales_USD__c == null ? 0 : quoteLine.Sales_USD__c; 
                        salesOverrideList.add(salesOverride);
                    }
                }
            
        //fetch the account numbers
        for(Opportunity opp : [SELECT (SELECT Account__r.Account_Number__c  FROM Contract_Parties__r) FROM Opportunity WHERE Id =: oppId]) {
            for(ContractParty__c cp : opp.Contract_Parties__r) {
                accountNumbers.add(cp.Account__r.Account_Number__c);
            }
        }

         //adding data request body
        requestBody.customers = accountNumbers;
        requestBody.volumeOverrides = volumeOverrideList;
        requestBody.salesOverrides = salesOverrideList;

        return requestBody;

    }

    /******************************************************
     * @desctption  : method to send post request
     * @param       : String - jsonBody
     * @return      : String 
     ******************************************************/
    public static String sendRequest(String jsonBody, String quoteId) {

        String returnVal;

        //get the api key and endpoint from the custom setting
        API_Keys__c pdfAPI = API_Keys__c.getInstance('Quote_PDF');
        String accessToken;

        //set dummy token when executing from test class
        if(Test.isRunningTest()) {
            accessToken = 'dffdsdfdsadfsa';
        } else {
            accessToken = AccessTokenGenerator.getAccessToken('QuotePdf');
        }

        // Set up the HTTP request to the external service
        HttpRequest request = new HttpRequest();
        request.setEndpoint(pdfAPI.End_Point__c);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Ocp-Apim-Subscription-Key', pdfAPI.Subscription_Key__c);
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setTimeout(120000);
        request.setBody(jsonBody);

         //send the request
         Http http = new Http();
         HTTPResponse response = http.send(request);

         if (response.getStatusCode() == 200) {
            //handle the pdf response
            Blob responsePDF = response.getBodyAsBlob();
        
            insertQuotePdf(responsePDF, curQuote.Id, curQuote.Name);
        
            returnVal = 'Success';
         } else {
            System.debug('error'+response.getBody());
            returnVal = response.getBody();
            TransactionLogHandler.doHandleException(null, returnVal, 'QuotePdfRestAPI', quoteId, true, false);
         }

         return returnVal;
    }

    public static void insertQuotePdf(Blob blobValue, Id quoteId, String quoteName) {
        //create a file
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // S specify this document is in SF
        conVer.PathOnClient = quoteName + '_' + Datetime.now().format('MMM_d_yyyy_HH:mm:ss') + '_Preview.pdf'; 
        conVer.Title = quoteName + '_' + Datetime.now().format('MMM_d_yyyy_HH:mm:ss') + '_Preview'; 
        conVer.VersionData = blobValue;
        insert conVer;

        // get the content document Id from ContentVersion
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        //Create ContentDocumentLink that links the file with current quote
        ContentDocumentLink cDL = new ContentDocumentLink();
        cDL.ContentDocumentId = conDoc;
        cDL.LinkedEntityId = quoteId; 
        cDL.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
        cDL.Visibility = 'AllUsers';
        insert cDL;
    }
}