global with sharing class sendMailWithPRPDFExt {
	Case cs;
	static String csId;
    public sendMailWithPRPDFExt(ApexPages.StandardController controller) {
    	cs = (Case)controller.getRecord();
    	csId = cs.Id;
    }
    public pageReference sendMail(){
    	Blob b;
        Boolean isRespondToBlank = false;
    	List<Messaging.EmailFileAttachment> efaList = new List<Messaging.EmailFileAttachment>();
    	for(Port_Request__c PDRRecord : PortReqList){
    		if(PDRRecord.Status__c == 'Answered'){
	    		PageReference p = new PageReference('/apex/GenerateCaseResponsePDF?Id='+PDRRecord.Id);
	    		if (Test.IsRunningTest()) {
		            b = Blob.valueOf('UNIT.TEST');
		        } else {
		            b = p.getContent();
		        }
	    		Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
	            efa.setFileName(PDRRecord.Name+'.pdf');
	            efa.setBody(b);
	            efaList.add(efa);
	        }
    	}
        EmailTemplate template = [select Id, Subject, Body from EmailTemplate where DeveloperName =: 'Email_Port_Detail_Request'];
        String myBody = template.Body;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] to = new List<String>();
        if(caseRec.Respond_to__c != null){
            to.add(caseRec.Respond_to__c);
        }
        else{
            isRespondToBlank = true;
        }
        if(!isRespondToBlank){
            if(caseRec.Additional_Emails__c != null){
    	        String AdditionalEmails = caseRec.Additional_Emails__c;
    	        String[] emailList = AdditionalEmails.split(',');
    	        to.addall(emailList);
    	    }
            mail.setToAddresses(to);
            mail.setSubject(template.Subject);
            mail.setPlainTextBody(myBody);
            mail.setWhatId(this.caseRec.Id);
            //mail.setSaveAsActivity(true); 
            //mail.setTargetObjectId(caseRec.ContactId);
            mail.setFileAttachments(efaList);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 

        	PageReference pr = new PageReference('/'+cs.Id);
        	return pr;
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please enter email in Respond to (Email)'));
            return null;
        }
    }
    public static Port_Request__c[] PortReqList {
        get {
            if (PortReqList == null) {
                PortReqList = [select Id, Status__c, Description__c, Name, Port__c,Port__r.OwnerId,Location__r.OwnerId, OwnerId, Submitted_By__c, Location__c,
                                                 Case__r.Subject, Case__r.Description, Case__r.CaseNumber, Case__r.Status, Case__r.Vessel__c,
                                                 Submitted_By__r.Name, Submitted_By__r.Email, Submitted_By__r.Phone, (SELECT Id, ParentId, Description FROM Attachments) 
                                            from Port_Request__c
                                           where Case__c = :csId];
            }
            return PortReqList;
        }
        set;
    }
    public Case caseRec {
        get {
            if (caseRec == null) {
                caseRec = [SELECT Id, Additional_Emails__c, Respond_to__c,ContactId FROM Case where Id = :csId];
            }
            return caseRec;
        }
        set;
    }
    WebService static Boolean checksendMail(String caseId){
    	csId = caseId;
    	Boolean isAtt = false;
    	for(Port_Request__c PDRRecord : PortReqList){
    		if(PDRRecord.Status__c == 'Answered'){
    			isAtt = true;
    		}
    	}
    	return isAtt;
    }

}