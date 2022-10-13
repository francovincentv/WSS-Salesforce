/*
* $LastChangedDate: 2018-11-20 07:21:58 +0100 (Tue, 20 Nov 2018) $
* $Rev: 24566 $
* $Header$ *
 */
@isTest
private class TestEmailDomainAssignmentRulesManager {
    static testMethod void testSplitEmailAddresses() {
        system.assert( EmailDomainAssignmentRulesManager.splitAndCleanToEmailAddresses(null) == null);

        system.assertEquals(0, EmailDomainAssignmentRulesManager.splitAndCleanToEmailAddresses('marius@zenior.no').size());


        system.assertEquals(3, EmailDomainAssignmentRulesManager.splitAndCleanToEmailAddresses('spdsss@evergreen-marine.com; fanyi.lu@wilhelmsen.com; wss.cs.taipei.products@wilhelmsen.com; teresa.qiu@wilhelmsen.com').size());
        system.assertEquals(1, EmailDomainAssignmentRulesManager.splitAndCleanToEmailAddresses('wss.cs.germany.products@wilhelmsen.com; tsm-lb@hms-services.com; psm-lb@hms-services.com; matthias.berndt@cargotec.com; ressin@ppg.com; hamburg.shipspares@logwin-logistics.com; leonhardtblumberg-storescatering@kloska.com; catering@bastelange.com; castrolmarine@castrol.com; service@comtide.de; leonhardt-blumberg@gac.com').size());

        
         system.assertEquals('fanyi.lu@wilhelmsen.com', EmailDomainAssignmentRulesManager.splitAndCleanToEmailAddresses('spdsss@evergreen-marine.com; fanyi.lu@wilhelmsen.com; wss.cs.taipei.products@wilhelmsen.com; teresa.qiu@wilhelmsen.com')[0]);
        system.assertEquals('wss.cs.taipei.products@wilhelmsen.com', EmailDomainAssignmentRulesManager.splitAndCleanToEmailAddresses('spdsss@evergreen-marine.com; fanyi.lu@wilhelmsen.com; wss.cs.taipei.products@wilhelmsen.com; teresa.qiu@wilhelmsen.com')[1]);
        system.assertEquals('teresa.qiu@wilhelmsen.com', EmailDomainAssignmentRulesManager.splitAndCleanToEmailAddresses('spdsss@evergreen-marine.com; fanyi.lu@wilhelmsen.com; wss.cs.taipei.products@wilhelmsen.com; teresa.qiu@wilhelmsen.com')[2]);


    }
    static testMethod void testSplitPickList() {
        system.assert( EmailDomainAssignmentRulesManager.splitPickList(null) == null);

        system.assertEquals(1, EmailDomainAssignmentRulesManager.splitPickList('marius@zenior.no').size());
        system.assertEquals('marius@zenior.no', EmailDomainAssignmentRulesManager.splitPickList('marius@zenior.no')[0]);
        system.assertEquals('marius@zenior.no', EmailDomainAssignmentRulesManager.splitPickList('marius@zenior.no;marius@gmail.com')[0]);
        system.assertEquals('marius@gmail.com', EmailDomainAssignmentRulesManager.splitPickList('marius@zenior.no;marius@gmail.com')[1]);




    }

    static testMethod void testEmailNotHavingFromAddress() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account europeAccount;
        EmailDomainAssignmentRule__c rule;
        Contact contact;

        europeAccount = makeAccount('1000000001', 'Europe Account');
        rule = makeAssignmentRuleForText(europeAccount, 'gmail.com', 'XXX');

        contact = makeContact('firstName',
                'lastName',
                'marius.midtvik@gmail.com',
                europeAccount,false);

        Test.StartTest ();


        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        // Associate case with europe account
        caseObject.AccountId = europeAccount.ID;
        caseObject.contact = contact;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com;dummy@gmail.com';
        emailMessage.ParentId = caseObject.ID;
        emailMessage.TextBody = 'BLA BLA XXX';

