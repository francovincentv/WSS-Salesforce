/*
$Rev: 24471 $
$LastChangedDate: 2018-10-30 11:53:53 +0100 (Tue, 30 Oct 2018) $
*/
({
             
    handleChangeOfAttachmentOptions : function(component, event, helper) {
                  helper.refreshList(component);

     },
    
    myAction : function(component, event, helper) {
        var actions = [
            { label: 'Show details', name: 'show_details' }];
        
        component.set("v.Columns", [
            
            {label:"Name", fieldName:"Name", type:"text", sortable:"true"},
            {label:"Date", fieldName:"CreatedDate", sortable:"true", type:"date", typeAttributes:{
                year:"numeric",
                month:"2-digit",
                day:"2-digit", 
                hour:"2-digit",
                minute:"2-digit"
            }},
             {label:"Type", fieldName:"Type", type:"text", sortable:"true"}

            ,
            
            
            { type: 'action', typeAttributes: { rowActions: actions }}]);
        
        
        helper.refreshList(component);
       
    },
    
    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        
        switch (action.name) {
            case 'show_details':
               
                window.open("/servlet/servlet.FileDownload?file=" + row.Id ,'_blank');   
                
                
                break;
                
        }
    }
})