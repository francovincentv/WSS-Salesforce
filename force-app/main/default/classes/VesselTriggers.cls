/*
 * (C) 2015 Finn Arild Aasheim, Fluido Oy. No liabilities accepted
 *
 * Handles vessel functionalities.
 */ 
public class VesselTriggers {
/*
	public static void createOppsFor(Vessel__c[] weasels) {

		// Query vessels again to get the related fields we need
		Map<Id, Vessel__c> vslMap = new Map<Id, Vessel__c>(weasels); // quickie to get the ids
		vslMap = new Map<Id, Vessel__c>([
			select Vessel_sub_type__c, Gt__c, Status__c, Due_or_delivered__c, Next_Dry_Dock_Date__c, Statcode5__c, Name,
			       Default_Account__r.Name, Default_Account__c, Default_Account__r.OwnerId, 
			       Manager_Account__c
			  from Vessel__c
			 where Id in :vslMap.keySet()
			]);

		// Query any existing opportunities for the vessels
		Opportunity[] xistOpps = [select Vessel__c, CloseDate 
									from Opportunity
								   where Vessel__c in :vslMap.keySet()];

		Vessel__c[] updVessels = new Vessel__c[]{};
		Opportunity[] updOpps = new Opportunity[]{};

		for (Opportunity o:xistOpps) {
			System.debug('### xistOpp: ' + o);
			Vessel__c v = vslMap.get(o.Vessel__c);
			if (v == null) {
				continue;
			}
			// If status is "On Order"
				// If opportunity exists in pending - not started 
					// Update date (remove from vslMap)
				// If opportunity exists at all
					// Remove from vslMap so it doesn't create a new opportunity (opp should already exist)
			// If status is Any Other (see Nostatuses in trigger)
				// If opportunity exists in pending - not started
					// update date (remove from vslMap)
				// If opportunity exists in any stages which are not Closed something
					// Remove from vslMap (do not create new opportunity).

			// TODO when it comes to updates, this should only update the latest 'Pending - Not Started'
			Date cDate = v.Status__c == 'On Order' ? v.Due_or_delivered__c : v.Next_Dry_Dock_Date__c;
			System.debug('### cDate: ' + cDate);
			if (o.CloseDate.addMonths(-12) <= cDate &&
				o.CloseDate.addMonths(12) >= cDate) {
				updVessels.add(vslMap.remove(v.Id));
				updOpps.add(o);
			}
		}

		VesselTriggers.updateOppsFor(updVessels, updOpps);

		Opportunity[] opps = VesselTriggers.createNewBuildOpportunitiesFor(vslMap.values());
		insert opps;

		// TODO Create a targeted vessel object for the connection.

		OpportunityLineItem[] olis = createOpportunityProductsFor(opps, weasels);
		insert olis;
	}

	public static void updateOppsFor(Vessel__c[] weasels, Opportunity[] opps) {
		// First just update the close dates
		Map<Id, Opportunity[]> vslOppsMap = new Map<Id, Opportunity[]>();
		
		Opportunity[] toUpdate = new Opportunity[]{};

		for (Opportunity o:opps) {
			if (!vslOppsMap.containsKey(o.Vessel__c)) {
				vslOppsMap.put(o.Vessel__c, new Opportunity[]{});
			}
			vslOppsMap.get(o.Vessel__c).add(o);
		}
		for (Vessel__c v:weasels) {
			for (Opportunity o:vslOppsMap.get(v.Id)) {
				Date cDate = v.Status__c == 'On Order' ? v.Due_or_delivered__c : v.Next_Dry_Dock_Date__c;
				if (o.CloseDate != cDate) {
					o.CloseDate = cDate;
					toUpdate.add(o);
				}
			}
		}
		// Just update if we need to
		if (toUpdate.size() > 0) {
			update toUpdate;
		}
	}

	public static Opportunity[] createNewBuildOpportunitiesFor(Vessel__c[] weasels) {
		// Creates and returns opportunities from a list of vessels
		Opportunity[] ret = new Opportunity[]{};

		// Create opportunities for vessels
		for (Vessel__c v:weasels) {
			Date cDate = v.Status__c == 'On Order' ? v.Due_or_delivered__c : v.Next_Dry_Dock_Date__c;
			String namepart = v.Status__c == 'On Order' ? 'New Build' : 'Dry Dock';
			Id accId = v.Default_Account__c;
			if (accId == null) {
				accId = v.Manager_Account__c;
			}
			Opportunity o = new Opportunity(
					Name=namepart + ' - ' + v.Name + ' - ' + String.valueOf(cDate.year()),
					AccountId=accId,
					CloseDate=cDate,
					OwnerId=v.Default_Account__r.OwnerId,
					StageName='Pending - Not Started',
					Vessel__c = v.Id
				);
			ret.add(o);
		}
		return ret;

	}

	public static OpportunityLineItem[] createOpportunityProductsFor(Opportunity[] opps, Vessel__c[] weasels) {
		// Make a neat vessel map
		Map<Id, Vessel__c> vMap = new Map<Id, Vessel__c>(weasels);

		// Creates and returns olis for certain opportunities based on vessels
		OpportunityLineItem[] olis = new OpportunityLineItem[]{};

		Set<String> statcodes = new Set<String>();
		Set<String> scenarios = new Set<String>();
		Map<String, PricebookEntry> pbeMap = new Map<String, PricebookEntry>();
		Map<String, Vessel_Product__c[]> vpMap = new Map<String, Vessel_Product__c[]>();

		// Limit the query to only ask for the vessel products we need
		for (Vessel__c v:weasels) {
			statcodes.add(v.Statcode5__c);
			if (v.Status__c == 'On Order') {
				scenarios.add('New build');
			} else if (v.Status__c == 'Delivered') {
				scenarios.add('Dry-docking');
			}
		}
		System.debug('### scenarios: ' + scenarios);
		System.debug('### statcodes: ' + statcodes);
		Vessel_Product__c[] vps = [select Product__r.ProductCode, Gt_category__c, Id, Interval__c, Name, OwnerId, Price__c, Product__c,
										  Product_Code__c, Quantity__c, Scenario__c, VesselStatcode5__c
									 from Vessel_Product__c
									where Scenario__c in :scenarios
									  and VesselStatcode5__c in :statcodes];

		// Loop and get the product codes and map vessel products after Statcode5
		for (Vessel_Product__c vp:vps) {
			pbeMap.put(vp.Product_Code__c, null);
			if (!vpMap.containsKey(vp.VesselStatcode5__c)) {
				vpMap.put(vp.VesselStatcode5__c, new Vessel_Product__c[]{});
			}
			vpMap.get(vp.VesselStatcode5__c).add(vp);
		}
		if (vpMap.size() == 0) {
			return olis;
		}
		PricebookEntry[] pbes = [select Id, UnitPrice, ProductCode
								   from PricebookEntry 
								  where ProductCode in :pbeMap.keySet()];
		// Clear and re-enter them into the map.
		pbeMap.clear();
		for (PricebookEntry pbe:pbes) {
			pbeMap.put(pbe.ProductCode, pbe);
		}

		// map them up after Vessel sub types
		
		//Map<String, PricebookEntry[]> pbMap = new Map<String, PricebookEntry[]>();
		//for (PricebookEntry pb:pbes) {
		//	if (!pbMap.containsKey(pb.Product2.Vessel_sub_type__c)) {
		//		pbMap.put(pb.Product2.Vessel_sub_type__c, new PricebookEntry[]{});
		//	}
		//	pbMap.get(pb.Product2.Vessel_sub_type__c).add(pb);
		//}
		
		for (Opportunity o:opps) {
			Vessel__c v = vMap.get(o.Vessel__c);
			System.debug('### v: ' + v);
			System.debug('### vpMap: ' + vpMap);
			for (Vessel_Product__c vp:vpMap.get(v.Statcode5__c)) {
				if (!pbeMap.containsKey(vp.Product__r.ProductCode)) { // If product doesn't exist in standard pricebook, skip
					continue;
				}
				String[] tons = vp.Gt_category__c.split('-');
				Integer tonL = Integer.valueOf(tons[0]);
				Integer tonH = Integer.valueOf(tons[1]);
				Integer vTon = Integer.valueOf(v.Gt__c);
				if (vTon >= tonL && vTon <= tonH) {
					OpportunityLineItem oli = new OpportunityLineItem(
							OpportunityId = o.Id,
							PricebookEntryId = pbeMap.get(vp.Product__r.ProductCode).Id,
							UnitPrice = vp.Price__c,
							Quantity = vp.Quantity__c
						);
					olis.add(oli);
				}
			}
		}
		return olis;
	}
*/
	// For Vessel, if Default Payer Account ID is set (on insert) or has changed, update Default Payer Account
	public static void lookupIFSFor(Vessel__c[] vls) {
		Map<String, Account> IFSIds = new Map<String,Account>();
		for (Vessel__c v:vls) {
			if (!IFSIds.containsKey(v.Default_Payer_Account_ID_del__c)) {
				IFSIds.put(v.Default_Payer_Account_ID_del__c, null);	
			}
		}
		Account[] acs = [select Id, IFS_Account_Id__c, ParentId from Account where IFS_Account_Id__c in :IFSIds.keySet()];

		for (Account a:acs) {
			IFSIds.put(a.IFS_Account_Id__c, a);
		}

		for (Vessel__c v:vls) {
			if (IFSIds.containsKey(v.Default_Payer_Account_ID_del__c)) {
				Account a = IFSIds.get(v.Default_Payer_Account_ID_del__c);
				if (a != null) {
					v.Default_Payer_Account__c = a.Id;
					if (a.ParentId == null) {
						v.Default_Account__c = null;
					} else {
						v.Default_Account__c = a.ParentId;
					}
				} else {
					v.Default_Payer_Account__c = null;
					v.Default_Account__c = null;
				}

			}
		}
	}

