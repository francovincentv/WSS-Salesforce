/*
 * (C) 2015 Finn Arild Aasheim, Fluido Oy. No liabilities accepted.
 * 
 */
trigger VesselBefore on Vessel__c (before insert, before update) {
	Vessel__c[] toIHSFor = new Vessel__c[]{}; // To which to lookup IHS Companies for
	Vessel__c[] toIFSFor = new Vessel__c[]{}; // Not to be confused with the above, which to lookup payer accounts for

	for (Vessel__c v:Trigger.new) {
		if (Trigger.isInsert) {
			if (v.Default_Payer_Account_ID_del__c != null) {
				toIFSFor.add(v);
			}
			if (v.IHS_Builder_ID_del__c != null || v.IHS_Manager_ID__c != null || v.IHS_Operator_ID__c != null ||
				v.IHS_Owner_ID__c != null || v.IHS_P_and_I_ID__c != null || v.IHS_Registered_Owner_ID__c != null ||
				v.IHS_Technical_Manager_ID__c != null) {
				toIHSFor.add(v);
			}
		} else if (Trigger.isUpdate) {
			Vessel__c old = Trigger.oldMap.get(v.Id);
			if (old.Default_Payer_Account_ID_del__c != v.Default_Payer_Account_ID_del__c && v.Default_Payer_Account_ID_del__c != null) {
				toIFSFor.add(v);
			}
			if ((v.IHS_Builder_ID_del__c != null && old.IHS_Builder_ID_del__c != v.IHS_Builder_ID_del__c ) ||
				(v.IHS_Manager_ID__c != null && old.IHS_Manager_ID__c != v.IHS_Manager_ID__c ) || 
				(v.IHS_Operator_ID__c != null && old.IHS_Operator_ID__c != v.IHS_Operator_ID__c ) ||
				(v.IHS_Owner_ID__c != null && old.IHS_Owner_ID__c != v.IHS_Owner_ID__c ) ||
				(v.IHS_P_and_I_ID__c != null && old.IHS_P_and_I_ID__c != v.IHS_P_and_I_ID__c ) || 
				(v.IHS_Registered_Owner_ID__c != null && old.IHS_Registered_Owner_ID__c != v.IHS_Registered_Owner_ID__c ) ||
				(v.IHS_Technical_Manager_ID__c != null && old.IHS_Technical_Manager_ID__c != v.IHS_Technical_Manager_ID__c )
			) {
				toIHSFor.add(v);
			}
		}
	}

	if (toIFSFor.size() > 0) {
		VesselTriggers.lookupIFSFor(toIFSFor);
	}

	if (toIHSFor.size() > 0) {
		VesselTriggers.lookupIHSFor(toIHSFor);
	}
}