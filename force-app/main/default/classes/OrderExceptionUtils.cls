/**
 * Created by Andrej Tazky on 29-Nov-21.
 */

public without sharing class OrderExceptionUtils {

    public static final String OPERATOR_APPLIES_TO='Applies to';
    public static final String OPERATOR_DOES_NOT_APPLY_TO='Doesn’t apply to';
    public static final String OPERATOR_MORE_THAN='More Than';
    public static final String OPERATOR_LESS_THAN='Less Than';
    public static final String OPERATOR_EQUAL_TO='Equal To';


    @AuraEnabled(cacheable=true)
    public static InputDataWrapper getCaseDataWrapper(String caseId){

        Case myCase=[SELECT ID, Account.ID,Account.Name,Account.Country_of_Domicile__c,Account.Type,Account.Ultimate_parent__c,Account.Account_Number__c,Account.CS_Team__c,Account.Sales_Territory__c,
                (SELECT Account__c,Account__r.Name,Account__r.Account_Number__c,Account__r.Country_of_Domicile__c,
                        Account__r.Type,Account__r.Ultimate_parent__c,Port_Code__c,Vessel_IMO__c,Account__r.CS_Team__c,Account__r.Sales_Territory__c FROM Quotes__r),
                (SELECT AccountId,Account__r.Name,Account__r.Account_Number__c,Account__r.Country_of_Domicile__c,
                        Account__r.Type,Account__r.Ultimate_parent__c,Port_Code__c,Vessel_IMO__c,Order_Value__c,Account__r.CS_Team__c,Account__r.Sales_Territory__c FROM OrdersCase__r)
                    FROM Case WHERE ID=:caseId];

        //List<Account> accountsHierarchy=[SELECT ID,NAME,Account_Number__c FROM Account WHERE Ultiamte_parent__c=:myCase.Account.Ultiamte_parent__c];


        InputDataWrapper inputDataWrapper=new InputDataWrapper(myCase/*,accountsHierarchy*/);

        return InputDataWrapper;

    }

    public static Map<String,Set<String>> filterExceptions(InputDataWrapper inputDataWrapper){

        Map<String,Set<String>> exceptionAndAccounts=new Map<String,Set<String>>();
        Set<String> exceptionsToShow=new Set<String>();
        Set<String> accountsToShow=new Set<String>();

        //System.debug('inputDataWrapper.accountsById.keySet()'+inputDataWrapper.accountsById.keySet());

        List<OrderProcessExceptionCondition__c> opes=[SELECT ID,OrderProcessException__r.Id,Account__r.Id,OrderProcessException__r.Name,Account__r.Name,OrderProcessException__r.CustomerRole__c FROM OrderProcessExceptionCondition__c
        WHERE Status__c='Active' and OrderProcessException__r.Status__c IN :OPEDataValidation.OPE_STATUS_ACTIVE_LIST and Account__c IN: inputDataWrapper.accountsById.keySet()];

//        for(String accountId:inputDataWrapper.accountsById.keySet()) {
//            accountsToShow.add(accountId);
//        }

        for(OrderProcessExceptionCondition__c ope:opes){

//            if(inputDataWrapper.accountsById.get(ope.Account__r.Id).roles.isEmpty() "){
                exceptionsToShow.add(ope.OrderProcessException__r.Id);
                accountsToShow.add(ope.Account__r.Id);
//            }else if(inputDataWrapper.accountsById.get(ope.Account__r.Id).roles.contains(ope.OrderProcessException__r.CustomerRole__c))


            //System.debug('adding '+ope.OrderProcessException__r.Name+' '+ope.Account__r.Name);
        }

        List<OrderProcessException__c> exceptions=[SELECT ID,Name,CountryOfCustomerList__c,CountryOfCustomerLogic__c,CustomerSegmentLogic__c,CustomerSegmentList__c,
                CSTeam__c,CSTeamLogic__c,SalesTerritory__c,SalesTerritoryLogic__c
        FROM OrderProcessException__c WHERE Sub_Account_Ids__c = null and  Status__c IN :OPEDataValidation.OPE_STATUS_ACTIVE_LIST];

        for(String accountId:inputDataWrapper.accountsById.keySet()) {
            for (OrderProcessException__c exc : exceptions) {


                //System.debug(exc.id);

                Boolean isMatch = true;

                //System.debug('aaa'+exc.PortOfDelivery__c);
                //System.debug('aaa'+exc.PortOfDeliveryLogic__c);

                //System.debug('CountryOfCustomerList__c '+exc.Name+''+exc.CountryOfCustomerList__c+' '+exc.CountryOfCustomerLogic__c+' '+isMatch);
                if (exc.CountryOfCustomerList__c != null && exc.CountryOfCustomerLogic__c != null && isMatch == true) {
                    isMatch = evaluateSimpleCondition(exc.CountryOfCustomerLogic__c, inputDataWrapper.accountsById.get(accountId).country, exc.CountryOfCustomerList__c);

                }

                //System.debug('CustomerSegmentList__c '+exc.Name+''+exc.CustomerSegmentList__c+' '+exc.CustomerSegmentLogic__c+' '+isMatch);

                if (exc.CustomerSegmentList__c != null && exc.CustomerSegmentLogic__c != null && isMatch == true) {


                    isMatch = evaluateSimpleCondition(exc.CustomerSegmentLogic__c, inputDataWrapper.accountsById.get(accountId).segment, exc.CustomerSegmentList__c);

                }
                if (exc.CSTeam__c != null && exc.CSTeamLogic__c != null && isMatch == true) {

                    isMatch = evaluateSimpleCondition(exc.CSTeamLogic__c, inputDataWrapper.accountsById.get(accountId).CSTeam, exc.CSTeam__c);
               }
                if (exc.SalesTerritory__c != null && exc.SalesTerritoryLogic__c != null && isMatch == true) {

                    isMatch = evaluateSimpleCondition(exc.SalesTerritoryLogic__c, inputDataWrapper.accountsById.get(accountId).territory, exc.SalesTerritory__c);
                }


                if (isMatch) {
                    exceptionsToShow.add(exc.Id);
                    accountsToShow.add(accountId);
                    //System.debug('adding 2'+exc.Name+' '+ inputDataWrapper.accountsById.get(accountId).name);

                }
                isMatch = true;
            }
        }



//        for(String accountId:inputDataWrapper.accountsById.keySet()){
//
//            System.debug(inputDataWrapper.accountsById.get(accountId).roles);
//
//            List<OrderProcessExceptionCondition__c> accConditions=[SELECT ID,OrderProcessException__c
//                                                                    FROM OrderProcessExceptionCondition__c
//                                                                    WHERE Account__c =:accountId
//                                                                        and (Status__c='Active' or Status__c=null)
//                                                                        and OrderProcessException__r.CustomerRole__c in: inputDataWrapper.accountsById.get(accountId).roles];
//
//            Set<Id> exceptionsIds=new Set<Id>();
//            for(OrderProcessExceptionCondition__c orderProcessExceptionCondition:accConditions){
//                exceptionsIds.add(orderProcessExceptionCondition.OrderProcessException__c);
//            }
//
//
//            System.debug(exceptionsIds);
//
//            List<OrderProcessException__c> exceptions=[SELECT ID,Name,PortOfDeliveryLogic__c,VesselLogic__c,Vessel__c,PortOfDelivery__c,isMatch,CountryOfCustomerLogic__c,CustomerSegmentLogic__c,
//                    VesselFlag__c,VesselFlagLogic__c,VesselTypeLogic__c,OrderValue__c,OrderValueLogic__c,CountryOfDelivery__c,CountryOfDeliveryLogic__c,VesselTypeList__c,CustomerSegmentList__c,
//            (SELECT ID,Account__c, Port__c,Vessel__c FROM Conditions__r) FROM OrderProcessException__c WHERE ID IN :exceptionsIds];
//
//            for(OrderProcessException__c exc:exceptions){
//
//
//                //System.debug(exc.id);
//
//                Boolean isMatch=true;
//
//                //System.debug('aaa'+exc.PortOfDelivery__c);
//                //System.debug('aaa'+exc.PortOfDeliveryLogic__c);
//
//                if(exc.PortOfDelivery__c!=null && exc.PortOfDeliveryLogic__c!=null){
//
//                    //System.debug('bbb'+exc.PortOfDelivery__c);
//                    isMatch=evaluateJunctionCondition(exc.PortOfDeliveryLogic__c,inputDataWrapper.accountsById.get(accountId).portsIds,exc.Conditions__r,'Port__c');
//
//                }
//
//                if(exc.Vessel__c!=null && exc.VesselLogic__c!=null && isMatch==true){
//                    isMatch=evaluateJunctionCondition(exc.VesselLogic__c,inputDataWrapper.accountsById.get(accountId).vesselIds,exc.Conditions__r,'Vessel__c');
//
//                }
//                //System.debug('CountryOfCustomer__c '+exc.Name+''+exc.CountryOfCustomer__c+' '+exc.CountryOfCustomerLogic__c+' '+isMatch);
//                if(exc.CountryOfCustomer__c!=null && exc.CountryOfCustomerLogic__c!=null && isMatch==true){
//                    isMatch=evaluateSimpleCondition(exc.CountryOfCustomerLogic__c,inputDataWrapper.accountsById.get(accountId).country,exc.CountryOfCustomer__c);
//
//                }
//
//                //System.debug('CustomerSegmentList__c '+exc.Name+''+exc.CustomerSegmentList__c+' '+exc.CustomerSegmentLogic__c+' '+isMatch);
//
//                if(exc.CustomerSegmentList__c!=null && exc.CustomerSegmentLogic__c!=null && isMatch==true){
//
//
//
//                    isMatch=evaluateSimpleCondition(exc.CustomerSegmentLogic__c,inputDataWrapper.accountsById.get(accountId).segment,exc.CustomerSegmentList__c);
//
//                }
//
//                if(exc.VesselTypeList__c!=null && exc.VesselTypeLogic__c!=null && isMatch==true){
//                    isMatch =evaluateListCondition(exc.VesselTypeLogic__c, inputDataWrapper.accountsById.get(accountId).vesselTypes,exc.VesselTypeList__c);
//
//                }
//
//                if(exc.VesselFlag__c!=null && exc.VesselFlagLogic__c!=null && isMatch==true){
//                    isMatch =evaluateListCondition(exc.VesselFlagLogic__c, inputDataWrapper.accountsById.get(accountId).vesselFlags,exc.VesselFlag__c);
//
//                }
//
//                if(exc.CountryOfDelivery__c!=null&& exc.CountryOfDeliveryLogic__c!=null && isMatch==true){
//                    isMatch =evaluateListCondition(exc.CountryOfDeliveryLogic__c, inputDataWrapper.accountsById.get(accountId).portsCountries,exc.CountryOfDelivery__c);
//
//                }
//
//                if(exc.OrderValue__c!=null && exc.OrderValueLogic__c!=null && isMatch==true){
//                    isMatch=false;
//                    if(exc.OrderValueLogic__c==OPERATOR_MORE_THAN){
//
//                        for(Decimal orderValue: inputDataWrapper.accountsById.get(accountId).orderValues){
//
//                            if(orderValue>exc.OrderValue__c){
//                                System.debug(orderValue+'>'+exc.OrderValue__c);
//                                isMatch=true;
//                                break;
//                            }
//                        }
//
//
//                    }else if(exc.OrderValueLogic__c==OPERATOR_LESS_THAN){
//
//                        for(Decimal orderValue: inputDataWrapper.accountsById.get(accountId).orderValues){
//                            if(orderValue<exc.OrderValue__c){
//                                isMatch=true;
//                                break;
//                            }
//                        }
//
//
//                    }else if(exc.OrderValueLogic__c==OPERATOR_EQUAL_TO){
//
//                        for(Decimal orderValue: inputDataWrapper.accountsById.get(accountId).orderValues){
//                            if(orderValue==exc.OrderValue__c){
//                                isMatch=true;
//                                break;
//                            }
//                        }
//                    }
//                }
//
//                if(isMatch){
//                    exceptionsToShow.add(exc.Id);
//                }
//                isMatch=true;
//            }
//        }

        exceptionAndAccounts.put('exc',exceptionsToShow);
        exceptionAndAccounts.put('acc',accountsToShow);

        return exceptionAndAccounts;
    }

//    private static Boolean evaluateJunctionCondition(String operator,Set<String> idsFromCase, List<OrderProcessExceptionCondition__c> junctions,String field){
//
//            Boolean isMatch;
//
//            if(operator==OPERATOR_APPLIES_TO){
//                for(OrderProcessExceptionCondition__c junction:junctions){
//
//                    if(idsFromCase.contains(junction.get(field)!=null?junction.get(field).toString():null)){
//                        isMatch=true;
//                        break;
//                    }else{
//                        isMatch=false;
//                    }
//                }
//
//            }else if(operator==OPERATOR_DOES_NOT_APPLY_TO){
//                for(OrderProcessExceptionCondition__c junction:junctions){
//
//                    if(idsFromCase.contains(junction.get(field)!=null?junction.get(field).toString():null)){
//                        isMatch=false;
//                        break;
//                    }else{
//                        isMatch=true;
//                    }
//                }
//            }
//
//        return isMatch;
//    }
//
//    private static Boolean evaluateListCondition(String operator,Set<String> valuesFromCase, String valueFromException){
//
//        Boolean isMatch;
//
//        valuesFromCase.remove(null);
//        if(operator==OPERATOR_APPLIES_TO){
//            for(String singleValueFromException : valueFromException.split(';') ){
//                if(valuesFromCase.contains(singleValueFromException)){
//                    isMatch=true;
//                    break;
//                }else{
//                    isMatch=false;
//                }
//            }
//
//        }else if(operator==OPERATOR_DOES_NOT_APPLY_TO){
//            for(String singleValueFromException : valueFromException.split(';') ) {
//                if (valuesFromCase.contains(singleValueFromException)) {
//                    isMatch = false;
//                    break;
//                } else {
//                    isMatch = true;
//
//                }
//            }
//        }
//
//        return isMatch;
//    }

    private static Boolean evaluateSimpleCondition(String operator,String valueFromCase, String valueFromException){

        Boolean isMatch;

        if(operator==OPERATOR_APPLIES_TO){
            if(valueFromException.split(';').contains(valueFromCase)){
                isMatch=true;
            }else{
                isMatch=false;
            }
        }else if(operator==OPERATOR_DOES_NOT_APPLY_TO){
            if(!valueFromException.split(';').contains(valueFromCase)){
                isMatch=true;
            }else{
                isMatch=false;
            }
        }

        return isMatch;
    }

    public class InputDataWrapper{

        public Set<String> exceptionsIds=new Set<String>();

        public Map<String,AccountDataWrapper>  accountsById=new Map<String,AccountDataWrapper>();
        public List<AccountDataWrapper>  accounts=new List<AccountDataWrapper>();

        public Set<String> ultimateParents=new Set<String>();

        InputDataWrapper(Case inputCase/*,List<Account> accountsHierarchy*/){

            this.accountsById.put(inputCase.Account.Id, new AccountDataWrapper(inputCase.Account.Id,inputCase.Account.Name,inputCase.Account.Account_Number__c,
                    'requester','case',inputCase.Account.Country_of_Domicile__c,inputCase.Account.Type,
                    inputCase.Account.CS_Team__c,inputCase.Account.Sales_Territory__c));
            accountsById.get(inputCase.Account.Id).isRequester=true;
            ultimateParents.add(inputCase.Account.Ultimate_parent__c);

            Set<String> codes = new Set<String>();
            Set<String> IMOs = new Set<String>();

            for(Quote__c quote: inputCase.Quotes__r){

                if (accountsById.containsKey(quote.Account__c)){
                    accountsById.get(quote.Account__c).portsCodes.add(quote.Port_Code__c);
                    accountsById.get(quote.Account__c).vesselCodes.add(quote.Vessel_IMO__c);
                    accountsById.get(quote.Account__c).objs.add('quote');
                }else{
                    this.accountsById.put(quote.Account__c, new AccountDataWrapper(quote.Account__c, quote.Account__r.Name,quote.Account__r.Account_Number__c,
                            'payer','quote',quote.Account__r.Country_of_Domicile__c,quote.Account__r.Type,
                            quote.Account__r.CS_Team__c,quote.Account__r.Sales_Territory__c));
                    accountsById.get(quote.Account__c).isPayer=true;
                    ultimateParents.add(quote.Account__r.Ultimate_parent__c);
                    accountsById.get(quote.Account__c).portsCodes.add(quote.Port_Code__c);
                    accountsById.get(quote.Account__c).vesselCodes.add(quote.Vessel_IMO__c);

                }


                codes.add(quote.Port_Code__c);
                IMOs.add(quote.Vessel_IMO__c);
            }
            for(Order order: inputCase.OrdersCase__r){

                System.debug('order acc'+order.AccountId);

                if (accountsById.containsKey(order.AccountId)){
                    accountsById.get(order.AccountId).portsCodes.add(order.Port_Code__c);
                    accountsById.get(order.AccountId).vesselCodes.add(order.Vessel_IMO__c);
                    accountsById.get(order.AccountId).orderValues.add(order.Order_Value__c);
                    accountsById.get(order.AccountId).objs.add('order');
                }else{
                    this.accountsById.put(order.AccountId, new AccountDataWrapper(order.AccountId,order.Account__r.Name,order.Account__r.Account_Number__c,
                            'payer','order',order.Account__r.Country_of_Domicile__c,order.Account__r.Type,
                            order.Account__r.CS_Team__c,order.Account__r.Sales_Territory__c));
                    accountsById.get(order.AccountId).isPayer=true;
                    ultimateParents.add(order.Account__r.Ultimate_parent__c);
                    accountsById.get(order.AccountId).portsCodes.add(order.Port_Code__c);
                    accountsById.get(order.AccountId).vesselCodes.add(order.Vessel_IMO__c);
                    accountsById.get(order.AccountId).orderValues.add(order.Order_Value__c);

                }

                codes.add(order.Port_Code__c);
                IMOs.add(order.Vessel_IMO__c);
            }

            //System.debug('codes'+codes);

            List<Port__c> ports =[SELECT ID,Port_Code__c,Country_Code_ISO_formula__c FROM Port__c WHERE Port_Code__c IN :codes];
            List<Vessel__c> vessels =[SELECT ID,IMO_Number__c,Ship_Type__c,Flag_MDM__c FROM Vessel__c WHERE IMO_Number__c IN :IMOs];

            for(String key:accountsById.keySet()){
                for(Port__c port:ports){
                    if(accountsById.get(key).portsCodes.contains(port.Port_Code__c)){
                        accountsById.get(key).portsIds.add(port.Id);
                        accountsById.get(key).portsCountries.add(port.Country_Code_ISO_formula__c);
                    }
                }
                for(Vessel__c vessel:vessels){
                    if(accountsById.get(key).vesselCodes.contains(vessel.IMO_Number__c)){
                        accountsById.get(key).vesselIds.add(vessel.Id);
                        accountsById.get(key).vesselFlags.add(vessel.Flag_MDM__c);
                        accountsById.get(key).vesselTypes.add(vessel.Ship_Type__c);
                    }
                }
            }

            if (accountsById.size()==1){
                accountsById.get(inputCase.Account.Id).roles.add('payer');
                accountsById.get(inputCase.Account.Id).isPayer=true;
            }

            Id subId=SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Sub_Account').getRecordTypeId();

            List<Account> accountsHierarchy=[SELECT Id,Name,Account_Number__c,Country_of_Domicile__c,Type,CS_Team__c,Sales_Territory__c FROM Account
            WHERE Ultimate_parent__c IN: ultimateParents and RecordTypeId=:subId ORDER BY Name];


            for(Account acc: accountsHierarchy){
                if (!accountsById.containsKey(acc.Id)){
                    System.debug('adding acc '+acc.Name);
                    this.accountsById.put(acc.Id, new AccountDataWrapper(acc.Id,acc.Name,acc.Account_Number__c,acc.Type,acc.Country_of_Domicile__c,acc.CS_Team__c,acc.Sales_Territory__c));

                }
            }

        }
    }

    public class AccountDataWrapper{

        String id;
        String name;
        String accNumber;
        String country;
        String segment;
        String CSTeam;
        String territory;

        Boolean isRequester=false;
        Boolean isPayer=false;

        public Set<String> portsIds=new Set<String>();
        public Set<String> portsCodes=new Set<String>();
        public Set<String> portsCountries=new Set<String>();

        public Set<String> vesselIds=new Set<String>();
        public Set<String> vesselCodes=new Set<String>();
        public Set<String> vesselFlags=new Set<String>();
        public Set<String> vesselTypes=new Set<String>();

        public Set<String> productIds=new Set<String>();
        public Set<String> productCodes=new Set<String>();

        public Set<Decimal> orderValues=new Set<Decimal>();


        public Set<String> roles=new Set<String>();
        public Set<String> objs=new Set<String>();

        AccountDataWrapper(String id,String name,String accNumber,String role,String obj,String country,String segment,
                String CSTeam,String territory){
            this.id=id;
            this.name=name;
            this.country=country;
            this.segment=segment;
            this.roles.add(role);
            this.objs.add(obj);
            this.accNumber=accNumber;
            this.CSTeam=CSTeam;
            this.territory=territory;

        }

        AccountDataWrapper(String id,String name,String accNumber,String country,String segment,String CSTeam,String territory){
            this.id=id;
            this.name=name;
            this.accNumber=accNumber;
            this.country=country;
            this.segment=segment;
            this.CSTeam=CSTeam;
            this.territory=territory;
        }
    }


}