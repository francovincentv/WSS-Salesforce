({
    doInit : function(component, event, helper) {
        console.log('@doInit');
        if(!component.get("v.recordId")){
            helper.getRecordIdFromUrl(component);
        }
        component.find("recordLoader").reloadRecord();
    },
    
    onPageReferenceChange : function(component, event, helper) {
        console.log('@onPageReferenceChange');
        helper.getRecordIdFromUrl(component);
        component.find("recordLoader").reloadRecord();
        component.find("exceptionPanel").clear();
    },
    recordUpdated : function(component, event, helper) {
        console.log("@recordUpdated");
        var changeType = event.getParams().changeType;
        console.log("changeType:" + changeType);
        // console.log("Ready?:" + component.get("v.ready"));

        if (changeType === "ERROR") { 
            helper.showToast(component,"error","Error Loading Record Data",component.get("v.recordLoadError"));
        }
        else if (changeType === "LOADED") {
            helper.setConsoleLabel(component);
            let account = component.get("v.accountRecord");
            console.log(JSON.stringify(account,null,2));
            
            let title = account.Name;
            
            // Report Filters by position:
            // (1) 2: Sub-Account Filter: Account Number
            // (2) 3: Sub-Accounts Under Approval: Account Number
            // (7) 8: Customer Segment includes: Category (Type)
            // (10) 11: Country of Customer includes: Country of Domicile
            // (13) 14: Included CS Teams
            // (16) 17: Included Sales Territories
            
            let filters = Array(17).fill("");
            filters[1] = filters[2] = (';'+account.Account_Number__c+';'||'');
            filters[7] = (account.Type||'');
            //filters[10] = (account.Country_of_Domicile__c||'');
            filters[10] =  !account.Country_of_Domicile__c ? '' : (account.Country_of_Domicile__c).includes(',') ? JSON.stringify(account.Country_of_Domicile__c) :  (account.Country_of_Domicile__c);
            filters[13] = (account.CS_Team__c||''); 
            filters[16] = (account.Sales_Territory__c||'');
            
            let reportLinkFilters = [];
            reportLinkFilters.push('fv1=' + filters[1]);
            reportLinkFilters.push('fv2=' + filters[2]);
            reportLinkFilters.push('fv7=' + filters[7]);
            reportLinkFilters.push('fv10=' + filters[10]);
            reportLinkFilters.push('fv13=' + filters[13]);
            reportLinkFilters.push('fv16=' + filters[16]);
            console.log(reportLinkFilters);

            component.set("v.reportTitle",title);
            component.set("v.filtersAttribute", filters.join(','));
            component.set("v.reportLinkFilters", reportLinkFilters.join('&'));
            if(!component.get("v.ready"))
                component.set("v.ready",true);
            else{
                component.find("report-component").refreshReport();
            }

        }
        else if (changeType === "REMOVED") { /* handle record removal */ }
        else if (changeType === "CHANGED") { /* handle record change */ }
    },
    loadRecord : function(component, event, helper) {
        if(event.getParam("item")){
            var item = event.getParam("item");
            let cmp = component.find("exceptionPanel");
            let idColumn = component.get('v.reportLinkColumn');
            let recordId = item[idColumn].value;
            console.log(idColumn,recordId);
            cmp.loadRecord(recordId);
        }
    }
})