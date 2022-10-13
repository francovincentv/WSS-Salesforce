/*************************************************************************
 * Class       :   VolumeDiscountRestApi
 * References  :   VolumeDiscountRestApiTest.cls
 * Description :   This rest resouce will handle the process related to Volument_Discount records(based on quanity) with updated data from external system
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [23.Sep.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
@RestResource(urlMapping='/volumeDiscount')
global class VolumeDiscountRestApi {

    static final String PRODUCTS = 'Products';
    global static final Map<String,Schema.RecordTypeInfo> VD_REC_TYPES = Schema.SObjectType.Volume_Discount__c.getRecordTypeInfosByDeveloperName();
    public static string requestStirng;
   
    @HttpPost
    global static void doPost() {
        
        RestRequest request = RestContext.Request;
        RestResponse response = RestContext.Response;
        List<VolumeDiscountRestApiWrapper> requestData ;
        requestStirng = request.requestBody.toString();

        //if any error happens while parsing, send error back
        try{
            requestData = VolumeDiscountRestApiWrapper.parse(request.requestBody.toString());
        } catch (Exception e) {
            //add the error to response
            response.statusCode = 500;
            response.responseBody = Blob.valueOf('Bad Request : ' + e.getMessage());
        }

        //if any error happen while manipulating data, then handle within salesforce
        try {
            if(requestData != null) {
                processData(requestData);
            }
        } catch (Exception ex) {
            String message = ex.getStackTraceString() +'<br/>' + ex.getMessage() + '<br/>' + ex.getCause() +' <br/>'+ ex.getTypeName();
            TransactionLogHandler.insertErrorWithAttchment(message, 'VolumeDiscountRestApi', requestStirng);
        }
    }

    /**************************************************************************************
     * @Description  Helper method of doPost()
     * @Param		VolumeDiscountRestApiWrapper - the actual request data
     * @Return       void
     **************************************************************************************/  
    public static void processData(List<VolumeDiscountRestApiWrapper> requestData) {
        Set<String> productCodes = new Set<String>();
        Map<String, Product2> prodCodeWithProductMap = new Map<String, Product2>();

        //List of Volume_Discount__c records that needs to inserted/updated
        List<Volume_Discount__c> volDiscountInsertList = new List<Volume_Discount__c>();

        //set of product Ids, where we can use them to delete the related volume discounts
        Set<Id> prodIds = new Set<Id>();

        for(VolumeDiscountRestApiWrapper eachRequest : requestData) {
            productCodes.add(eachRequest.data.productNumber);
        }

        //query the products and form it into a map by product code
        for(Product2 prod : [SELECT Id, Product_Code__c, Product_Discount_Group__c FROM Product2 WHERE Product_Code__c IN: productCodes]) {
            prodCodeWithProductMap.put(prod.Product_Code__c, prod);
        }

        for(VolumeDiscountRestApiWrapper eachRequest : requestData) {
            Product2 prod = prodCodeWithProductMap.get(eachRequest.data.productNumber);
            if(prod != null) {
                List<Volume_Discount__c> curProductDiscounts = generateVolumeDiscounts(eachRequest, prod);
                if(curProductDiscounts.size() > 0) {
                    volDiscountInsertList.addAll(curProductDiscounts);
                    prodIds.add(prod.Id);
                }
            }
        }

        //insert/update the records
        if(volDiscountInsertList.size() > 0) {
            //delete the exiting volume discount records
            delete [SELECT Id FROM Volume_Discount__c WHERE Product__c =: prodIds AND RecordType.DeveloperName =: PRODUCTS];

            //insert new discounts
            List<Database.SaveResult> uResults = Database.insert(volDiscountInsertList, false);  
            handleResult(uResults, volDiscountInsertList);
        }
        
    }

    /**************************************************************************************
     * @Description  Helper method of processData(), this method hanlde the success and fail result
     * @Param		 uResults - List of redcords with success or fail result
     * @Param        locationCodeWithPortname - map with location code as key and port name as a value
     * @Return       List<Location__c> - newly created location__c records
     **************************************************************************************/  
    public static void handleResult(List<Database.SaveResult> uResults ,  List<Volume_Discount__c> vdUpsertList) {
        
        String message = '<html><body>';
        String createdMsg  = '<b><u>Records Created :</u></b> ';
        String errorMsg = '<b><u>Errors :</u></b>';
        Boolean attachFile = false;

        //handle errors
        for(Integer i=0; i<uResults.size(); i++) {
            Database.SaveResult result = uResults[i];
            if(!result.isSuccess()) {
                attachFile = true;
                // Operation failed, so get all errors                
                for(Database.Error err : result.getErrors()) {
                    errorMsg +=  '<p> Product Code :<b>' + vdUpsertList[i].Product_Code__c + '</b> and Discount Id : <b>'+vdUpsertList[i].discountId__c+'</b> ====> '+ err.getStatusCode() + ' : ' + err.getMessage() + ' : '+ err.getFields() + '</p> <br/>';
                }
            } else if(result.isSuccess()) {
                createdMsg += result.getId() + ',';
            }
        }

        message += createdMsg + '<br/><br/>' + errorMsg +'</body></html>';
        if(attachFile) {
            TransactionLogHandler.insertErrorWithAttchment(message, 'VolumeDiscountRestApi', requestStirng);
        } else {
            TransactionLogHandler.doHandleException(null, message, 'VolumeDiscountRestApi', null, true, false);
        }
    }

    /**************************************************************************************
     * @Description  Helper method of doPost(), this method will generate the Volume_Discount__c records that needs to be inserted
     * @Param		List<VolumeDiscountRestApiWrapper.VolumeDiscounts> - the volume discount information for each product 
     * @Param        Product2 - the actual product where the volume discount to be applied
     * @Return       List<Volume_Discount__c> - volDiscountInsertList
     **************************************************************************************/  
    public static List<Volume_Discount__c> generateVolumeDiscounts(VolumeDiscountRestApiWrapper eachRequest, Product2 product) {

        //modified data of the proudct volume disoucnts
        DateTime modifiedTime = formattedDateTime(eachRequest.data.modifiedOn);

        //List of Volume_Discount__c records that needs to inserted/updated
        List<Volume_Discount__c> volDiscountInsertList = new List<Volume_Discount__c>();

        List<VolumeDiscountWrapper> volDiscountWrapperList = new List<VolumeDiscountWrapper>();

        //loop the records to store the volumeDiscounts in 'VolumeDiscountWrapper' object, so it can be sorted
        for(VolumeDiscountRestApiWrapper.DiscountThresholds volDiscount : eachRequest.data.discountThresholds) {
            volDiscountWrapperList.add(new VolumeDiscountWrapper(volDiscount));
        }

        //sort the volumeDiscounts by 'quantity'
        volDiscountWrapperList.sort();

        //size of volume discounts
        Integer volDiscountSize = volDiscountWrapperList.size();


        for(Integer i=0; i<volDiscountSize; i++) {
            VolumeDiscountRestApiWrapper.discountThresholds curVolDiscount = volDiscountWrapperList[i].volDiscount;
            VolumeDiscountRestApiWrapper.discountThresholds nextVolDiscount = ((i+1) < volDiscountSize) ? volDiscountWrapperList[i+1].volDiscount : null;

            Volume_Discount__c vd = new Volume_Discount__c();            
            vd.RecordtypeId = VD_REC_TYPES.get(PRODUCTS).getRecordTypeId();
            vd.volumeSchemeId__c = eachRequest.id;
            vd.Product__c = product.Id;
            vd.Volume_Discount__c = curVolDiscount.discountPercentage;
            vd.Product_Code__c = product.Product_Code__c;
            vd.discountId__c = curVolDiscount.id;
            vd.Min_Qty__c = curVolDiscount.quantity;
            vd.Max_Qty__c = nextVolDiscount != null ? (nextVolDiscount.quantity - 1) : 999999;
            vd.modifiedOn__c = modifiedTime;
            volDiscountInsertList.add(vd);

        }

        return volDiscountInsertList;
    }



    /* 
     * Wrapper class to sort the volume discount by quantity field vlaue
     */
    public class VolumeDiscountWrapper implements Comparable {
        public VolumeDiscountRestApiWrapper.DiscountThresholds volDiscount = new VolumeDiscountRestApiWrapper.DiscountThresholds();

        public VolumeDiscountWrapper(VolumeDiscountRestApiWrapper.DiscountThresholds vd) {
            volDiscount = vd;
        }

        // Compare members based on the VolumeDiscountRestApiWrapper.DiscountThresholds quantity.
        public Integer compareTo(Object obj) {

            //case argument to VolumeDiscountRestApiWrapper.DiscountThresholds
            VolumeDiscountWrapper compareToVd = (VolumeDiscountWrapper) obj;

            Integer returnVal = 0;
            if (volDiscount.quantity > compareToVd.volDiscount.quantity) {
                // Set return value to a positive value.
                returnVal = 1;
            } else if (volDiscount.quantity < compareToVd.volDiscount.quantity) {
                // Set return value to a negative value.
                returnVal = -1;
            }

            return returnVal;
        }
    }

    public static DateTime formattedDateTime(String dateTimeString) {
        return (DateTime)JSON.deserialize('"' + dateTimeString + '"', DateTime.class);
    }
}