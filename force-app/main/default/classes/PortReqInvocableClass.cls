public class PortReqInvocableClass{

    @InvocableMethod
    public static void initiateProcess(List<Port_Request__c> PDRList){

    	List<Port_Request__c> PDGeneratePDFList = new List<Port_Request__c>();
        List<Port_Request__c> SendMailList = new List<Port_Request__c>();
    	for(Port_Request__c PDRRec : PDRList){

    		if(PDRRec.Generate_Pdf__c == true){
    			PDGeneratePDFList.add(PDRRec);
    		}
           /* if(PDRRec.Send_Mail__c == true){
                SendMailList.add(PDRRec);
            }*/
    	}
        if(PDGeneratePDFList.size() > 0){
            Database.executeBatch(new PortDetailReqPDFCreation(PDGeneratePDFList, 'Generate PDF'),1);
        }
       /* if(SendMailList.size() > 0){
            Database.executeBatch(new PortDetailReqPDFCreation(SendMailList,'Mail PDF'),1);
        }*/
    	
    }
}