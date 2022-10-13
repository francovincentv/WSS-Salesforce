/**
 * Handles the custom trigger for case
 *
 * $LastChangedDate: 2018-11-14 07:13:57 +0100 (Wed, 14 Nov 2018) $
 * $Rev: 24534 $
 * $Header$
 */
public with sharing class CustomCaseAssignmentTriggerHandler {
    public static Boolean writeDebugAsCaseComments = false;
    public static Boolean verboseCaseComments = false;

    public static void handleCaseUpdate(List<Case> cases,
            boolean isUpdateBefore,
            boolean isUpdateAfter) {

        /* First global account assignment - either use the the static debug configuration -
		or enable debug comments/verbose comments by default is executing as test */
        GlobalAccountAssignmentManager.handleCaseUpdate(cases,
                isUpdateBefore,
                isUpdateAfter,
                writeDebugAsCaseComments || Test.isRunningTest(),
                verboseCaseComments|| Test.isRunningTest());

        /* Then email domain rules */
    	EmailDomainAssignmentRulesManager.handleCaseUpdate(Trigger.New, Trigger.isBefore, Trigger.isAfter);

    }
}