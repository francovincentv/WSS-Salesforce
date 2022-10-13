/**
* Implements the logic that based on records of class GlobalAccountAssignmentRule will
* assing a case to an Account.
*
* The records of class GlobalAccountAssignmentRule associates Contacts and WSS CS email addresses with Accounts.
*
* The purpose is to configure assignments that uses the sender and receiver address of the email creating a case to assign
* the case to an account.
*
* $LastChangedDate$
* $Rev$
* $Header$
*/
public with sharing class GlobalAccountAssignmentManager {
    Case caseObject;
    List<String> debugMessages;
    boolean writeDebugAsCaseComments = false;
    boolean verboseCaseComments = false;
    boolean isUpdateBefore = false;
    boolean isUpdateAfter = false;

    public static Set<Id> setOfIds = new Set<Id>();

    /**
* Prepares manager for the given case
*
* @param caseObject the case to process
*/
    private GlobalAccountAssignmentManager(Case caseObject,
            boolean isUpdateBefore,
            boolean isUpdateAfter,
            boolean writeDebugAsCaseComments,
            boolean verboseCaseComments) {
        this.caseObject = caseObject;
        debugMessages = new List<String>();
        this.isUpdateBefore = isUpdateBefore;
        this.isUpdateAfter = isUpdateAfter;
        this.writeDebugAsCaseComments = writeDebugAsCaseComments;
        this.verboseCaseComments = verboseCaseComments;
    }

    /**
* Factory to produce manager for the given case
*
* @param caseObject the case ot process
*/
    public static GlobalAccountAssignmentManager getInstance(Case caseObject,
            boolean isUpdateBefore,
            boolean isUpdateAfter,
            boolean writeDebugAsCaseComments,
            boolean verboseCaseComments) {
        return new GlobalAccountAssignmentManager(caseObject,
                isUpdateBefore,
                isUpdateAfter,
                writeDebugAsCaseComments,
                verboseCaseComments);
    }

    /**
* Instansiates manager and handles the list of cases.
* This is the entry point for triggers.
*
* @param cases list of cases to process
*/
    public static void handleCaseUpdate(List<Case> cases,
            boolean isUpdateBefore,
            boolean isUpdateAfter) {

        handleCaseUpdate(cases,
                isUpdateBefore,
                isUpdateAfter,
                false,
                false);
    }

    /**
* Instansiates manager and handles the list of cases.
* This is the entry point for triggers.
*
* @param cases list of cases to process
*/
    public static void handleCaseUpdate(List<Case> cases,
            boolean isUpdateBefore,
            boolean isUpdateAfter,
            boolean writeDebugAsCaseComments,
            boolean verboseCaseComments) {
        GlobalAccountAssignmentManager manager;

        for (Case caseObjectToHandle : cases) {

            try {
                /* Skip cases already being handled to avoid recursion */
                if (caseObjectToHandle.Id != null) {

                    if (setOfIds.contains(caseObjectToHandle.Id)) {
                        System.debug('Case is already being handled - skip update - ' + caseObjectToHandle.Id);
                        continue;
                    } else {
                        setOfIds.add(caseObjectToHandle.Id);
                    }
                }


                manager = getInstance(caseObjectToHandle,
                        isUpdateBefore,
                        isUpdateAfter,
                        writeDebugAsCaseComments,
                        verboseCaseComments);

                manager.handleCase();
                manager.writeDebugAsCaseComments();

            } finally {

                if (caseObjectToHandle.Id != null) {
                    setOfIds.remove(caseObjectToHandle.Id);
                }
            }
        }
    }

    /**
* Collects debug messages - allows verbose logging back to the case if configured
*
* @param message the message to log
*/
    private void debug(String message) {
        System.debug('GAR:' + message);
        debugMessages.add(message + '\n');
    }

    /**
* Implements the actual evaluation and execution of the assignment
*/
    private boolean handleCase() {
        List<EmailMessage> messages;
        String fromAddress;
        String toAddress;
        List<GlobalAccountAssignmentRule__c> rules;

        if (isCaseCandidateForAssignmentRules() != true) {
            return false;
        }

        /* Check single inbound email and get to and from address */
        messages = getMessagesForCase();
        if (messages.size() == 0) {

            debug(' Case ' + caseObject.caseNumber + ' - No email (yet) - will not update flag as processed');

            return false;
        } else if (messages.size() > 1) {

            if (verboseCaseComments) {
                markCaseAsAssignmentRulesExecuted(
                        'Case has multiple emails associated (' + messages.size() + ') - can not evaluate rules',
                        null);

            } else {
                markCaseAsAssignmentRulesExecuted();
            }

            return false;
        } else {

            fromAddress = messages[0].fromaddress;
            toAddress = messages[0].toaddress;

            if (fromAddress == null) {
                debug(' Case ' + caseObject.caseNumber + ' - does not have an email with from address');
                markCaseAsAssignmentRulesExecuted();
                return false;
            }

            rules = getGlobalAccountAssignmentRules(fromAddress, toAddress);
            debug(' Case ' + caseObject.caseNumber + ' - searching   fromAddress ' + fromAddress + ' toAddress ' + toAddress + '  returns ordered rule ' + rules);

            if (rules.size() < 1) {
                /* No rules found - give up */
                debug(' Case ' + caseObject.caseNumber + ' - searching   fromAddress ' + fromAddress + ' toAddress ' + toAddress + ' returned no rules .');

                if (verboseCaseComments) {
                    markCaseAsAssignmentRulesExecuted(
                            'No rules found matching from ' + fromAddress + ' to ' + toAddress + ' will not evaluate rules',
                            null);
                } else {
                    markCaseAsAssignmentRulesExecuted();
                }

                return false;
            }

            for (GlobalAccountAssignmentRule__c rule : rules) {
                debug(' Check rule ' + rule);
                markCaseAsAssignmentRulesExecuted('Global Account Assignment using rule ' + rule.Name + '.', rule.Account__r.ID);
                break;
            }


        }


        return true;
    }

    /**
 * Washes list of to email addresses, separated by ;
 * The order of addresses are retained. All non-wilhelmsen addresses are removed.
 *
 * @param all a string of email addresses, expecting ; to be the separator symbol
 *
 * @return a list of string - all ending with @wilhelmsen.com
 */
    @TestVisible static List<String> splitAndCleanToEmailAddresses(String all) {
        List<String> result;

        if (all == null) {
            return null;
        }

        // Make sure all whitespaces are removed
        all = all.replaceAll('\\s+', '');

        if (all.contains(';')) {
            result = all.split(';');

        } else {

            result = new List<String>();
            result.add(all);
        }


        return removeNonWilhelmsenAddresses(result);
    }


    /**
     * Filters the list of strings to only include the ones containing @wilhelmsen.com
     *
     * @param addresses list of strings
     *
     * @return list of cleaned addresses
     */
    static List<String> removeNonWilhelmsenAddresses(List<String> addresses) {
        List<String> result;

        result = new List<String>();

        for (String address : addresses) {
            if (address == null) {
                continue;
            }

            if (address.contains('@wilhelmsen.com')) {
                result.add(address);
            }
        }

        return result;
    }


    /**
* Lookup rules for the given from and to addresses.
*
* The two addresses are split by ; (if existing) and processed in the order the addresses appears in the address.
*/
    private List<GlobalAccountAssignmentRule__c> getGlobalAccountAssignmentRules(String fromAddress,
            String toAddress) {
         List<GlobalAccountAssignmentRule__c> rulesInOrder;
        List<String> splitAddresses;
        rulesInOrder = new List<GlobalAccountAssignmentRule__c>();

        if (fromAddress == null || toAddress == null) {
            return rulesInOrder;
        }

        splitAddresses = splitAndCleanToEmailAddresses(toAddress);

        if (splitAddresses != null && splitAddresses.size() > 0) {
            rulesInOrder = [select Name, ToAddress__c, Contact__r.Email, Account__r.ID from GlobalAccountAssignmentRule__c where Enabled__c = true and ToAddress__c in :splitAddresses and Contact__r.Email = :fromAddress];
        }

        return rulesInOrder;
    }

    /**
* Performs high level verification is the Case is an candidate for rule evaluation.
* The following checks are done:
*
* 1. If caseObject.Global_Account_Assignment_Rule_Executed__c is true then the case is NOT candidate (as the rule has already been executed)
* 2. If status is not new then the case is not candidate for update.
*
* @return true if this case is a candidate for checking against the assignment rules
*/
    private boolean isCaseCandidateForAssignmentRules() {

        /* Evaluate if case is to be processed */
        if (caseObject.Global_Account_Assignment_Rule_Executed__c == true) {
            debug(' No handling of case ' + caseObject.caseNumber + ' as it is already marked as handled (Global_Account_Assignment_Rule_Executed__c)');
            return false;
        }

        /* Is status of case new ? */
        if (caseObject.status != 'New') {
            debug(' No handling of case ' + caseObject.caseNumber + ' as status is in state not allowed for assignment ' + caseObject.status);

            if (verboseCaseComments) {
                markCaseAsAssignmentRulesExecuted('Case has status ' + caseObject.status + ' that is not allowed for Global Account Assignment', null);
            } else {
                markCaseAsAssignmentRulesExecuted();
            }


            return false;
        }

        /* Is Origin of case Email ? */
        if (caseObject.Origin != 'Email') {
            debug(' No handling of case ' + caseObject.caseNumber + ' as Origin is not allowed for assignment ' + caseObject.Origin);

            if (verboseCaseComments) {
                markCaseAsAssignmentRulesExecuted(
                        'Case has origin ' + caseObject.Origin + ' that is not allowed for Global Account Assignment',
                        null);
            } else {
                markCaseAsAssignmentRulesExecuted();

            }

            return false;
        }

        return true;
    }

    private void markCaseAsAssignmentRulesExecuted() {
        markCaseAsAssignmentRulesExecuted(null,
                null);
    }


    /**
* Fetches a fresh instance of the case being processed
*
* @return a case is found
*/
    private Case getCaseObjectForUpdate() {
        List<Case> cases;

        cases = [SELECT ID, AccountId FROM CASE WHERE ID = :caseObject.ID];

        if (cases.size() > 0) {
            return cases[0];
        }

        return null;
    }


    /**
* Flushes the debug comments as a case comment
*/
    private void writeDebugAsCaseComments() {
        CaseComment caseComment;

        if (!writeDebugAsCaseComments) {
            System.debug('writeDebugAsCaseComments is not enabled');
            return;
        }

        if (debugMessages != null && debugMessages.size() > 0) {

            caseComment = new CaseComment();
            caseComment.CommentBody = 'GlobalAccountAssignmentManager:   ' + debugMessages;
            caseComment.ParentId = caseObject.id;

            insert caseComment ;

            System.debug('GAR: writeDebugAsCaseComments is   enabled - added ' + caseComment.CommentBody + ' as CaseComments for case ' + caseObject.caseNumber);

        }

        debugMessages = new List<String>();
    }

    /**
* Gets the account having the given id.
*
* @param accountId the id of the account
* @return an account with name and coordinator code
*/
    Account getAccount(String accountId) {

        if (accountId == null) {
            return null;
        }

        List<Account> accounts = [SELECT Name, Account_Number__c, Customer_Coordinator__r.ID from Account WHERE ID = :accountId];

        if (accounts.size() > 0) {
            return accounts[0];
        }

        return null;
    }

    List<EmailMessage> getMessagesForCase() {
        List<EmailMessage> emailMessages;

        emailMessages = [select id, fromaddress, toaddress, HtmlBody, TextBody, subject, HasAttachment from emailmessage where Incoming = true and IsDeleted = false and parentid = :caseObject.ID];

        return emailMessages;
    }

    String getUserName(String id) {

        List<User> users = [SELECT Name from User WHERE ID = :id];

        if (users.size() > 0) {
            return users[0].Name;
        }

        return null;
    }


    /**
* Sets the flag Global_Account_Assignment_Rule_Executed__c to true.
* If enabled also appends a case comment to the case with information that the assignment rules has been evaluated
*
*/
    private void markCaseAsAssignmentRulesExecuted(
            String comments,
            String accountId) {

        Case caseObjectToUpdate = null;
        CaseComment caseComment;
        String beforeAccountName;
        String afterAccountName;
        Account account;

        debug(' Will update Global_Account_Assignment_Rule_Executed__c for case ' + caseObject.caseNumber + ' comments: ' + comments + ' accountId: ' + accountId);

        /* Depending of the trigger point, update this object, or get a fresh instance (as this.caseObject is readonly when isUpdateAfter) */
        if (isUpdateBefore) {
            caseObjectToUpdate = caseObject;
        } else if (isUpdateAfter) {
            caseObjectToUpdate = getCaseObjectForUpdate();
        }

        if (caseObjectToUpdate != null) {

            debug('isUpdateBefore:' + isUpdateBefore + 'isUpdateAfter:' + isUpdateAfter + '. Will update Global_Account_Assignment_Rule_Executed__c for case ' + caseObject.caseNumber + ' comments: ' + comments + ' accountId: ' + accountId);
            /* Mark the case with the flag that the rule has been updated */

            caseObjectToUpdate.Global_Account_Assignment_Rule_Executed__c = true;

            /* Update the accountId only if different */
            if (accountId != null && caseObjectToUpdate.accountId != accountId) {

                caseComment = new CaseComment();

                account = getAccount(caseObjectToUpdate.AccountId);
                if (account != null) {
                    beforeAccountName = account.Name + '(' + account.Account_Number__c + ')';
                } else {
                    beforeAccountName = '';
                }

                account = getAccount(accountId);
                if (account != null) {
                    afterAccountName = account.Name + '(' + account.Account_Number__c + ')';

                } else {
                    afterAccountName = '';
                }

                caseObjectToUpdate.accountId = accountId;

                caseComment.CommentBody = 'Changed account from ' + beforeAccountName + ' to ' + afterAccountName;

                /*  do not set the owner anymore 
                if (account.Customer_Coordinator__r.ID != null) {
                    caseObjectToUpdate.ownerId = account.Customer_Coordinator__r.ID;
                    caseComment.CommentBody = caseComment.CommentBody + '\nSet owner to ' + getUserName(caseObjectToUpdate.ownerId);
                } else {
                    caseComment.CommentBody = caseComment.CommentBody + '\nWill not change owner as no coordinator set for account ' + afterAccountName;

                }
                */
            }
        }

        /* If any comments given - append to comments already prepared in this context */
        if (comments != null) {
            if (caseComment == null) {
                /* No other comments, make new CaseComment object */
                caseComment = new CaseComment();
                caseComment.CommentBody = comments;
            } else {
                /* Already prepared some comments, append the comments first */

                caseComment.CommentBody = comments + '\n' + caseComment.CommentBody;
            }
        }

        /* Associate the case comment with the case and insert if needed */
        if (caseComment != null) {
            caseComment.parentId = caseObjectToUpdate.id;

            caseComment.CommentBody = 'GAR:' + caseComment.CommentBody;
            debug('Add caseComment for case ' + caseObject.caseNumber + ' with text ' + caseComment.CommentBody);
            insert caseComment;
        }

        /* If the trigger is updateAfter and there are changes to the case object then make sure it is updated.
This is not needed for isUpdateBefore
*/
        if (isUpdateAfter && caseObjectToUpdate != null) {
            update caseObjectToUpdate;
        }

    }


}