({
    callServer : function(component,event,method,params,callback) 
    {
        var getAllPorts = component.get(method);
        if(params) {
            getAllPorts.setParams(params);
        }
        getAllPorts.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                callback.call(this,response.getReturnValue());   
                var result = response.getReturnValue();
             } else if (state === "ERROR") {
                // generic error handler
                var errors = response.getError();
                if (errors) {
                    $A.log("Errors", errors);
                    if (errors[0] && errors[0].message) {
                        throw new Error("Error" + errors[0].message);
                    }
                } else {
                    throw new Error("Unknown Error");
                }
            }
        });
        $A.enqueueAction(getAllPorts,params);
    },
    
    savePort: function (component, event ,selectedPortId,recordId) {
        var selectedId = component.get("c.createKeyPortRecord");
        selectedId.setParams({
            "portId" : selectedPortId,
            "recordId":recordId
        });
        
        selectedId.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                this.toast(component, event, 'Success!', 'KeyPorts updated.', 'success');
                component.find("savecheckedPort").set("v.disabled", false);

			} else {
                this.toast(component, event , 'Error!', 'Could not update Keyport. Try again!', 'error');
            }

        });

        $A.enqueueAction(selectedId);

    },
    
    toast: function (component, event, title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "duration": 2000
        });
        toastEvent.fire();
    },
    
    filterLists: function (component, event, helper) {
        var allList = component.get('v.keyPortRows'); 
        
        var filteredList = [];
        
        var  nameCodefilteredList = [];
        var searchByName = component.get('v.searchName');
        var searchByCode = component.get('v.searchCode');
        var searchByLocation = component.get('v.searchLocation');
        
        var searchName = searchByName;
        var searchCode = searchByCode;
        var searchLocation = searchByLocation;
        
        if(searchByName){
            searchName = searchByName.toLowerCase();
        }
        if(searchByCode){
            searchCode = searchByCode.toLowerCase();
        }
        if(searchByLocation){
            searchLocation = searchByLocation.toLowerCase();
        }
        if ((!searchName || searchName.length === 0) && (!searchCode || searchCode.length === 0) && (!searchLocation|| searchLocation.length === 0)){
            this.renderPage(component, allList);
        }
        
        if (searchName && (!searchCode || searchCode.length === 0) && (!searchLocation || searchLocation.length === 0)){
            var currentPortList;
            for( var index = 0; index < allList.length; index++ ){
                currentPortList= allList[index];
                if (currentPortList.KeyPort.Name && currentPortList.KeyPort.Name.toLowerCase().indexOf(searchName) !== -1) {
                    filteredList.push(currentPortList);
                }
            }
            this.renderPage(component, filteredList);
        }
        
        if (searchCode && (!searchName || searchName.length === 0) && (!searchLocation || searchLocation.length === 0)){
            var currentPortList;
            for( var index = 0; index < allList.length; index++ ){
                currentPortList= allList[index];
                if (currentPortList.KeyPort.Port_Code__c && currentPortList.KeyPort.Port_Code__c.toLowerCase().indexOf(searchCode) !== -1) {
                    filteredList.push(currentPortList);
                }
            }
            this.renderPage(component, filteredList);
        }
        
        if (searchLocation && (!searchName || searchName.length === 0) && (!searchCode || searchCode.length === 0)){
            var currentPortList;
            for( var index = 0; index < allList.length; index++ ){
                currentPortList= allList[index];
                if (currentPortList.KeyPort.LocationName__c && currentPortList.KeyPort.LocationName__c.toLowerCase().indexOf(searchLocation) !== -1) {
                    filteredList.push(currentPortList);
                }
            }
            this.renderPage(component, filteredList);
        }
        if (searchName && searchCode && !searchLocation){
            var currentPortList;
            for( var index = 0; index < allList.length; index++ ){
                currentPortList= allList [index];
                if (currentPortList.KeyPort.Name && currentPortList.KeyPort.Name.toLowerCase().indexOf(searchName) !== -1) {
                    if (currentPortList.KeyPort.Port_Code__c && currentPortList.KeyPort.Port_Code__c.toLowerCase().indexOf(searchCode) !== -1) {
                        filteredList.push(currentPortList);
                        
                    }
                }
            }
            this.renderPage(component,filteredList);
        }
        
        if (searchName && searchCode && searchLocation){
            var currentPortList;
            for( var index = 0; index < allList.length; index++ ){
                currentPortList= allList[index];
                if (currentPortList.KeyPort.Name && currentPortList.KeyPort.Name.toLowerCase().indexOf(searchName) !== -1) {
                    if (currentPortList.KeyPort.Port_Code__c && currentPortList.KeyPort.Port_Code__c.toLowerCase().indexOf(searchCode) !== -1) {
                        if (currentPortList.KeyPort.LocationName__c && currentPortList.KeyPort.LocationName__c.toLowerCase().indexOf(searchLocation) !== -1) {
                            filteredList.push(currentPortList);
                        }
                    }
                }
            }
            this.renderPage(component,filteredList);
        }
    },
   
    sortBy: function(component, event, field) {
        var currentDir = component.get("v.arrowDirection");
        var selectedTabsoft = component.get("v.selectedTabsoft");
        var  records = component.get("v.keyPortRows");
        
        
        
        if (currentDir == 'arrowdown') {
            component.set("v.arrowDirection", 'arrowdown');
            component.set("v.isAsc", true);
            var sortAsc = component.get("v.isAsc");
            sortAsc = selectedTabsoft != field || !sortAsc;
			records.sort(function(a,b){
                if (selectedTabsoft=='Name'){
                    var t1 = a.KeyPort.Name == b.KeyPort.Name,
                        t2 = (!a.KeyPort.Name && b.KeyPort.Name) || (a.KeyPort.Name < b.KeyPort.Name);
                }
                if (selectedTabsoft=='Code'){
                    var t1 = a.KeyPort.Port_Code__c == b.KeyPort.Port_Code__c,
                        t2 = (!a.KeyPort.Port_Code__c && b.KeyPort.Port_Code__c) || (a.KeyPort.Port_Code__c < b.KeyPort.Port_Code__c);
                }
                if (selectedTabsoft=='Location'){
                    var t1 = a.KeyPort.LocationName__c == b.KeyPort.LocationName__c,
                        t2 = (!a.KeyPort.LocationName__c && b.KeyPort.LocationName__c) || (a.KeyPort.LocationName__c < b.KeyPort.LocationName__c);
                }
                if (selectedTabsoft=='Zone'){
                    var t1 = a.KeyPort.PortPricingZone__r.Name == b.KeyPort.PortPricingZone__r.Name,
                        t2 = (!a.KeyPort.PortPricingZone__r.Name && b.KeyPort.PortPricingZone__r.Name) || (a.KeyPort.PortPricingZone__r.Name < b.KeyPort.PortPricingZone__r.Name);
                }
                if (selectedTabsoft=='Group'){
                    var t1 = a.KeyPort.PortPricingGroup__r.Name == b.KeyPort.PortPricingGroup__r.Name,
                        t2 = (!a.KeyPort.PortPricingGroup__r.Name && b.KeyPort.PortPricingGroup__r.Name) || (a.KeyPort.PortPricingGroup__r.Name < b.KeyPort.PortPricingGroup__r.Name);
                }
                return t1? 0: (sortAsc?-1:1)*(t2?1:-1);
            });
            component.set("v.arrowDirection", 'arrowup');
            component.set("v.isAsc", false)
            this.renderPage(component,records);
            
        } else if (currentDir == 'arrowup'){
            console.log('Done1');
            
            component.set("v.arrowDirection", 'arrowup');
            component.set("v.isAsc", false);
            var sortAsc = component.get("v.isAsc");
            sortAsc = selectedTabsoft != field || !sortAsc;
            records.sort(function(a,b){
                if (selectedTabsoft=='Name'){
                    var t1 = a.KeyPort.Name == b.KeyPort.Name,
                        t2 = (!a.KeyPort.Name && b.KeyPort.Name) || (a.KeyPort.Name < b.KeyPort.Name);
                }
                if (selectedTabsoft=='Code'){
                    var t1 = a.KeyPort.Port_Code__c == b.KeyPort.Port_Code__c,
                        t2 = (!a.KeyPort.Port_Code__c && b.KeyPort.Port_Code__c) || (a.KeyPort.Port_Code__c < b.KeyPort.Port_Code__c);
                }
                if (selectedTabsoft=='Location'){
                    var t1 = a.KeyPort.LocationName__c == b.KeyPort.LocationName__c,
                        t2 = (!a.KeyPort.LocationName__c && b.KeyPort.LocationName__c) || (a.KeyPort.LocationName__c < b.KeyPort.LocationName__c);
                }
                if (selectedTabsoft=='Zone'){
                    var t1 = a.KeyPort.PortPricingZone__r.Name == b.KeyPort.PortPricingZone__r.Name,
                        t2 = (!a.KeyPort.PortPricingZone__r.Name && b.KeyPort.PortPricingZone__r.Name) || (a.KeyPort.PortPricingZone__r.Name < b.KeyPort.PortPricingZone__r.Name);
                }
                if (selectedTabsoft=='Group'){
                    var t1 = a.KeyPort.PortPricingGroup__r.Name == b.KeyPort.PortPricingGroup__r.Name,
                        t2 = (!a.KeyPort.PortPricingGroup__r.Name && b.KeyPort.PortPricingGroup__r.Name) || (a.KeyPort.PortPricingGroup__r.Name < b.KeyPort.PortPricingGroup__r.Name);
                }
                return t1? 0: (sortAsc?1:-1)*(t2?-1:1);
                
            });
            
            component.set("v.arrowDirection", 'arrowdown');
            component.set("v.isAsc", true);
            this.renderPage(component,records);
            
        }
        
        
    },
    renderPage: function(component, records) {
        
        component.set("v.maxPageNumber", Math.floor((records.length+19)/20));
        var  pageNumber = component.get("v.currentPageNumber");
        var  pageRecords = records.slice((pageNumber-1)*20, pageNumber*20);
		component.set("v.currentData", pageRecords);
    },
    
    
})