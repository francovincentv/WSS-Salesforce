/*************************************************************************
 * Class       :   PhbLinesActivateBatch
 * References  :   PhbLinesActivateBatchTest.cls
 * Description :   this batch will be scheduled for everyday, 
 *                  This batch will be update 'isActive__c' field value to true on Purchase_History_Bucket_Lines__c records based on follow condition
 *                  conditon  : 'invoiceDate__c' is belongs to this month and isActive__c = false
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [03.Sep.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
global class PhbLinesActivateBatch implements Database.Batchable<sObject>, schedulable{

    global void execute(SchedulableContext sc) {
        Database.executebatch(new PhbLinesActivateBatch(), 2000);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, InvoiceDate__c FROM Purchase_History_Bucket_Lines__c WHERE isActive__c = FALSE AND InvoiceDate__c = THIS_MONTH]);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope) {
    
        List<Purchase_History_Bucket_Lines__c> updateList = new List<Purchase_History_Bucket_Lines__c>();

        for(Purchase_History_Bucket_Lines__c phbl : (List<Purchase_History_Bucket_Lines__c>)scope) {
            phbl.isActive__c = true;
            updateList.add(phbl);
        }

        try {
            if(updateList.size() > 0) {
                update updateList;
            }
        } catch (Exception e) {
            TransactionLogHandler.doHandleException(e, '', 'PhbLinesActivateBatch', null, true, true);
        }
    }

    global void finish(Database.BatchableContext bc) {}
}