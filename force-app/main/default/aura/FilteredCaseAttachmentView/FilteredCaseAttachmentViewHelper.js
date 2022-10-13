/*
$Rev: 24471 $
$LastChangedDate: 2018-10-30 11:53:53 +0100 (Tue, 30 Oct 2018) $
*/
({
	refreshList : function(component, item, callback) {
        var action = component.get("c.getAttachments");
        var selection = component.find("AttachmentFilterGroup").get("v.value");

         action.setParams({
            recordId: component.get("v.recordId"),
            fromCustomer : selection.includes('FromCustomer'),
            toCustomer : selection.includes('ToCustomer'),
            internal : selection.includes('Neither'),
        });

        action.setCallback(this, function(data) {
            component.set("v.Attachments", data.getReturnValue());
        });

        $A.enqueueAction(action);

    },

})