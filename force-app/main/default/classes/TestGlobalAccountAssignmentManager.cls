/** *
 * $LastChangedDate$
 * $Rev$
 * $Header$
 */
@isTest
private class TestGlobalAccountAssignmentManager {

    static testMethod void testCaseHavingEmailWithoutFromAddress() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account asiaAccount;
        Account europeAccount;
        Contact contact;
        GlobalAccountAssignmentRule__c rule;

        asiaAccount = makeAccount('1000000000', 'Asia Account');
        europeAccount = makeAccount('1000000001', 'Europe Account');
        contact = makeContact('Marius', 'Midtvik', 'marius.midtvik@gmail.com', europeAccount);
        rule = makeAssignmentRule(asiaAccount, 'cs.singapore@wilhelmsen.com', contact);

        Test.StartTest ();


        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';

        // Associate case with europe account
        caseObject.AccountId = europeAccount.ID;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
         emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com;dummy@gmail.com';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

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
        Account asiaAccount;
        Account europeAccount;
        Contact contact;
        GlobalAccountAssignmentRule__c rule;

        asiaAccount = makeAccount('1000000000', 'Asia Account');
        europeAccount = makeAccount('1000000001', 'Europe Account');
        contact = makeContact('Marius', 'Midtvik', 'marius.midtvik@gmail.com', europeAccount);
        rule = makeAssignmentRule(asiaAccount, 'cs.singapore@wilhelmsen.com', contact);

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
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com; dummy@gmail.com';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
        // Expect account to be changed to asia
        System.assertEquals(caseObjectAfterUpdate.AccountId, asiaAccount.Id, 'Account is not asia as expected.');
        System.assertEquals(true,caseObjectAfterUpdate.Global_Account_Assignment_Rule_Executed__c, 'The flag Global_Account_Assignment_Rule_Executed__c is not true as expected');
    }

    static testMethod void testCaseHavingMultipleEmailNoRules() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account account;

        account = makeAccount('1000000000', 'Asia Account');

        Test.StartTest ();

        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';
        caseObject.AccountId = account.ID;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@gmail.com';
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@gmail.com';
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
        System.assertEquals(caseObjectAfterUpdate.AccountId, account.Id, 'Account has been changed.');
        System.assertEquals(true,caseObjectAfterUpdate.Global_Account_Assignment_Rule_Executed__c, 'The flag Global_Account_Assignment_Rule_Executed__c is not true as expected');
        assertCaseHasCaseComment(caseObject.ID, 'No rules found matching from marius.midtvik@gmail.com to cs.singapore@wilhelmsen.com will not evaluate rules');
    }


    static testMethod void testCaseHavingEmailWithRulesNotMatching() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account asiaAccount;
        Account europeAccount;
        Contact contact;
        GlobalAccountAssignmentRule__c rule;

        asiaAccount = makeAccount('1000000000', 'Asia Account');
        europeAccount = makeAccount('1000000001', 'Europe Account');
        contact = makeContact('Marius', 'Midtvik', 'marius.midtvik@gmail.com', europeAccount);
        rule = makeAssignmentRule(asiaAccount, 'cs.singapore@wilhelmsen.com', contact);

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
        emailMessage.ToAddress = 'cs.norway@wilhelmsen.com';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
        // Expect account to be unchanged as europe
        System.assertEquals(caseObjectAfterUpdate.AccountId, europeAccount.Id, 'Account is not europe as expected.');
        System.assertEquals(true,caseObjectAfterUpdate.Global_Account_Assignment_Rule_Executed__c, 'The flag Global_Account_Assignment_Rule_Executed__c is not true as expected');
    }


    static testMethod void testCaseHavingEmailWithRulesMatching() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account asiaAccount;
        Account europeAccount;
        Contact contact;
        GlobalAccountAssignmentRule__c rule;

        asiaAccount = makeAccount('1000000000', 'Asia Account');
        europeAccount = makeAccount('1000000001', 'Europe Account');
        contact = makeContact('Marius', 'Midtvik', 'marius.midtvik@gmail.com', europeAccount);
        rule = makeAssignmentRule(asiaAccount, 'cs.singapore@wilhelmsen.com', contact);

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
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
        // Expect account to be changed to asia
        System.assertEquals(caseObjectAfterUpdate.AccountId, asiaAccount.Id, 'Account is not asia as expected.');
        System.assertEquals(true,caseObjectAfterUpdate.Global_Account_Assignment_Rule_Executed__c, 'The flag Global_Account_Assignment_Rule_Executed__c is not true as expected');
    }


    static testMethod void testCaseHavingEmailNoRules() {
        Case caseObject;
        Case caseObjectAfterUpdate;
        List<Case> cases;
        EmailMessage emailMessage;
        Account account;

        account = makeAccount('1000000000', 'Asia Account');

        Test.StartTest ();



        caseObject = new Case();
        caseObject.status = 'New';
        caseObject.origin = 'Email';
        caseObject.AccountId = account.ID;

        insert caseObject;

        emailMessage = new EmailMessage();
        emailMessage.Incoming = true;
        emailMessage.FromAddress = 'marius.midtvik@gmail.com';
        emailMessage.ToAddress = 'cs.singapore@wilhelmsen.com';
        emailMessage.ParentId = caseObject.ID;

        insert emailMessage;

        caseObject = getCase(caseObject.ID);

        cases = new List<Case>();
        cases.add(caseObject);

        Test.stopTest();

        caseObjectAfterUpdate = getCase(caseObject.ID);
        System.assertEquals(caseObjectAfterUpdate.AccountId, account.Id, 'Account has been changed.');
        System.assertEquals(true,caseObjectAfterUpdate.Global_Account_Assignment_Rule_Executed__c, 'The flag Global_Account_Assignment_Rule_Executed__c is not true as expected');
        assertCaseHasCaseComment(caseObject.ID, 'No rules found matching from marius.midtvik@gmail.com to cs.singapore@wilhelmsen.com will not evaluate rules');
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
        System.assertEquals(false,caseObjectAfterUpdate.Global_Account_Assignment_Rule_Executed__c);

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
        System.assertEquals(true,caseObjectAfterUpdate.Global_Account_Assignment_Rule_Executed__c);

        assertCaseHasCaseComment(caseObject.ID, 'Case has status NewX that is not allowed for Global Account Assignment');
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
        System.assertEquals(true,caseObjectAfterUpdate.Global_Account_Assignment_Rule_Executed__c);

        assertCaseHasCaseComment(caseObject.ID, 'Case has origin EmailX that is not allowed for Global Account Assignment');
    }

    static Case getCase(ID caseId) {
        List<Case> cases;

        cases = [SELECT ID, Global_Account_Assignment_Rule_Executed__c, status, origin, casenumber, AccountId from Case where ID = :caseId];

        System.assertEquals(1,cases.size());
        return cases[0];

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
            Account account) {
        Contact contact;

        contact = new Contact();
        contact.LastName = lastName;
        contact.FirstName = firstName;
        contact.Email = email;
        contact.AccountId = account.ID;
        contact.Phone = '+47 926 00 207';
        contact.function__c = 'Other';

        insert contact;

        return contact;
    }

    static GlobalAccountAssignmentRule__c makeAssignmentRule(Account account,
            String toEmail,
            Contact contact) {
        GlobalAccountAssignmentRule__c rule;

        rule = new GlobalAccountAssignmentRule__c();
        rule.account__c = account.ID;
        rule.Enabled__c = true;
        rule.ToAddress__c = toEmail;
        rule.Contact__c = contact.ID;

        insert rule;

        return rule;
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

}