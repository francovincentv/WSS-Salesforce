/*************************************************************************
 * Class       :   PhbLinesInActiveateBatch
 * References  :   PhbLinesInActiveateBatchTest.cls
 * Description :   this batch will be scheduled for everyday, 
 *                  This batch will be update 'isActive__c' field value to false on Purchase_History_Bucket_Lines__c records based on follow condition
 *                  conditon  : 'invoiceDate__c' is lessthan last 12 months for today
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [03.Sep.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/

global class PhbLinesInActiveateBatch implements Database.Batchable<sObject>, schedulable {
    
    public Integer thisMonth;
    public Integer thisYear;

    public PhbLinesInActiveateBatch() {
        Date today = System.today();
        thisMonth = today.month();
        thisYear = today.year();
    }

    global void execute(SchedulableContext sc) {
        Database.executebatch(new PhbLinesInActiveateBatch(), 2000);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, InvoiceDate__c FROM Purchase_History_Bucket_Lines__c WHERE isActive__c = TRUE]);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        
        List<Purchase_History_Bucket_Lines__c> updateList = new List<Purchase_History_Bucket_Lines__c>();

        for(Purchase_History_Bucket_Lines__c phbl : (List<Purchase_History_Bucket_Lines__c>)scope) {
            Integer invoiceMonth = phbl.InvoiceDate__c.month();
            Integer invoiceYear = phbl.InvoiceDate__c.year();

            //if invocie date is belongs to this year then skip this record
            if(thisYear == invoiceYear && invoiceMonth < thisMonth) {
                continue;
            } 
            
            //if invocie date is belongs last 12 months then skip
            if(thisYear == (invoiceYear+1) && invoiceMonth >= thisMonth) {
                continue;
            }

            phbl.isActive__c = false;

            updateList.add(phbl);
        }

        try {
            if(updateList.size() > 0) {
                update updateList;
            }
        } catch (Exception e) {
            TransactionLogHandler.doHandleException(e, '', 'PhbLinesInActiveateBatch', null, true, true);
        }
    }

    global void finish(Database.BatchableContext bc) {

    }
}