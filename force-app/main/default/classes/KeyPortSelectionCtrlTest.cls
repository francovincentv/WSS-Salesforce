@isTest
public class KeyPortSelectionCtrlTest {
    
    // test class for KeyPortSelectionCtrl, DeleteQuoteKeyportGroupZoneString, keyPortStringOnKPGChange UpdateQuoteGroupZoneString, KeyPortGroupName
    static  testMethod  void testMethod1() {
        Account testAccount = new Account(name='Test Account');
        insert testAccount;
        
        Opportunity testOpportunity = new Opportunity(name='Test Opportunity');
        testOpportunity.StageName = 'Contact Made';
        Date x = Date.valueOf('2015-12-31');
        testOpportunity.CloseDate = x;
        testOpportunity.Amount = 10;
        insert testOpportunity;
        
        ContractParty__c testContractParty1 = new ContractParty__c ();
        testContractParty1.Account__c = testAccount.id;
        testContractParty1.Opportunity__c = testOpportunity.id;   
        
        ContractParty__c testContractParty2 = new ContractParty__c ();
        testContractParty2.Account__c = testAccount.id;
        testContractParty2.Opportunity__c = testOpportunity.id;   
        insert new List<ContractParty__c> {testContractParty1, testContractParty2};

        Test.startTest();
        
        SBQQ__Quote__c quote1 = new SBQQ__Quote__c();
        Id quoteType = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
        quote1.RecordTypeId=quoteType;
        quote1.TermType__c = 'Evergreen';
        quote1.ContractScope__c='Key Port Prices';
        quote1.SBQQ__Account__c=testAccount.id;
        quote1.SBQQ__Opportunity2__c=testOpportunity.id;
        insert quote1;
        
        
        
        KeyPortGroup__c keyPortGroup1 = new KeyPortGroup__c ();
        keyPortGroup1.Quote__c = quote1.id;
        keyPortGroup1.KeyPortGroupType__c= 'Pricing Zone 1';
        
        KeyPortGroup__c keyPortGroup2 = new KeyPortGroup__c ();
        keyPortGroup2.Quote__c = quote1.id;
        keyPortGroup2.KeyPortGroupType__c= 'Pricing Zone 2';
        insert new List<KeyPortGroup__c> {keyPortGroup1, keyPortGroup2};
        
        PricingEntity__c  PricingEntity1 = new PricingEntity__c();
        PricingEntity1.name = 'Test PricingEntity1';
        PricingEntity1.PricingType__c  = 'Zone';
        PricingEntity1.Index__c = 1;
        insert PricingEntity1;

        Port__c  port1 = new Port__c (Name='Port 1', PortPricingZone__c=PricingEntity1.Id);
        Port__c  port2 = new Port__c (Name='Port 2', PortPricingZone__c=PricingEntity1.Id);
        insert new List<Port__c> {port1, port2};
        Test.stopTest();   
        KeyPortSelectionCtrl.KeyPortRow keyPortRow = new KeyPortSelectionCtrl.KeyPortRow(port1);    
        KeyPortSelectionCtrl ctrl = KeyPortSelectionCtrl.getKeyPorts(keyPortGroup1.id);
        List<Id> allPort = new List <Id> ();
        allPort.add(port1.id);
        allPort.add(port2.id);
        KeyPortSelectionCtrl.createKeyPortRecord(allPort,keyPortGroup1.id);
        
        list<KeyPort__c> allRelatedKeyports=new list<KeyPort__c>();
        for(KeyPortGroup__c allKeyportGroup : [SELECT id ,name,Quote__c,KeyPortGroupType__c,KeyPortGroupName__c, (SELECT Id,KeyPortName__c, KeyPortGroupType__c ,KeyPortGroupLookup__c FROM Key_Ports__r) from KeyPortGroup__c where id=:keyPortGroup1.id and Quote__r.id =: quote1.id]){
            
            for(KeyPort__c keyports : allKeyportGroup.Key_Ports__r){
                allRelatedKeyports.add(keyports);
                
            }
        System.assertEquals('Key Ports A1',allKeyportGroup.KeyPortGroupName__c);

        }

        System.assertEquals(2,allRelatedKeyports.size());

        list<Id> allRelatedPorts=new list<Id>();
     
        SBQQ__Quote__c  []  quotes = [Select id, ZoneKPGNo__c, GroupKPGNo__c, GroupKeyPortString__c, ZoneKeyPortString__c from SBQQ__Quote__c where id =: quote1.id limit 1];
        String resultFinal = quotes[0].ZoneKeyPortString__c.stripHtmlTags();
		
        System.assertEquals('Key Ports A1: Port 1,Port 2 Key Ports A2:',resultFinal);

        System.assertEquals(2, quotes[0].ZoneKPGNo__c);
        System.assertEquals(0, quotes[0].GroupKPGNo__c);
        delete allRelatedKeyports;
        delete keyPortGroup1;

        SBQQ__Quote__c  []  quotes1 = [Select id, ZoneKPGNo__c, GroupKPGNo__c, GroupKeyPortString__c, ZoneKeyPortString__c from SBQQ__Quote__c where id =: quote1.id limit 1];
        String resultFinal2 = quotes[0].ZoneKeyPortString__c.stripHtmlTags();

        System.assertEquals('Key Ports A1: Port 1,Port 2 Key Ports A2:',resultFinal2);
        System.assertEquals(1, quotes1[0].ZoneKPGNo__c);
        System.assertEquals(0, quotes1[0].GroupKPGNo__c);

    }
       
}