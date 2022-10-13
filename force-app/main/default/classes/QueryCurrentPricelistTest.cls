@isTest
public class QueryCurrentPricelistTest {
    
    static testMethod void getCurrentPriceListTest(){

        Product2 prod = TestFactory.createProducts(1, true)[0];

        List<Price_List__c> priceListToInsert = new List<Price_List__c>();

        //create 3 current pricelist = true
        for(Integer i=1; i<4; i++) {
            Price_List__c pl = new Price_List__c(Current_Price_List__c = true, Version__c = '2021' + i, Product__c = prod.Id,  id__c = 'test'+(i*9));
            priceListToInsert.add(pl);
        }

        //create 3 current pricelist = false
        for(Integer i=1; i<4; i++) {
            Price_List__c pl = new Price_List__c(Current_Price_List__c = false, Version__c = '2020' + i, Product__c = prod.Id, id__c = 'test'+i);
            priceListToInsert.add(pl);
        }

        insert priceListToInsert;

        Test.startTest();
        List<String> curPriceList = QueryCurrentPricelist.queryCurrentPriceList();
        Test.stopTest();

        //only we should get Current_Price_List__c = true pricelist records 
        System.assertEquals(3, curPriceList.size(), 'There is only 3 current pircelist exist, which is 3');

    }
}