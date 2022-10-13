/*
$Rev: 24534 $
$LastChangedDate: 2018-11-14 07:13:57 +0100 (Wed, 14 Nov 2018) $
*/
trigger CustomCaseAssignmentTrigger on Case ( after update) {
    CustomCaseAssignmentTriggerHandler.handleCaseUpdate(Trigger.New, Trigger.isBefore, Trigger.isAfter);

}