({
    callApex : function(component, actionName, params, callback) {
        var action = component.get(actionName);
        action.setParams(params);
        action.setCallback(this, callback);
        $A.enqueueAction(action);
    },
    showError : function(component){
        var loadingSpinner = component.find('loading');
        var reportError = component.find('report-error');
        $A.util.addClass(loadingSpinner, 'slds-hide');
        $A.util.removeClass(reportError, 'slds-hide');
    },
    showTable : function(component,onoff){
        var loadingSpinner = component.find('loading');
        var reportContainer = component.find('report');
        if(onoff){
            $A.util.addClass(loadingSpinner, 'slds-hide');
            $A.util.removeClass(reportContainer, 'slds-hide');
        }else{
            $A.util.removeClass(loadingSpinner, 'slds-hide');
            $A.util.addClass(reportContainer, 'slds-hide');
        }
    },
    getReport : function(component) {
        const helper = this;
        //hide report and show spinner while we process
        //debugger;
        let filters = component.get("v.filtersAttribute");
        let reportId = component.get("v.reportIdAttribute");

        console.log('filters: '+filters);
        console.log('reportId: '+reportId);

        //get report data from Apex controller using report ID provided
        let action = "c.getReportMetadata";
        let params = { 
            "reportId" : reportId,
            "filters" : filters
        };
        //handle response from Apex controller
        helper.callApex(component, action, params, 
            function(response){
                // transform into JSON object
                var returnValue = JSON.parse(response.getReturnValue());
                var groupingLabels = {};
                
                if( returnValue && returnValue.reportExtendedMetadata ){
                    // categorize groupings into levels so we can access them as we go down grouping level
                    var columnInfo = returnValue.reportExtendedMetadata.groupingColumnInfo;
                    for( var property in columnInfo ){
                        if( columnInfo.hasOwnProperty(property) ){
                            var level = columnInfo[property].groupingLevel;
                            var label = columnInfo[property].label;
                            groupingLabels[level] = label;
                        }
                    }
                    // set lightning attributes so we have access to variables in the view
                    component.set("v.groupingLevelToLabel", groupingLabels)
                    component.set("v.reportData", returnValue);
                    component.set("v.factMap", returnValue.factMap);
                    let groupingMap = {};
                    for(var grouping in returnValue.factMap){
                        // console.log(JSON.stringify(returnValue.factMap[grouping],null,2));
                        let groupingKey = returnValue.factMap[grouping].key.split('!').shift();
                        let rows = (returnValue.factMap[grouping].rows != null?returnValue.factMap[grouping].rows.length:0);
                        groupingMap[groupingKey] = rows;
                    }
                    console.log(groupingMap);
                    component.set("v.groupingMap", groupingMap);
                    
                    //set column headers, this assumes that they are returned in order
                    var tableHeaders = [];
                    for( var i = 0; i < returnValue.reportMetadata.detailColumns.length; i++ ){
                        var fieldAPIName = returnValue.reportMetadata.detailColumns[i];
                        var fieldLabel = returnValue.reportExtendedMetadata.detailColumnInfo[fieldAPIName].label;
                        tableHeaders.push(fieldLabel)
                    }
                    component.set("v.columnLabels", tableHeaders);
                    
                    //hide spinner, reveal data
                    helper.showTable(component,true);
                }
                else {
                    helper.showError(component);
                }
            }
        );
    },
    resetData : function(component){
        component.set("v.groupingLevelToLabel", null)
        component.set("v.reportData", null);
        component.set("v.factMap", null);
        //show spinner, hide data
        this.showTable(component,false);
    }
})