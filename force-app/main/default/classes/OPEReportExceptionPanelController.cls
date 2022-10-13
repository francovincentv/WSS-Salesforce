public with sharing class OPEReportExceptionPanelController {
    @AuraEnabled(cacheable=true)
    public static List<OrderProcessException__c> getStarlistExceptionDetails(String exceptionId){
        return [ SELECT Id, Name, ExceptionTypeTitle__c, Exception__c,Exception__r.ExceptionDescription__c,ValidationDataEntity__c,Details__c,DetailsLong__c,CustomerRole__c,
                        Sub_Account_Ids__c,CountryOfCustomerLogic__c,CountryofCustomerList__c,CustomerSegmentLogic__c,CustomerSegmentList__c,PortOfDeliveryLogic__c,PortOfDelivery__c,CountryOfDeliveryLogic__c,toLabel(CountryofDeliveryList__c),ProductLogic__c,Product__c,ProductCategoryLogic__c,ProductCategory__c,VesselLogic__c,Vessel__c,VesselFlagLogic__c,toLabel(VesselFlagList__c),VesselTypeLogic__c,VesselTypeList__c,OrderValueLogic__c,OrderValue__c,Other__c,CurrencyIsoCode,SalesTerritory__c,SalesTerritoryLogic__c,CSTeam__c,CSTeamLogic__c,  
                (SELECT Id, Name, Code__c, RecordTypeId, RecordType.DeveloperName, Account__r.Name, Port__r.Name, Product__r.Name,Vessel__r.Name, Status__c FROM Conditions__r)
                   FROM OrderProcessException__c WHERE Id = :exceptionId LIMIT 1];
    }
    @AuraEnabled
    public static Map<String,String> getOPEFieldLabels(){ 
        Map<String,String> fieldLabelMap = new Map<String,String>();
        DescribeSObjectResult objDsc = OrderProcessException__c.getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = objDsc.fields.getMap();
        for(String field : fieldsMap.keySet()){
            Schema.DescribeFieldResult fDesc = fieldsMap.get(field).getDescribe();
            if(fDesc.isAccessible()){
                fieldLabelMap.put(fDesc.getName(),fDesc.getLabel());
            }
        }
        return fieldLabelMap;
    }
}