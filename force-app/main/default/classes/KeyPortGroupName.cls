public class KeyPortGroupName {
    
    public static void nameKeyPortGroup(list<KeyPortGroup__c> keyportGroupList){
        Decimal countZone=1;
             Decimal countGroup=1;
        
        list<id> quotesId=new list<id>();
        list<KeyPortGroup__c> keyPortToBeUpdated=new list<KeyPortGroup__c>();

        for(KeyPortGroup__c keyportGroup :keyportGroupList){
            	quotesId.add(keyportGroup.Quote__c);
      		  }
        
         for(KeyPortGroup__c keyportgroup : [SELECT id ,KeyPortGroupType__c,KeyPortGroupName__c from KeyPortGroup__c where Quote__r.id IN: quotesId ORDER BY KeyPortGroupType__c ASC]){
			 if(keyportgroup.KeyPortGroupType__c.contains('Zone')){
                keyportgroup.KeyPortGroupName__c = 'Key Ports A'+ countZone;
                countZone++;
				}
             if(keyportgroup.KeyPortGroupType__c.contains('Group')){
                keyportgroup.KeyPortGroupName__c = 'Key Ports B'+ countGroup;
                countGroup++;
               }

			keyPortToBeUpdated.add(keyportgroup);
             }
        update keyPortToBeUpdated;
    }

}