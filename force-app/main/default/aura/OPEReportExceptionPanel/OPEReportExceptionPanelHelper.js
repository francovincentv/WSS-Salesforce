({
    getLabels : function(component) {
        var action = component.get("c.getOPEFieldLabels");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                component.set("v.labelMap",result);
            } else if (state === "INCOMPLETE") {
                // do something
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },

    getData : function(component) {
        component.set('v.error',undefined);
        let recordId = component.get("v.recordId");
        var action = component.get("c.getStarlistExceptionDetails");
        action.setParams({ 
            exceptionId : recordId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            let spinner = component.find('spinner');
            $A.util.addClass(spinner, "slds-hide");
            if (state === "SUCCESS") {
                let result = response.getReturnValue();
                console.log(JSON.stringify(result,null,2));
                if(result.length == 1){
                    // Extract Conditions
                    var record = result[0];
                    if(record.hasOwnProperty('Conditions__r') && record['Conditions__r'].length > 0){
                        console.log('Conditions:',record['Conditions__r']);
                        let SubAccounts = [];
                        let PortsofDelivery = [];
                        let Vessels = [];
                        let Products = [];
                        
                        record['Conditions__r'].forEach(c => {
                            let condition = { "Code" : c.Code__c };
                            switch(c.RecordType.DeveloperName){
                                case 'SubAccounts':
                                    if(c.Status__c = 'Active'){
                                        condition.Id = c.Account__c;
                                        condition.Name = c.Account__r.Name;
                                        SubAccounts.push(condition);
                                    }
                                    break;
                                case 'PortsofDelivery':
                                    condition.Id = c.Port__c;
                                    condition.Name = c.Port__r.Name;
                                    PortsofDelivery.push(condition);
                                    break;
                                case 'Vessels':
                                    condition.Id = c.Vessel__c;
                                    condition.Name = c.Vessel__r.Name;
                                    Vessels.push(condition);
                                    break;
                                case 'Products':
                                    condition.Id = c.Product__c;
                                    condition.Name = c.Product__r.Name;
                                    Products.push(condition);
                                    break;
                                default: break;
                            }
                        });
                        console.log('SubAccounts',JSON.stringify(SubAccounts));
                        console.log('PortsofDelivery',JSON.stringify(PortsofDelivery));
                        console.log('Vessels',JSON.stringify(Vessels));
                        console.log('Products',JSON.stringify(Products));
                        if(!$A.util.isEmpty(SubAccounts))
                            record.SubAccounts = SubAccounts;
                        if(!$A.util.isEmpty(PortsofDelivery))
                            record.PortsofDelivery = PortsofDelivery;
                        if(!$A.util.isEmpty(Vessels))
                            record.Vessels = Vessels;
                        if(!$A.util.isEmpty(Products))
                            record.Products = Products;                        
                    }
                    component.set("v.record", record);
                }
                else
                    component.set("v.error","Data could not be retrieved for record with Id: "+recordId+'. The record could have been deleted or you don&#39;t have access to it. Please refresh the page and try again or contact your System Administrator.');
                
            } else if (state === "INCOMPLETE") {
                // do something
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.error","Data could not be retrieved for record with Id: "+recordId+'.');
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    }
})