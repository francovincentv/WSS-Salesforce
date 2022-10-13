public with sharing class QuoteLineTriggerHelper {

    public static void setQuoteLineGroupForTopLevelQL(List<SBQQ__QuoteLine__c> newList) {

        System.debug('Quoteline Trigger-->setQuoteLineGroupForTopLevelQL()');

        try {
                              
            Set<Id> quoteIds = new Set<Id> ();
            Set<Id> qlProductIds = new Set<Id>();
            List<SBQQ__QuoteLine__c> qlWithNewGroup = new List<SBQQ__QuoteLine__c>();   //list to hold the quote lines which needs a new quote line group
            List<SBQQ__QuoteLine__c> qlUpdateList = new List<SBQQ__QuoteLine__c>();     //list to hold the new quote line that has any changes after insert
            List<SBQQ__QuoteLine__c> quoteLineToProcess = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLineGroup__c> newQuoteLineGroups = new List<SBQQ__QuoteLineGroup__c> ();    //list to hold the SBQQ__QuoteLineGroup__c that needs to be create
            Map<Id, Set<String>> quoteIdWithNewGroups = new Map<Id, Set<String>> ();    //quote id => related group names
            Map<Id, List<SBQQ__QuoteLineGroup__c>> quoteIdWithRelatedGroups =  new  Map<Id, List<SBQQ__QuoteLineGroup__c>>();
            Map<Id, List<SBQQ__QuoteLine__c>> parentQlIdWithChildQl = new Map<Id, List<SBQQ__QuoteLine__c>>();
            

            //filter the quotelines that dont have product option(mean top level ql)
            for (SBQQ__QuoteLine__c ql: newList) {
                //if ql is the paren
                if(ql.SBQQ__RequiredBy__c == null) {
                    quoteLineToProcess.add(ql);
                    quoteIds.add(ql.SBQQ__Quote__c);
                    qlProductIds.add(ql.SBQQ__Product__c);
                } else {
                    List<SBQQ__QuoteLine__c> childQls = parentQlIdWithChildQl.get(ql.SBQQ__RequiredBy__c);
                    if(childQls == null) {
                        childQls = new List<SBQQ__QuoteLine__c>();
                    }
                    childQls.add(ql);
                    parentQlIdWithChildQl.put(ql.SBQQ__RequiredBy__c, childQls);
                }
            }

            //assign parent ql groups to child ql 
            if(parentQlIdWithChildQl.size()>0) {
                for(SBQQ__QuoteLine__c parentQl : [SELECT Id, SBQQ__Group__c FROM SBQQ__QuoteLine__c WHERE Id =:parentQlIdWithChildQl.keyset()]){
                    for(SBQQ__QuoteLine__c childQl : parentQlIdWithChildQl.get(parentQl.Id)){
                        childQl.SBQQ__Group__c = parentQl.SBQQ__Group__c;
                    }
                }
            }

            //query the Product_Discount_Group__c for each product, to assing existing group or create new group based on this field
            Map<Id,Product2> qlProductsMap = new Map<Id, Product2>([SELECT Id,Name, Product_Discount_Group__c FROM Product2 WHERE Id IN:qlProductIds]);

            queryQuoteLineGroups(quoteIdWithRelatedGroups, quoteIds);

            for(SBQQ__QuoteLine__c ql : quoteLineToProcess) {
                Boolean needToCreateGroup = true;
                //get the Product_Discount_Group__c from the quote line related product
                String groupName = qlProductsMap.get(ql.SBQQ__Product__c).Product_Discount_Group__c;
                //if Product_Discount_Group__c is not defined on product then assing the default group
                if(groupName == null){
                    groupName = System.Label.Default_Quote_Line_Group;
                }
                system.debug('group : '+groupName + ' product name'+ qlProductsMap.get(ql.SBQQ__Product__c).Name);

                if(quoteIdWithRelatedGroups.get(ql.SBQQ__Quote__c) != null) {
                    for (SBQQ__QuoteLineGroup__c qlGroup: quoteIdWithRelatedGroups.get(ql.SBQQ__Quote__c)) {
                        if(qlGroup.Name == groupName) {
                            ql.SBQQ__Group__c = qlGroup.Id;
                            needToCreateGroup = false;
                        }
                    }
                }
                
                if(needToCreateGroup == true) {
                    qlWithNewGroup.add(ql);
                    if (quoteIdWithNewGroups.get(ql.SBQQ__Quote__c) == null) {
                        quoteIdWithNewGroups.put(ql.SBQQ__Quote__c, new Set<String> ());
                    }
                    quoteIdWithNewGroups.get(ql.SBQQ__Quote__c).add(groupName);
                }
            }


            if (quoteIdWithNewGroups.size()> 0) {
                //get the account from quote to assign it to the newly created group
                Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>([SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c WHERE Id IN: quoteIds]);
                //generate the new groups that needs to be create
                for (Id quoteId: quoteIdWithNewGroups.keySet()) {
                    for (String newGroupName: quoteIdWithNewGroups.get(quoteId)) {
                        SBQQ__QuoteLineGroup__c quoteLineGroup = new SBQQ__QuoteLineGroup__c();
                        quoteLineGroup.Name = newGroupName;
                        quoteLineGroup.SBQQ__Account__c = quoteMap.get(quoteId).SBQQ__Account__c;
                        quoteLineGroup.SBQQ__Quote__c = quoteId;
                        newQuoteLineGroups.add(quoteLineGroup);
                    }
                }
            }

            //create new groups and assign it to related quote lines
            if (newQuoteLineGroups.size()> 0) {
                //System.debug('Creating New Quote Line Groups : ' + newQuoteLineGroups);
                insert newQuoteLineGroups;

                //add the latest quote line groups to the map
                for (SBQQ__QuoteLineGroup__c qlGroup : newQuoteLineGroups){
                    //System.debug('New qlGroup>>'+ qlGroup);
                    if (quoteIdWithRelatedGroups.get(qlGroup.SBQQ__Quote__c) == null) {
                        quoteIdWithRelatedGroups.put(qlGroup.SBQQ__Quote__c, new List < SBQQ__QuoteLineGroup__c> ());
                    }
                    quoteIdWithRelatedGroups.get(qlGroup.SBQQ__Quote__c).add(qlGroup);
                }

                //iterat the quote lines which don't have group
                for (SBQQ__QuoteLine__c ql: qlWithNewGroup) {
                   String qlProductGroupName = qlProductsMap.get(ql.SBQQ__Product__c).Product_Discount_Group__c;
                    //if qlProductGroupName is null then assign the default group name
                    qlProductGroupName = (qlProductGroupName != null ? qlProductGroupName : System.Label.Default_Quote_Line_Group);
                    for(SBQQ__QuoteLineGroup__c qlGroup: quoteIdWithRelatedGroups.get(ql.SBQQ__Quote__c)) {
                        //if any existing group is found, then assing the group Id
                        if (qlProductGroupName == qlGroup.Name) {
                            System.debug('assing group '+ qlGroup.Name + ' ql>> ' +ql);
                            ql.SBQQ__Group__c = qlGroup.Id;
                        }
                    }
                }
            }

        } catch(Exception e) {
            System.debug('Error : ' + e.getMessage());
        }
    }

    public static void queryQuoteLineGroups(Map<Id, List<SBQQ__QuoteLineGroup__c>> quoteIdWithRelatedGroups, Set <Id> quoteIds) {
        //query the existing SBQQ__QuoteLineGroup__c for quote that was edited
        for (SBQQ__QuoteLineGroup__c qlGroup : [SELECT Id, Name, SBQQ__Quote__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c IN: quoteIds]) {
            if (quoteIdWithRelatedGroups.get(qlGroup.SBQQ__Quote__c) == null) {
                quoteIdWithRelatedGroups.put(qlGroup.SBQQ__Quote__c, new List < SBQQ__QuoteLineGroup__c> ());
            }
            quoteIdWithRelatedGroups.get(qlGroup.SBQQ__Quote__c).add(qlGroup);
        }
    }

    
    public static void setQlDiscountGroup(List<SBQQ__QuoteLine__c> quoteLines) {
        Set<Id> productIds = new Set<Id>();
       
        for(SBQQ__QuoteLine__c ql : quoteLines) {
            productIds.add(ql.SBQQ__Product__c);
        } 

        Map<Id, Product2> productsMap = new Map<Id, Product2>([SELECT Id, Product_Discount_Group__c FROM Product2 WHERE Id IN: productIds]);

        for(SBQQ__QuoteLine__c ql : quoteLines) {
            if(productsMap.get(ql.SBQQ__Product__c).Product_Discount_Group__c != null) {
                ql.Product_Discount_Group__c = productsMap.get(ql.SBQQ__Product__c).Product_Discount_Group__c;
            }
        }
    }

    public static void setSPGImpact(List<SBQQ__QuoteLine__c> newQuoteLines, Map<Id, SBQQ__QuoteLine__c> oldQuoteLinesMap) {
        try {
            for(SBQQ__QuoteLine__c newQl : newQuoteLines) {
                //when updating the products
                if(oldQuoteLinesMap != null && oldQuoteLinesMap.size() > 0) {
                    if(newQl.SPG_Impact_Formula__c != oldQuoteLinesMap.get(newQl.Id).SPG_Impact_Formula__c) {
                        newQl.SPG_Impact__c = newQl.SPG_Impact_Formula__c;
                    }
                } else {//for new products
                    newQl.SPG_Impact__c = newQl.SPG_Impact_Formula__c;
                }
            }
        } catch (Exception e) {
            System.debug('exception ' + e.getMessage());
        }
    }

    public static void setSalesUsd(List<SBQQ__QuoteLine__c> newQuoteLines, Map<Id, SBQQ__QuoteLine__c> oldQuoteLinesMap) {
        try {
            for(SBQQ__QuoteLine__c newQl : newQuoteLines) {
                //when updating the products
                if(oldQuoteLinesMap != null && oldQuoteLinesMap.size() > 0) {
                    if(newQl.Sales_USD__c != oldQuoteLinesMap.get(newQl.Id).Sales_USD__c) {
                        newQl.Sales_USD_Amount__c = newQl.Sales_USD__c;
                    }
                } else {//for new products
                    newQl.Sales_USD_Amount__c = newQl.Sales_USD__c;
                }
            }
        } catch (Exception e) {
            System.debug('exception ' + e.getMessage());
        }
    }
}