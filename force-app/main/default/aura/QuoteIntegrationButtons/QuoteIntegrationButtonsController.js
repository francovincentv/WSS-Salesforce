({
    doInit : function(component) {
        var action = component.get("c.getQuoteDetails");
        console.log(component.get("v.recordId"));
        action.setParams({
            "quoteId" : component.get("v.recordId")
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS') {
                var returnVal = response.getReturnValue();
                if(returnVal.SBQQ__Opportunity2__r) {
                    var recTypeDevName = returnVal.SBQQ__Opportunity2__r.RecordType.DeveloperName;
                    if(recTypeDevName === 'Special_Offer') {
                        component.set('v.showInsertQuoteLine', false);
                    } else {
                        component.set('v.showInsertQuoteLine', true);
                    }
                }
            } else {
                console.log('response.getError()', JSON.stringify(response.getError()));
            }
        });
        $A.enqueueAction(action);
    }
})