/*
 * (C) 2015 Finn Arild Aasheim, Fluido Oy. No liabilities accepted.
 *
 * Class for the controller, testing base data and containing necessary getters/setters
 *
 */
public class PCETestpageController extends PCEBase {
	public PCETestpageController(ApexPages.StandardController controller) {

	}
	public PCETestpageController() {
		
	}
	public Id accId {
		get {
			if (ApexPages.currentPage().getParameters().containsKey('accId')) {
				return ApexPages.currentPage().getParameters().get('accId');
			}
			return null;
		}
		private set;
	}

	public Id oppId {
		get {
			if (ApexPages.currentPage().getParameters().containsKey('oppId')) {
				return ApexPages.currentPage().getParameters().get('oppId');
			}
			return null;
		}
		private set;		
	}

	public Id repId {
		get {
			if (ApexPages.currentPage().getParameters().containsKey('repId')) {
				return ApexPages.currentPage().getParameters().get('repId');
			}
			return null;
		}
		private set;
	}

	public Boolean storeable {
		get {
			if (oppId != null || accId != null || repId != null) {
				return true;
			}
			return false;
		}
		private set;
	}
	public SelectOption[] portSelection {
		get {
			if (portSelection == null) {
				portSelection = new SelectOption[]{};
				portSelection.add(new SelectOption('', '---- Select Port ----'));
				for (String p:ports) {
					portSelection.add(new SelectOption(p,p));
				}
			}
			return portSelection;
		}
		private set;
	}

	public SelectOption[] cargoSelection {
		get {
			if (cargoSelection == null) {
				cargoSelection = new SelectOption[]{};
				cargoSelection.add(new SelectOption('', '---- Select Cargo Type ----'));
				for (String c:cargotypes) {
					if (c != null) {
						cargoSelection.add(new SelectOption(c,c));
					}
				}
			}
			return cargoSelection;
		}
		private set;
	}

	public void calcIt() {
		calcDAs();
		calcPortCalls();
		calcCargoData();
	}

	public PageReference storeIt() {
		PCE_Report__c rep = new PCE_Report__c(
			Port_name__c = selPort,
			Vessel_size_min__c = selVesselLo,
			Vessel_size_max__c = selVesselHi,
			Agent_role__c = selAgent,
			Cargo__c = selCargoType,
			Month__c = monthName(selMonth),
			DA_Average__c = daMean,
			DA_Deviation__c = daDeviation,
			DA_Entries__c = daNoEntries,
			DA_80__c = daBelow80,
			PC_Average__c = pcMean,
			PC_Deviation__c = pcDeviation,
			PC_Entries__c = pcNoEntries,
			PC_80__c = pcNoEntries,
			CG_Average__c = cgMean,
			CG_Deviation__c = cgDeviation,
			CG_Entries__c = cgNoEntries,
			CG_80__c = cgBelow80
		);
		PageReference ret = null;
		if (accId != null) {
			rep.Account__c = accId;
			ret = new PageReference('/'+accId);
		}
		/*
		if (oppId != null) {
			rep.Opportunity__c = oppId;
			ret = new PageReference('/'+oppId);
		}*/
		upsert rep;
		return ret;
	}
	
}