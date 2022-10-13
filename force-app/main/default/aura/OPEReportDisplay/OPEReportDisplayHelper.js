({
    getRecordIdFromUrl : function(component){
        var myPageRef = component.get("v.pageReference");
        var recordId = myPageRef.state.c__recordId;
        component.set("v.recordId", recordId);
        console.log("v.recordId: " + component.get("v.recordId"));
    },

    showToast : function(component, type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type" : type,
            "title": title,
            "message": message
        });
        toastEvent.fire();
    },

    setConsoleLabel : function(component){
        console.log("@setConsoleLabel");
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(isRunningInConsole) {
			if(isRunningInConsole){
                workspaceAPI.getEnclosingTabId().then(function(thisTabId) {
                    workspaceAPI.setTabLabel({
                        tabId: thisTabId,
                        label: "Starlist Exceptions"
                    });
                    workspaceAPI.setTabIcon({
                        tabId: thisTabId,
                        icon: "standard:report", //set icon you want to set
                        iconAlt: "Report" //set label tooltip you want to set
                    });
                })
                .catch(function(error) {
                    console.warn(error);
                });
            }
        });
    }
})