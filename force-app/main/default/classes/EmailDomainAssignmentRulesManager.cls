/**
 * Implements the logic that will assign cases based on configured rules for email domain, attachment type or email body content
 *
 * $LastChangedDate: 2018-11-20 07:20:33 +0100 (Tue, 20 Nov 2018) $
 * $Rev: 24565 $
 * $Header$
 */
public with sharing class EmailDomainAssignmentRulesManager {
    List<String> debugMessages;
    Case caseObject;
    boolean isUpdateBefore = false;
    boolean isUpdateAfter = false;
    boolean isFuture = false;
    String instanceId;

    public static Set<Id> setOfIds = new Set<Id>();


    private EmailDomainAssignmentRulesManager(Case caseObject,
            boolean isUpdateBefore,
            boolean isUpdateAfter,
            boolean isFuture) {

        debugMessages = new List<String>();
        this.caseObject = caseObject;
        this.isUpdateBefore = isUpdateBefore;
        this.isUpdateAfter = isUpdateAfter;
        this.isFuture = isFuture;

        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        instanceId = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);

        //debug('Will process case ' + caseObject);
    }

    public static EmailDomainAssignmentRulesManager getInstance(Case caseObject,
            boolean isUpdateBefore,
            boolean isUpdateAfter,
            boolean isFuture) {
        return new EmailDomainAssignmentRulesManager(caseObject,
                isUpdateBefore,
                isUpdateAfter,
                isFuture);
    }
    /**
   * Processes the given cases to check is email domain assignment rules are to be executed
   *
   * @param newCases the list of cases to process
   */
    public static void handleCaseUpdate(List<Case> newCases,
            boolean isUpdateBefore,
            boolean isUpdateAfter) {

        handleCaseUpdate(newCases,
                isUpdateBefore,
                isUpdateAfter,
                false);
    }

    /**
     * Processes the given cases to check is email domain assignment rules are to be executed
     *
     * @param newCases the list of cases to process
     */
    public static void handleCaseUpdate(List<Case> newCases,
            boolean isUpdateBefore,
            boolean isUpdateAfter,
            boolean isFuture) {
        EmailDomainAssignmentRulesManager instance;

        for (Case caseObjectToHandle : newCases) {

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


                instance = getInstance(caseObjectToHandle,
                        isUpdateBefore,
                        isUpdateAfter,
                        isFuture);

                instance.handleCase();

                if (isUpdateCaseWithCaseCommentWhenMarkingAssignedEnabled()) {
                    instance.writeDebugAsCaseComments();
                }


            } finally {

                if (caseObjectToHandle.Id != null) {
                    setOfIds.remove(caseObjectToHandle.Id);
                }

            }


        }

    }

    private void debug(String message) {
        System.debug('EAR: ' + message);
        debugMessages.add(message + '\n');
    }


    /**
     *
     * @return true if one of the assignment rules matches this object and the assignment was successful, otherwise false
     */
    boolean handleCase() {
        Case caseObjectWithAccount;
        List<EmailDomainAssignmentRule__c> emailDomainAssignmentRules;
        String fromAddress;
        String toAddress;
        String accountId;
        List<EmailMessage> messages;

        if (isCaseCandidateForAssignmentRules() != true) {
            return false;
        }

        /* Check single inbound email and get to and from address */
        messages = getMessagesForCase();
        if (messages.size() == 0) {

            debug('Case ' + caseObject.caseNumber + ' - No email (yet) - will not update flag as processed');

            return false;
        } else if (messages.size() > 1) {

            markCaseAsAssignmentRulesExecuted(
                    'Case has multiple emails associated (' + messages.size() + ') - can not evaluate rules',
                    null);

            return false;
        } else {

            fromAddress = messages[0].fromaddress;
            toAddress = messages[0].toaddress;
        }

        if (fromAddress == null) {
            markCaseAsAssignmentRulesExecuted(
                    'Email does not have from address - can not evaluate rules',
                    null);

            return false;

        }

        /* Get id of associated account */
        caseObjectWithAccount = fetchCaseWithAccountDetails();
        accountId = caseObjectWithAccount.Account.ID;

        /* Resolve the rules - in the order to be processed */
        emailDomainAssignmentRules = getEmailDomainRules(fromAddress, toAddress, accountId);

        debug('Case ' + caseObject.caseNumber + ' - searching   fromAddress ' + fromAddress + ' toAddress ' + toAddress + ' and account ' + accountId + ' returns ordered rule ' + emailDomainAssignmentRules);

        if (emailDomainAssignmentRules.size() < 1) {
            /* No rules found - give up */
            debug('Case ' + caseObject.caseNumber + ' - searching   fromAddress ' + fromAddress + ' toAddress ' + toAddress + ' and account ' + accountId + ' returned no rules .');

            markCaseAsAssignmentRulesExecuted(
                    'No rules found matching from ' + fromAddress + ' to ' + toAddress + ' and account ' + caseObjectWithAccount.Account.Name + '(' + caseObjectWithAccount.Account.Account_Number__c + ') - will not evaluate rules',
                    null);

            return false;
        }

        /* Evaluate the rules */
        for (EmailDomainAssignmentRule__c rule : emailDomainAssignmentRules) {
            if (evaluateRule(messages[0], rule)) {
                return true;
            }
        }

        markCaseAsAssignmentRulesExecuted(
                'None of the rules matched the email with subject ' + messages[0].subject,
                null);

        /* No rules was evaluated successfully */
        return false;
    }

    /**
    * Will evaluate a domain rule by checking the enabled attachment rules and text content rules against the email.
    *
     * @param emailMessage the email that created the case
    * @param the domain rule that matches the case and the email
    */
    boolean evaluateRule(
            EmailMessage emailMessage,
            EmailDomainAssignmentRule__c rule) {


        if (evaluateAttachmentRules(
                emailMessage,
                rule)) {
            return true;
        }

        if (evaluateContentRules(
                emailMessage,
                rule)) {
            return true;
        }

        return false;

    }

    @future
    public static void processInFuture(Id caseObjectIds) {
        List<Case> cases;

        cases = [SELECT CaseNumber, ID, Email_Domain_Assignment_Rule_Executed__c, status, type, origin from Case where Id = :caseObjectIds];

        if (cases.size() > 0) {
            handleCaseUpdate(cases, false, true, true);
        } else {
            System.debug('No cases found for ' + caseObjectIds + ' can not execute future');

        }

    }

    /**
     * Checks if the email message matches an attachment rule
     *
     * @param emailMessage
     * @param rule
     *
     * @return
     */
    boolean evaluateAttachmentRules(
            EmailMessage emailMessage,
            EmailDomainAssignmentRule__c rule) {
        List<EmailAttachmentRule__c> attachmentRules;
        List<Attachment> attachments;

        /* Fetch the attachment rules referencing the domain rule */
        attachmentRules = getAttachmentRules(rule);

        debug('Case ' + caseObject.caseNumber + ' Email has attachments : ' + emailMessage.HasAttachment + ' : ' + getAttachments(emailMessage));

        /* Any attachment rules ? */
        if (attachmentRules.size() > 0) {

            attachments = getAttachments(emailMessage);

            /* Does email have attachments ? */
            if (emailMessage.HasAttachment || attachments.size() > 0) {

                if (attachments.size() < 1) {
                    /* The email has attachments - but no attachments are returned loading them -
                       The reason can be that the attachments has not yet been saved.

                       This scenario is handled by returning true to stop further rule evaluation -
                       and then triggering a new execution of the rule checking in the future
                     */

                    if (!isFuture) {
                        debug('Case ' + caseObject.caseNumber + ' Email has attachments : ' + emailMessage.HasAttachment + ' but no emails are available for reading yet - will request future processing');
                        processInFuture(caseObject.ID);
                    } else {
                        debug('Case ' + caseObject.caseNumber + ' Email has attachments : ' + emailMessage.HasAttachment + ' but no emails are available for reading yet - this is a future call - will not request another');

                    }

                    return true;

                }

                debug('Case ' + caseObject.caseNumber + ' attachment rules ' + attachmentRules + ' and attachments ' + attachments);
                if (attachments.size() > 0) {

                    /* Then iterate over all attachment rules */
                    for (EmailAttachmentRule__c attachmentRule : attachmentRules) {

                        /* And check each attachment rule against the attachments of the email */
                        for (Attachment attachment : attachments) {

                            debug('Case ' + caseObject.caseNumber + ' attachment rules ' + attachmentRule + ' will check attachment ' + attachment + ' having content type ' + attachment.contentType + ' against ' + attachmentRule.ContentTypes__c);

                            /* Match by content type - this is not always set in Salesforce */
                            if (attachmentRule.ContentTypes__c != null) {
                                for (String contentType : splitPickList(attachmentRule.ContentTypes__c)) {
                                    debug('Case ' + caseObject.caseNumber + ' attachment rules ' + attachmentRule + ' will check attachment ' + attachment + ' having content type ' + attachment.contentType + ' against contentType ' + contentType);

                                    if (contentType != null && contentType.equals(attachment.contentType)) {
                                        debug('Case ' + caseObject.caseNumber + ' attachment rules ' + attachmentRule + ' has match for attachment ' + attachment + ' by content type ' + attachment.contentType);

                                        markCaseAsAssignmentRulesExecuted(
                                                'Assignment rule matches attachment ' + attachment.name,
                                                rule.OwnerId);

                                        return true;
                                    }

                                }
                            }

                            debug('Case ' + caseObject.caseNumber + ' attachment rules ' + attachmentRule + ' will check attachment ' + attachment + ' having name ' + attachment.name + ' against ' + attachmentRule.NameExtensions__c);

                            /* Then check the extension */
                            if (attachmentRule.NameExtensions__c != null) {
                                for (String nameExtension : splitPickList(attachmentRule.NameExtensions__c)) {
                                    debug('Case ' + caseObject.caseNumber + ' attachment rules ' + attachmentRule + ' will check attachment ' + attachment + ' having name ' + attachment.name + ' against nameExtension ' + nameExtension);

                                    if (nameExtension != null && attachment.name.endsWithIgnoreCase(nameExtension)) {
                                        debug('Case ' + caseObject.caseNumber + ' attachment rules ' + attachmentRule + ' has match for attachment ' + attachment + ' by content type ' + nameExtension);

                                        markCaseAsAssignmentRulesExecuted(
                                                'Assignment rule matches attachment ' + attachment.name,
                                                rule.OwnerId);

                                        return true;
                                    }

                                }
                            }
                        }
                    }
                }
            }
        } else {
            debug('Case ' + caseObject.caseNumber + ' attachment rules ' + attachmentRules + ' - email does not have any attachments');
        }

        return false;
    }

    /**
     * Checks email for presence of text
     *
     * @param emailMessage
     * @param rule
     *
     * @return
     */
    boolean evaluateContentRules(
            EmailMessage emailMessage,
            EmailDomainAssignmentRule__c rule) {
        List<EmailContentRule__c> contentRules;

        contentRules = getContentRules(rule);

        if (contentRules.size() > 0) {
            debug('Case ' + caseObject.caseNumber + ' contentrules ' + contentRules);

            for (EmailContentRule__c emailContentRule : contentRules) {
                if (emailMessage.textBody != null && emailMessage.textBody.containsIgnoreCase(emailContentRule.TextContentForMatching__c)) {
                    debug('Case ' + caseObject.caseNumber + ' has match in textBody for contentrules ' + contentRules + ' with text ' + emailContentRule.TextContentForMatching__c);
                    markCaseAsAssignmentRulesExecuted(
                            'Assignment rule matches email text ' + emailContentRule.TextContentForMatching__c,
                            rule.OwnerId);

                    return true;
                }

                if (emailMessage.htmlBody != null && emailMessage.htmlBody.containsIgnoreCase(emailContentRule.TextContentForMatching__c)) {
                    debug('Case ' + caseObject.caseNumber + ' has match in htmlBody for contentrules ' + contentRules + ' with text ' + emailContentRule.TextContentForMatching__c);

                    markCaseAsAssignmentRulesExecuted(
                            'Assignment rule matches email text ' + emailContentRule.TextContentForMatching__c,
                            rule.OwnerId);

                    return true;
                }
            }
        }

        return false;
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

    @TestVisible static List<String> splitPickList(String pickListValue) {
        if (pickListValue == null) {
            return null;
        }

        return pickListValue.split(';');
    }
    @TestVisible static List<Attachment> getAttachments(EmailMessage emailMessage) {
        List<Attachment> attachments;
        attachments = [select contentType, name from Attachment where ParentId = :emailMessage.id];

        return attachments;
    }

    List<EmailAttachmentRule__c> getAttachmentRules(EmailDomainAssignmentRule__c rule) {
        List<EmailAttachmentRule__c> attachmentRules;

        attachmentRules = [select ContentTypes__c, NameExtensions__c from EmailAttachmentRule__c where Enabled__c = true AND EmailDomainAssignmentRule__r.Id = :rule.id];

        return attachmentRules;
    }

    List<EmailContentRule__c> getContentRules(EmailDomainAssignmentRule__c rule) {
        List<EmailContentRule__c> contentRules;

        contentRules = [select TextContentForMatching__c from EmailContentRule__c where Enabled__c = true AND EmailDomainAssignmentRule__r.Id = :rule.id];

        return contentRules;
    }

    /**
    * Looks up rules and returns in the following order
    * 1. Rule matching domain of from address, to address and account id
    * 2. Rule matching domain of from address,  account id and no to address
    * 3. Rule matching domain of from address,  to address and no account id
    * 4. Rule matching domain of from address

     *
    * @param fromAddress
    * @param toAddress
    * @param accountId
    *
    * @return
    */
    List<EmailDomainAssignmentRule__c> getEmailDomainRules(String fromAddress, String toAddress, String accountId) {
        List<EmailDomainAssignmentRule__c> rules;
        List<EmailDomainAssignmentRule__c> rulesInOrder;

        rulesInOrder = new List<EmailDomainAssignmentRule__c>();

        if (toAddress != null) {
            if (accountId != null) {

                rules = getEmailDomainRuleMatching(fromAddress, toAddress, accountId);
                if (rules != null) {
                    rulesInOrder.addAll(rules);
                }

                rules = getEmailDomainRuleMatching(fromAddress, null, accountId);
                if (rules != null) {
                    rulesInOrder.addAll(rules);
                }

            }
            rules = getEmailDomainRuleMatching(fromAddress, toAddress, null);
            if (rules != null) {
                rulesInOrder.addAll(rules);
            }


        } else {
            if (accountId != null) {
                rules = getEmailDomainRuleMatching(fromAddress, null, accountId);

                if (rules != null) {
                    rulesInOrder.addAll(rules);
                }
            }

        }

        rules = getEmailDomainRuleMatching(fromAddress, null, null);

        if (rules != null) {
            rulesInOrder.addAll(rules);
        }

        return rulesInOrder;

    }

    /**
     * Fetches rules based on the given input. fromAddress is mandatory
     *
     * @param fromAddress
     * @param toAddress
     * @param accountId
     *
     * @return
     */
    List<EmailDomainAssignmentRule__c> getEmailDomainRuleMatching(String fromAddress, String toAddress, String accountId) {
        List<String> domains;
        List<EmailDomainAssignmentRule__c> rules;
        List<EmailDomainAssignmentRule__c> rulesInOrder;
        List<String> filteredToEmailAddresses;

        domains = getEmailDomainValList(fromAddress);

        if (domains.size() < 1) {
            debug('No domains extracted from address ' + fromAddress + ' - can not lookup rules');
            return null;
        }


        for (String domain : domains) {
            if (toAddress != null) {
                filteredToEmailAddresses = splitAndCleanToEmailAddresses(toAddress);
            }

            if (filteredToEmailAddresses != null && filteredToEmailAddresses.size() > 0) {


                if (filteredToEmailAddresses != null && filteredToEmailAddresses.size() > 0) {

                    if (accountId != null) {
                        /* Both toAddress and accountId is given */
                        rulesInOrder = new List<EmailDomainAssignmentRule__c>();

                        rules = [select Id, OwnerId, Name, ToAddress__c, FromDomain__c from EmailDomainAssignmentRule__c where Enabled__c = true and FromDomain__c = :domain AND Account__r.ID = :accountId AND ToAddress__c in :filteredToEmailAddresses];

                        debug('Search for "' + filteredToEmailAddresses + '" returned ' + rules);
                        if (rules != null) {
                            rulesInOrder.addAll(rules);
                        }


                        rules = rulesInOrder;

                    } else {
                        /* Only toAddress is given */
                        rulesInOrder = new List<EmailDomainAssignmentRule__c>();


                        rules = [select Id, OwnerId, Name, ToAddress__c, FromDomain__c from EmailDomainAssignmentRule__c where Enabled__c = true and FromDomain__c = :domain AND ToAddress__c in :filteredToEmailAddresses AND Account__c = null];
                        if (rules != null) {
                            rulesInOrder.addAll(rules);
                        }


                        rules = rulesInOrder;

                    }
                }
            } else {
                if (accountId != null) {
                    /* Only accountId is given */
                    rules = [select Id, OwnerId, Name, ToAddress__c, FromDomain__c from EmailDomainAssignmentRule__c where Enabled__c = true and FromDomain__c = :domain AND Account__r.ID = :accountId AND ToAddress__c = null];

                } else {
                    /* Neither toAddress or accountId is given */
                    rules = [select Id, OwnerId, Name, ToAddress__c, FromDomain__c from EmailDomainAssignmentRule__c where Enabled__c = true and FromDomain__c = :domain AND Account__c = null AND ToAddress__c = null];

                }
            }

            if (rules.size() > 0) {
                debug('Searching with domain ' + domain + ' fromAddress ' + fromAddress + ' toAddress ' + toAddress + ' and account ' + accountId + ' returns rule ' + rules);
                return rules;
            }

        }
        debug('Searching with domains ' + domains + ' fromAddress ' + fromAddress + ' toAddress ' + toAddress + ' and account ' + accountId + ' does not return any rules ');

        return null;
    }

    /**
     * Todo - return list of domains like
     * purchaser@vessel.customer.com would return
     * vessel.customer.com
     * customer.com
     *
     *
     * @param emailstring
     *
     * @return
     */
    public List<String> getEmailDomainValList(string emailstring) {
        List<String> domains;

        domains = new List<String>();
        domains.add(getEmailDomainVal(emailstring));

        return domains;
    }


    /**
     * Extracts the domain from an email address -
     * input marius.midtvik@wilhelmsen.com would return wilhelmsen.com
     *
     * @param emailstring string expected to contain an email address
     *
     * @return
     */
    public static String getEmailDomainVal(string emailstring) {
        String result;

        return emailString.substringAfter('@');
    }


    /**
     * Performs high level verification is the Case is an candidate for rule evaluation.
     *
     * @return true if this case is a candidate for checking against the assignment rules
     */
    boolean isCaseCandidateForAssignmentRules() {
        /* Evaluate if case is to be processed */
        if (caseObject.Email_Domain_Assignment_Rule_Executed__c == true) {
            debug('No handling of case ' + caseObject.caseNumber + ' as it is already marked as handled');
            return false;
        }


        /* Is status of case new ? */
        if (caseObject.status != 'New') {
            debug('No handling of case ' + caseObject.caseNumber + ' as status is in state not allowed for assignment ' + caseObject.status);

            markCaseAsAssignmentRulesExecuted(
                    'Case has status ' + caseObject.status + ' that is not allowed for assignment to CBSLink',
                    null);

            return false;
        }

        if (caseObject.type != null) {
            /* Is Type of case New ? */
            if (caseObject.type != 'MPPS') {
                debug('No handling of case ' + caseObject.caseNumber + ' as type is not allowed for assignment ' + caseObject.type);
    
                markCaseAsAssignmentRulesExecuted(
                        'Case has type ' + caseObject.type + ' that is not allowed for assignment to CBSLink',
                        null);
    
                return false;
            }
        }
    
        /* Is Origin of case Email ? */
        if  (caseObject.Origin != 'Email') {
            if (caseObject.Origin != 'CBSLink') {
            
                debug('No handling of case ' + caseObject.caseNumber + ' as Origin is not allowed for assignment ' + caseObject.Origin);
    
    
                markCaseAsAssignmentRulesExecuted(
                        'Case has origin ' + caseObject.Origin + ' that is not allowed for assignment to CBSLink',
                        null);
    
                return false;
            } else {
             
                debug('No handling of case ' + caseObject.caseNumber + ' as Origin is not allowed for assignment rules - origin: ' + caseObject.Origin);
    
    
                return false;
            }
        }

        if (checkIfCaseHasContactThatIsNOTEligibleForCBSLink()) {
            return false;
        }

        return true;
    }


    /**
     * Loads the contact of the case to check is this contact is marked explicitly as NOT eligible for CBSLink - as
     * emails from the email of this contact is NOT to be processed further
      *
     * @return true if contact is not to be handled further
     */
    boolean checkIfCaseHasContactThatIsNOTEligibleForCBSLink() {
        Case caseObjectWithDetails;

        /* Load contact details for the case - needed to lookup the Contact below */
        caseObjectWithDetails = fetchCaseWithContactDetails();

        /* Now check if the contact assigned to the case is marked as NOT eligible for CBSLink - as cases having such contact should not be processed */
        List<Contact> contacts = [SELECT Name, EligibleForCBSLink__c from Contact WHERE ID = :caseObjectWithDetails.Contact.ID];

        if (contacts.size() >= 1) {
            debug('Found ' + contacts.size() + ' contacts for case ' + caseObject.caseNumber);

            for (Contact contact : contacts) {
                if (contact.EligibleForCBSLink__c != true) {
                    debug('No handling of case ' + caseObject.caseNumber + ' as the Contact ' + contact.name + ' is NOT Eiligble for handling by Email Assignment Rules');

                    markCaseAsAssignmentRulesExecuted(
                            'Case has contact ' + contact.Name + ' that is not eligible for assignment to CBSLink',
                            null);

                    return true;
                }
            }

        } else {
            debug('No contacts found for case ' + caseObject.caseNumber + ' having contact id ' + caseObject.Contact.ID);
        }

        /* Either no contact found or contact is eligible for processing by CBSLink */
        return false;

    }

    private Case getCaseObjectForUpdate() {
        List<Case> cases;

        cases = [SELECT ID FROM CASE WHERE ID = :caseObject.ID];

        if (cases.size() > 0) {
            return cases[0];
        }

        return null;
    }

    /**
      * Sets the flag Email_Domain_Assignment_Rule_Executed__c to true.
    * If enabled also appends a case comment to the case with information that the email assignment rules has been evaluated
    *
    */
    void markCaseAsAssignmentRulesExecuted(
            String comments,
            String ownerId) {
        CaseComment caseComment;
        String userName;
        Case caseObjectToUpdate = null;

        debug('Will update Email_Domain_Assignment_Rule_Executed__c for case ' + caseObject.caseNumber + ' comments: ' + comments + ' owner: ' + ownerId);

        if (isUpdateBefore) {
            caseObjectToUpdate = caseObject;
        } else if (isUpdateAfter) {
            caseObjectToUpdate = getCaseObjectForUpdate();
        }

        if (caseObjectToUpdate != null) {
            debug('isUpdateBefore:' + isUpdateBefore + 'isUpdateAfter:' + isUpdateAfter + '. Will update Email_Domain_Assignment_Rule_Executed__c for case ' + caseObject.caseNumber + ' comments: ' + comments + ' owner: ' + ownerId);
            caseObjectToUpdate.Email_Domain_Assignment_Rule_Executed__c = true;
        }

        if (caseObjectToUpdate != null) {
            if (ownerId != null) {
                caseObjectToUpdate.ownerId = ownerId;
                userName = getUserName(ownerId);
                debug('isUpdateBefore:' + isUpdateBefore + 'isUpdateAfter:' + isUpdateAfter + 'Set owner for case ' + caseObject.caseNumber + ' to ' + ownerId + ' having name ' + userName);
            }
        }

        if (caseObjectToUpdate != null && isUpdateAfter) {
            update caseObjectToUpdate;
        }

        if (comments != null) {

            caseComment = new CaseComment();
            if (userName != null) {

                if (!comments.endsWith('.')) {
                    comments += '.';
                }

                caseComment.CommentBody = 'EAR:' + comments + ' Will assign case to ' + userName;

            } else {
                caseComment.CommentBody = 'EAR:' + comments ;

            }
            caseComment.ParentId = caseObject.id;

            debug('Add caseComment for case ' + caseObject.caseNumber + ' with text ' + caseComment.CommentBody);


            insert caseComment ;
        }


    }

    void writeDebugAsCaseComments() {
        CaseComment caseComment;


        debug('1. Number of Queries used in this Apex code so far: ' + Limits.getQueries());

        debug('2. Number of rows queried in this Apex code so far: ' + Limits.getDmlRows());

        debug('3. Number of DML statements used so far: ' + Limits.getDmlStatements());
        debug('4. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());


        if (debugMessages != null && debugMessages.size() > 0) {

            caseComment = new CaseComment();
            caseComment.CommentBody = 'EAR: Debug: isFuture' + isFuture + '\nThis:' + instanceId + '\n' +
                    '\n1. Number of Queries used in this Apex code so far: ' + Limits.getQueries() +
                    '\n2. Number of rows queried in this Apex code so far: ' + Limits.getDmlRows() +
                    '\n3. Number of DML statements used so far: ' + Limits.getDmlStatements() +
                    '\n4. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime() +
                    '\n' + debugMessages;
            caseComment.ParentId = caseObject.id;
            insert caseComment ;

        }

        debugMessages = new List<String>();
    }


    String getUserName(String id) {

        List<User> users = [SELECT Name from User WHERE ID = :id];

        if (users.size() > 0) {
            return users[0].Name;
        }

        return null;
    }

    /**
     * @return true if case comments are enabled when cases as marked as executed
     */
    static boolean isUpdateCaseWithCaseCommentWhenMarkingAssignedEnabled() {
        return true;
    }

    /**
      *
     * @return a Case object having the contact element populated the Contact.ID, Contact.Name and Contact.EligibleForCBSLink__c
    */
    Case fetchCaseWithContactDetails() {
        List<Case> caseObjectWithDetails;

        caseObjectWithDetails = [SELECT Id, Contact.ID, Contact.Name, Contact.EligibleForCBSLink__c from Case WHERE ID = :caseObject.ID];

        if (caseObjectWithDetails.size() > 0) {
            return caseObjectWithDetails[0];
        } else {
            return null;
        }
    }


    /**
     * @param caseToGet the case get details for
     *
     * @return a Case object having the contact element populated the Contact.ID, Contact.Name and Contact.EligibleForCBSLink__c
     */
    Case fetchCaseWithAccountDetails() {
        List<Case> caseObjectWithDetails;

        caseObjectWithDetails = [SELECT Id, Account.ID, Account.Name, Account.Account_Number__c from Case WHERE ID = :caseObject.ID];

        if (caseObjectWithDetails.size() > 0) {
            return caseObjectWithDetails[0];
        } else {
            return null;
        }
    }

    List<EmailMessage> getMessagesForCase() {
        List<EmailMessage> emailMessages;

        emailMessages = [select id, fromaddress, toaddress, HtmlBody, TextBody, subject, HasAttachment from emailmessage where Incoming = true and IsDeleted = false and parentid = :caseObject.ID];

        return emailMessages;
    }

}