/*************************************************************************
 *  Class       :   LWC_ContractRenewalOpportunityHelper
 *  References  :   ContractRenewalOpportunityHelper_Test, ContractRenewalOpportunity (web component)
 *  Description :   This class is used in ContractRenewalOpportunity lightning web component    
 *                  To clone the opportunity and related contract parties 
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [14.Aug.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
public with sharing class LWC_ContractRenewalOpportunityHelper {

    /**************************************************************************************
    * @Description  This method create new Opporunity(Renewal)
    * @Param		Id - Opportunty id to renewal
    * @Param		Date - contract exp date
    * @Param		Double - opportunty amount
    * @Param		String - contract number
    * @Return       Opportunity - Newly created opportunity
    **************************************************************************************/ 
    @AuraEnabled
    public static Opportunity createRenewalOpportunity(Contract contract) {
        try {
            System.debug('contract : '+ contract);
            String oppId = contract.SBQQ__Opportunity__c;
            String oppQuery = 'SELECT Account.Name, ';

            //get all the fields from opportunity
            SObjectType opportunityType = Schema.getGlobalDescribe().get('Opportunity');
            Map <String, Schema.SObjectField> oppFields = opportunityType.getDescribe().fields.getMap();
            for (Schema.SObjectField f: oppFields.values()) {
                oppQuery += f + ',';
            }
            oppQuery = oppQuery.removeEnd(',');
            oppQuery += ' FROM Opportunity WHERE Id =:oppId';

            //query the parent opportunity with all fields
            List <Opportunity> parentOppList = Database.query(oppQuery);
            Opportunity parentOpp = parentOppList[0];

            //clone the parent opportunity to create new renewal opportunity
            Opportunity clonedOpp = parentOpp.clone(false, true);
            clonedOpp.Name = contract.ContractNumber + ' - '+ parentOpp.Account.Name + ' - Renewal';
            clonedOpp.CloseDate = contract.SBQQ__ExpirationDate__c > System.today() ? contract.SBQQ__ExpirationDate__c : System.today().addDays(30);
            clonedOpp.Previous_Opportunity_OfRenewal__c = parentOpp.Id;
            clonedOpp.Amount = contract.Deal_Value_per_annum__c;
            clonedOpp.Related_Contract__c = contract.Id;
            clonedOpp.Legal_Approval__c = true;
            insert clonedOpp;
            //System.debug('Cloned opp' + clonedOpp);

            String cpQuery = 'SELECT ';

            //get all the fields from ContractParty__c
            SObjectType cpType = Schema.getGlobalDescribe().get('ContractParty__c');
            Map < String, Schema.SObjectField > cpFields = cpType.getDescribe().fields.getMap();
            for (Schema.SObjectField f: cpFields.values()) {
                cpQuery += f + ',';
            }
            cpQuery = cpQuery.removeEnd(',');
            cpQuery += ' FROM ContractParty__c WHERE Opportunity__c =:oppId';

            //query the exiting contract parties of the parent opportunity
            List <ContractParty__c> relatedContactParites = Database.query(cpQuery);
            List <ContractParty__c> cpInsertList = new List <ContractParty__c> ();

            for (ContractParty__c cp: relatedContactParites) {
                ContractParty__c clonedCP = cp.clone(false, true);
                clonedCP.Opportunity__c = clonedOpp.Id;
                cpInsertList.add(clonedCP);
            }

            insert cpInsertList;

            return clonedOpp;
        } catch (Exception e) {
            system.debug('exception' + e.getMessage());
            system.debug('exception' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}