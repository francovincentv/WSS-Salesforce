({
    doInit : function(component, event, helper) 
    {
        component.set('v.response','');
        var spinner = component.find("spinner");
        var resultTable = component.find("resultID");
        var recordId = component.get("v.recordId");  
        component.set("v.recordId", recordId);
        console.log('recordId: ',recordId);
        helper.callServer(
            component,event,
            'c.getKeyPorts',
            {
                recordId: recordId
            },
            function(response)
            {
                var ctrl = response;
                //At least somehow handle Errors
                if(ctrl.success == 'false'){
                    $A.util.addClass(spinner, "slds-hide");
                    $A.util.addClass(resultTable, "slds slds-show");
                    return;
                }
                console.log('ctrl: ',ctrl);
                component.set('v.response', ctrl.rowResponse);
                component.set('v.keyPortRows', ctrl.keyPortRows);
                var records=  component.get('v.keyPortRows');
                var currentPortList;
                var currentPortList1;
                component.set("v.maxPageNumber", Math.floor((records.length+1)/20));
                component.set('v.ctrl', ctrl); 
                $A.util.addClass(spinner, "slds-hide");
                $A.util.addClass(resultTable, "slds slds-show");
                helper.renderPage(component,records);
            }
        );
    },
    clearSearchByLocation: function (component, event, helper) {
        var searchLocation = component.get('v.searchLocation');
        if(searchLocation){
            component.set('v.searchLocation','');
        }
        helper.filterLists(component, event, helper);
        
    },
    
    clearSearchByName: function (component, event, helper) {
        var searchName = component.get('v.searchName');
        if(searchName){
            component.set('v.searchName','');
        }
        helper.filterLists(component, event, helper);
        
    },
   
    clearSearchByCode: function (component, event, helper) {
        var searchCode = component.get('v.searchCode');
        if(searchCode){
            component.set('v.searchCode','');
        }
        helper.filterLists(component, event, helper);
    },
    
    search: function (component, event, helper) {
        console.log('testing');
        
        var typingTimer = component.get('v.typingTimer');
        clearTimeout(typingTimer);
        
        typingTimer = setTimeout(function () {
            helper.filterLists(component, event, helper);
            clearTimeout(typingTimer);
            component.set('v.typingTimer', null);
        }, 200);
        
        component.set('v.typingTimer', typingTimer);
    },
    
    selectAll: function(component, event, helper) {
        var selectedHeaderCheck = event.getSource().get("v.value");
        var allList = component.get('v.keyPortRows'); 
        if(selectedHeaderCheck == true){ 
            for( var index = 0; index < allList.length; index++ ){
                allList[index].Selected=true;
            }
        }  else{
            for( var index = 0; index < allList.length; index++ ){
                allList[index].Selected=false;
            }
        }
        
        helper.renderPage(component, allList);
        
        
    },
    handleClick: function (component, event, helper) {
        var selectedItem = event.currentTarget; // Get the target object
        var index = selectedItem.dataset.record; // Get its value i.e. the index
        var portId = component.get("v.keyPortRows")[index].KeyPort.Id; // Use it retrieve the store record 
        // console.log('test');
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": portId,
            "slideDevName": "related"
        });
        navEvt.fire();
    },
    
    sortByName: function(component, event, helper) {
        // set current selected header field on selectedTabsoft attribute.     
        component.set("v.selectedTabsoft", 'Name');
        // call the helper function with pass sortField Name   
        helper.sortBy(component, event, 'Name');
    },
    firstPage: function(component, event, helper) {
        component.set("v.currentPageNumber", 1);
    },
    
    nextPage : function(component, event, helper) 
    {
        component.set("v.currentPageNumber", Math.min(component.get("v.currentPageNumber")+1, component.get("v.maxPageNumber")));
       
    },
    
    previousPage : function(component, event, helper) 
    {
        component.set("v.currentPageNumber", Math.max(component.get("v.currentPageNumber")-1, 1));
        //   console.log('previous '+ component.get("v.currentPageNumber"));
        // helper.renderPage(component);
        
    },
    
    lastPage: function(component, event, helper) {
        component.set("v.currentPageNumber", component.get("v.maxPageNumber"));
    },
    
    
    sortByCode: function(component, event, helper) {
        // set current selected header field on selectedTabsoft attribute.    
        component.set("v.selectedTabsoft", 'Code');
        // call the helper function with pass sortField Name  
        helper.sortBy(component, event, 'Code');
    },
    
    sortByLocation: function(component, event, helper) {
        // set current selected header field on selectedTabsoft attribute.        
        component.set("v.selectedTabsoft", 'Location');
        // call the helper function with pass sortField Name      
        helper.sortBy(component, event, 'Location');
        
    },
    sortByZone: function(component, event, helper) {
        // set current selected header field on selectedTabsoft attribute.        
        component.set("v.selectedTabsoft", 'Zone');
        // call the helper function with pass sortField Name      
        helper.sortBy(component, event, 'Zone');
        
    },
    sortByGroup: function(component, event, helper) {
        component.set("v.selectedTabsoft", 'Group');
        helper.sortBy(component, event, 'Group');
        
    },
    
    save: function(component, event, helper) {
        component.find("savecheckedPort").set("v.disabled", true);
        var allList = component.get('v.keyPortRows'); 
        var selectedPortId = [];
        for( var index = 0; index < allList.length; index++ ){
            if (allList[index].Selected==true){
                selectedPortId.push(allList[index].KeyPort.Id);
            }
        }
        var recordId = component.get("v.recordId");  
        helper.savePort(component, event,selectedPortId,recordId);
        
    },
    
    close: function(component, event, helper) {
        var recordId = component.get("v.recordId");  
        var previousPage = component.get("c.getQuoteId");
        previousPage.setParams({
            "recordId":recordId
        });
        previousPage.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var quoteId = response.getReturnValue();
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": quoteId,
                    "slideDevName": "related"
                });
                navEvt.fire();            
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(previousPage);
    },
    
    renderPage: function(component,event, helper) {
        var records=  component.get('v.keyPortRows');
        console.log('length '+ records.length);
        helper.renderPage(component,records);
    },
})