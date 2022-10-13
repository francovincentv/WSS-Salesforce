/*************************************************************************
 * Class       :   QueryCurrentPricelist
 * References  :   QueryCurrentPricelistTest.cls
 * Description :   This is used in screen flow "Price List Version Selection Screen"
 *                  This class with query the current pricelist versions and return that to screen flow
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [26.Jan.2021]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
public with sharing class QueryCurrentPricelist {
    
    @AuraEnabled
    public static List<String> queryCurrentPriceList() {
        List<AggregateResult> arList = [SELECT Count(Id), Version__c FROM Price_List__c WHERE Current_Price_List__c = TRUE Group BY Version__c LIMIT 2000];
        List<String> versions = new List<String>();
        for(AggregateResult ar: arList) {
            versions.add((String) ar.get('Version__c'));
        }

        return versions;
    }

}