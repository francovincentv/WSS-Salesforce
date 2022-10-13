public class keyPortStringOnKPGChange {

     public static void changekeyPortStringOnquote(list<SBQQ__Quote__c> TriggerNew, Map<Id,SBQQ__Quote__c> TriggerOldMap,string event){
        list<id> quotesId=new list<id>();
        list<SBQQ__Quote__c> allQuotes=new list<SBQQ__Quote__c>();
        list<id> allKeyPortGroups=new list<id>();
        list<SBQQ__Quote__c> quotestobeUpdated=new list<SBQQ__Quote__c>();
        map<KeyPortGroup__c,list<String>> keyportsInKeyportGroup=new map<KeyPortGroup__c,list<String>>();
        Map<id, Map<KeyPortGroup__c, list<String>>> quoteKeyportgroupKeyport = new Map<id, Map<KeyPortGroup__c, list<String>>>();
        
        for(SBQQ__Quote__c quote :TriggerNew){
            if( event=='update' && ((TriggerOldMap.get(quote.Id).GroupKPGNo__c != quote.GroupKPGNo__c) || (TriggerOldMap.get(quote.Id).ZoneKPGNo__c !=quote.ZoneKPGNo__c))) {
                quotesId.add(quote.id); 
            }  
        }
        
        if(quotesId.isEmpty())  return;
        
        allQuotes = [Select id, (Select id from Key_Port_Groups__r), GroupKeyPortString__c, ZoneKeyPortString__c from SBQQ__Quote__c where id IN: quotesId];
        
        for(SBQQ__Quote__c quotes : allQuotes){
            
            for(KeyPortGroup__c  keyportGroups : quotes.Key_Port_Groups__r){
                allKeyPortGroups.add(keyportGroups.id);
            }
        }
        
        
        if (allKeyPortGroups.size()>0  &&  allKeyPortGroups!=null){
            for(KeyPortGroup__c keyportgroup : [SELECT id ,name,Quote__c,KeyPortGroupType__c,KeyPortGroupName__c, (SELECT Id,KeyPortName__c, KeyPortGroupType__c ,KeyPortGroupLookup__c FROM Key_Ports__r) from KeyPortGroup__c where id IN: allKeyPortGroups ORDER BY KeyPortGroupType__c ASC]){
                list<String> allRelatedKeyports=new list<String>();
                
                for(KeyPort__c keyports : keyportgroup.Key_Ports__r){
                    allRelatedKeyports.add(keyports.KeyPortName__c);
                    
                }
                keyportsInKeyportGroup.put(keyportgroup,allRelatedKeyports);
                quoteKeyportgroupKeyport.put(keyportgroup.Quote__c,keyportsInKeyportGroup);
            }
            
            for (SBQQ__Quote__c quote : allQuotes){
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
    
}