/*************************************************************************
 * Class       :   PortIntegrationRestApi
 * References  :   PortIntegrationRestApiTest.cls
 * Description :   This rest resouce will handle the process related to Port__c records with updated data from external system
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [23.Sep.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
@RestResource(urlMapping='/port')
global class PortIntegrationRestApi {
    public static String requestString;
    
    @HttpPost
    global static void doPost() {
        //SavePoint sp = Database.setSavePoint();

        RestRequest reqeust = RestContext.Request;
        RestResponse response = RestContext.Response;
        List<PortIntegrationRestApiWrapper> requestData;
        requestString = reqeust.requestBody.toString();

        //if any error happens while parsing, send error back
        try {
            requestData = PortIntegrationRestApiWrapper.parse(reqeust.requestBody.toString());
        } catch(Exception e) {
            //add the error to response
            response.statusCode = 500;
            response.responseBody = Blob.valueOf('Bad Request : ' + e.getMessage());
        }

        //if any error happen while manipulating data, then handle within salesforce
        try {
            if(requestData != null) processData(requestData);
        } catch(Exception ex) {
            //capture the error into custom object
            String message = ex.getStackTraceString() +'<br/>' + ex.getMessage() + '<br/>' + ex.getCause() +' <br/>'+ ex.getTypeName();
            TransactionLogHandler.insertErrorWithAttchment(message, 'PortIntegrationRestApi', requestString);
        }
    }

     /**************************************************************************************
     * @Description  Helper method of doPost()
     * @Param		 PortIntegrationRestApiWrapper - the actual request data
     * @Return       void
     **************************************************************************************/  
    public static void processData(List<PortIntegrationRestApiWrapper> requestData) {

        Set<String> portIds = new Set<String>();
        Map<String, String> locationCodesMap = new Map<String, String>();
        Map<String, String> locationCodeWithPortname = new Map<String, String>();
        Map<String, Port__c> portCodeByPortMap = new Map<String, Port__c>();
        Map<String, Location__c> locationCodeByLocationMap = new Map<String, Location__c>();
        List<Port__c> portsToUpsert = new List<Port__c>();

        for(PortIntegrationRestApiWrapper portdata : requestData) {
            portIds.add(portdata.data.portId); 
            String conCode = portdata.data.portCountryCode;
            locationCodesMap.put(conCode, conCode);
            locationCodeWithPortname.put(conCode, portdata.data.portName);
        }

        //to avoid Apex error 'List has no rows for assignment to SObject', query the records into list and get records
        for(Port__c port : [SELECT Id, Port_Code__c, ModifiedOn__c FROM Port__c WHERE Port_Code__c IN: portIds]) {
            portCodeByPortMap.put(port.Port_Code__c, port);
        }
        
        
        for(Location__c location : [SELECT Id,isocode__c FROM Location__c WHERE isocode__c IN: locationCodesMap.values()]) {
            locationCodeByLocationMap.put(location.isocode__c, location);
            if(locationCodesMap.containsKey(location.isocode__c)) {
                locationCodesMap.remove(location.isocode__c);
            }
        }

        if(locationCodesMap.size() > 0) {
            List<Location__c> locations = insertNewLocations(locationCodesMap.values(), locationCodeWithPortname);
            for(Location__c location : locations) {
                locationCodeByLocationMap.put(location.isocode__c, location);
            }
        }

        for(PortIntegrationRestApiWrapper portdata : requestData) {
            Port__c port = portCodeByPortMap.get(portdata.data.portId);
            DateTime modifedDate = formattedDateTime(portdata.data.modifiedOn);

            if(port == null) {
                port = new Port__c();
            }  else if(port.ModifiedOn__c == modifedDate){ //if modified date is not changed, then skip the record
                continue ;
            }

            port.Port_Code__c = portdata.data.portId;
            port.Country_Code__c = portdata.data.portCountryCode;
            port.Name = portdata.data.portName;
            port.ModifiedOn__c = modifedDate;
            port.Location__c = locationCodeByLocationMap.get(portdata.data.portCountryCode).Id;

            portsToUpsert.add(port);
        }

        System.debug('portsToUpsert>>>' + portsToUpsert);
        
        if(portsToUpsert.size() > 0) {
            //upsert portsToUpsert;
            List<Database.upsertResult> uResults = Database.upsert(portsToUpsert, false);
            handleResult(uResults, portsToUpsert);
        }
    }

    /**************************************************************************************
     * @Description  Helper method of processData(), this method hanlde the success and fail result
     * @Param		 uResults - List of redcords with success or fail result
     * @Param        locationCodeWithPortname - map with location code as key and port name as a value
     * @Return       List<Location__c> - newly created location__c records
     **************************************************************************************/  
    public static void handleResult(List<Database.upsertResult> uResults ,  List<Port__c> portsToUpsert) {
        
        String message = '<html><body>';
        String createdMsg  = '<b><u>Records Created :</u></b> ';
        String updatedMsg  = '<b><u>Records Updated :</u></b> ';
        String errorMsg = '<b><u>Errors :</u></b>';
        Boolean attachFile = false;

        //handle errors
        for(Integer i=0; i<uResults.size(); i++) {
            Database.upsertResult result = uResults[i];
            if(!result.isSuccess()) {
                attachFile = true;
                // Operation failed, so get all errors                
                for(Database.Error err : result.getErrors()) {
                    errorMsg +=  '<p> Port Code <b>' + portsToUpsert[i].Port_Code__c + '</b> ====> '+ err.getStatusCode() + ' : ' + err.getMessage() + ' : '+ err.getFields() + '</p> <br/>';
                }
            } else if(result.isSuccess()) {
                if(result.isCreated()) {
                    createdMsg += result.getId() + ',';
                } else {
                    updatedMsg += result.getId() + ',';
                }
            }
        }

        message += createdMsg + '<br/><br/>' + updatedMsg + '<br/><br/>' + errorMsg +'</body></html>';
        if(attachFile) {
            TransactionLogHandler.insertErrorWithAttchment(message, 'PortIntegrationRestApi', requestString);
        } else {
            TransactionLogHandler.doHandleException(null, message, 'PortIntegrationRestApi', null, true, false);
        }
    }

    /**************************************************************************************
     * @Description  Helper method of processData(), this method will insert new location__c record
     * @Param		 locationCodes - List of location codes that needs to be inserted
     * @Param        locationCodeWithPortname - map with location code as key and port name as a value
     * @Return       List<Location__c> - newly created location__c records
     **************************************************************************************/  
    public static List<Location__c> insertNewLocations(List<String> locationCodes, Map<String, String> locationCodeWithPortname) {
        List<Location__c> locationsToInsert = new List<Location__c>();
        for(String locationCode : locationCodes) {
            locationsToInsert.add(
                new Location__c(
                    Name = locationCodeWithPortname.get(locationCode),
                    isocode__c = locationCode
                )
            );
        }

        System.debug('locationsToInsert>>>' + locationsToInsert);
        insert locationsToInsert;

        return locationsToInsert;
    }


     /**************************************************************************************
     * @Description  Helper method of processData(), this method format the datetime strint into datetime format
     * @Param		 dateTimeString - the datetime string
     * @Return       DateTime - the converted datetime value
     **************************************************************************************/ 
    public static DateTime formattedDateTime(String dateTimeString) {
        return (DateTime)JSON.deserialize('"' + dateTimeString + '"', DateTime.class);
    }
}