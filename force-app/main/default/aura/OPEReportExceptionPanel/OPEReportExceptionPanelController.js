({
    doInit : function(component, event, helper) {
        helper.getLabels(component);
    },

    doLoadRecord : function(component, event, helper) {
        let spinner = component.find('spinner');
        $A.util.removeClass(spinner, "slds-hide");
        var params = event.getParam("arguments");
        if (params){
            var recordId = params.recordId;
            var previousRecordId = component.get('v.recordId');
            if(recordId !== previousRecordId){
                component.set('v.recordId',recordId);
            }
            console.log(recordId);
            helper.getData(component);
        }
    },

    recordUpdated : function(component, event, helper) {
        console.log("@recordUpdated");
        var changeType = event.getParams().changeType;
        console.log("changeType:" + changeType);
        console.log("Record:",component.get('v.record'));
        let spinner = component.find('spinner');
        $A.util.addClass(spinner, "slds-hide");
    },

    doClear  : function(component, event, helper) {
        component.set('v.recordId',null);
        component.set('v.record',null);
    }

})