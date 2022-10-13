global class ScmRelatedInfo {
    global string scmName{get;set;}
    global List<ProdSite_SCMTEST__c> getProdSites() {
		List<ProdSite_SCMTEST__c> prodSites;
        prodSites = [SELECT Initial_stock_qty_at_launch__c, 
                     Product_Number__c,
                     Product__r.Name, 
                     Site_Abbreviation__c,
                     Site_Name__r.Name
                     FROM ProdSite_SCMTEST__c WHERE SCM_Implementation__r.Name =: scmName];
        system.debug(scmName);
        return prodSites;
    }   
}