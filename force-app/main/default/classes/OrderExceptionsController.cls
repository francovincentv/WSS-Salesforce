/**
 * Created by Andrej Tazky on 06-Dec-21.
 */

public without sharing class OrderExceptionsController {

    public Integer numberOfRecords {get;set;}
    public Integer numberOfSkippedRecords {get;set;}
    public Boolean showValidation {get;set;}
    public Boolean showConfirmation {get;set;}
    public Boolean showToast {get;set;}

    public String validationMessage {get;set;}
    public String confirmationMessage {get;set;}

    @AuraEnabled(cacheable=true)
    public static String getExceptionsDataWrapperForCase(String caseId){

        OrderExceptionUtils.InputDataWrapper inputDataWrapper=OrderExceptionUtils.getCaseDataWrapper(caseId);

        Map<String,Set<String>> exceptionsAndAccounts=OrderExceptionUtils.filterExceptions(inputDataWrapper);
		System.debug('exceptionsAndAccounts '+exceptionsAndAccounts);
        inputDataWrapper.exceptionsIds=exceptionsAndAccounts.get('exc');

        for(String key :inputDataWrapper.accountsById.keySet()){
            if(exceptionsAndAccounts.get('acc').contains(key)){
                inputDataWrapper.accounts.add(inputDataWrapper.accountsById.get(key));
            }

        }

        //inputDataWrapper.accounts=inputDataWrapper.accountsById.values();

        inputDataWrapper.accountsById=null;
		System.debug('inputDataWrapper '+inputDataWrapper);
        return JSON.serialize(inputDataWrapper);
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderProcessException__c> loadExceptions(String exceptionsIds) {
        List<String> ids = (List<String>) JSON.deserialize(exceptionsIds, List<String>.class);

        return [
                SELECT Id, Name,Details__c, CustomerRole__c, Exception__r.Title__c,Exception__r.Code__c,
                        PortOfDelivery__c,PortOfDeliveryLogic__c,
                        Vessel__c,VesselLogic__c,
                        Product__c,ProductLogic__c,
                        CountryOfCustomerList__c,CountryOfCustomerLogic__c,
                        CustomerSegmentLogic__c,CustomerSegmentList__c,
                        VesselTypeLogic__c,VesselTypeList__c,
                        VesselFlagList__c,VesselFlagLogic__c,
                        CountryOfDeliveryList__c,CountryOfDeliveryLogic__c,
                        OrderValue__c,OrderValueLogic__c,
                        SalesTerritoryLogic__c,SalesTerritory__c,
                        CSTeamLogic__c,CSTeam__c
                FROM OrderProcessException__c
                WHERE ID in:ids

        ];
    }

    private ApexPages.StandardSetController standardController;

    public OrderExceptionsController(ApexPages.StandardSetController standardController)  {

        this.standardController = standardController;
        if(!this.isReviewer()) {
            this.showValidation = true;
            this.showConfirmation = false;
        }else
                if(this.standardController.getSelected().size()<1){
            this.validationMessage='Please select at least one record.';
            this.showValidation = true;
            this.showConfirmation = false;
        }else{
            this.createConfirmationMessage();
            //this.confirmationMessage='aaaaaa';
            this.showValidation=false;
            this.showConfirmation=true;
        }
        this.showToast=false;
    }

    public Boolean isReviewer(){

         if(System.FeatureManagement.checkPermission('Editing_review_date_of_an_exception')){
           return true;
         }else{

             String noPermissonOpes='';

             Set<Id> ids=new Set<Id>();
             for(SObject obj:this.standardController.getSelected()){
                 ids.add(obj.Id);
             }

             List<OrderProcessException__c> selectedOPES = [SELECT ID,ReviewDate__c,Status__c,Name,Reviewer__c FROM OrderProcessException__c WHERE ID IN: ids];
             for(OrderProcessException__c ope:selectedOPES){
                 if(ope.Reviewer__c!=UserInfo.getUserId()){
                     noPermissonOpes=noPermissonOpes+' '+ope.Name;
                 }

             }

             if(noPermissonOpes!=''){
                 this.validationMessage='Action is not allowed for: '+noPermissonOpes;
                 return false;
             }else{
                 return true;
             }

         }


//        List<Group> groups=[Select Id from Group where Type='Queue' and Name='OPE Reviewer'];
//        //List<GroupMember> groupMembers=[Select UserOrGroupId From GroupMember where GroupId =:groups[0].Id and UserOrGroupId=: UserInfo.getUserId()];
//        List<GroupMember> groupMembers=[Select UserOrGroupId From GroupMember where GroupId =:groups[0].Id and UserOrGroupId=: '005D0000006VJsJIAW'];
//
//        if(groupMembers.size()>0){
//            return true;
//        }else{
//            this.validationMessage='Action is allowed only for OPE reviewers.';
//            return false;
//        }

    }

    public void createConfirmationMessage(){

        this.confirmationMessage = '';
        String recordsHeader ='You are about to extend the Review Date of the following OPEs for 1 year :\n';
        String skippedHeader='The following OPEs are not Active so they will be skipped:\n';
        this.numberOfSkippedRecords=0;
        this.numberOfRecords=0;

        Set<Id> ids=new Set<Id>();
        for(SObject obj:this.standardController.getSelected()){
            ids.add(obj.Id);
        }
        String[] recordsInfo = new List<String>();
        String[] skippedInfo = new List<String>();
        
        List<OrderProcessException__c> selectedOPES = [SELECT ID,ReviewDate__c,Status__c,Name, ExceptionTypeTitle__c, Exception__r.Code__c, ExceptionReason__c  FROM OrderProcessException__c WHERE ID IN: ids];
        for(OrderProcessException__c ope:selectedOPES){
            String[] info = new List<String>();
            info.add(ope.Exception__r.Code__c);
            info.add(ope.ExceptionTypeTitle__c);
            info.add(ope.ExceptionReason__c);
            info.add(ope.Status__c);
            if(ope.Status__c=='Active' || ope.Status__c=='Under review'){
                this.numberOfRecords++;
                info.add('Review Date: '+ope.ReviewDate__c.format()+' → ' + ope.ReviewDate__c.addYears(1).format());
                recordsInfo.add(String.join(info,' • '));
            }else{
                this.numberOfSkippedRecords++;
                skippedInfo.add(String.join(info,' • '));
            }
        }
        if(numberOfRecords > 0)
            this.confirmationMessage=recordsHeader+'\n'+String.join(recordsInfo,'\n');
        if(numberOfSkippedRecords>0){
            this.confirmationMessage+=skippedHeader+'\n'+String.join(skippedInfo,'\n');
        }
    }


    public PageReference extendReviewDate()
    {
        // Get the selected records (optional, you can use getSelected to obtain ID's and do your own SOQL)

        Set<Id> ids=new Set<Id>();
        for(SObject obj:standardController.getSelected()){
            ids.add(obj.Id);
        }

        List<OrderProcessException__c> selectedOPES = [SELECT ID,ReviewDate__c,Status__c FROM OrderProcessException__c WHERE ID IN: ids];

        for(OrderProcessException__c ope:selectedOPES){
            if(ope.ReviewDate__c!=null && (ope.Status__c=='Active' || ope.Status__c=='Under review')){
                ope.ReviewDate__c=ope.ReviewDate__c.addYears(1);
            }

        }

        try{
            update selectedOPES;
            PageReference cancel = standardController.cancel();
            return cancel;
        }catch(Exception ex){
            System.debug('***** '+ex.getMessage());
            //ApexPages.addMessages(ex.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,ex.getMessage()));
        }



//        this.showToast=true;

//        System.debug( ApexPages.currentPage().getParameters().get('retURL'));
//        System.debug(ApexPages.currentPage().getHeaders().get('Referer'));
//        PageReference newRequestURL = new PageReference( ApexPages.currentPage().getHeaders().get('Referer'));
//        newRequestURL.setRedirect(true);
//        return newRequestURL;


        //standardController.save();
        //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Records Updated Successfully'));

       return null;

        //return  ApexPages.currentPage();
    }

    public PageReference closePopup() {
        PageReference cancel = standardController.cancel();
        //standardController.save();
        return cancel;
    }


}