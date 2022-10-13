/*************************************************************************
 * Class       :   PurchaseHistoryRestApi
 * References  :   PurchaseHistoryRestApiTest.cls
 * Description :   This rest resouce will handle the process related to Purchase_History_Bucket_Lines__c records with updated data from external system
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [03.Sep.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
@RestResource(urlMapping='/order')
global without sharing class PurchaseHistoryRestApi {

    public static string requestStirng;

    
    @HttpPost
    global static void doPost() {
      
        RestRequest request = RestContext.Request;
        RestResponse response = RestContext.Response;
        requestStirng = request.requestBody.toString();
        List<PurchaseHistoryRestApiWrapper> requestData;

         //if any error happens while parsing, send error back
         try{
            requestData = PurchaseHistoryRestApiWrapper.parse(request.requestBody.toString());
        } catch (Exception e) {
            //add the error to response
            response.statusCode = 500;
            response.responseBody = Blob.valueOf('Bad Request : ' + e.getMessage());
        }
        
        //if any error happen while manipulating data, then handle within salesforce
        try {
            if(requestData != null) processData(requestData);
        } catch(Exception ex) {
            String message = ex.getStackTraceString() +'<br/>' + ex.getMessage() + '<br/>' + ex.getCause() +' <br/>'+ ex.getTypeName();
            TransactionLogHandler.insertErrorWithAttchment(message, 'PurchaseHistoryRestApi', requestStirng);
        } 
    }

    /**************************************************************************************
    * @Description  Helper method of doPost()
    * @Param		List<PurchaseHistoryRestApiWrapper> the request body
    * @Return       void
    **************************************************************************************/  
    public static void processData(List<PurchaseHistoryRestApiWrapper> requestData) {

        List<Purchase_History_Bucket_Lines__c> phbLinesUpsertList = new List<Purchase_History_Bucket_Lines__c>();
        Map<String, PurchaseHistoryRestApiWrapper> uniqueIdWithRequestDataMap = new Map<String, PurchaseHistoryRestApiWrapper>();
        Map<String, Purchase_History_Bucket_Lines__c> phbLinesMap = new Map<String, Purchase_History_Bucket_Lines__c>();
        Map<String, PurchaseHistoryBucket__c> phbMap = new Map<String, PurchaseHistoryBucket__c>();
        Map<String, Product2> prodCodeWithProdMap = new Map<String, Product2>();
        Map<String, Account> accNumWithAccountMap = new Map<String, Account>();
        Map<Id, Parent_PHB__c> accIdToParentPHB = new Map<Id, Parent_PHB__c>();
        Map<String, String> uniqueIdToAccNum = new Map<String, String>();
        Map<String, String> uniqueIdToOrderNum = new Map<String, String>();
        Set<String> prodCodes = new Set<String>();
        Set<String> accountNums = new Set<String>();
        Set<String> orderNums = new Set<String>();
        Set<String> uniqueIds = new Set<String>();
        Set<Id> accIds = new Set<Id>();
        Set<String> accNumAndProdCode = new Set<String>();

        for(PurchaseHistoryRestApiWrapper ph : requestData) {
            String accNum = ph.data.payer;
            String orderNum = ph.data.orderNo;
            accountNums.add(accNum);
            orderNums.add(orderNum);

            for(PurchaseHistoryRestApiWrapper.OrderLines orderLine : ph.data.orderLines) {
                prodCodes.add(orderLine.productId);
                String uniqueId = accNum + orderNum + orderLine.productId + orderLine.lineNo + orderLine.relNo + String.valueOf(orderLine.lineItemNo) + orderLine.invoiceNo + orderLine.invoiceSeries;
                uniqueIds.add(uniqueId);
                uniqueIdToAccNum.put(uniqueId, accNum);
                uniqueIdToOrderNum.put(uniqueId, orderNum);
                accNumAndProdCode.add(accNum+'-'+orderLine.productId);
            }
        }

        //get necessary information from account
        for(Account account : [SELECT Id, Account_Number__c FROM Account WHERE Account_Number__c =:accountNums]) {
            accNumWithAccountMap.put(account.Account_Number__c, account);
            accIds.add(account.Id);
        }

        //get the parent phb
        for(Parent_PHB__c parentPHB : [SELECT Id, Account__c FROM Parent_PHB__c WHERE Account__c IN: accIds]) {
            accIdToParentPHB.put(parentPHB.Account__c, parentPHB);
        }

        //get necessary information from product
        for(Product2 product : [SELECT Id, Product_Code__c, Sales_Product_Group__c FROM Product2 WHERE Product_Code__c IN: prodCodes]) {
            prodCodeWithProdMap.put(product.Product_Code__c , product);
        }

        //get necessary information from PurchaseHistoryBucket__c
        for(PurchaseHistoryBucket__c pbh : [SELECT Id, ProductCode__c, Account__c, Row_Id__c  FROM PurchaseHistoryBucket__c WHERE Row_Id__c IN:accNumAndProdCode]) {
            System.debug('existing phb key ' + pbh.Row_Id__c);
            phbMap.put(pbh.Row_Id__c , pbh);
        }

        //get necessary information from Purchase_History_Bucket_Lines__c
        for(Purchase_History_Bucket_Lines__c phbLine : [SELECT Id, Unique_ID__c FROM Purchase_History_Bucket_Lines__c WHERE Unique_ID__c IN:uniqueIds]) {
            phbLinesMap.put(phbLine.Unique_ID__c, phbLine);
        }

        //clear the uniqueIds, to re-use it
        uniqueIds = new Set<String>();
        Map<String, PurchaseHistoryBucket__c> newPHBMap = new Map<String, PurchaseHistoryBucket__c>();

        //this for loop is used to create PHB and Parent_PHB record if not exist in salesforce
        for(PurchaseHistoryRestApiWrapper ph : requestData) {
            for(PurchaseHistoryRestApiWrapper.OrderLines orderLine : ph.data.orderLines) {
                String uniqueId = ph.data.payer + ph.data.orderNo + orderLine.productId + orderLine.lineNo + orderLine.relNo + String.valueOf(orderLine.lineItemNo) + orderLine.invoiceNo + orderLine.invoiceSeries;
                String accNumProdCode = ph.data.payer + '-' + orderLine.productId;

                //if this data already processed, then skip 
                 if(uniqueIds.contains(uniqueId)) {
                    continue;
                }

                uniqueIds.add(uniqueId);

                Product2 product = prodCodeWithProdMap.get(orderLine.productId);
                if(product != null) {
                    Account acc = accNumWithAccountMap.get(uniqueIdToAccNum.get(uniqueId));
                    if(acc == null) {
                        continue;
                    }

                    PurchaseHistoryBucket__c phb = phbMap.get(accNumProdCode);
                    System.debug('<<phb>> ' + phb);
                    if(phb == null) {
                        Parent_PHB__c parentPHB = accIdToParentPHB.get(acc.Id);
                        //if parent PHB not availble then create new one
                        if(parentPHB == null) {
                            parentPHB = createNewParentPhb(acc.Id);
                            accIdToParentPHB.put(acc.Id, parentPHB); 
                        }

                        phb = generateNewPhb(acc, product, parentPHB.Id);
                        newPHBMap.put(accNumProdCode, phb);
                    }
                }
            }
        }

        //insert new phb
        if(newPHBMap.size() > 0) {
            insertNewPhb(newPHBMap.values(), phbMap);
        }

        uniqueIds = new Set<String>();
        //this for loop is used to create or update PHBL records with the latest values
        for(PurchaseHistoryRestApiWrapper ph : requestData) {
            for(PurchaseHistoryRestApiWrapper.OrderLines orderLine : ph.data.orderLines) {
                //generate unique id
                String uniqueId = ph.data.payer + ph.data.orderNo + orderLine.productId + orderLine.lineNo + orderLine.relNo + String.valueOf(orderLine.lineItemNo) + orderLine.invoiceNo + orderLine.invoiceSeries;
                String accNumProdCode = ph.data.payer + '-' + orderLine.productId;

                //if this data already processed, then skip this loop
                if(uniqueIds.contains(uniqueId)) {
                    continue;
                }

                uniqueIds.add(uniqueId);

                Product2 product = prodCodeWithProdMap.get(orderLine.productId);

                //if product exist in salesforce, then proceed for next steps
                if(product != null) {
                    Account acc = accNumWithAccountMap.get(uniqueIdToAccNum.get(uniqueId));
                 
                    if(acc == null) {
                        continue;
                    }
                    
                    Purchase_History_Bucket_Lines__c phbLine = phbLinesMap.get(uniqueId);
                    Boolean addToUpsert = true;

                    //Purchase_History_Bucket_Lines__c not exist in salesforce then create new one
                    if(phbLine == null) {
                        //if no purchasehistorybucket__c record found
                        if(phbMap.get(accNumProdCode) != null) {
                            phbLine = new Purchase_History_Bucket_Lines__c();
                            phbLine.Purchase_History_Bucket__c = phbMap.get(accNumProdCode).Id;
                        } else {
                            addToUpsert = false;
                        }
                    }

                    if(addToUpsert) {
                        addLatestValueToPHBL(orderLine, ph, phbLine, acc);
                        phbLinesUpsertList.add(phbLine);
                    }
                }
            }
        }
   
        if(phbLinesUpsertList.size() > 0) {
            List<Database.upsertResult> uResults = Database.upsert(phbLinesUpsertList, false);  
            handleResult(uResults, phbLinesUpsertList);
        }
    }

    /**************************************************************************************
     * @Description  Helper method of processData(), this method hanlde the success and fail result
     * @Param		 phbInsertList - List of new PurchaseHistoryBucket__c records to insert
     * @Param        phbMap - map which holds the new PurchaseHistoryBucket__c records
     * @Return       void
     **************************************************************************************/  
    public static void insertNewPhb(List<PurchaseHistoryBucket__c> phbInsertList, Map<String, PurchaseHistoryBucket__c> phbMap) {
        List<Database.SaveResult> srList = Database.insert(phbInsertList, false);
            
        Set<Id> newPhbIds = new Set<Id>();

        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                newPhbIds.add(sr.getId());
            }
        }
        for(PurchaseHistoryBucket__c phb : [SELECT Id, Account__c, ProductCode__c, Row_Id__c FROM PurchaseHistoryBucket__c WHERE ID IN: newPhbIds]) {
            phbMap.put(phb.Row_Id__c , phb);
        }
    }

     /**************************************************************************************
     * @Description  Helper method of processData(), this method hanlde the success and fail result
     * @Param		 uResults - List of redcords with success or fail result
     * @Param        locationCodeWithPortname - map with location code as key and port name as a value
     * @Return       List<Location__c> - newly created location__c records
     **************************************************************************************/  
    public static void handleResult(List<Database.upsertResult> uResults ,  List<Purchase_History_Bucket_Lines__c> phbLinesUpsertList) {
        
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
                    errorMsg +=  '<p> Product Code :<b>' + phbLinesUpsertList[i].payer__c + '</b> and Discount Id : <b>'+phbLinesUpsertList[i].productId__c+'</b> ====> '+ err.getStatusCode() + ' : ' + err.getMessage() + ' : '+ err.getFields() + '</p> <br/>';
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
            TransactionLogHandler.insertErrorWithAttchment(message, 'PurchaseHistoryRestApi', requestStirng);
        } else {
            TransactionLogHandler.doHandleException(null, message, 'PurchaseHistoryRestApi', null, true, false);
        }
    }

    /**************************************************************************************
    * @Description  Helper method of processData()
    * @Param		PurchaseHistoryRestApiWrapper.OrderLines - orderLine
    * @Param        PurchaseHistoryRestApiWrapper - the actual purchase histrory data
    * @Param        Purchase_History_Bucket_Lines__c - The PHBL to insert or udpate
    * @Param        Account - the account related to the PHBL
    * @Return       void
    **************************************************************************************/  
    public static void addLatestValueToPHBL(PurchaseHistoryRestApiWrapper.OrderLines orderLine, PurchaseHistoryRestApiWrapper ph, Purchase_History_Bucket_Lines__c phbLine, Account acc) {
        //keep the updated values 
        phbLine.Amount__c = Decimal.valueOf(orderLine.amount);
        phbLine.relNo__c = orderLine.relNo;
        phbLine.qtyRefr__c = orderLine.qtyRefr;
        phbLine.qty__c = Decimal.valueOf(orderLine.qty);
        phbLine.productId__c = orderLine.productId;
        phbLine.port__c = ph.data.port;
        phbLine.payer__c = Decimal.valueOf(acc.Account_Number__c);
        phbLine.orderType__c = ph.data.orderType;
        phbLine.orderNo__c = ph.data.orderNo;
        phbLine.Order_modifiedOn__c = formatDateTime(ph.data.modifiedOn);
        phbLine.modifiedOn__c = formatDateTime(orderLine.modifiedOn);
        phbLine.createdDate__c = formatDateTime(orderLine.createdDate);
        phbLine.lineItemNo__c = orderLine.lineItemNo;
        phbLine.lineNo__c = orderLine.lineNo;
        phbLine.invoiceNo__c = orderLine.invoiceNo;
        phbLine.invoiceSeries__c = orderLine.invoiceSeries;
        phbLine.invoiceDate__c = formatDateTime(orderLine.invoiceDate);
        phbLine.deliveryDate__c = formatDateTime(orderLine.deliveryDate);
        phbLine.CurrencyIsoCode = orderLine.transactionCurrencyId;
        phbLine.accountSalesIncome__c = (orderLine.accountSalesIncome == 'Y' || orderLine.accountSalesIncome == 'true' ? TRUE : FALSE);
    }

    /**************************************************************************************
    * @Description  Helper method of processData()
    * @Param		Id - accountId
    * @Return       Parent_PHB__c
    **************************************************************************************/  
    public static Parent_PHB__c createNewParentPhb(Id accId) {
        Parent_PHB__c parentPHB = new Parent_PHB__c();
        parentPHB.Account__c = accId;
        insert parentPHB;
        return parentPHB;
    }
    

    /**************************************************************************************
    * @Description  Helper method of processData()
    * @Param		Account - account
    * @Param		Product2 - product
    * @Param		Id - parent PHB Id
    * @Return       PurchaseHistoryBucket__c
    **************************************************************************************/ 
    public static PurchaseHistoryBucket__c generateNewPhb(Account acc, Product2 prod,Id parentPHBId) {
        PurchaseHistoryBucket__c phb = new PurchaseHistoryBucket__c();
        phb.Account__c = acc.Id;
        phb.Product__c = prod.Id;
        phb.SalesProductGroup__c = prod.Sales_Product_Group__c;
        phb.Parent_PHB__c = parentPHBId;
        phb.Row_Id__c = acc.Account_Number__c + '-' +prod.Product_Code__c;
        return phb;
    }

    public static DateTime formatDateTime(String jsonDate) {
        return (DateTime)JSON.deserialize('"' + jsonDate + '"', DateTime.class);
    }
}