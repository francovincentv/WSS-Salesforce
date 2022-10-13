public with sharing class GenerateCaseResponsePDFExt {

    private static Id prId;
    private static Port_Request__c prRec;
    public GenerateCaseResponsePDFExt(ApexPages.StandardController stdController) {

        prId = stdController.getId();
        prRec = (Port_Request__c)stdController.getRecord();
    }

    public Port_Request__c selPortReq {
        get {
            if (selPortReq == null) {
                Port_Request__c[] reqs = [select Id, Status__c, Description__c, Name, Port__c, OwnerId, Submitted_By__c, Location__c,
                                                 Case__r.Subject, Case__r.Description, Case__r.CaseNumber, Case__r.Status,
                                                 Submitted_By__r.Name, Submitted_By__r.Email, Submitted_By__r.Phone
                                            from Port_Request__c
                                           where Id = :prId];
                if (reqs.size() > 0) {
                    selPortReq = reqs[0];
                }
            }
            return selPortReq;
        }
        set;
    }
    public Port__c selPort {
        get {
            //selPort.recordTypeId = portRecTypes.get('PIT');
            if (this.selPortReq.Port__c != null) {
                selPort = [select Name, OwnerId, Latitude_Longitude__c, Country_Code__c, Crew_Change__c,
                                  Customs_Immigration__c, Daylight_Restriction__c, Documents_Required__c, General_Overview__c,
                                  Location__c,Phone__c,Name__c,Email__c, Location_Description__c, Medical_Facilities__c, Officials_Visitors__c,
                                  Pilot_Escort__c, Port_Administration_WH_holidays__c, Port_Administration_WH_weekdays__c,
                                  Port_Administration_WH_weekends__c, Port_Code__c, Port_Name_local__c, Pre_Arrival_Notification__c,
                                  Repairs__c, Salinity__c, Sludge__c, Tidal_Restriction__c, Time_Zone__c, Traffic_Figures__c, 
                                  Transport_Inland__c, Tugs_availble__c, Tugs_required__c,Responsible_WSS_Site__c, Salinity_range__c, Other_names__c, Local_Currency__c,Official_Website__c, State__c,Public_Holidays__c
                             from port__c
                            where Id = :this.selPortReq.Port__c];
            }
            System.debug('selPort='+selPort);
            return selPort;
        }
        set;
    }
    public Channel__c[] channels {
        get {
            if (channels == null && selPort != null) {
                channels = [select Id, Daylight_Restriction__c, Max_LOA__c, Channel_UKC__c, Channel_Width__c, 
                            Channel_Depth__c, Name,Max_Airdraft_Hatch__c,Max_Airdraft_Mast__c,Max_Beam__c,Max_DWT_Displacement__c,
                            Max_Sailing_Draft__c,Min_UKC__c, LastModifiedDate
                            from Channel__c
                            where port__c = :selPort.Id];
            }
            return channels;
        }
        set;
    }
    public Terminal__c[] terminals {
        get {
            if (terminals == null && selPort != null) {
                terminals = [select Id, Name, Terminal_Type__c,Terminal_Name_local__c, Storage_type__c, Number_of_Berths__c, 
                                    Working_hours_weekdays__c, Operator_Manager_Name__c,
                                    Working_hours_weekends__c, Working_hours_holidays__c, Gang_Size__c, Security__c, LastModifiedDate
                               from Terminal__c
                              where port__c = :selPort.Id];
            }
            return terminals;
        }
        set;
    }
    public Map<Id, Berth_Alternative__c> selBerth2Alternative {
        get {
            if (selBerth2Alternative == null) {
                selBerth2Alternative = new Map<Id, Berth_Alternative__c>();
                for (Berth_Alternative__c bal:balts) {
                    if (bal.Status__c == 'Suggested') {
                        selBerth2Alternative.put(bal.Berth__c, bal);
                    }
                }
            }
            return selBerth2Alternative;
        }
        set;
    }
    public Berth_Alternative__c[] balts {
        get {
            if (balts == null) {
                balts = [select Name, Berth__c, Description__c, Status__c,Berth__r.Berth_No__c,
                            Berth__r.Name,Berth__r.Cargo_Handling__c 
                           from Berth_Alternative__c
                          where Port_Request__c = :selPortReq.ID and Status__c =: 'Suggested'];
            }
            return balts;
        }
        set;
    }
    public List<Cargo_Type__c> cargoTypes{

      get{
        List<Id> berthId = new List<Id>();
        if(berths.size() > 0){
            for(Berth__c b : berths){
                berthId.add(b.id);
            } 
        }
        cargoTypes = [SELECT Id, OwnerId, Name, Berth__c,Berth__r.Name,Berth__r.Berth_No__c, 
                      Cargo_Type__c, Cargo_Handling__c, Description__c, Cargo_Group__c FROM Cargo_Type__c where Berth__c IN : berthId]; 
        return cargoTypes;
      }
      set;
    }
    public Berth__c[] berths {
        get{
          berths = [select Name, Berth_Length__c, Port__c, Selected__c, Berth_Length_Depth__c,Max_Sailing_Draft__c,
                      Berth_No__c, Berth_Type__c, Description__c, LastModifiedDate,Cargo_Handling__c, Min_UKC_mtr__c,
                      Max_LOA__c,Max_Beam__c,Max_DWT_Displacement__c,Max_Airdraft_Hatch__c,Max_Airdraft_Mast__c,
                      (SELECT Id, OwnerId, Name, Berth__c, Cargo_Type__c, Cargo_Handling__c, Description__c, Cargo_Group__c FROM Cargo_Types__r)  
                      from Berth__c 
                      where Id in :selBerth2Alternative.keyset()];

          return berths;
        }
        set;
    }
    public Map<Id,String> berthCGMap{

      get{
          
          berthCGMap = new Map<Id,String>();
          Set<String> CGSet ;
          for(Berth__c b : berths){
            CGSet = new Set<String>();
            String CargoGroups = '';
            for(Cargo_Type__c ct : b.Cargo_Types__r){
                CGSet.add(ct.Cargo_Group__c);
            }

            for(String s : CGSet){
              CargoGroups += s+' , ';
            }
            
            CargoGroups = CargoGroups.removeEnd(' , ');

            berthCGMap.put(b.id,CargoGroups);
          }
                      
        return berthCGMap;
      }
      set;
    }

    public Map<Id,String> berthCTMap{

      get{
          
          berthCTMap = new Map<Id,String>();
          Set<String> CTSet;
          for(Berth__c b : berths){
            CTSet = new Set<String>();
            String CTList = '';
            for(Cargo_Type__c ct : b.Cargo_Types__r){

                //CTList += ct.Cargo_Type__c+' , ';
                
                CTSet.add(ct.Cargo_Type__c);
            }
            
            for(String s : CTSet){
              CTList += s+' , ';
            }
            
            CTList = CTList.removeEnd(' , ');
            system.debug('---CTList--'+CTList);
            berthCTMap.put(b.id,CTList);
          }
    
        return berthCTMap;
      }
      set;
    }

    public void generateAtt(){
        system.debug('---in generate pdf--');
        PageReference p = new PageReference('/apex/GenerateCaseResponsePDF?Id='+prId);

        Blob pdf;

        if (Test.IsRunningTest()) {
            pdf=Blob.valueOf('UNIT.TEST');
        } else {
            pdf = p.getContent();
        }

        Attachment att = new Attachment();
        att.parentId = prId;
        att.isPrivate = false;
        att.body = pdf;
        att.name = selPortReq.Name+'.pdf';
        insert att;
        //String baseUrl = String.valueOf(system.URL.getSalesforceBaseUrl());
        String PRUrl = URL.getSalesforceBaseUrl().toExternalForm() +'/servlet/servlet.FileDownload?file=' + att.id;
        system.debug('-------PRUrl---'+PRUrl);
        prRec.Response_PDF__c = PRUrl;
        update prRec;
    }
    /*public void MailPdf(Port_Request__c PDRRecord){

        if(PDRRecord.Case__r.Respond_to__c != null){

            Blob b;
            PageReference p = new PageReference('/apex/GenerateCaseResponsePDF?Id='+prId);

            if (Test.IsRunningTest()) {
                b = Blob.valueOf('UNIT.TEST');
            } else {
                b = p.getContent();
            }
            String AdditionalEmails = PDRRecord.Case__r.Additional_Emails__c;
            String[] emailList = AdditionalEmails.split(',');
            EmailTemplate template = [select Id, Subject, Body from EmailTemplate where DeveloperName =: 'Email_Port_Detail_Request'];
            String myBody = template.Body;
            //Id MailFromId = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Strex Faktura' LIMIT 1].Id;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] to = new List<String>();
            to.add(PDRRecord.Case__r.Respond_to__c);
            to.addall(emailList);
            mail.setToAddresses(to);
            mail.setSubject(template.Subject);
            mail.setPlainTextBody(myBody);
            mail.setWhatId(prId);

            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(PDRRecord.Name+'.pdf');
            efa.setBody(b);

            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { efa });
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 

        }
    }*/

}