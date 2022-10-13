({
    getReportId : function(component, event, helper){
        console.log('@getReportId()');
        let reportId = component.get("v.reportIdAttribute");
        var loadingSpinner = component.find('loading');
        $A.util.removeClass(loadingSpinner, 'slds-hide');
        var reportContainer = component.find('report');
        $A.util.addClass(reportContainer, 'slds-hide');
        var reportError = component.find('report-error');
        $A.util.addClass(reportError, 'slds-hide');

        if(!reportId){
            let developerName = component.get("v.reportDeveloperName");
            console.log('reportDeveloperName: '+developerName);
            if(!developerName){
                helper.showError(component);
            }else{
                var action = component.get("c.getReportIdFromDeveloperName");
                action.setParams({ "developerName" : developerName });
                action.setCallback(this, function(response){
                    var state = response.getState();
                    // console.log(state);
                    if (state === "SUCCESS") {
                        let data = response.getReturnValue();
                        // console.log(data);
                        if(!data){
                            helper.showError(component);
                            return;
                        }else{
                            component.set("v.reportIdAttribute", data);
                            helper.getReport(component);
                        }
                    }
                });
                $A.enqueueAction(action);
            }
        }else{
            helper.getReport(component);
        }
    },
    getReport : function(component, event, helper){
        console.log('@ReportContainer.refreshReport()');
        helper.resetData(component);
        helper.getReport(component);
    },
    handleKeyDown : function(component, event, helper){
        console.log('@ReportContainer.handleKeyDown()');
        let keyName = event.key;
        if(keyName == 'ArrowUp' || keyName == 'ArrowDown'){
            event.preventDefault();
            var keyPressedEvent = $A.get("e.c:ReportContainerKeyPressedEvent");
            keyPressedEvent.setParams({"key" : keyName });
            keyPressedEvent.fire();
        }
    }
})