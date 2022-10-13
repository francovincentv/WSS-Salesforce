/*************************************************
* Class                 : CustomerContractIntegration
* References            : CustomerContractIntegrationTest.cls
* Description           : This class will make a callout to WSS extenal system with necessary contract informaiton and handles the response
* Change Log    
* Date Modified     Modified By         Description of the update
* [10.Aug.2020]     [Lokesh - Fluido]   [Initial development]
*************************************************/
public class CustomerContractIntegration {

    /**************************************************************************************
    * @Description  This method runs from the flow
    *               This method make a callout to external system along with the contract information
    * @Param		List<Id> - Contact ids
    * @Return       void
    **************************************************************************************/ 
    @InvocableMethod 
    public static void initiateCalloutFromFlow(List<Id> contractIds) {
        Map<Id, CustomerContractBodyWrapper> bodyMap = CustomerContractIntegrationHelper.generateBody(contractIds);
        //System.debug('****** '+ JSON.serializePretty(bodyMap.values()));

        String jsonBody = JSON.serializePretty(bodyMap.values());
        sendFutureRequest(jsonBody, contractIds); 
    }

    /**************************************************************************************
    * @Description  This method runs from the button 'Send Contract Info' on contract record deatils page
    *               This method make a callout to external system along with the contract information
    * @Param		List<Id> - Contact ids (this will only contain one contract id)
    * @Return       Integer 
    **************************************************************************************/ 
    @AuraEnabled
    public static Integer initiateCalloutFromContract(List<Id> contractIds){
        Map<Id, CustomerContractBodyWrapper> bodyMap = CustomerContractIntegrationHelper.generateBody(contractIds);
        String jsonBody = JSON.serialize(bodyMap.values());
        //System.debug('*******'+ jsonBody);
        
        Integer responseCode =  sendRequest(jsonBody);

        //once the callout is done, then update the Contract_Integrated__c field on contract accordingly
        Contract cntrt = new Contract(Id = contractIds[0]);
        if (responseCode == 200) { 
            cntrt.Contract_Integrated__c = true; 
            update cntrt;
            saveAttachment(jsonBody,contractIds[0]);
        }

        return responseCode;
    }

    /**************************************************************************************
    * @Description  This method runs from the button 'Send Contract Info' on Quote record deatils page
    *               This method make a callout to external system along with the contract information
    * @Param		Id - Quote Id
    * @Return       Integer 
    **************************************************************************************/ 
    @AuraEnabled
    public static Integer initiateCalloutFromQuote(Id quoteId){
        try {
            Id masterContractId = CustomerContractIntegrationHelper.getContractIdFromQuote(quoteId);
            Map<Id, SBQQ__Quote__c> quotes = CustomerContractIntegrationHelper.getSplOfferOpptyQuotes(masterContractId);
            Map<Id, CustomerContractBodyWrapper> bodyMap = CustomerContractIntegrationHelper.generateBody(new List<Id>{masterContractId});
            CustomerContractIntegrationHelper.addSplOfferOpptyQuotesToBody(bodyMap.get(masterContractId), quotes);
            String jsonBody = JSON.serialize(bodyMap.values());
            //System.debug('****** json from quote '+ jsonBody);
            Integer responseCode = sendRequest(jsonBody);
            
            SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = quoteId);
            if (responseCode == 200) { 
                quote.Contract_Integrated__c = true; 
                update quote;
                saveAttachment(jsonBody,quoteId);
            }

            return responseCode;
        } catch(CustomException e){
            System.debug('custom exception ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        } catch(Exception e) {
             System.debug('error' + e.getMessage());
             System.debug('error' + e.getStackTraceString());
             throw new AuraHandledException(e.getMessage());
        }
    }

    /**************************************************************************************
    * @Description  helper method for sendRequest() and sendFutureRequest()
    *               This method generate the HttpRequest 
    * @Param		String - request body in string format
    * @Return       HttpRequest 
    **************************************************************************************/ 
    public static HttpRequest generateHttpRequest(String jsonBody) {
        System.debug('Json Body : ' + jsonBody);
        //get the api key and endpoint from the custom setting
        API_Keys__c contractAPI = API_Keys__c.getInstance('ContractIntegration');

        // Set up the HTTP request to the external service
        HttpRequest request = new HttpRequest();
        request.setEndpoint(contractAPI.End_Point__c);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('aeg-sas-key', contractAPI.API_key__c);
        request.setBody(jsonBody);

        return request;
    }

    /**************************************************************************************
    * @Description  Helper method for initiateCalloutFromContract() and initiateCalloutFromQuote
    *               this method will send the http request to external system
    * @Param		String - request body in string format
    * @Return       Integer 
    **************************************************************************************/ 
    public static Integer sendRequest(String jsonBody) {
        try {
            System.debug('jsonBody >>> ' + JSON.serialize(jsonBody));
            HttpRequest request = generateHttpRequest(jsonBody);
            Http http = new Http();
            HTTPResponse response = http.send(request);

            //if request is not success, then send mail to admin
            if(response.getStatusCode() != 200) {
                String error = response.getStatusCode() + '.' + response.getBody();
            }

            return response.getStatusCode();
        } catch (Exception e) {
            System.debug('error' +e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**************************************************************************************
    * @Description  helper method for initiateCalloutFromFlow() 
    *               This method will send the http request to external system in future
    * @Param		String - request body in string format
    * @Param		List<Id> - Contract ids
    * @Return       void 
    **************************************************************************************/ 
    @future(callout=true)
    public static void sendFutureRequest(String jsonBody, List<Id> contractIds) {
        try {
            HttpRequest request = generateHttpRequest(jsonBody);
            Http http = new Http();
            HTTPResponse response = http.send(request);
            String responseStatus = 'Status Code=' + response.getStatusCode() + ', Status=' + response.getStatus();
            CustomerContractIntegrationHelper.updateIntegrationStatus(responseStatus, contractIds);
        } catch (Exception e) {
            System.debug('error' + e.getMessage());
            System.debug('Tree' + e.getStackTraceString());
            CustomerContractIntegrationHelper.updateIntegrationStatus(e.getStackTraceString(), contractIds);
        }
    }
        /**************************************************************************************
     * @Description  This method will create an attachment that contains the payload that is sent to IFS
     * @Param		 Map<Id, CustomerContractBodyWrapper> bodyMap 
     * @Return       void
     **************************************************************************************/ 
    public static void saveAttachment(String jsonBody, Id recId){
        try {
            String recordName;
            String sObjName = recId.getSObjectType().getDescribe().getName();
            if(sObjName == 'Contract' ){
                recordName = [SELECT ContractNumber FROM Contract WHERE Id =: recId].ContractNumber;
            }else if(sObjName == 'SBQQ__Quote__c' ){
                recordName = [SELECT Name FROM SBQQ__Quote__c WHERE Id =: recId].Name;           
            }
            //create a file
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.VersionData = Blob.valueOf(jsonBody);
            contentVersion.Title = recordName + '_' + Datetime.now().format('MMM_d_yyyy_HH:mm:ss');
            contentVersion.ContentLocation = 'S'; 
            contentVersion.PathOnClient = '.txt';
            insert contentVersion;

            // get the content document Id from ContentVersion
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id].ContentDocumentId;

            //Create ContentDocumentLink that links the file with current contract
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = conDocId;
            contentDocumentLink.LinkedEntityId = recId;
            contentDocumentLink.ShareType = 'I'; // Inferred permission
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;
        } catch(Exception e) {
            System.debug('Error while generating the file' + e.getMessage());
        }
    }
}