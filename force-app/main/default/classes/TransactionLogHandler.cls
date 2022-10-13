/*********************************************
TransactionLogHandler
The class which is responsible for catching the exception and then inserting into the Transaction Log Object.
*********************************************/
public class TransactionLogHandler{

    public static Transaction_Log__c doHandleException(System.Exception ex , String errorMsg, String processName, String recordId, Boolean doInsert, Boolean sendAlert){
        if(
            (Limits.getDMLRows() < Limits.getLimitDMLRows()) && 
            (Limits.getDMLStatements() < Limits.getLimitDMLStatements())
        ){
            Transaction_Log__c log = new Transaction_Log__c();
            if(ex == null) {
                log.Error_Log__c = errorMsg;
            } else {
                log.Error_Log__c = ex.getStackTraceString() +'<br/>' + ex.getMessage() + '<br/>' + ex.getCause() +' <br/>'+ ex.getTypeName();
            }
            
            log.Record_Id__c = recordId;
            log.Class_Name__c = processName;
            log.Send_Alert__c = sendAlert;
            if(doInsert) {
                insert log;
            }

            return log;
        } 
        else{
            System.debug('The Governor Limits have already been exhausted and hence failed to create a Transaction_Log__c!');
            return null;
        }
        
    }

    public static void insertErrorWithAttchment(String errorMsg, String className, String body) {
        //insert trasaction_log__c records
        Transaction_Log__c tr = TransactionLogHandler.doHandleException(null, errorMsg, className, null, true, true);



        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
        conVer.PathOnClient = className+ '_'+ Datetime.now().format('MMM_d_yyyy_HH:mm:ss') +'.txt'; // The files name, extension is very important here which will help the file in preview; 
        conVer.Title = className+ '_' +Datetime.now().format('MMM_d_yyyy_HH:mm:ss');// Display name of the files
        conVer.VersionData = Blob.valueOf(body); // converting your binary string to Blog
        insert conVer;    //Insert ContentVersion


        // First get the Content Document Id from ContentVersion Object
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;

        //create ContentDocumentLink  record 
        ContentDocumentLink conDocLink = New ContentDocumentLink();
        conDocLink.LinkedEntityId = tr.Id;
        conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
        conDocLink.shareType = 'V';
        insert conDocLink;
    }

}