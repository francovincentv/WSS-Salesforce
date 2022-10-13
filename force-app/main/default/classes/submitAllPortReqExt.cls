global with sharing class submitAllPortReqExt {
	Case cs;
    public submitAllPortReqExt(ApexPages.StandardController controller) {
        cs = (Case)controller.getRecord();
        system.debug('---------'+cs);
    }
    public pageReference submitPR(){
    	List<Port_Request__c> prListToUpdate = new List<Port_Request__c>();
    	List<Attachment> attList = new List<Attachment>();
    	FeedItem[] feedPostList = new FeedItem[]{};
    	for(Port_Request__c p : PortReqList){
    		if(p.Status__c != 'Answered'){
	    		p.Status__c = 'Submitted';
	    		p.Submitted_By__c = UserInfo.getUserId();
	    		/*if (p.Port__c == null) {
		            p.OwnerId = p.Location__r.OwnerId;
		        } else {
		            p.OwnerId = selPort.OwnerId;
		            p.Port__c = selPort.Id;
		        }*/
	    		prListToUpdate.add(p);
	    		for(Attachment att : caseAtts){
	    			Attachment at = new Attachment();
			        at.parentId = p.Id;
			        at.isPrivate = false;
			        at.body = att.Body;
			        at.name = att.Name;
			        attList.add(at);

	    		}
	    	}
    	}
    	system.debug('--prListToUpdate-------'+prListToUpdate);
    	if(!prListToUpdate.isEmpty()){
    		update prListToUpdate;
    	}
    	if(!attList.isEmpty()){
    		insert attList;
    		/*ContentVersion[] contList = new ContentVersion[]{};
    		for(Attachment att : attList){
    			contList.add(generateNewContentVersionVersion(null,att));
    		}
    		insert contList;
    		FeedItem[] FeedItemList = new FeedItem[]{};
    		for(ContentVersion con : contList){
    			FeedItemList.add(generatePostWithRelatedDocument(con,con.Title));
    		}
    		if(!FeedItemList.isEmpty()){
    			insert FeedItemList;
    		}*/
    	}
    	PageReference pr = new PageReference('/'+cs.Id);
    	return pr;
    }
    public pageReference submitPRWithpoutAtt(){
    	List<Port_Request__c> prListToUpdate = new List<Port_Request__c>();
    	for(Port_Request__c p : PortReqList){
    		if(p.Status__c != 'Answered'){
    			p.Status__c = 'Submitted';
	    		p.Submitted_By__c = UserInfo.getUserId();
	    		/*if (p.Port__c == null) {
		            p.OwnerId = p.Location__r.OwnerId;
		        } else {
		            p.OwnerId = selPort.OwnerId;
		            p.Port__c = selPort.Id;
		        }*/
	    		prListToUpdate.add(p);
    		}
    		
    	}
    	system.debug('--prListToUpdate-------'+prListToUpdate);
    	if(!prListToUpdate.isEmpty()){
    		update prListToUpdate;
    	}
    	PageReference pr = new PageReference('/'+cs.Id);
    	return pr;

    }
    public Port_Request__c[] PortReqList {
        get {
            if (PortReqList == null) {
                PortReqList = [select Id, Status__c, Description__c, Name, Port__c,Port__r.OwnerId,Location__r.OwnerId, OwnerId, Submitted_By__c, Location__c,
                                                 Case__r.Subject, Case__r.Description, Case__r.CaseNumber, Case__r.Status, Case__r.Vessel__c,
                                                 Submitted_By__r.Name, Submitted_By__r.Email, Submitted_By__r.Phone
                                            from Port_Request__c
                                           where Case__c = :cs.Id];
            }
            return PortReqList;
        }
        set;
    }
    public Attachment[] caseAtts {
        get {
            if (caseAtts == null) {
                caseAtts = [SELECT Id, ParentId, Description, Name, ContentType, BodyLength, Body 
                			FROM Attachment where ParentId = :cs.Id];
            }
            return caseAtts;
        }
        set;
    }

///////////////attachment

	/*public static ContentVersion generateNewContentVersionVersion(Id contentDocId, Attachment att) {
	    ContentVersion cont = new ContentVersion();

	    if (contentDocId != null) {
	        cont.ContentDocumentId = contentDocId;
	    }
	    cont.Title = att.Name+','+att.parentId;
	    cont.PathOnClient = att.Name;
	    cont.VersionData = att.Body;
	    //insert cont;

	    return cont;
	}

	public static FeedItem generatePostWithRelatedDocument(ContentVersion conVer,String conVerTitle) {
		String parent = conVerTitle.split(',')[1];
	    FeedItem elm = new FeedItem(Body = 'Post with related document body', ParentId = parent, RelatedRecordId = conVer.Id, Type = 'ContentPost');
	    //insert elm;
	    return elm;
	}*/
}