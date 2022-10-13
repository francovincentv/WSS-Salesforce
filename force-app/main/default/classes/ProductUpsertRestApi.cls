/*************************************************************************
 * Class       :   ProductUpsertRestApi
 * References  :   ProductUpsertRestApiTest.cls
 * Description :   This rest resouce will handle the process related to Products Insert/Update from external system
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [03.Sep.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
@RestResource(urlMapping='/product')
global class ProductUpsertRestApi {

    public static Map<String, String> groupNameWithMainGroup = new Map<String, String>();
    public static Map<String, String> groupNameWithCategory = new Map<String, String>();
    public static List<ProductGroup__c> prodGroupToUpsert = new List<ProductGroup__c>();
    public static String requestString;

    @httpPost
    global static void doPost() {
        //SavePoint sp = Database.setSavepoint();
        RestRequest request = RestContext.Request;
        RestResponse response = RestContext.Response;
        List<ProductUpsertRestApiWrapper> requestData ;
        requestString = request.requestBody.toString();

        //if any error happens while parsing, send error back
        try {
            requestData = ProductUpsertRestApiWrapper.parse(request.requestBody.toString());
        } catch(Exception e) {
            //add the error to response
            response.statusCode = 500;
            response.responseBody = Blob.valueOf('Bad Request : ' + e.getMessage());
        }

        //if any error happen while manipulating data, then handle within salesforce
        try {
            if(requestData != null) { 
                processData(requestData); 
                response.responseBody = Blob.valueOf('Success'); 
            }
        } catch (Exception ex) {
            //capture the error into custom object
            String message = ex.getStackTraceString() +'<br/>' + ex.getMessage() + '<br/>' + ex.getCause() +' <br/>'+ ex.getTypeName();
            TransactionLogHandler.insertErrorWithAttchment(message, 'ProductUpsertRestApi', requestString);
        }
    }

    public static void processData(List<ProductUpsertRestApiWrapper> requestData) {
        Set<String> productIds = new Set<String>();
        Set<String> productGroupNames = new Set<String>();
        List<Product2> productUpsertList = new List<Product2>();
        Map<String, Product2> prodCodeWithProductMap = new Map<String, Product2>();
        Map<String, ProductGroup__c> groupNameWithProductGroup = new Map<String, ProductGroup__c>();

        //get the product codes
        for(ProductUpsertRestApiWrapper mainObj : requestData) {
            if(mainObj.data.masterType == 'Mastered') {
                productIds.add(mainObj.data.productId);
                
                //generate product group name 
                String groupName = mainObj.data.productGroupId + '-' + mainObj.data.productGroupName;
                productGroupNames.add(groupName);

                //mainProductGroup
                String parentGroup = '';
                if(!String.isBlank(mainObj.data.mainProductGroupId)) {
                    parentGroup += mainObj.data.mainProductGroupId;
                }
                if(!String.isBlank(mainObj.data.mainProductGroupName)) {
                    parentGroup += '-' + mainObj.data.mainProductGroupName;
                }

                if(parentGroup != '') {
                    groupNameWithMainGroup.put(groupName, parentGroup);
                }

                if(mainObj.data.solution != '' && mainObj.data.solution != null) {
                    groupNameWithCategory.put(groupName, mainObj.data.solution);
                }
            }
        }

        //get the existing products groups, if not found then create new 
        createGroupsIfNotExist(productGroupNames, groupNameWithProductGroup, productUpsertList);
       
        //query the products based on product codes
        for(Product2 product : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN: productIds FOR UPDATE]){
            prodCodeWithProductMap.put(product.ProductCode, product);
        }

        for(ProductUpsertRestApiWrapper mainObj : requestData) {
            if(mainObj.data.masterType == 'Mastered') {
                String productCode = mainObj.data.productId;
                String groupName = mainObj.data.productGroupId + '-' + mainObj.data.productGroupName;
                //get the existing product from salesforce
                Product2 product = prodCodeWithProductMap.get(productCode);
                
                //if product not found, create new product
                if(product == null) {
                    product = new Product2();
                    //System.debug('<<BrandNewProd>>' + mainObj.data.productName);
                }

                //add the update info to product
                product = formProductWithLatestDetails(product, mainObj.data);
                product.ProductGroup__c = groupNameWithProductGroup.get(groupName).Id;

                //add to upsert list
                productUpsertList.add(product);
            }
        }
    
        //insert/update products
        if(productUpsertList.size() > 0) {
            List<Database.upsertResult> uResults = Database.upsert(productUpsertList, false);
            //once the products successfully created, create default prices books for new products
            createPriceBookEntries(uResults, productUpsertList);
        }
    }

    public static Product2 formProductWithLatestDetails(Product2 product, ProductUpsertRestApiWrapper.Data productData) {
        product.Product_Code__c = productData.productId;
        product.ProductCode = productData.productId;
        product.Name = productData.productName;
        product.Sales_Product_Group__c = productData.salesProductGroup;
        product.Unit_of_Measure__c = productData.uomId;
        product.IsActive = productData.partStatusCode == 'Z' ? false : true;
        product.Classification__c = productData.Classification;
        product.hazardClassCode__c = productData.hazardClassCode;
        product.hazardClassName__c = productData.hazardClassName;

        return product;
    }

    public static void createGroupsIfNotExist(Set<String> productGroupNames, Map<String, ProductGroup__c> groupNameWithProductGroup, List<Product2> productUpsertList) {
        groupNameWithProductGroup.putAll(queryProductGroups(productGroupNames));
        Set<String> newGroupName = new Set<String>();

        for(String groupName : productGroupNames) {
            if(groupNameWithProductGroup.get(groupName) == null) {
                prodGroupToUpsert.add(formNewProductGroup(groupName));
                newGroupName.add(groupName);
            }
        }

        if(prodGroupToUpsert.size() > 0) {
            upsert prodGroupToUpsert;
            for(ProductGroup__c prodGroup : prodGroupToUpsert) {
                //create new product for the new productGroup inserted
                if(newGroupName.contains(prodGroup.Name)) {
                    groupNameWithProductGroup.put(prodGroup.Name, prodGroup);

                    Product2 product = new Product2();
                    product.Name = prodGroup.Name;
                    product.IsActive = true;
                    product.IsProductGroup__c = true;
                    product.ProductGroup__c = prodGroup.Id;
                    productUpsertList.add(product);
                }
            }
        }
    }

    public static ProductGroup__c formNewProductGroup(String name) {
        ProductGroup__c prodGroup = new ProductGroup__c();
        prodGroup.Name = name;
        prodGroup.MainProductGroup__c = groupNameWithMainGroup.get(name) != null ? groupNameWithMainGroup.get(name) : '';
        prodGroup.Category__c = groupNameWithCategory.get(name) != null ? groupNameWithCategory.get(name) : '';
        return prodGroup;
    }

    public static Map<String, ProductGroup__c> queryProductGroups(Set<String> productGroupNames) {
        Map<String, ProductGroup__c> groupNameWithProductGroup = new Map<String, ProductGroup__c>();
        //query the ProductGroup__c on product codes
        for(ProductGroup__c prodGroup : [SELECT Id, Name, MainProductGroup__c,Category__c FROM ProductGroup__c WHERE Name IN: productGroupNames FOR UPDATE]){
            String mainProdGroupName = groupNameWithMainGroup.get(prodGroup.Name);
            String category = groupNameWithCategory.get(prodGroup.Name);
            Boolean needToUpdate = false;
            if(prodGroup.MainProductGroup__c != mainProdGroupName) {
                //System.debug('update existProd mainGroup from ' + prodGroup.MainProductGroup__c  + ' to ' + mainProdGroupName);
                prodGroup.MainProductGroup__c = mainProdGroupName;
                needToUpdate = true;
            }
            if(prodGroup.Category__c != category) {
                //System.debug('update existProd Category__c from ' + prodGroup.Category__c  + ' to ' + category);
                prodGroup.Category__c = category;
                needToUpdate = true;
            }
            if(needToUpdate) { prodGroupToUpsert.add(prodGroup); }

            groupNameWithProductGroup.put(prodGroup.Name, prodGroup);
        }

        return groupNameWithProductGroup;
    }

    /* 
     * @desctiption : helper method to create pricebook entries for the newly 
     */
    public static void createPriceBookEntries(List<Database.upsertResult> uResults, List<Product2> prodUpsertList) {
        List<PricebookEntry> newPricebookEntries = new List<PricebookEntry>();
        List<Transaction_Log__c> errorsToInsert = new List<Transaction_Log__c>();

        Id standardPriceBookId = [SELECT Id FROM Pricebook2 WHERE isStandard = true].Id;
        String cpqPriceBookId = System.Label.CPQ_PriceBookId;

        List<String> pricebookIDs = new List<String>();
        pricebookIds.add(standardPriceBookId);
        if(cpqPriceBookId != null) { pricebookIDs.add(cpqPriceBookId); }

        Integer counter = 0;
        String message = '<html><body>';
        String createdMsg  = '<b><u>Records Created :</u></b> ';
        String updatedMsg  = '<b><u>Records Updated :</u></b> ';
        String errorMsg = '<b><u>Errors :</u></b>';
        Boolean attachFile = false;

        for(Database.upsertResult result : uResults) {
            if(result.isSuccess()){
                if(result.isCreated()) {
                    createdMsg += result.getId() + ',';
                    for(String pId : pricebookIDs) {
                        PricebookEntry pbe = new PricebookEntry();
                        pbe.Product2Id = result.getId();
                        pbe.Pricebook2Id = pId;
                        pbe.IsActive = true;
                        pbe.UnitPrice = 0;
                        pbe.CurrencyIsoCode = 'USD';
                        newPricebookEntries.add(pbe);
                    }
                } else {
                    updatedMsg += result.getId() + ',';
                }
            } else if(!result.isSuccess()) {
                attachFile = true;
                
                // Operation failed, so get all errors                
                for(Database.Error err : result.getErrors()) {
                    if(errorMsg == '') {
                        errorMsg += '<html><body>';
                    }
                    errorMsg +=  '<p> Product Code <b>' + prodUpsertList[counter].ProductCode + '</b> ====> '+ err.getStatusCode() + ' : ' + err.getMessage() + ' : '+ err.getFields() + '</p> <br/>';
                }
            }
            counter++;
        }

        //insert the pricebookentries
        if(newPricebookEntries.size()>0) {
            insert newPricebookEntries;
        }

        message += createdMsg + '<br/><br/>' + updatedMsg + '<br/><br/>' + errorMsg +'</body></html>';

        if(attachFile) {
            TransactionLogHandler.insertErrorWithAttchment(message, 'ProductUpsertRestApi', requestString);
        } else {
            TransactionLogHandler.doHandleException(null, message, 'ProductUpsertRestApi', null, true, false);
        }

    }

}