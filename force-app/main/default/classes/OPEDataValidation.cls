/*************************************************
* Class                 : OPEDataValidation
* References            : OrderProcessExceptionTriggerHandler
* Description           : This is the class at which we 1. Validate the conditions that are inputed as free text 
                          in the OPE & created the related junction objects (Conditions) and 2. Valitate the free 
                          text input for the 'Details List' field
* Change Log    
* Date Modified     Modified By                         Description of the update
* ----------------------------------------------------------------
* [03.Jan.2022]     [Niki - Fluido]                     [Initial development]
* [26.Jan.2022]     [felix.guerrero@fluidogroup.com]    [Reimplementation of usecase 1.]
*************************************************/
public inherited sharing class OPEDataValidation {
    private static Map<Id,String> rtIdOPEFieldMap;
    private static Map<Id,String> rtIdConditionFieldMap;
    private static Map<String,String> opeFieldObjectMap;
    
    private static Map<String,String> objectCodeFieldMap = new Map<String,String>{
        'Port__c' => 'Port_Code__c',
        'Product2' => 'Product_Code__c',
        'Account' =>  'Account_Number__c',
        'Vessel__c' => 'IMO_Number__c'
    };
    private static Map<String,String> opeFieldLabelMap;
    public static Map<String,String> getOPEFieldLabelMap(){
        if(opeFieldLabelMap == null){
            opeFieldLabelMap = new Map<String,String>();
            Map<String, Schema.SObjectField> opeFieldMap = Schema.SObjectType.OrderProcessException__c.fields.getMap();
            //System.debug(opeFieldMap);
            for (String fieldName : opeFieldMap.keySet()) {
                Schema.DescribeFieldResult dfr = opeFieldMap.get(fieldName.toLowerCase()).getDescribe();
                String label = dfr.getLabel();
                opeFieldLabelMap.put(fieldName,label);
            }
            //System.debug(opeFieldLabelMap);
        }
        return opeFieldLabelMap;
    }
    public static Id subAccsRTId;
    private static Id portsRTId;
    private static Id vesselsId;
    private static Id productsRTId;
    static {
        Map<String,Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.OrderProcessExceptionCondition__c.getRecordTypeInfosByDeveloperName();
        subAccsRTId = rtInfos.get('SubAccounts').getRecordTypeId();
        portsRTId = rtInfos.get('PortsofDelivery').getRecordTypeId();
        vesselsId = rtInfos.get('Vessels').getRecordTypeId();
        productsRTId = rtInfos.get('Products').getRecordTypeId();
    }

    private static String OPE_STATUS_INACTIVE = 'Archived';
    public static List<String> OPE_STATUS_ACTIVE_LIST = new List<String>{'Active','Under review'};
    public static String APPROVER_QUEUE = 'OPEApprover';

    private static Map<String,Boolean> validateProductGroups(Set<String> productGroups){
        Map<String,Boolean> validationResults = new Map<String,Boolean>();
        for(ProductGroup__c grp : [SELECT Code__c FROM ProductGroup__c WHERE Code__c <> NULL AND Code__c IN :productGroups]){
            String code = grp.Code__c;
            if(!validationResults.containsKey(code))
                validationResults.put(code,true);
        }
        productGroups.removeAll(validationResults.keySet());
        for(String productCode : productGroups){
            validationResults.put(productCode,false);
        }
        return validationResults;
    }

/*     private static Map<String,Boolean> validateCountriesOfDelivery(Set<String> countries){
        Map<String,Boolean> validationResults = new Map<String,Boolean>();
        for(AggregateResult ar : [SELECT Country_Code__c FROM Port__c WHERE Country_Code__c IN :countries GROUP BY Country_Code__c]){
            String code = (String)ar.get('Country_Code__c');
            if(!validationResults.containsKey(code))
                validationResults.put(code,true);
        }
        countries.removeAll(validationResults.keySet());
        for(String country : countries){
            validationResults.put(country,false);
        }
        return validationResults;
    }

    private static Map<String,Boolean> validateCountriesOfCustomer(Set<String> countries){
        Map<String,Boolean> validationResults = new Map<String,Boolean>();
        Schema.DescribeFieldResult countryField = Account.Country_of_Domicile__c.getDescribe();
        Map<String,String> countryPicklistValueMap = new Map<String,String>();
        for(Schema.PicklistEntry pe :countryField.getPicklistValues()){
            if(pe.isActive())
                countryPicklistValueMap.put(pe.getValue(),pe.getLabel());
        }
        for(String country : countries){
            validationResults.put(country,countryPicklistValueMap.containsKey(country));
        }
        return validationResults;
    }
    
    private static Map<String,Boolean> validateVesselFlags(Set<String> vesselFlags){
        Map<String,Boolean> validationResults = new Map<String,Boolean>();
        for(String vesselFlag : vesselFlags){
            validationResults.put(vesselFlag,VESSEL_FLAG_SET.contains(vesselFlag));
        }
        return validationResults;
    } */

    /**************************************************************************************
    * @Description  Initializes static maps and variables that are used for reference in other class methods
    * @Return       void
    **************************************************************************************/ 
    private static void getRecordTypesAndFields(){

        rtIdOPEFieldMap = new Map<Id,String>{
            subAccsRTId => 'Sub_Account_Ids__c',
            portsRTId => 'PortOfDelivery__c',
            vesselsId => 'Vessel__c',
            productsRTId => 'Product__c'
        };
        rtIdConditionFieldMap = new Map<Id,String>{
            subAccsRTId => 'Account__c',
            portsRTId => 'Port__c',
            vesselsId => 'Vessel__c',
            productsRTId => 'Product__c'
        };
        opeFieldObjectMap = new Map<String,String>{
            'Sub_Account_Ids__c' => 'Account',
            'PortOfDelivery__c' => 'Port__c',
            'Vessel__c' => 'Vessel__c',
            'Product__c' => 'Product2'
        };

        System.debug('subAccsRTId: '+ subAccsRTId + '\n' +
        'portsRTId: '+ portsRTId + '\n' + 
        'vesselsId: '+ vesselsId + '\n' +
        'productsRTId: '+ productsRTId);
    }

    /**************************************************************************************
    * @Description  Validates Conditions that are not dependent on junction records 
    * @Param        Map<Id,SObject> newRecordsMap: the map of records from update/insert trigger
    * @Return       void
    **************************************************************************************/ 
    public static void opeConditionInputValidations(Map<Id,SObject> newRecordsMap){

        /*
        ProductCategory__c  //Product Category: Query Product Code on Product where 'Is Product Group' is checked. METHOD> this.validateProductGroups()
        
        # Handled in Validation Rule:
        # ----------------------------------------
        # OrderValue__c       // Order Value: Check it's a positive Number VALIDATIONRULE> Condition_OrderValue_Must_Be_Positive

        # Handled in conditionsValidation method:
        # ----------------------------------------
        ## PortOfDelivery__c // Port of delivery: Junction Record Validation to object 'Port__c' => 'Port_Code__c'
        ## Product__c        // Product: Junction Record Validation to object Product2 'Product2' => 'Product_Code__c',
        ## Vessel__c         // Vessel: Junction Record Validation 'Vessel__c' => 'IMO_Number__c'
        ## Sub_Account_Ids__c // Customer Subaccount Id: Junction Record Validation to Account

        # Not Handled:
        # ----------------------------------------
        # Other__c            // Other: None
        # VesselTypeList__c   // Restricted Multipicklist with Picklist values from: Vessel__c.Ship_Type__c
        # CustomerSegmentList__c  // Restricted Multipicklist with Picklist values from: Account > Category (Account.Type)
        # VesselFlagList__c       // Restricted Multipicklist with Picklist values from provided File
        # CountryOfCustomerList__c // Restricted Multipicklist with Picklist values from: Account > Country of Domicile
        # CountryOfDeliveryList__c // Restricted Multipicklist with Picklist values from: Location object
        # SalesTerritory__c // Restricted Multipicklist with Picklist values from: User.SM_Territory__c
        # CSTeam__c // Restricted Multipicklist with Picklist values from: User.SM_Territory__c
        */

        Map<Id,Set<String>> opeProductCategoriesMap = new Map<Id,Set<String>>();
        Set<String> productCategorySet = new Set<String>();
        /*
        Map<Id,Set<String>> opeVesselFlagsMap = new Map<Id,Set<String>>();
        Set<String> vesselFlagSet = new Set<String>();
        Map<Id,Set<String>> opeCountriesOfDeliveryMap = new Map<Id,Set<String>>();
        Set<String> countryOfDeliverySet = new Set<String>();
        Map<Id,Set<String>> opeCountriesOfCustomerMap = new Map<Id,Set<String>>();
        Set<String> countryOfCustomerSet = new Set<String>();
        */
        for(Id opeId : newRecordsMap.keySet()){
            OrderProcessException__c ope = (OrderProcessException__c)newRecordsMap.get(opeId);
            if(ope.ProductCategory__c != null){
                List<String> productCategories = splitCSVString(ope.ProductCategory__c);
                opeProductCategoriesMap.put(opeId,new Set<String>(productCategories));
                ope.ProductCategory__c = String.join(productCategories, ';');
                productCategorySet.addAll(productCategories);
            }
           /* if(ope.VesselFlag__c != null){
                List<String> vesselFlags = splitCSVString(ope.VesselFlag__c);
                opeVesselFlagsMap.put(opeId,new Set<String>(vesselFlags));
                ope.VesselFlag__c = String.join(vesselFlags, ';');
                vesselFlagSet.addAll(vesselFlags);
            }
            if(ope.CountryOfDelivery__c != null){
                List<String> countriesOfDelivery = splitCSVString(ope.CountryOfDelivery__c);
                opeCountriesOfDeliveryMap.put(opeId,new Set<String>(countriesOfDelivery));
                ope.CountryOfDelivery__c = String.join(countriesOfDelivery, ';');
                countryOfDeliverySet.addAll(countriesOfDelivery);
            }
            if(ope.CountryOfCustomer__c != null){
                List<String> countriesOfCustomer = splitCSVString(ope.CountryOfCustomer__c);
                opeCountriesOfCustomerMap.put(opeId,new Set<String>(countriesOfCustomer));
                ope.CountryOfCustomer__c = String.join(countriesOfCustomer, ';');
                countryOfCustomerSet.addAll(countriesOfCustomer);
            } */
        }
        System.debug('productCategorySet: '+ productCategorySet);
        //System.debug('vesselFlagSet: '+ vesselFlagSet);
        //System.debug('vesselTypeSet: '+ vesselTypeSet);
        //System.debug('countryOfDeliverySet: '+ countryOfDeliverySet);
        //System.debug('countryOfCustomerSet: '+ countryOfCustomerSet);

        if(!productCategorySet.isEmpty()){
            Map<String,Boolean> productCategoryValidation = validateProductGroups(productCategorySet);
            performValidation(newRecordsMap, 'Product Categories', opeProductCategoriesMap, productCategoryValidation);
        }
        /*
        if(!vesselFlagSet.isEmpty()){
            Map<String,Boolean> vesselFlagValidation = validateVesselFlags(vesselFlagSet);
            performValidation(newRecordsMap, 'Vessel Flags', opeVesselFlagsMap, vesselFlagValidation);
        }
        if(!countryOfDeliverySet.isEmpty()){
            Map<String,Boolean> countryOfDeliveryValidation = validateCountriesOfDelivery(countryOfDeliverySet);
            performValidation(newRecordsMap, 'Country Codes', opeCountriesOfDeliveryMap, countryOfDeliveryValidation);
        }       
        if(!countryOfCustomerSet.isEmpty()){
            Map<String,Boolean> countryOfCustomerValidation = validateCountriesOfCustomer(countryOfCustomerSet);
            performValidation(newRecordsMap, 'Countries', opeCountriesOfCustomerMap, countryOfCustomerValidation);
        }
        */
    }

    private static void performValidation(Map<Id,SObject> newRecordsMap, String validationType, Map<Id,Set<String>> opeValueSetMap, Map<String,Boolean> validationResultMap){
        String errorMessage = 'The following {0} are invalid: "{1}" please verify or remove and try again.';
        for(Id opeId : opeValueSetMap.keySet()){
            List<String> validationErrors = new List<String>();
            for(String value : opeValueSetMap.get(opeId)){
                if(!validationResultMap.get(value)){
                    validationErrors.add(value);
                }
            }
            if(!validationErrors.isEmpty()){
                newRecordsMap.get(opeId).addError(String.format(errorMessage, new List<String>{validationType,String.join(validationErrors,'", "')}));
            }
        }
    }

    /**************************************************************************************
    * @Description  Checks that the Details contains actual valid data based on Validation Data Entity
    * @Param        Map<Id,SObject> newRecordsMap: the map of records from update/insert trigger
    * @Return       void
    **************************************************************************************/ 
    public static void detailsValidation(Map<Id,SObject> newRecordsMap){
        System.debug('@detailsValidation()');
        // VALIDATION VALUES: "Port Code","Sub-Account Number","Product Number","Number","No Validation","None"
        Map<String,String> validationObjectMap = new Map<String,String>{
            'Port Code' => 'Port__c',
            'Sub-Account Number' => 'Account',
            'Product Number' => 'Product2'
        };

        Map<String, Set<String>> objectCodesMap = new Map<String, Set<String>>();
        Map<Id, List<String>> opeIdCodesMap = new Map<Id, List<String>>();
        for(Id opeId : newRecordsMap.keySet()){
            OrderProcessException__c ope = (OrderProcessException__c)newRecordsMap.get(opeId);
            String validation = ope.ValidationDataEntity__c;
            String details = ope.Details__c;
            System.debug('details: '+details+'\nValidation: '+validation);
            List<String> codeList = splitCSVString(ope.Details__c);
            System.debug('codeList: '+codeList);
            if(!codeList.isEmpty()){
                if(validationObjectMap.containsKey(validation)){
                    String objectName = validationObjectMap.get(validation);
                    System.debug('objectName: '+objectName);
                    if(!objectCodesMap.containsKey(objectName))
                        objectCodesMap.put(objectName,new Set<String>());
                    objectCodesMap.get(objectName).addAll(codeList);
                    if(!opeIdCodesMap.containsKey(opeId))
                        opeIdCodesMap.put(opeId,new List<String>());
                    opeIdCodesMap.get(opeId).addAll(codeList);
                }
            }
        }
        System.debug(JSON.serializePretty(objectCodesMap));
        System.debug(JSON.serializePretty(opeIdCodesMap));

        // No validations needed, no codes were identified
        if(objectCodesMap.isEmpty())
            return;
        
        Map<String, Set<String>> existingCodesMap = new Map<String, Set<String>>();
        for(String objectName : objectCodesMap.keySet()){
            Set<String> codes = objectCodesMap.get(objectName);
            String fieldName = objectCodeFieldMap.get(objectName);
            String soql = 'SELECT Id, {0} FROM {1} WHERE {0} IN :codes';
            if(objectName == 'Account')
                soql += ' AND RecordType.DeveloperName = \'Customer_Sub_Account\'';
            String query = String.format(soql,new List<Object>{fieldName,objectName});
            System.debug(query);
            List<SObject> results = Database.query(query);
            if(!results.isEmpty()){
                if(!existingCodesMap.containsKey(objectName))
                    existingCodesMap.put(objectName,new Set<String>());
                for(SObject record : results){
                    String code = (String)record.get(fieldName);
                    existingCodesMap.get(objectName).add(code);
                }
            }
        }
        System.debug(JSON.serializePretty(existingCodesMap));
        for(Id opeId : opeIdCodesMap.keySet()){
            SObject opeRecord = newRecordsMap.get(opeId);
            String objectName = validationObjectMap.get((String)opeRecord.get('ValidationDataEntity__c'));
            Set<String> nonExistingCodes = new Set<String>(opeIdCodesMap.get(opeId));
            if(existingCodesMap.containsKey(objectName))
                nonExistingCodes.removeAll(existingCodesMap.get(objectName));
            if(!nonExistingCodes.isEmpty()){
                Boolean single = (nonExistingCodes.size()==1);
                newRecordsMap.get(opeId).addError('Details__c','The value'+(single?'':'s')+' "'+String.join(new List<String>(nonExistingCodes),'","')+'" do'+(single?'es':'')+' not exist in the database, please verify the Details entered.');
            }
            else
                opeRecord.put('Details__c', String.join(opeIdCodesMap.get(opeId),';'));
        }
        
    }

    /**************************************************************************************
    * @Description  Validates conditions that need to be created as related junction records
    * @Param        Map<Id,SObject> newRecordsMap: the map of records from update/insert trigger
    * @Return       void
    **************************************************************************************/ 
    public static void conditionsValidation(Map<Id,SObject> newRecordsMap){

        // Query existing conditions for all OPEs, store in Map with list of codes for each Condition type
        Map<Id,Map<Id,List<OrderProcessExceptionCondition__c>>> opeConditionsMap = new Map<Id,Map<Id,List<OrderProcessExceptionCondition__c>>>();
        if(rtIdOPEFieldMap==null)
            getRecordTypesAndFields();
        
        System.debug('newRecordsMap.keySet(): ' + newRecordsMap.keySet());
        for(OrderProcessExceptionCondition__c opec : 
            [SELECT Id, OrderProcessException__c, Account__c, Port__c, Product__c,Vessel__c, Code__c, RecordTypeId
               FROM OrderProcessExceptionCondition__c 
              WHERE OrderProcessException__c IN :newRecordsMap.keySet()]) {
            if(!opeConditionsMap.containsKey(opec.OrderProcessException__c))
                opeConditionsMap.put(opec.OrderProcessException__c, new Map<Id,List<OrderProcessExceptionCondition__c>>());
                Map<Id,List<OrderProcessExceptionCondition__c>> conditionsMap = opeConditionsMap.get(opec.OrderProcessException__c);
                for(Id rtId : rtIdOPEFieldMap.keySet()){
                    if(opec.RecordTypeId == rtId){
                        if(!conditionsMap.containsKey(rtId))
                            conditionsMap.put(rtId,new List<OrderProcessExceptionCondition__c>());
                        conditionsMap.get(rtId).add(opec);
                    }
                }
        }

        System.debug(JSON.serializePretty(opeConditionsMap));
        Map<Id,Map<Id,Set<String>>> codesToCreate = new Map<Id,Map<Id,Set<String>>>();
        List<OrderProcessExceptionCondition__c> conditionsToCreate = new List<OrderProcessExceptionCondition__c>();
        List<Id> conditionsToDelete = new List <Id>();

        Map<Id,Set<String>> allCodesToCreate = new Map<Id,Set<String>>();
        for(Id opeId : newRecordsMap.keySet()){
            OrderProcessException__c ope = (OrderProcessException__c)newRecordsMap.get(opeId);
            System.debug('OPE Id: '+ opeId);
            Map<Id,Set<String>> toCreate = new Map<Id,Set<String>>();
            for(Id conditionType : rtIdOPEFieldMap.keySet()){
                System.debug('Comparing condition RecordType: '+conditionType);
                List<OrderProcessExceptionCondition__c> conditions = new List<OrderProcessExceptionCondition__c>();
                if(opeConditionsMap.containsKey(opeId) && opeConditionsMap.get(opeId).containsKey(conditionType))
                    conditions = opeConditionsMap.get(opeId).get(conditionType);
                if(conditions.isEmpty())
                    System.debug('NO existing condition records.');
                else
                    System.debug('OPE has existing condition records.');
                compareConditionChanges(conditionType, ope, conditions, conditionsToDelete, toCreate);
                if(toCreate.containsKey(conditionType) && !toCreate.get(conditionType).isEmpty()){
                    System.debug('** Condition Type='+conditionType+'\n** toCreate\n'+JSON.serializePretty(toCreate));
                    System.debug('** allCodesToCreate:\n'+JSON.serializePretty(allCodesToCreate));
                    if(!allCodesToCreate.containsKey(conditionType))
                        allCodesToCreate.put(conditionType,toCreate.get(conditionType));
                    else
                        allCodesToCreate.get(conditionType).addAll(toCreate.get(conditionType));
                }
            }
            codesToCreate.put(opeId,toCreate);
        }
        System.debug('conditionsToDelete:');
        System.debug(JSON.serializePretty(conditionsToDelete));
        System.debug('codesToCreate:');
        System.debug(JSON.serializePretty(codesToCreate));

        System.debug(JSON.serializePretty(allCodesToCreate));

        Map<Id,Map<String,Id>> conditionTypeCodeRecordIdMap = new Map<Id,Map<String,Id>>();
        for(Id rtId : allCodesToCreate.keySet()){

            String objectName = opeFieldObjectMap.get(rtIdOPEFieldMap.get(rtId));
            String fieldName = objectCodeFieldMap.get(objectName);
            Set<String> codes = allCodesToCreate.get(rtId);
            
            String soql = 'SELECT Id, {0} FROM {1} WHERE {0} IN :codes';
            if(rtId == subAccsRTId)
                soql += ' AND RecordType.DeveloperName = \'Customer_Sub_Account\'';
            String query = String.format(soql,new List<Object>{fieldName,objectName});
            System.debug(query);
            List<SObject> results = Database.query(query);
            Map<String,Id> codeRecordIdMap = new Map<String,Id>();
            for(SObject record : results){
                String code = (String)record.get(fieldName);
                codeRecordIdMap.put(code,Id.valueOf((String)record.get('Id')));
            }
            conditionTypeCodeRecordIdMap.put(rtId,codeRecordIdMap);
        }
        
        System.debug('conditionTypeCodeRecordIdMap:\n'+JSON.serializePretty(conditionTypeCodeRecordIdMap));
        Boolean hasErrors = false;
        for(Id opeId : codesToCreate.keySet()){
            List<String> errors = new List<String>();
            for(Id rtId : codesToCreate.get(opeId).keySet()){
                if(codesToCreate.get(opeId).get(rtId).isEmpty())
                    continue;
                List<String> errorCodes = new List<String>();
                Set<String> validCodes = conditionTypeCodeRecordIdMap.get(rtId).keySet();
                String conditionFieldName = rtIdConditionFieldMap.get(rtId);
                for(String code : codesToCreate.get(opeId).get(rtId)){
                    if(validCodes.contains(code)){
                        OrderProcessExceptionCondition__c condition = new OrderProcessExceptionCondition__c();
                        condition.RecordTypeId = rtId;
                        condition.OrderProcessException__c = opeId;
                        condition.put(conditionFieldName,conditionTypeCodeRecordIdMap.get(rtId).get(code));
                        conditionsToCreate.add(condition);
                    }else{
                        errorCodes.add(code);
                    }
                }
                if(!errorCodes.isEmpty()){
                    String opeFieldName = rtIdOPEFieldMap.get(rtId).toLowerCase();
                    String opeFieldLabel = getOPEFieldLabelMap().get(opeFieldName);
                    String error = 'The field "'+opeFieldLabel+'" contains the following invalid code(s): "'+String.join(errorCodes, '", "')+'".';
                    errors.add(error);
                }
            }
            if(!errors.isEmpty()){
                String message = 'Could not save the changes because of the following error(s):\n'+String.join(errors, ' \n') + ' \nPlease remove the invalid value(s) and try again.';
                newRecordsMap.get(opeId).addError(message);
                hasErrors = true;
                System.debug('Error: ' + message);
            }
        }
        
        System.debug('conditionsToCreate:');
        System.debug(JSON.serializePretty(conditionsToCreate));
        if(!hasErrors){
            if(!conditionsToCreate.isEmpty())
                insert conditionsToCreate;
            if(!conditionsToDelete.isEmpty())
                deleteConditionsAsnc(conditionsToDelete);
        }
    }

    @future
    private static void deleteConditionsAsnc(List<Id> conditionIdsToDelete){
        Database.delete(conditionIdsToDelete);
    }

    @future
    public static void inactivateAmendedOPEs(List<Id> amendedOPEIds){
        List<OrderProcessException__c> amendedOPEs = new List<OrderProcessException__c>();
        for(Id opeId : amendedOPEIds)
            amendedOPEs.add(new OrderProcessException__c(Id=opeId,Status__c=OPE_STATUS_INACTIVE));
        Database.update(amendedOPEs);
    }

    /**************************************************************************************
    * @Description  Trims whitespace and duplicate values from a comma-separated list of codes
    * @Param        String codeListString: original text value in the field
    * @Return       String
    **************************************************************************************/ 
    public static String cleanUpCodeList(String codeListString){
        System.debug('codeList: "'+codeListString+'"');
        List<String> codeList = splitCSVString(codeListString);
        System.debug('CLEAN codeList: "'+String.valueOf(codeList)+'"');
        return String.join(codeList, ';');
    }

    public static List<String> splitCSVString(String csvString){
        if(String.isBlank(csvString))
            return new List<String>();
        List<String> csvList = csvString.split(';');
        Set<String> csvSet = new Set<String>();
        for(String s : csvList){
            if(String.isNotBlank(s))
                csvSet.add(s.normalizeSpace());
        }
        return new List<String>(csvSet);
    }

    /**************************************************************************************
    * @Description  Compares the list of codes in the field to existing condition records for the corresponding type to identify which to delete and which to create
    * @Param        Id rtId: record type of the condition records to check
    * @Param        OrderProcessException__c ope: current exception parent to the condition records
    * @Param        List<OrderProcessExceptionCondition__c> conditions: existing condition records
    * @Param        List<OrderProcessExceptionCondition__c> toDelete: list where to put the existing conditions that have to be removed
    * @Param        Map<Id,List<String>> toCreate: map where we put the codes for the new conditions that need to be created
    * @Return       void
    **************************************************************************************/ 
    private static void compareConditionChanges(Id rtId, OrderProcessException__c ope, List<OrderProcessExceptionCondition__c> conditions, List<Id> toDelete, Map<Id,Set<String>> toCreate){
        String fieldName = rtIdOPEFieldMap.get(rtId);
        System.debug('@compareConditionChanges for field: ' + fieldName);
        if(String.isEmpty((String)ope.get(fieldName))){
            System.debug('Field is Empty!');
            if(!conditions.isEmpty()){
                for(OrderProcessExceptionCondition__c opec : conditions)
                    toDelete.add(opec.Id);
            }
        }else{ 
            String newCodes = (String)ope.get(fieldName);
            Set<String> newCodeSet = new Set<String>(splitCSVString(newCodes));
            
            for(OrderProcessExceptionCondition__c opec : conditions){
                if(newCodeSet.contains(opec.Code__c))
                    newCodeSet.remove(opec.Code__c);
                else
                    toDelete.add(opec.Id);
            }
            System.debug('newCodes: '+newCodes);
            System.debug('newCodeSet: '+newCodeSet);
            System.debug('toCreate: ' + toCreate);
            System.debug('toDelete: ' + toDelete);

            if(!toCreate.containsKey(rtId))
                toCreate.put(rtId, new Set<String>());
            if(!newCodeSet.isEmpty())
                toCreate.get(rtId).addAll(newCodeSet);
        }
    }

    public static void validateAttachments(Map<Id,SObject> newRecordsMap){
        Map<Id,Boolean> validationResults =  new Map<Id,Boolean>();
        Set<Id> opeIds = newRecordsMap.keySet();
        Set<Id> opeIdsWithAttachment = new Set<Id>();
        for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId
                                         FROM ContentDocumentLink
                                        WHERE LinkedEntityId IN :opeIds]){
            opeIdsWithAttachment.add(cdl.LinkedEntityId);
        }
        System.debug(opeIds);
        System.debug(opeIdsWithAttachment);
        opeIds.removeAll(opeIdsWithAttachment);
        if(!opeIds.isEmpty()){
            for(Id opeId : opeIds){
                newRecordsMap.get(opeId).addError('No file attachment(s) found. For this exception it\'s mandatory to upload a document that supports the exception reason. Please upload the corresponding File(s) before requesting the Approval.');
            }
        }
    }

    public static void setAfterApprovalFields(Map<Id,SObject> newRecordsMap){
        Map<Id,Id> approverIdMap = new Map<Id,Id>();
        for(ProcessInstance approval : [
            SELECT LastActorId, TargetObjectId 
            FROM ProcessInstance
            WHERE CompletedDate = TODAY
              AND Status = 'Approved' 
              AND TargetObjectId IN : newRecordsMap.keySet()
            ]){
            approverIdMap.put(approval.TargetObjectId, approval.LastActorId);
        }
        for(Id opeId : newRecordsMap.keySet()){
            SObject ope = newRecordsMap.get(opeId);
            // Set Approver
            if(approverIdMap.containsKey(opeId))
                ope.put('Approver__c',approverIdMap.get(opeId));
            // Set Reviewer as Owner of the record
            if(ope.get('Reviewer__c') != null)
                ope.put('OwnerId',ope.get('Reviewer__c'));
        }
    }
    
