/*
 * (C) 2015 Finn Arild Aasheim, Fluido Oy. No liabilities accepted.
 * 
 */
trigger AccountBefore on Account (before insert, before update) {
	Account[] lookupOwnersFor = new Account[]{};

	for (Account a:Trigger.new) {
		if (Trigger.isInsert) {
			lookupOwnersFor.add(a);
		} else {
			if (Trigger.oldMap.get(a.Id).WMSAcctOwner_ID__c != a.WMSAcctOwner_ID__c) { // Only update when changed
				if (a.WMSAcctOwner_ID__c != null) { // And isn't null
					lookupOwnersFor.add(a);
				}
			}
		}
	}
	if (lookupOwnersFor.size() > 0) {
		AccountTriggers.lookupAccountOwner(lookupOwnersFor);
	}
}