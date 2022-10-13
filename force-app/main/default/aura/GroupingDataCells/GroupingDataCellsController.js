({
	doInit : function(component, event, helper) {
		console.log('@GroupingDataCells.doInit()');
		var factMap = component.get("v.factMap");
		if( factMap ){
			var groupingKey = component.get("v.groupingKey");
			console.log("groupingKey: "+groupingKey);
			component.set("v.dataRows", factMap[groupingKey+"!T"].rows)
		}
		var workspaceAPI = component.find("workspace");
		workspaceAPI.isConsoleNavigation().then(function(isRunningInConsole) {
            console.log('isRunningInConsole: '+isRunningInConsole);
			component.set('v.isConsole',isRunningInConsole);
		})
        .catch(function(error) {
            console.log(error);
        });
	},
	editRecord : function (component, event, helper) {
		var recordId = event.currentTarget.dataset.recordid;
		var editRecordEvent = $A.get("e.force:editRecord");
		editRecordEvent.setParams({
			 "recordId": recordId
		});
		editRecordEvent.fire();
	},
	viewRecord : function (component, event, helper) {
		var recordId = event.currentTarget.dataset.recordid;
		var isRunningInConsole = component.get('v.isConsole');
		var workspaceAPI = component.find("workspace");
		
		if(isRunningInConsole){
			workspaceAPI.openTab({
				url: '#/sObject/' + recordId + '/view',
				focus: true
			}).then(function(response) {
				// actions to do after opening tab if necessary
			}).catch(function(error) {
				console.log(error);
			});
		}
	},
	rowClicked : function (component, event, helper) {
		console.warn(component.getGlobalId() + ' @rowClicked');
		let itemIndex = event.currentTarget.dataset.index;
		console.log('itemIndex: '+itemIndex);
		let dataRows = component.get('v.dataRows');
		let item = dataRows[itemIndex];

		component.set('v.selectedRow',itemIndex);
		console.log('Set v.selectedRow = '+component.get('v.selectedRow'));
		
		var appEvent = $A.get("e.c:GroupingDataRowClickedEvent");
		appEvent.setParams({'componentId' : component.getGlobalId() });
		appEvent.setParams({'item' : item.dataCells });
		appEvent.fire();

		dataRows.forEach((item,i)=>{item.selected=(i==itemIndex)});
		component.set('v.dataRows', dataRows);
	},
	handleRowClickEvent : function (component, event, helper) {
		console.warn('@handleRowClickEvent');

		let componentId = event.getParam("componentId");
		let groupingKey = event.getParam("groupingKey");
		let isRowClickedEvent = !$A.util.isEmpty(componentId);
		
		
		let myId = component.getGlobalId();
		let myGrouping = component.get('v.groupingKey');
		
		console.log('Event params:\ncomponentId: '+componentId+', groupingKey:'+groupingKey);
		console.log('myId: '+myId+', myGrouping: '+myGrouping);

		let isThisGrouping = false;
		if(isRowClickedEvent){
			isThisGrouping = (myId === componentId);
		}else{
			isThisGrouping = (myGrouping === groupingKey);
		}
		console.log('isThisGrouping: '+isThisGrouping);

		let dataRows = component.get('v.dataRows');
		if(!isThisGrouping){
			console.log('Not match, clear selection');
			dataRows.forEach((item,i)=>{item.selected=false});
			component.set('v.dataRows', dataRows);
			component.set('v.selectedRow', undefined);
		}else{
			if(!isRowClickedEvent){
				console.log('Match, set selection');
				let myIndex = component.get('v.selectedRow');
				let index = event.getParam("index");
				console.log('Current selectedRow: '+myIndex);
				console.log('Event index: '+index);
				
				if(index===0 || index && myIndex !== index){
					console.log('Index changed, set selectedRow to:'+index);
					component.set('v.selectedRow',index);
					let item = dataRows[index];
					console.log('Fire click event for item:',item);
					dataRows.forEach((row,i)=>{row.selected=(i==index)});
					component.set('v.dataRows', dataRows);
					var appEvent = $A.get("e.c:GroupingDataRowClickedEvent");
					appEvent.setParams({'componentId' : component.getGlobalId() });
					appEvent.setParams({'item' : item.dataCells });
					appEvent.fire();
					var cmpRows = [].concat(component.find("data-row"));
					var rowElem = cmpRows[index].getElement();
					rowElem.scrollIntoView({behavior:'smooth',block:'nearest'});
				}
			}else{
				console.log('Stop. Already handled.');
				event.stopPropagation();
			}
		}
	},
	shiftRowSelection : function (component, event, helper) {
		let selectedRow = component.get('v.selectedRow');
		console.warn('@shiftRowSelection','selectedRow:'+selectedRow);
		if(selectedRow !== 0 && !selectedRow)
			return;
		else
			event.stopPropagation();

		let key = event.getParam("key");
		let shift = 0;
		if(key == "ArrowUp")
			shift = -1;
		if(key == "ArrowDown")
			shift = 1;
		
		console.warn("Row shift: "+shift);
		
		let groupingMap = component.get('v.groupingMap');
		let myGrouping = component.get('v.groupingKey');
		let newSelectedRow = parseInt(selectedRow) + shift;
		let newGrouping = myGrouping;
		
		console.log('Current SelectedRow:', selectedRow);
		console.log('Current GroupingKey:', myGrouping);
		console.log('items in Grouping:', groupingMap[myGrouping]);
		if(newSelectedRow < 0 || newSelectedRow >= groupingMap[myGrouping]){
			console.log('newSelectedRow out of bounds:', newSelectedRow);
			if(myGrouping !== 'T'){
				let groupIndex = parseInt(myGrouping) + shift;
				console.log('groupIndex: '+groupIndex);
				newGrouping = (groupIndex).toString();
			}
			if(!groupingMap.hasOwnProperty(newGrouping))
				newGrouping = myGrouping;
			if(newGrouping === myGrouping)
				return; // This is the last item, do nothing
			else
				newSelectedRow = (shift>0?0:groupingMap[newGrouping]-1);
		}
		
		console.log('newGrouping:', newGrouping);
		console.log('newSelectedRow:', newSelectedRow);

		window.setTimeout(
			$A.getCallback(function() {
				var appEvent = $A.get("e.c:GroupingDataRowClickedEvent");
				appEvent.setParams({'groupingKey' : newGrouping });
				appEvent.setParams({'index' : newSelectedRow });
				appEvent.fire();
			}), 200
		);
		
	}
})