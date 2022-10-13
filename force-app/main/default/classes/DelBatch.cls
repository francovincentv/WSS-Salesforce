global class DelBatch implements Database.Batchable<sObject> {
	
	String query;
	
	global DelBatch() {
		query = 'select Id from PCE_Cargo__c';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		PCE_Cargo__c[] das = (PCE_Cargo__c[])scope;
		delete das;
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}