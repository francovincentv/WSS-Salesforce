/*
 * (C) 2015 Finn Arild Aasheim, Fluido Oy. No liabilities accepted.
 * 
 */
@isTest
private class AccountTriggersTests
{

	/*@isTest
	private static void testLookupAccountManager() {
    	UserRole[] rls = [select Id from UserRole where DeveloperName = 'AccountManagerEASTSOUTHAFRICA'];
		
		// Create users 
		Profile pf = [select Id from Profile where Name = 'WSS - International Sales & Head Office'];

		//Create two different Users
		User[] usrs = new User[]{
			new User(email='odduser@testorg.com', emailencodingkey='UTF-8', lastname='Testing', ProfileId=pf.Id,
				languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles',
				username='odd@i.no', Alias='oddern', CommunityNickname='oddie', UserRoleId=rls[0].Id,
				Account_Manager_Code__c='NO001;NO003;NO005;NO007;NO009'),
			new User(email='evenuser@testorg.com', emailencodingkey='UTF-8', lastname='Testing', ProfileId=pf.Id,
				languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles',
				username='even@i.no', Alias='evenrud', CommunityNickname='evenie', UserRoleId=rls[0].Id,
				Account_Manager_Code__c='NO002;NO004;NO006;NO008')
		};
		insert usrs;

		Account[] accs = new Account[]{
			new Account(Name='oddball', AccountNumber='1000000001', WMSAcctOwner_ID__c='NO005'),
			new Account(Name='evenball', AccountNumber='1000000002', WMSAcctOwner_ID__c='NO002'),
			new Account(Name='missball', AccountNumber='1000000003', WMSAcctOwner_ID__c='NO067'),
			new Account(Name='noball', AccountNumber='1000000004')
		};
		insert accs;
		User curUser = [select Alias from User where Id = :UserInfo.getUserId()];
		accs = [select Name, owner.Alias from Account];
		for (Account a:accs) {
			if (a.Name == 'oddball') System.assertEquals('oddern', a.Owner.Alias);
			if (a.Name == 'evenball') System.assertEquals('evenrud', a.Owner.Alias);
			if (a.Name == 'missball') System.assertEquals(curUser.Alias, a.Owner.Alias);
			if (a.Name == 'noball') System.assertEquals(curUser.Alias, a.Owner.Alias);
		}
		for (Account a:accs) {
			if (a.Name == 'oddball') a.WMSAcctOwner_ID__c = 'NO008';
			if (a.Name == 'evenball') a.WMSAcctOwner_ID__c = 'NO007';
			if (a.Name == 'missball') a.WMSAcctOwner_ID__c = 'NO006';
			if (a.Name == 'noball') a.WMSAcctOwner_ID__c = 'NO005';
		}
		update accs;
		accs = [select Name, owner.Alias from Account];
		for (Account a:accs) {
			if (a.Name == 'oddball') System.assertEquals('evenrud', a.Owner.Alias);
			if (a.Name == 'evenball') System.assertEquals('oddern', a.Owner.Alias);
			if (a.Name == 'missball') System.assertEquals('evenrud', a.Owner.Alias);
			if (a.Name == 'noball') System.assertEquals('oddern', a.Owner.Alias);
		}

	}
*/
}