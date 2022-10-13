/*************************************************
* Class       	: LWC_SelectContractParties
* References  	: LWC_SelectContractParties_Test.cls
* Description 	: This is the helper class for SelectContractParties web component, 
                    this class will handle all the necessary data to query/update/delete.
* Change Log	
* Date Modified		Modified By 		Description
* -----------------------------------------------------------
* [14.Aug.2020]	    [Lokesh - Fluido]	[initial development]
**************************************************/

public with sharing class LWC_SelectContractParties {
    

    /**************************************************************************************
    * @Description  This method gets all accounts with record type 'Customer_Sub_Account'
    * @Param		
    * @Return       List<Account>
    **************************************************************************************/ 
    @AuraEnabled
    public static List<Account> getSubAccounts(){
        return [SELECT Id, Name, Account_Number__c, CurrencyIsoCode, Recordtype.DeveloperName,
                OwnerId, Owner.SM_Territory__c, Owner.Sales_Area__c, Account_Status__c,
                (SELECT Opportunity__c FROM Contract_Parties__r) 
                FROM Account 
                WHERE Recordtype.DeveloperName = 'Customer_Sub_Account' ORDER BY Name ASC];
    }

    /**************************************************************************************
    * @Description  This method gets all contract parties related to opportunity
    * @Param		Id - Opportunity Id
    * @Return       List<ContractParty__c>
    **************************************************************************************/ 
    @AuraEnabled
    public static List<ContractParty__c> getContractParties(Id oppId){
        List<ContractParty__c> cpList = [SELECT Id, Account__c,Account__r.Name, Account__r.OwnerId, 
                                            Account__r.Account_Number__c, Account__r.CurrencyIsoCode, Account__r.Account_Status__c,
                                            Account__r.RecordType.DeveloperName, Account__r.Owner.SM_Territory__c, Account__r.Owner.Sales_Area__c 
                                            FROM ContractParty__c 
                                            WHERE Opportunity__c =: oppId];

        //Integer count = [SELECT Count() FROM ContractParty__c WHERE Opportunity__c =: oppId];
        return cpList;
    }

    /**************************************************************************************
    * @Description  This method gets Sub_Deal__c accounts information related to the contract id passed as param
    * @Param		Id - Contract Id
    * @Return       List<Account>
    **************************************************************************************/ 
    @AuraEnabled
    public static List<Account> getSubDealsForContract(Id contractId){
        Set<Id> accountIdSet = new Set<Id>();
        for(Sub_Deal__c deal: [SELECT Customer_Sub_Account__c FROM Sub_Deal__c WHERE Deal__c =: contractId]) {
            accountIdSet.add(deal.Customer_Sub_Account__c);
        }

        return [SELECT Id, Name, Account_Number__c, CurrencyIsoCode, Recordtype.DeveloperName,
                    OwnerId, Owner.SM_Territory__c, Owner.Sales_Area__c, Account_Status__c 
                FROM Account 
                WHERE Id IN: accountIdSet];
    }

    /**************************************************************************************
    * @Description  This method commits the data to database based on the parameters passed from web component
    * @Param		List<ContractParty__c> - contractParty__c to delete, 
    * @Param		List<ContractParty__c> - contractParty__c to insert,
    * @Param		Opportunity - Opportunity to update,
    * @Param		Boolean - To identify opportunity to update or not
    * @Return       void
    **************************************************************************************/ 
    @AuraEnabled 
    public static void commitTheData(List<ContractParty__c> deleteList, List<ContractParty__c> insertList, Opportunity opp, Boolean updateOpp){
        system.debug('Contract parties to insert'+insertList.size());
        system.debug('Contract parties to delete'+deleteList.size());

        SavePoint sp = Database.setSavePoint();

        try{
            if(insertList.size()>0) {
                insert insertList;
            }
            if(deleteList.size() > 0) {
                delete deleteList;
            }
            opp.Approval_Status__c = '';
            update opp;

            updateActiveQuote(opp.Id);
        } catch (exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**************************************************************************************
    * @Description  Helper method for commitTheData()
    *               This method will update the quote field 'ApprovalStatus__c' to ''
                    and if there is any BonusAgreement__c is exist then updates that records 
    * @Param		Id - quote related opportunity Id
    * @Return       void
    **************************************************************************************/ 
    @future
    public static void updateActiveQuote(Id oppId) {
        List<SBQQ__Quote__c> quotes = [SELECT Id,BonusAgreement__c FROM SBQQ__Quote__c WHERE SBQQ__Primary__c = true AND SBQQ__Opportunity2__c =: oppId];

        if(quotes.size() > 0) {
            //there should be only one primary quote, need to update that
            SBQQ__Quote__c quote = quotes[0];
            quote.ApprovalStatus__c = '';
            update quote;

            //if there is any bouns agreement, udpate that record
            if(quote.BonusAgreement__c != null) {
                BonusAgreement__c bonusAgrmnt = new BonusAgreement__c(Id = quote.BonusAgreement__c);
                update bonusAgrmnt;
            }
        }
    }


    /**************************************************************************************
    * @Description  This method first gets opportunity id's related to contract based on the input serchkey
                    Then it query the opportunites along with contract parties to return 
    * @Param		String - contract number
    * @Return       List<Opportunity>
    **************************************************************************************/ 
    @AuraEnabled
    public static List<Opportunity> getContractAccounts(String searchKey) {
        String contractNum = '%'+searchKey+'%';
        List<Id> oppIds = new List<Id>();
        for(Contract contract : [SELECT Id, SBQQ__Opportunity__c FROM Contract WHERE ContractNumber LIKE : contractNum ]) {
            if(contract.SBQQ__Opportunity__c != null) {
                oppIds.add(contract.SBQQ__Opportunity__c);
            }
        }
    
        return [SELECT Id, (SELECT Account__c FROM Contract_Parties__r) FROM Opportunity WHERE Id IN: oppIds];
    }

    /**************************************************************************************
    * @Description  This method get the all accounts realted to the account id passed as param
    * @Param		String - account id
    * @Return       List<Account>
    **************************************************************************************/ 
    @AuraEnabled
    public static List<Account> getAccountHierarchy( String accountId ){
        List<Account> accReturnList = new List<Account>();
        List<Account> accList = new List<Account>{};
        List<ID> currentParent = new List<ID>{};
        Integer level = 0;
        Boolean endOfStructure = false;
        try{
            //Find highest level obejct in the structure
            currentParent.add(getTopElement(accountId));

            //Loop though all children
            while ( !endOfStructure ){
                if( level == 0 ){    
                    accList = [ SELECT Name, Id, RecordType.Name,RecordType.DeveloperName, OwnerId, Owner.SM_Territory__c, Owner.Sales_Area__c, Account_Number__c, Account_Status__c  FROM Account WHERE Id IN : CurrentParent];
                } 
                else {    
                    accList = [ SELECT Name, Id, ParentId, RecordType.Name,RecordType.DeveloperName, OwnerId,  Owner.SM_Territory__c, Owner.Sales_Area__c, Account_Number__c, Account_Status__c  FROM Account WHERE ParentID IN : CurrentParent ORDER BY Name ];
                }

                if( accList.size() == 0 ){
                    endOfStructure = true;
                }
                else{
                    currentParent.clear();
                    for(Account acc : accList) {
                        accReturnList.add(acc);
                        currentParent.add(acc.Id);
                    }               
                    level++;
                }
            }
            return accReturnList;
        }
        catch(exception e) {
            System.debug('exception'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**************************************************************************************
    * @Description  This is helper method for getAccountHierarchy() 
                    this method Find the top most account id in Heirarchy  
    * @Param		String - account id
    * @Return       String - AccountId
    **************************************************************************************/ 
    public static String getTopElement( String accId ){
        Boolean top = false;
        while ( !top ) {
            //get 5 levels of parent
            Account a = [ SELECT a.Id, a.ParentId,a.Parent.ParentId,a.Parent.Parent.ParentId,a.Parent.Parent.Parent.ParentId FROM Account a WHERE a.Id =: accId limit 1 ];

            if ( a.ParentID != null ) {
                accId = a.ParentID;
                if(a.Parent.ParentId != null) {
                   accId = a.Parent.ParentId; 
                    if(a.Parent.Parent.ParentId != null) {
                       accId = a.Parent.Parent.ParentId;
                        if(a.Parent.Parent.Parent.ParentId != null){
                            accId = a.Parent.Parent.Parent.ParentId;
						}
					}
				}
            } 
            else {
                top = true;
            }
        }
        return accId ;
    }

}