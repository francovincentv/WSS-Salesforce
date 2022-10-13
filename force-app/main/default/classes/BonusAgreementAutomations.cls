public class BonusAgreementAutomations {
    
    public static void generateProductGroupString(list<BonusAgreement__c> TriggerNew, Map<Id,BonusAgreement__c> TriggerOldMap,string event){
        //before insert always update the group string. Values should be always selected when creating agreement.
        if( Trigger.isInsert ){
            for(BonusAgreement__c ba: TriggerNew){
                string pgs = ba.Sales_Product_Group__c;
                if(pgs != null) {
                    pgs = pgs.replaceAll('(_)', ' '); //pgs.replaceAll('(\\s?\\-[^\\;]*)', '');
                    pgs = pgs.replace(';',', ');
                    ba.ProductGroups__c = pgs;
                }
            }
        }
        
        if( Trigger.isUpdate ){
            for(BonusAgreement__c ba :TriggerNew){
                if(TriggerOldMap.get(ba.ID).Sales_Product_Group__c!= ba.Sales_Product_Group__c){
                    string pgs = ba.Sales_Product_Group__c;
                    if(pgs != null) {
                        pgs = pgs = pgs.replaceAll('(_)', ' '); //pgs.replaceAll('(\\s?\\-[^\\;]*)', '');
                        pgs = pgs.replace(';',', ');
                        ba.ProductGroups__c = pgs;
                    }
                }
            }
        } 
    }
    /*
Updates bonus agreement fields to quote when agreement is changed.
*/
    public static void updateBonusInformationtoQuote(list<BonusAgreement__c> TriggerNew, Map<Id,BonusAgreement__c> TriggerOldMap,string event){
        set<id> bonusAgreementIds=new set<id>();
        if(event=='update'){
            for(BonusAgreement__c ba:TriggerNew){
                if (
                    (ba.ProductGroups__c != TriggerOldMap.get(ba.Id).ProductGroups__c) ||
                    (ba.BonusAmountString__c != TriggerOldMap.get(ba.Id).BonusAmountString__c) ||
                    (ba.BonusPercentString__c != TriggerOldMap.get(ba.Id).BonusPercentString__c)
                ){
                    bonusAgreementIds.add(ba.id);    
                }
            }
        }
        
        if(bonusAgreementIds!=null && bonusAgreementIds.size()>0){
            list<SBQQ__Quote__c> quotesToUpdate=new list<SBQQ__Quote__c>();
            for(SBQQ__Quote__c singleQuote: [SELECT id,
                                             BonusAgreement__r.BonusAmountString__c,
                                             BonusAgreement__r.ProductGroups__c,
                                             BonusAgreement__r.BonusPercentString__c
                                             FROM SBQQ__Quote__c 
                                             WHERE BonusAgreement__c IN: bonusAgreementIds
                                             AND ApprovalStatus__c!='Approved'
                                             AND ApprovalStatus__c!='Rejected']){
                                                 singleQuote.BonusAmountString__c=singleQuote.BonusAgreement__r.BonusAmountString__c;
                                                 singleQuote.BonusGroups__c=singleQuote.BonusAgreement__r.ProductGroups__c;
                                                 singleQuote.BonusPercentString__c=singleQuote.BonusAgreement__r.BonusPercentString__c;
                                                 quotesToUpdate.add(singleQuote);  
                                             }
            if(quotesToUpdate.size()>0){
                update quotesToUpdate;
            }
        }
    }
    
    
    /*
Kick off the bonus agreement automation (quote-agreement fields sync) when agreement lookup on quote changes
*/
    public static void updateBonusInformationAgreementChanged(list<SBQQ__Quote__c> TriggerNew, Map<Id,SBQQ__Quote__c> TriggerOldMap,string event){
        set<id> bonusAgreementIds=new set<id>();
        list<SBQQ__Quote__c> quotesToUpdate=new list<SBQQ__Quote__c>();
        map<id,BonusAgreement__c> BonusAgreementMap=new map<id,BonusAgreement__c>();
        if(event=='update'){
            for(SBQQ__Quote__c singleQuote:TriggerNew){
                if (
                    singleQuote.BonusAgreement__c != TriggerOldMap.get(singleQuote.Id).BonusAgreement__c
                ){
                    if(singleQuote.BonusAgreement__c !=null ){
                        bonusAgreementIds.add(singleQuote.BonusAgreement__c);
                        quotesToUpdate.add(singleQuote);
                    }
                    //Clean quote field values the lookup is empty
                    else{
                        singleQuote.BonusAmountString__c=null;
                        singleQuote.BonusGroups__c=null;
                        singleQuote.BonusPercentString__c=null;
                    }
                }
            }
        }
        if(bonusAgreementIds.size()==0){
            return;
        }
        for(BonusAgreement__c BonusAgreement: [SELECT id,
                                               BonusAmountString__c,
                                               ProductGroups__c,
                                               BonusPercentString__c  
                                               FROM BonusAgreement__c
                                               WHERE id IN:bonusAgreementIds]){
                                                   BonusAgreementMap.put(BonusAgreement.id,BonusAgreement);
                                                   
                                               }
        for(SBQQ__Quote__c singleQuote: quotesToUpdate){
            if(singleQuote.BonusAgreement__c!=null && 
               BonusAgreementMap.get(singleQuote.BonusAgreement__c)!=null){
                   BonusAgreement__c quoteBonusAgreement=BonusAgreementMap.get(singleQuote.BonusAgreement__c);
                   //Update quote fields with new agreement info
                   singleQuote.BonusAmountString__c=quoteBonusAgreement.BonusAmountString__c;
                   singleQuote.BonusGroups__c=quoteBonusAgreement.ProductGroups__c;
                   singleQuote.BonusPercentString__c=quoteBonusAgreement.BonusPercentString__c;
               }
        }
    }
    
}