public with sharing class OpportunityProcessApx {
    @InvocableMethod
    public static List<Opportunity> contractPartiesClass(List<Id> oppIds) {
        List<Opportunity> oppToReturn = new List<Opportunity>();
        Integer cPCounter =0; //used
        Integer cPSignersCounter =0;
        Integer accTransactionalCounter =0;//used
        Integer accWinCentreAccountCount =0; //used
        Integer accTransitionalDiscountCount =0; //used
        String salesTerritoryFinal ='';//used
        String salesTerritorySingle ='';//used
        String salesAreaFinal ='';//used
        String salesAreaSingle ='';//used
        
        System.debug('**START SOQL QUERIES COUNT '+ Limits.getQueries());
		Opportunity oppRecord = [SELECT Id, Contracted_Items__c,Only_Transactional_Accounts__c,Win_Centre_Contract__c,Signers_Scenario_3__c,Document_Signer_Scenario__c,Amount FROM Opportunity WHERE Id=: oppIds[0]];
        //System.debug('oppRecord '+oppRecord);
        
        //collect the contract parties related to that opportunity
        Map<Id, ContractParty__c> cpMap = new Map<Id, ContractParty__c>([SELECT Id,Account__c, SignstheContract__c,Win_Centre_Account__c FROM ContractParty__c  WHERE Opportunity__c =: oppRecord.id AND RecordTypeDeveloperName__c !='WSS']);
		//System.debug('CP MAP: '+cpMap.size());
        
        //collect the accounts related to all the above cp
        Set<Id> accIds = new Set<Id>();
        for (ContractParty__c cp : cpMap.values()) {
            accIds.add(cp.Account__c);
        }
        
        //query all these accounts
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Type,Transition_Discount__c,Sales_Territory__c,Sales_Area__c, (SELECT id FROM Applies_to_Sub_Accounts__r) FROM Account WHERE Id IN: accIds]);
        //System.debug('ACC MAP: '+accMap.size());

        //query all the subdeals with acc id in the loop
        Map<Id, Sub_Deal__c> subdealsMap = new Map<Id, Sub_Deal__c>([SELECT Id, Customer_Sub_Account__c,Active__c FROM Sub_Deal__c WHERE Customer_Sub_Account__c IN: accIds AND Active__c = true]);
        //System.debug('SUBD MAP: '+subdealsMap.size());
        
        //Create a map with acc id as key and sd as value
        Map<String, Sub_Deal__c> sdWithAcc = new  Map<String, Sub_Deal__c>();
        if(subdealsMap !=null) {
            for(Sub_Deal__c sd : subdealsMap.values()) {
                sdWithAcc.put(sd.Customer_Sub_Account__c, sd);
            }
        }

        //System.debug('MAP ACC ID WITH SD '+sdWithAcc);
        
        for(Id cp : cpMap.keySet()) {
            ContractParty__c cpRecord = cpMap.get(cp);
            //System.debug('CP '+ cpMap.get(cp));
            
            Id accountId = cpMap.get(cp).Account__c;
            Account accRecord = accMap.get(accountId);
			
            String accid = cpMap.get(cp).Account__c;
			
            if(accid == null){
              //  System.debug('IN CONTINUE');
                Continue;
            }else{
              //  System.debug('************************************IN ELSE');
                cPCounter++;
                //is this cp a contract signer?
                if (cpRecord.SignstheContract__c) cPSignersCounter++;
                //Is this a transactional account?
                if (accRecord.Type == 'Transactional') accTransactionalCounter++;
                //Is Win Center Account?
                if (cpRecord.Win_Centre_Account__c ) accWinCentreAccountCount++;
                //Transitional Discount marked on Accounts?
                if (accRecord.Transition_Discount__c) accTransitionalDiscountCount++;
                //Is territory already added?
                if(accRecord.Sales_Territory__c!=null) {
                    if(salesTerritoryFinal.contains(accRecord.Sales_Territory__c)) salesTerritorySingle= '';
                    else salesTerritorySingle = accRecord.Sales_Territory__c+';';                    
                }
                //Is sales area already added?                
                if(accRecord.Sales_Area__c!=null) {
                    if(salesAreaFinal.contains(accRecord.Sales_Area__c)) salesAreaSingle= '';
                	else salesAreaSingle = accRecord.Sales_Area__c+';';
                }
                //final assignments
                salesTerritoryFinal = salesTerritoryFinal + salesTerritorySingle;
                salesAreaFinal = salesAreaFinal + salesAreaSingle;
            }
            
            //Is there an active subdeals related to this account?
            if(sdWithAcc.get(accountId) != null) oppRecord.Contracted_Items__c = 'Yes';
            else oppRecord.Contracted_Items__c = 'No';
            //System.debug(oppRecord.Contracted_Items__c );
        }
                    
        //if Transition Discount >1
        if(accTransitionalDiscountCount > 1) oppRecord.Transition_Discount_Included__c = true;
        else oppRecord.Transition_Discount_Included__c= false;
		//all CP are Transactional Accounts
		if(cPCounter == accTransactionalCounter) oppRecord.Only_Transactional_Accounts__c = true;
        else oppRecord.Only_Transactional_Accounts__c = false;
        //Assign the final values to opp
        oppRecord.Account_CP_Territory__c = salesTerritoryFinal;
        oppRecord.Account_CP_Area__c = salesAreaFinal;
        //Is Win Center in Opp true?
        if(oppRecord.Win_Centre_Contract__c == false) {
            if(oppRecord.Amount >= 1000000 || accWinCentreAccountCount >0){
                oppRecord.Win_Centre_Contract__c = true;  
                oppToReturn.add(oppRecord);
                return oppToReturn;
            }   
        }
        //Scenarios - contract signer
        if(cPSignersCounter == cPCounter && cPSignersCounter==1) {
            oppRecord.Signers_Scenario_3__c = false;
            oppRecord.Document_Signer_Scenario__c = '1a - one signer CP';
        }else if(cPSignersCounter == cPCounter && cPSignersCounter>1) {
            oppRecord.Signers_Scenario_3__c = false;
            oppRecord.Document_Signer_Scenario__c = '1b - more than one CP all signers';
        }else if(cPSignersCounter != cPCounter && cPSignersCounter==1) {
            oppRecord.Signers_Scenario_3__c = false;            
            oppRecord.Document_Signer_Scenario__c = '2 - more than one CP and only one signer';            
        }else if(cPSignersCounter>1) {
            oppRecord.Signers_Scenario_3__c = true;            
            oppRecord.Document_Signer_Scenario__c = '3 - more than one CP and more than one signer';            
        }else if(cPSignersCounter==0 || cPSignersCounter==NULL) {
            oppRecord.Signers_Scenario_3__c=true;
        }
          
        oppRecord.Account_CP_Area__c = salesAreaFinal;
        oppRecord.Account_CP_Territory__c = salesTerritoryFinal;
		/*
        System.debug('oppRecord.Account_CP_Area__c '+oppRecord.Account_CP_Area__c);   
        System.debug('oppRecord.Account_CP_Territory__c '+oppRecord.Account_CP_Territory__c);   
        System.debug('oppRecord.Signers_Scenario_3__c '+oppRecord.Signers_Scenario_3__c); 
        System.debug('oppRecord.Win_Centre_Contract__c '+oppRecord.Win_Centre_Contract__c);            
        System.debug('oppRecord.Sales_Territory__c '+oppRecord.Document_Signer_Scenario__c); 
        System.debug('oppRecord.Only_Transactional_Accounts__c '+oppRecord.Only_Transactional_Accounts__c); 
        System.debug('oppRecord.Contracted_Items__c '+oppRecord.Contracted_Items__c); 

        System.debug('**STOP SOQL QUERIES COUNT '+ Limits.getQueries());
        System.debug('CP SINGERS IN TOTAL '+ cPSignersCounter);
		System.debug('CP IN TOTAL '+ cPCounter);
        */
        oppToReturn.add(oppRecord);
        return oppToReturn;
    }
}