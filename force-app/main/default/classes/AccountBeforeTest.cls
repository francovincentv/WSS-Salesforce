@isTest
// test class for AccountBefore, AccountTriggers
public class AccountBeforeTest {
        static testMethod void testLookupAccountManager() {
        
        Account testAccount = new Account(name='Test Account');
        testAccount.WMSAcctOwner_ID__c = 'IFS1';
        
        Account testAccount1 = new Account(name='Test Account1');
        testAccount1.WMSAcctOwner_ID__c = '123';
        insert new List<Account> {testAccount, testAccount1};
        
      	Account[] lookupOwnersFor = new Account[]{};
		lookupOwnersFor.add(testAccount);
        lookupOwnersFor.add(testAccount1);
        

        Profile pf= [Select Id from profile where Name='WSS - Sales']; 
        
        User testUser = new User();
        testUser.Account_Manager_Code__c = 'IFS1';
        testUser.Username = 'TestUserFirst@test.com';
        testUser.LastName = 'User';
        testUser.Email= 'TestUserFirst@test.com';
        testUser.Alias = 'test';
        testUser.CommunityNickname ='tester';
        testUser.TimeZoneSidKey ='Europe/Paris';
        testUser.LocaleSidKey = 'en_GB';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.ProfileId = pf.Id;
        testUser.LanguageLocaleKey = 'en_US';
        insert testUser;
      
        AccountTriggers.lookupAccountOwner(lookupOwnersFor);
        Account updateTestAccount = [select id, WMSAcctOwner_ID__c from Account where name='Test Account' and WMSAcctOwner_ID__c = 'IFS1' limit 1 ];
        updateTestAccount.WMSAcctOwner_ID__c = 'IFS2';
        //update updateTestAccount;
        
        Account updateTestAccount1 = [select id, WMSAcctOwner_ID__c from Account where name='Test Account1' and WMSAcctOwner_ID__c = '123' limit 1 ];
        updateTestAccount1.WMSAcctOwner_ID__c = '1234';
        //update updateTestAccount1;
        update  new List<Account> {updateTestAccount, updateTestAccount1};

        Account  []  updatedAccount = [select id, WMSAcctOwner_ID__c from Account where name='Test Account' limit 1];
        System.assertEquals('IFS2', updatedAccount[0].WMSAcctOwner_ID__c);
        
    }
    
}