/*  private static final Set<String> VESSEL_FLAG_SET = new Set<String>{
        'ALD','ALB','DZA','AGO','AIA','ATG','ARG','ABW','AUS','AUT','AZE','BHS','BHR','BGD','BRB',
        'BEL','BLZ','BEN','BMU','BOL','BRA','BRU','BGR','KHM','CMR','CAN','CPV','CYM','CHL','COL',
        'COM','COK','CRI','HRV','CUB','CYP','CZE','DIS','DNK','DJI','DMA','DOM','ECU','EGY','SLV',
        'GNQ','ERI','EST','ETH','FRO','FIJ','FIN','FRA','ATF','GAB','GEO','DEU','GHA','GIB','GRC',
        'GRD','GLP','GTM','GIN','GUY','HTI','HND','HKG','HUN','ISL','IND','IDN','IRN','IRQ','IRL',
        'IOM','ISR','ITA','CIV','JAM','JPN','JAP','JOR','KEN','KIR','KWT','LAO','LVA','LBN','LBR',
        'LBY','LTU','LUX','MDG','PMD','MYS','MDV','MLT','MHL','MRT','MUS','MAU','MEX','MON','MNG',
        'MOR','MOZ','MMR','NAM','NRU','NLD','ANT','NZL','NIC','NIG','PRK','NOR','NIS','DDR','YUG',
        'OMN','PAK','PAN','PNG','PRY','PER','PHL','POL','PRT','QAT','CHN','ROM','RUS','SAU','SEN',
        'SLE','SGP','SVK','SVN','SLB','SOM','ZAF','KOR','ESP','LKA','LCA','VCT','SDN','SUR','SWE',
        'CHE','SYR','TWN','TZA','THA','COG','GMB','TGO','TON','TTO','TUN','TUR','TKM','TUV','UGA',
        'UKR','ARE','GBR','USA','VUT','VEN','VNM','ZAR'
    };*/

    public static void setReviewers(Map<Id, OrderProcessException__c> opeMap){
        System.debug('@setReviewers');
        // Query Sub-Account Conditions including the Account > Sales Advisor field
        Map<Id,Set<Id>> opeSalesAdvisorsMap = new Map<Id,Set<Id>>();
        for(OrderProcessExceptionCondition__c accountCondition : 
            [SELECT Id, Code__c, OrderProcessException__c, Account__r.Customer_Coordinator__c
               FROM OrderProcessExceptionCondition__c 
              WHERE RecordType.Id = :subAccsRTId AND OrderProcessException__c IN :opeMap.keySet()]){
            Id salesAdvisorId = accountCondition.Account__r?.Customer_Coordinator__c;
            // If the Account has a Sales Advidor add to map
            if(salesAdvisorId != null){
                Id opeId = accountCondition.OrderProcessException__c;
                if(!opeSalesAdvisorsMap.containsKey(opeId))
                    opeSalesAdvisorsMap.put(opeId,new Set<Id>());
                opeSalesAdvisorsMap.get(opeId).add(salesAdvisorId);
            }
        }
        System.debug(opeSalesAdvisorsMap);
        // Check for each OPE if at least one Sales Advisor was found, set the first one found as reviewer
        for(Id opeId : opeMap.keySet()){
            if(opeSalesAdvisorsMap.containsKey(opeId)){
                Set<Id> salesAdvisors = opeSalesAdvisorsMap.get(opeId);
                if(salesAdvisors.size() >= 1){
                    OrderProcessException__c ope = opeMap.get(opeId);
                    Id salesAdvisorId = (new List<Id>(salesAdvisors))[0];
                    ope.Reviewer__c = salesAdvisorId;
                    System.debug('Reviewer for '+ ope.Name + ': ' + ope.Reviewer__c);
                }
            }
        }
    }

    // Retrieve Id of a user Queue by DeveloperName
    private static Map<String,Id> queueIdMap;
    public static Id getQueueIdByName(String developerName){
        Id queueId;
        if(queueIdMap == null)
            queueIdMap = new Map<String,Id>();
        
        if(queueIdMap.containsKey(developerName)){
            queueId = queueIdMap.get(developerName);
        }else{
            Group queue = [SELECT Id FROM Group WHERE Type='Queue' AND DeveloperName = :developerName LIMIT 1];
            queueId = queue.Id;
            if(queueId != null)
                queueIdMap.put(developerName,queueId);
        }
        return queueId;
    }

    public static Id getActiveApprovalProcessId(String developerName){
        Id processId;
        List<ProcessDefinition> approvalProcesses = [SELECT Id FROM ProcessDefinition WHERE Type = 'Approval' AND DeveloperName = :developerName AND State = 'Active' LIMIT 1];
        if(approvalProcesses.size() == 1)
            processId = approvalProcesses[0].Id;
        else
            System.debug('Approval Process "'+developerName+'" is Inactive or does not exist.');
        System.debug('getActiveApprovalProcessId: '+processId);
        return processId;
    }
}