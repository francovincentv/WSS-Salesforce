global without sharing class KeyPortSelectionCtrl {
    
    @AuraEnabled public list<KeyPortRow> keyPortRows;
    @AuraEnabled public Object rowResponse;
    @AuraEnabled public Integer itemSize; 
    @AuraEnabled public string success; 
    @AuraEnabled public string errormessage; 
    @AuraEnabled public string errorcode;
    
    
    @AuraEnabled
    public static KeyPortSelectionCtrl getKeyPorts(Id recordId){
        
        KeyPortGroup__c [] portGroup = [SELECT KeyPortGroupType__c FROM KeyPortGroup__c where id=:recordId limit 1];
        String portGroupZone =portGroup[0].KeyPortGroupType__c;
        KeyPortSelectionCtrl ctrl = new KeyPortSelectionCtrl();
        List<KeyPortRow> items = new List<KeyPortRow>();
        for(Port__c KP: [SELECT id,name,Port_Code__c,LocationName__c, PortPricingZone__r.name,PortPricingGroup__r.name
                         FROM Port__c where PortPricingZone__r.name=:portGroupZone OR PortPricingGroup__r.name=:portGroupZone]) {
                             items.add(new KeyPortRow(KP));
                         }
        
        
        KeyPort__c [] relatedKeyPort =	[Select id,Port__r.id, Port__r.name, PortChecked__c from KeyPort__c where KeyPortGroupLookup__r.id =:recordId];
        for(integer i= 0; i<items.size(); i++){
            for(integer j= 0; j<relatedKeyPort.size(); j++){
                if(items[i].KeyPort.Id==relatedKeyPort[j].Port__c)
                    items[i].Selected=true;
            } 
        }
        ctrl.keyPortRows = items;
        return ctrl;
    }
    
    
    @AuraEnabled
    public static id getQuoteId(Id recordId){
        KeyPortGroup__c [] quote = [SELECT Quote__c FROM KeyPortGroup__c where id=:recordId limit 1];
        return quote[0].Quote__c ;
        
    }
    
    @AuraEnabled
    public static void createKeyPortRecord(List<Id> portId, Id recordId){
        KeyPortGroup__c [] PortGroupId = [SELECT  id, Quote__r.id, KeyPortGroupType__c FROM KeyPortGroup__c where id=:recordId limit 1];
        List<Id> portsIdToBeInserted= new List<Id>();
        List<Id> portsIdToBeDeleted= new List<Id>();
        List<Id> portIdInRelatedKeyPort = new List<Id>();
        list<KeyPort__c> listofKeyPorts = new list<KeyPort__c>();
        
        KeyPort__c [] relatedKeyPort =	[Select id,Port__r.id, Port__r.name, PortChecked__c from KeyPort__c where KeyPortGroupLookup__r.id =:recordId];
        
        for (KeyPort__c keyport: relatedKeyPort){
            portIdInRelatedKeyPort.add(keyport.Port__r.id);
        }
        system.debug('relatedKeyPort--->'+portIdInRelatedKeyPort);
        //list containing new ports to be inserted 
        for (Id port: portId){
            if(!portIdInRelatedKeyPort.contains(port)){
                portsIdToBeInserted.add(port);
            }
            
        }
        system.debug('portsIdToBeInserted--->'+portsIdToBeInserted);

        for (Id port: portIdInRelatedKeyPort){
            if(!portId.contains(port)){
                portsIdToBeDeleted.add(port);
            }
        }
        system.debug('portsIdToBeDeleted--->'+portsIdToBeDeleted);

        //deleting unchekced ports
        if (portsIdToBeDeleted.size()>0){
            KeyPort__c [] keyPortsIdTobeDeleted =	[Select id,Port__r.id, Port__r.name, PortChecked__c from KeyPort__c where KeyPortGroupLookup__r.id =:recordId And Port__r.id IN: portsIdToBeDeleted];
            delete keyPortsIdTobeDeleted;
        }      
        
        
        if(portsIdToBeInserted.size()>0){
            for (integer i=0; i<portsIdToBeInserted.size(); i++){
                KeyPort__c  newKeyPort = new KeyPort__c();
                newKeyPort.Quote__c= PortGroupId[0].Quote__r.id;
                newKeyPort.KeyPortGroupLookup__c = PortGroupId[0].id;
                newKeyPort.Port__c  = portsIdToBeInserted[i];
                newKeyport.PortChecked__c=true; 
                listofKeyPorts.add(newKeyPort);
            }
            if (listofKeyPorts.isEmpty()) return;
            insert listofKeyPorts;
        }
        
    }
    
    public class KeyPortRow{
        @AuraEnabled public boolean Selected {get;set;}
        @AuraEnabled public Port__c KeyPort {get;set;}
        public KeyPortRow(Port__c singleKeyPort) {
            KeyPort = singleKeyPort;
            Selected = false;
        }
    }
    
    
    
}