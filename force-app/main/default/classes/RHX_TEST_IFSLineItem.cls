@isTest(SeeAllData=true)
public class RHX_TEST_IFSLineItem {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM IFSLineItem__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new IFSLineItem__c()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}