	// For Vessel, if Builder, Manager, Operator, Owner, P&I, Registered owner or Technical manager is set (on insert) 
	// or has changed, update IHS Fairplay company
	public static void lookupIHSFor(Vessel__c[] vls) {
		Map<String, IHS_Fairplay_Company__c> IHSIds = new Map<String, IHS_Fairplay_Company__c>();
		for (Vessel__c v:vls) {
			if (v.IHS_Builder_ID_del__c != null) { IHSIds.put(v.IHS_Builder_ID_del__c, null); }
			if (v.IHS_Manager_ID__c != null) { IHSIds.put(v.IHS_Manager_ID__c, null); }
			if (v.IHS_Operator_ID__c != null) { IHSIds.put(v.IHS_Operator_ID__c, null); }
			if (v.IHS_Owner_ID__c != null) { IHSIds.put(v.IHS_Owner_ID__c, null); }
			if (v.IHS_P_and_I_ID__c != null) { IHSIds.put(v.IHS_P_and_I_ID__c, null); }
			if (v.IHS_Registered_Owner_ID__c != null) { IHSIds.put(v.IHS_Registered_Owner_ID__c, null); }
			if (v.IHS_Technical_Manager_ID__c != null) { IHSIds.put(v.IHS_Technical_Manager_ID__c, null); }
		}

		IHS_Fairplay_Company__c[] fpcs = [select Id, IHS_Company_ID__c from IHS_Fairplay_Company__c where IHS_Company_ID__c in :IHSIds.keySet()];

		IHSIds.clear();
		for (IHS_Fairplay_Company__c fpc:fpcs) {
			if (fpc != null) {
				IHSIds.put(fpc.IHS_Company_ID__c, fpc);
			}
		}

		for (Vessel__c v:vls) {
			if (v.IHS_Builder_ID_del__c != null && IHSIds.containsKey(v.IHS_Builder_ID_del__c)) { v.IHS_Builder__c = IHSIds.get(v.IHS_Builder_ID_del__c).Id; }
			if (v.IHS_Manager_ID__c != null && IHSIds.containsKey(v.IHS_Manager_ID__c)) { v.IHS_Manager__c = IHSIds.get(v.IHS_Manager_ID__c).Id; }
			if (v.IHS_Operator_ID__c != null && IHSIds.containsKey(v.IHS_Operator_ID__c)) { v.IHS_Operator__c = IHSIds.get(v.IHS_Operator_ID__c).Id; }
			if (v.IHS_Owner_ID__c != null && IHSIds.containsKey(v.IHS_Owner_ID__c)) { v.IHS_Owner__c = IHSIds.get(v.IHS_Owner_ID__c).Id; }
			if (v.IHS_P_and_I_ID__c != null && IHSIds.containsKey(v.IHS_P_and_I_ID__c)) { v.IHS_P_I_Club__c = IHSIds.get(v.IHS_P_and_I_ID__c).Id; }
			if (v.IHS_Registered_Owner_ID__c != null && IHSIds.containsKey(v.IHS_Registered_Owner_ID__c)) { v.IHS_Registered_Owner__c = IHSIds.get(v.IHS_Registered_Owner_ID__c).Id; }
			if (v.IHS_Technical_Manager_ID__c != null && IHSIds.containsKey(v.IHS_Technical_Manager_ID__c)) { v.IHS_Technical_Manager__c = IHSIds.get(v.IHS_Technical_Manager_ID__c).Id; }
		}
	}
}