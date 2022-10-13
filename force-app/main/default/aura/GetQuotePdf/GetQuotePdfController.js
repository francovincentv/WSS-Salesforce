({
    handleClick : function(component) {
        component.set('v.loading', true);
        var action = component.get('c.getQuotePdf');
        action.setParams({
            quoteId : component.get('v.recordId')
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            var returnVal = response.getReturnValue();

            var toastEvent = $A.get("e.force:showToast");
            //console.log('response ', response.getState(), JSON.stringify(response.getError()), JSON.stringify(response.getReturnValue()));
            
            if(state === 'SUCCESS' && returnVal === 'Success') {
                
                $A.get('e.force:refreshView').fire();
                
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The customer preview successfully imported.",
                    "type": 'success',
                });
                toastEvent.fire();
            } else {
                const errors = response.getError();
                var err = "Error on Importing Quote PDF! Please Contact System Admin!";
                if(JSON.stringify(errors).includes('Fleet size should be grearthan 0'))
                    err =  'Fleet size should be grearthan 0';
                toastEvent.setParams({
                    "title": "Error!",
                    "message": err,
                    "type": 'error',
                });
                toastEvent.fire();
            }
            component.set('v.loading', false);
        });
        $A.enqueueAction(action);
    }
})