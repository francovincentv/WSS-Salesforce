public class UpdateQuoteGroupZoneString {
    
    public static void updateQuoteGroupZoneString(list<KeyPort__c> keyportList){
        list<id> quotesId=new list<id>();
        list<SBQQ__Quote__c> quotes=new list<SBQQ__Quote__c>();
        list<SBQQ__Quote__c> quotestobeUpdated=new list<SBQQ__Quote__c>();
        map<KeyPortGroup__c,list<String>> keyportsInKeyportGroup=new map<KeyPortGroup__c,list<String>>();
        Map<id, Map<KeyPortGroup__c, list<String>>> quoteKeyportgroupKeyport = new Map<id, Map<KeyPortGroup__c, list<String>>>();
        
        for(KeyPort__c keyport :keyportList){
            
            quotesId.add(keyport.Quote__c);
        }
        
        quotes = [Select id,GroupKeyPortString__c, ZoneKeyPortString__c from SBQQ__Quote__c where id IN: quotesId];
        
        for(KeyPortGroup__c keyportgroup : [SELECT id ,name,Quote__c,KeyPortGroupType__c,KeyPortGroupName__c, (SELECT Id,KeyPortName__c, KeyPortGroupType__c ,KeyPortGroupLookup__c FROM Key_Ports__r) from KeyPortGroup__c where Quote__r.id IN: quotesId ORDER BY KeyPortGroupType__c ASC]){
            list<String> allRelatedKeyports=new list<String>();
            
            for(KeyPort__c keyports : keyportgroup.Key_Ports__r){
                allRelatedKeyports.add(keyports.KeyPortName__c);
                
            }
            keyportsInKeyportGroup.put(keyportgroup,allRelatedKeyports);
            quoteKeyportgroupKeyport.put(keyportgroup.Quote__c,keyportsInKeyportGroup);
        }
        
        
        for (SBQQ__Quote__c quote : quotes){
            quote.GroupKeyPortString__c='';
            quote.ZoneKeyPortString__c='';
            for (KeyPortGroup__c  key : quoteKeyportgroupKeyport.get(quote.id).keySet()){
                if(key.KeyPortGroupType__c.contains('Group')){
                        quote.GroupKeyPortString__c+='<p><b>'+key.KeyPortGroupName__c +': '+  '</b>' +string.join(quoteKeyportgroupKeyport.get(quote.id).get(key),',')+'</p>';                
                }
                
                if(key.KeyPortGroupType__c.contains('Zone')){
                        quote.ZoneKeyPortString__c+='<p><b>'+key.KeyPortGroupName__c +': '+  '</b>' +string.join(quoteKeyportgroupKeyport.get(quote.id).get(key),',')+'</p>';
                }
                
            }
            quotestobeUpdated.add(quote);
            
        }
        update quotestobeUpdated;
    }
    
    
}