        insert emailMessage;

        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
    }

    static testMethod void testCaseHavingEmailWithContactNotEligibleForCBSLink() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account europeAccount;
        EmailDomainAssignmentRule__c rule;
        Contact contact;

        europeAccount = makeAccount('1000000001', 'Europe Account');
        rule = makeAssignmentRuleForText(europeAccount, 'gmail.com', 'XXX');

        contact = makeContact('firstName',
                'lastName',
                'marius.midtvik@gmail.com',
                europeAccount,false);

        Test.StartTest ();


        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        // Associate case with europe account
        caseObject.AccountId = europeAccount.ID;
        caseObject.contact = contact;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@gmail.com';
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com;dummy@gmail.com';
        emailMessage.ParentId = caseObject.ID;
        emailMessage.TextBody = 'BLA BLA XXX';

        insert emailMessage;

        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
    }



    static testMethod void testCaseHavingEmailWithAttachmentsWithRulesMatching() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account europeAccount;
        EmailDomainAssignmentRule__c rule;


        europeAccount = makeAccount('1000000001', 'Europe Account');
        rule = makeAssignmentRuleForAttachment(europeAccount, 'gmail.com', 'application/pdf', 'pdf');

        Test.StartTest ();

        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        // Associate case with europe account
        caseObject.AccountId = europeAccount.ID;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@gmail.com';
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com;dummy@gmail.com';
        emailMessage.TextBody = 'BLA BLA XXX';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        Attachment attachment;
        attachment = new Attachment();
        attachment.ContentType = 'application/pdf';
        attachment.Name = 'file.pdf';
        attachment.ParentId = emailMessage.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;

        List<Attachment> attachments;

        attachments = EmailDomainAssignmentRulesManager.getAttachments(emailMessage);
        System.assertEquals(1, attachments.size());


        caseObject.subject = '123';
        caseObject.Email_Domain_Assignment_Rule_Executed__c = false;
        update caseObject;



        caseObject = getCase(caseObject.ID);
        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
                System.assertEquals(true,caseObjectAfterUpdate.Email_Domain_Assignment_Rule_Executed__c);

                assertCaseHasCaseComment(caseObject.ID, 'Marius Midtvik');

    }


    static testMethod void testCaseHavingEmailWithAttachmentsWithRulesMatchingMultipleFromAddresses() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account europeAccount;
        EmailDomainAssignmentRule__c rule;


        europeAccount = makeAccount('1000000001', 'Europe Account');
        rule = makeAssignmentRuleForAttachment(europeAccount, 'mail.evergreen-line.com', 'application/pdf', 'pdf');

        Test.StartTest ();

        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        // Associate case with europe account
        caseObject.AccountId = europeAccount.ID;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'cargo_notice@mail.evergreen-line.com';
        emailMessage.ToAddress = 'spdsss@evergreen-marine.com; fanyi.lu@wilhelmsen.com; wss.cs.taipei.products@wilhelmsen.com; teresa.qiu@wilhelmsen.com';
        emailMessage.TextBody = 'BLA BLA XXX';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        Attachment attachment;
        attachment = new Attachment();
        attachment.ContentType = 'application/pdf';
        attachment.Name = 'file.pdf';
        attachment.ParentId = emailMessage.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;

        List<Attachment> attachments;

        attachments = EmailDomainAssignmentRulesManager.getAttachments(emailMessage);
        System.assertEquals(1, attachments.size());


        caseObject.subject = '123';
        caseObject.Email_Domain_Assignment_Rule_Executed__c = false;

        update caseObject;



        caseObject = getCase(caseObject.ID);
        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);


        System.assertEquals(true,caseObjectAfterUpdate.Email_Domain_Assignment_Rule_Executed__c);

        assertCaseHasCaseComment(caseObject.ID, 'Marius Midtvik');

    }

    static testMethod void testCaseHavingEmailWithAttachmentsWithRulesMatchingMultipleFromAddressesRuleForTo() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account europeAccount;
        EmailDomainAssignmentRule__c rule;


        europeAccount = makeAccount('1000000001', 'Europe Account');
        rule = makeAssignmentRuleForAttachment(europeAccount, 'mail.evergreen-line.com', 'wss.cs.taipei.products@wilhelmsen.com', 'application/pdf', 'pdf');

        Test.StartTest ();

        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        // Associate case with europe account
        caseObject.AccountId = europeAccount.ID;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'cargo_notice@mail.evergreen-line.com';
        emailMessage.ToAddress = 'spdsss@evergreen-marine.com; fanyi.lu@wilhelmsen.com; wss.cs.taipei.products@wilhelmsen.com; teresa.qiu@wilhelmsen.com';
        emailMessage.TextBody = 'BLA BLA XXX';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        Attachment attachment;
        attachment = new Attachment();
        attachment.ContentType = 'application/pdf';
        attachment.Name = 'file.pdf';
        attachment.ParentId = emailMessage.Id;
        attachment.Body = EncodingUtil.base64Decode('X');
        insert attachment;

        List<Attachment> attachments;

        attachments = EmailDomainAssignmentRulesManager.getAttachments(emailMessage);
        System.assertEquals(1, attachments.size());



        caseObject.subject = '123';
        caseObject.Email_Domain_Assignment_Rule_Executed__c = false;
        update caseObject;



        caseObject = getCase(caseObject.ID);
        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);


        System.assertEquals(true,caseObjectAfterUpdate.Email_Domain_Assignment_Rule_Executed__c);

        assertCaseHasCaseComment(caseObject.ID, 'Marius Midtvik');

    }





    static testMethod void testCaseHavingEmailWithHTMLBodyWithRulesMatching() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account europeAccount;
        EmailDomainAssignmentRule__c rule;


        europeAccount = makeAccount('1000000001', 'Europe Account');
        rule = makeAssignmentRuleForText(europeAccount, 'gmail.com', 'XXX');

        Test.StartTest ();


        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        // Associate case with europe account
        caseObject.AccountId = europeAccount.ID;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@gmail.com';
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com;dummy@gmail.com';
        emailMessage.ParentId = caseObject.ID;
        emailMessage.TextBody = 'BLA BLA';
        emailMessage.HtmlBody = '<html>XXX</html>';

        insert emailMessage;

        emailMessage.TextBody = '';
        update emailMessage;


        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
    }


    static testMethod void testCaseHavingEmailWithHTMLBodyWithNORulesMatching() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account europeAccount;
        EmailDomainAssignmentRule__c rule;


        europeAccount = makeAccount('1000000001', 'Europe Account');
        rule = makeAssignmentRuleForText(europeAccount, 'gmail.com', 'XXX');

        Test.StartTest ();


        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        // Associate case with europe account
        caseObject.AccountId = europeAccount.ID;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@gmail.com';
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com;dummy@gmail.com';
        emailMessage.ParentId = caseObject.ID;
        emailMessage.TextBody = 'BLA BLA';
        emailMessage.HtmlBody = '<html>YYY</html>';

        insert emailMessage;

        emailMessage.TextBody = '';
        update emailMessage;


        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
    }



    static testMethod void testCaseHavingEmailWithTwoToAddressesWithRulesMatching() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account europeAccount;
        EmailDomainAssignmentRule__c rule;


        europeAccount = makeAccount('1000000001', 'Europe Account');
        rule = makeAssignmentRuleForText(europeAccount, 'gmail.com', 'XXX');

        Test.StartTest ();


        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        // Associate case with europe account
        caseObject.AccountId = europeAccount.ID;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@gmail.com';
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com;dummy@gmail.com';
        emailMessage.ParentId = caseObject.ID;
        emailMessage.TextBody = 'BLA BLA XXX';

        insert emailMessage;

        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
    }


    static testMethod void testCaseHavingEmailWithMultipleToAddressesWithRulesMatching() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account europeAccount;
        EmailDomainAssignmentRule__c rule;


        europeAccount = makeAccount('1000000001', 'EDR-0717');
        rule = makeAssignmentRuleForText(europeAccount, 'mail.evergreen-line.com', 'wss.cs.taipei.products@wilhelmsen.com', 'XXX');

        Test.StartTest ();


        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        // Associate case with europe account
        caseObject.AccountId = europeAccount.ID;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'cargo_notice@mail.evergreen-line.com';
        emailMessage.ToAddress = 'spdsss@evergreen-marine.com; fanyi.lu@wilhelmsen.com; wss.cs.taipei.products@wilhelmsen.com; teresa.qiu@wilhelmsen.com';
        emailMessage.ParentId = caseObject.ID;
        emailMessage.TextBody = 'BLA BLA XXX';

        insert emailMessage;

        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
        System.assertEquals(true,caseObjectAfterUpdate.Email_Domain_Assignment_Rule_Executed__c);
        assertCaseHasCaseComment(caseObject.ID, 'Marius Midtvik');

    }


    static testMethod void testCaseNotHavingEmail() {
        Case caseObject;
        Case caseObjectAfterUpdate;


        List<Case> cases;

        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';
        insert caseObject;

        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);
        Test.StartTest ();

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
        System.assertEquals(false,caseObjectAfterUpdate.Email_Domain_Assignment_Rule_Executed__c);

    }



    static testMethod void testCaseNotBeingNew() {
        Case caseObject;
        Case caseObjectAfterUpdate;

        Test.StartTest ();

        caseObject = new Case();
        caseObject.status = 'NewX';
        caseObject.origin = 'Email';
        insert caseObject;

        caseObject.Subject = 'X';
        update caseObject;

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
        System.assertEquals(true,caseObjectAfterUpdate.Email_Domain_Assignment_Rule_Executed__c);

        //assertCaseHasCaseComment(caseObject.ID, 'Case has status NewX that is not allowed for Global Account Assignment');
    }

    static testMethod void testCaseNotHavingEmailAsOrigin() {
        Case caseObject;
        Case caseObjectAfterUpdate;

        Test.StartTest ();

        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'EmailX';
        insert caseObject;

        caseObject.Subject = 'X';
        update caseObject;

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
        System.assertEquals(true,caseObjectAfterUpdate.Email_Domain_Assignment_Rule_Executed__c);

        //assertCaseHasCaseComment(caseObject.ID, 'Case has origin EmailX that is not allowed for Global Account Assignment');
    }


    static testMethod void testgetEmailDomainVal() {
        String email;
        String domain;
        EmailDomainAssignmentRulesManager manager;

        email = 'marius.midtvik@zenior.no';

        domain = EmailDomainAssignmentRulesManager.getEmailDomainVal(email);

        System.assertEquals( 'zenior.no', domain);

    }



    static EmailDomainAssignmentRule__c makeAssignmentRuleForAttachment(Account account,
                                                                        String fromEmail,
                                                                        String contentType,
                                                                        String nameExtension) {
        EmailDomainAssignmentRule__c rule;
        EmailAttachmentRule__c   attachmentRule;

        rule = makeAssignmentRule(account, fromEmail);

        attachmentRule = new  EmailAttachmentRule__c();
        attachmentRule.ContentTypes__c  = contentType;
        attachmentRule.NameExtensions__c  = nameExtension;
        attachmentRule.Enabled__c = true;
        attachmentRule.EmailDomainAssignmentRule__c = rule.Id;

        insert attachmentRule;

        return rule;
    }

    static EmailDomainAssignmentRule__c makeAssignmentRuleForAttachment(Account account,
                                                                        String fromDomain,
                                                                        String toEmail,
                                                                        String contentType,
                                                                        String nameExtension) {
        EmailDomainAssignmentRule__c rule;
        EmailAttachmentRule__c   attachmentRule;

        rule = makeAssignmentRule(account, fromDomain, toEmail);

        attachmentRule = new  EmailAttachmentRule__c();
        attachmentRule.ContentTypes__c  = contentType;
        attachmentRule.NameExtensions__c  = nameExtension;
        attachmentRule.Enabled__c = true;
        attachmentRule.EmailDomainAssignmentRule__c = rule.Id;

        insert attachmentRule;

        return rule;
    }


    static EmailDomainAssignmentRule__c makeAssignmentRuleForText(Account account,
                                                                  String fromEmail,
                                                                  String text) {
        EmailDomainAssignmentRule__c rule;
        EmailContentRule__c   contentRule;

        rule = makeAssignmentRule(account, fromEmail);

        contentRule = new  EmailContentRule__c();
        contentRule.TextContentForMatching__c = text;
        contentRule.Enabled__c = true;
        contentRule.EmailDomainAssignmentRule__c = rule.Id;

        insert contentRule;

        return rule;
    }

    static EmailDomainAssignmentRule__c makeAssignmentRuleForText(Account account,
                                                                  String fromDomain,
                                                                  String toEmail,
                                                                  String text) {
        EmailDomainAssignmentRule__c rule;
        EmailContentRule__c   contentRule;

        rule = makeAssignmentRule(account, fromDomain, toEmail);

        contentRule = new  EmailContentRule__c();
        contentRule.TextContentForMatching__c = text;
        contentRule.Enabled__c = true;
        contentRule.EmailDomainAssignmentRule__c = rule.Id;

        insert contentRule;

        return rule;
    }


    static EmailDomainAssignmentRule__c makeAssignmentRule(Account account,
                                                           String fromEmail ) {
        EmailDomainAssignmentRule__c rule;

        rule = new EmailDomainAssignmentRule__c();
        rule.account__c = account.ID;
        rule.Enabled__c = true;
        rule.FromDomain__c = fromEmail;

        insert rule;

        return rule;
    }

    static EmailDomainAssignmentRule__c makeAssignmentRule(Account account,
                                                           String fromDomain,
                                                            String toEmail) {
        EmailDomainAssignmentRule__c rule;

        rule = new EmailDomainAssignmentRule__c();
        rule.account__c = account.ID;
        rule.Enabled__c = true;
        rule.FromDomain__c = fromDomain;
        rule.ToAddress__c = toEmail;

        insert rule;

        return rule;
    }


    static Id getRecordTypeId(String developerName) {
        List<RecordType> recordTypes;

        recordTypes = [SELECT ID from RecordType where developername = :developerName];

        System.assert(recordTypes.size() > 0, 'No record type found matching name ' + developerName);
        return recordTypes[0].ID;
    }

    static Account makeAccount(String accountNumber,
                               String name) {
        Account account;

        account = new Account();
        account.Account_Number__c  = accountNumber;
        account.Name = name;
        account.Customer_Currency__c = 'USD';
        account.RecordTypeId = getRecordTypeId('Customer_Sub_Account');

        insert account;

        return account;

    }

    static Contact makeContact(String firstName,
                               String lastName,
                               String email,
                               Account account,
                               boolean eligibleForCBSLink) {
        Contact contact;

        contact = new Contact();
        contact.LastName = lastName;
        contact.FirstName = firstName;
        contact.Email = email;
        contact.AccountId = account.ID;
        contact.EligibleForCBSLink__c = eligibleForCBSLink;
        contact.Phone = '+47 926 00 207';
        contact.function__c = 'Other';

        insert contact;

        return contact;
    }


    static void assertCaseHasCaseComment(ID caseId,
                                         String comment) {
        List<CaseComment> caseComments;
        caseComments = [SELECT CommentBody from CaseComment where ParentId = : caseId];

        System.assert(caseComments.size() > 0);

        for (CaseComment caseComment : caseComments) {
            System.debug('Check comment ' + caseComment.CommentBody);
            if (caseComment.CommentBody.contains(comment)) {
                return;
            }
        }

        System.assert(false, 'No CommentBody found having comments ' + comment);
    }

    static Case getCase(ID caseId) {
        List<Case> cases;

        cases = [SELECT ID, Global_Account_Assignment_Rule_Executed__c, Email_Domain_Assignment_Rule_Executed__c, status, origin, casenumber, AccountId from Case where ID = :caseId];

        System.assertEquals(1,cases.size());
        return cases[0];

    }


}