/*
 * (C) 2015 Finn Arild Aasheim, Fluido Oy. No liabilities accepted.
 * 
 */
public class AccountTriggers {
	public static void lookupAccountOwner(Account[] acs) {
		Set<String> srchStrings = new Set<String>();

		for (Account a:acs) {
			srchStrings.add('%' + a.WMSAcctOwner_ID__c + '%');
		}

		User[] usrs = [select Id, Account_Manager_Code__c from User where Account_Manager_Code__c like :srchStrings];

		Map<String,User> usrMap = new Map<String,User>();
		for (User u:usrs) {
			for (String oid:u.Account_Manager_Code__c.split(';')) {
				usrMap.put(oid, u);
			}
		}

		for (Account a:acs) {
			if (usrMap.containsKey(a.WMSAcctOwner_ID__c)) {
				a.OwnerId = usrMap.get(a.WMSAcctOwner_ID__c).Id;
			}
		}
	}
}