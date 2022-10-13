global class PortDetailReqPDFCreation implements Database.Batchable<sObject> {

	List<Port_Request__c> PDRList = new List<Port_Request__c>();
    String PDFstatus;
	Set<Id> PDRIdList = new Set<Id>();
    global PortDetailReqPDFCreation(List<Port_Request__c> PDRList, String PDFstatus){
    	this.PDRList = PDRList;
        this.PDFstatus = PDFstatus;
    	for(Port_Request__c PDRRec : PDRList){
    		PDRIdList.add(PDRRec.Id);
    	}
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
    	
        return Database.getQueryLocator([SELECT Id, Name, Case__c,Response_PDF__c, Port__c, Status__c, Description__c, Submitted_By__c, Case__r.Respond_to__c,
                                        Case__r.Additional_Emails__c,Send_Mail__c,
    									Location__c, Vessel__c, Generate_Pdf__c FROM Port_Request__c where Id IN: PDRIdList]);
    }
    global void execute(Database.BatchableContext BC, List<Port_Request__c> scope) {
    	system.debug('----scope'+scope);
    	for(Port_Request__c PRDRec : scope){
    		ApexPages.StandardController sc = new ApexPages.StandardController(PRDRec);
    		GenerateCaseResponsePDFExt obj = new GenerateCaseResponsePDFExt(sc);

            //if(PDFstatus.equalsIgnoreCase('Generate PDF')){
                obj.generateAtt();
            //}
            /*if(PDFstatus.equalsIgnoreCase('Mail PDF')){
                obj.MailPdf(PRDRec);
            }*/ 
    		
    	}
    }
    global void finish(Database.BatchableContext BC) {
    }
}