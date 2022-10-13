/*
 * (C) 2015 Finn Arild Aasheim, Fluido Oy. No liabilities accepted.
 *
 * Base class containing all the calculations needed for PCE
 *
 */
public abstract class PCEBase {

	// Chart data
	public class ChartData {
		public Integer count {get;set;}
		public Double price {get;set;}
		public ChartData(Integer c, Decimal p) {
			count = c;
			price = p;
		}
	}

	// neccessary base data for selections
	public Set<String> ports {
		get {
			if (ports == null) {
				ports = new Set<String>();
				for (AggregateResult pg:[select Port_name__c from PCE_DA__c group by Port_name__c]) {
					ports.add((String)pg.get('Port_name__c'));
				}
			}
			return ports;
		}
		private set;
	}

	public Integer outlierPerc {
		get {
			if (outlierPerc == null) {
				outlierPerc = Integer.valueOf(Label.PCEOutliers);
			}
			return outlierPerc;
		}
		private set;
	}
	public Integer minimumEntries {
		get {
			if (minimumEntries == null)  {
				minimumEntries = Integer.valueOf(Label.PCEMinimumEntries);
			}
			return minimumEntries;
		}
		private set;
	}
	public Integer chartDiv {
		get {
			if (chartDiv == null) {
				chartDiv = Integer.valueOf(Label.PCEChartBars);
			}
			return chartDiv;
		}
		private set;
	}

	public Set<String> cargotypes {
		get {
			if (cargotypes == null) {
				cargotypes = new Set<String>();
				for (AggregateResult ct:[select Cargo_Group__c from PCE_DA__c group by Cargo_Group__c]) {
					cargotypes.add((String)ct.get('Cargo_Group__c'));
				}
			}
			return cargotypes;
		}
		private set;
	}

	//public Set<String> 
	// Necessary selectors - all these must be set for calculations to go through
	public String selPort {get;set;}
	public String selLimit {
		get {
			if (selLimit == null) {
				selLimit = '3Y';
			}
			return selLimit;
		}
		set;
	}
	public Decimal selVesselLo {get;set;} 
	public Decimal selVesselHi {get;set;} 
	public String selAgent {get;set;}
	public String selCargotype {get;set;}
	public Integer selMonth { 
		get;
		set {
			if (value == null) {
				selMonth = 0;
			} else {
				selMonth = Integer.valueOf(value); // Necessary to get number out of selectedoption
			}
		} 
	} // 1-12 (not 0-11) 0 = error or not selected

	public DateTime fromDate {
		get {
			if (selLimit == '3M') { return DateTime.now().addMonths(-3); }
			if (selLimit == '6M') { return DateTime.now().addMonths(-6); }
			if (selLimit == '12M') { return DateTime.now().addMonths(-12); }
			if (selLimit == '2Y') { return DateTime.now().addYears(-2); }
			return DateTime.now().addYears(-3);
		}
		private set;
	}
	private Boolean dataFilled() {
		if (selPort == null || selVesselLo == null || selVesselHi == null ||
			selAgent == null || selCargotype == null ) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You need to fill in all the fields'));			
			return false;			
		}
		return true;
	}
	// DA Data
	public Double daMean {get;set;}
	public Double daDeviation {get;set;}
	public Integer daNoEntries {get;set;}
	public Integer daNoEntriesShaved {get;set;}
	public Double daBelow80 {get;set;}
	public Boolean daSuccess {
		get {
			if (daSuccess == null) {
				daSuccess = false;
			}
			return daSuccess;
		}
		set;
	}
	public ChartData[] daChartData {get;set;}

	public void calcDAs() {
		// Check data is filled
		if (!dataFilled()) {
			daSuccess = false;
			return;
		}
		Double[] dSet = new Double[]{};

		// Query the data based on filled data
		String query = 'select FDA_AMT_USD__c from PCE_DA__c where ';
		query += 'Port_name__c = \'' + selPort + '\'';
		query += ' AND Vessel_size__c >= ' + String.valueOf(selVesselLo);
		query += ' AND Vessel_size__c <= ' + String.valueOf(selVesselHi);
		query += ' AND Agent_role__c = \'' + selAgent + '\'';
		query += ' AND Cargo_Group__c = \'' + selCargotype + '\'';
		query += ' AND Arrival_Date__c >= ' + fromDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
		query += ' AND FDA_AMT_USD__c > 0.0 order by FDA_AMT_USD__c';

		PCE_DA__c[] daData = Database.query(query);

		daNoEntries = daData.size();

		Integer shaveCount = (daNoEntries*outlierPerc) / 100;
		daNoEntriesShaved = daNoEntries - (shaveCount*2);

		if (daNoEntries < minimumEntries +(shaveCount*2)) {
			daSuccess = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'We found less than ' + String.valueOf(minimumEntries) + ' DA data with this selection'));
			return;
		}

		daChartData = new ChartData[]{};

		Double minVal = Double.valueOf(daData[0].FDA_AMT_USD__c);
		Double maxVal = Double.valueOf(daData[daNoEntries-1].FDA_AMT_USD__c);
		for (Integer i=0;i<chartDiv;i++) {
			daChartData.add(new ChartData(
				0,
				minVal+( (maxVal-minVal)/(Double)chartDiv ) * Double.valueOf(i)
				));
		}

		Double point80 = daNoEntries * 0.8;
		daMean = 0.0;
		daBelow80 = null;
		for (Integer i=0; i<daNoEntries;i++) {
			if (i+1 >= point80 && daBelow80 == null) {
				daBelow80 = daData[i].FDA_AMT_USD__c;
			}
			if (i >= shaveCount && i < daNoEntries-shaveCount) { // Shave away outliers
				daMean = ((daMean * i) + daData[i].FDA_AMT_USD__c) / (i+1.0); // running average
				dSet.add(daData[i].FDA_AMT_USD__c);
				// Get it into graph data
				for (Integer n=0;n<chartDiv;n++) { 
					if (daData[i].FDA_AMT_USD__c <= daChartData[n].price) {
						daChartData[n].count += 1;
						break;
					}
					if (n == chartDiv-1) {
						daChartData[n].count += 1;
					}
				}
			}
		}
		daDeviation = AdvancedMath.standardDeviation(dSet, daMean);
		daSuccess = true;
	}

	// Port call data
	public Double pcMean {get;set;}
	public Double pcDeviation {get;set;}
	public Integer pcNoEntries {get;set;}
	public Integer pcNoEntriesShaved {get;set;}
	public Double pcBelow80 {get;set;}
	public Boolean pcSuccess {get;set;}
	public ChartData[] pcChartData {get;set;}
	public void calcPortCalls() {
		// Check data is filled
		if (!dataFilled()) {
			daSuccess = false;
			return;
		}
		Double[] dSet = new Double[]{};

		// Query the data based on filled data
		String query = 'select Laytime__c from PCE_Port_Call__c where ';
		query += 'Port_name__c = \'' + selPort + '\'';
		query += ' AND Vessel_size__c >= ' + String.valueOf(selVesselLo);
		query += ' AND Vessel_size__c <= ' + String.valueOf(selVesselHi);
		query += ' AND Agent_role__c = \'' + selAgent + '\'';
		query += ' AND Cargo_Group__c = \'' + selCargotype + '\'';
		query += ' AND Laytime__c > 0.0';
		query += ' AND Arrival_Date__c >= ' + fromDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
		if (selMonth > 0) {
			query += ' AND 	(CALENDAR_MONTH(Arrival_Date__c) = ' + selMonth;
			query += ' or CALENDAR_MONTH(Departure_Date__c) = ' + selMonth+ ')';
		}
		query += ' order by Laytime__c';
		System.debug('## query: ' + query);

		PCE_Port_Call__c[] pcData = Database.query(query);

		pcNoEntries = pcData.size();

		Integer shaveCount = (pcNoEntries*outlierPerc) / 100;
		pcNoEntriesShaved = pcNoEntries - (shaveCount*2);

		if (pcNoEntries < minimumEntries+(shaveCount*2)) {
			pcSuccess = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'We found less than ' + String.valueOf(minimumEntries) + ' Port Call data with this selection'));
			return;
		}
		pcChartData = new ChartData[]{};

		Double minVal = Double.valueOf(pcData[0].Laytime__c);
		Double maxVal = Double.valueOf(pcData[pcNoEntries-1].Laytime__c);
		for (Integer i=0;i<chartDiv;i++) {
			pcChartData.add(new ChartData(
				0,
				minVal + ( (maxVal-minVal)/(Double)chartDiv ) * Double.valueOf(i)
				));
		}
		Double point80 = pcNoEntries * 0.8;
		pcMean = 0.0;
		pcBelow80 = null;
		System.debug('### shaveCount: ' + shaveCount);
		System.debug('### pcNoEntries: ' + pcNoEntries);
		for (Integer i=0; i<pcNoEntries; i++) {
			System.debug('### laytime1: ' + pcData[i].Laytime__c);
			if (i+1 >= point80 && pcBelow80 == null) {
				pcBelow80 = pcData[i].Laytime__c;
			}
			if (i >= shaveCount && i < pcNoEntries-shaveCount) {
				pcMean = ((pcMean * i) + pcData[i].Laytime__c) / (i+1.0); // running average
				dSet.add(pcData[i].Laytime__c);
				// Get it into graph data
				System.debug('### laytime2: ' + pcData[i].Laytime__c);
				for (Integer n=0;n<chartDiv;n++) {
					System.debug('### price: ' + pcChartData[n].price);
					if (pcData[i].Laytime__c <= pcChartData[n].price) {
						pcChartData[n].count += 1;
						break;
					}
					if (n == chartDiv-1) {
						pcChartData[n].count += 1;
					}
				}
			}
		}
		pcDeviation = AdvancedMath.standardDeviation(dSet, pcMean);
		pcSuccess = true;
	}

	// Cargo data
	public Double cgMean {get;set;}
	public Double cgDeviation {get;set;}
	public Integer cgNoEntries {get;set;}
	public Integer cgNoEntriesShaved {get;set;}
	public Double cgBelow80 {get;set;}
	public Boolean cgSuccess {get;set;}
	public ChartData[] cgChartData {get;set;}
	public void calcCargoData() {
		// Check data is filled
		if (!dataFilled()) {
			daSuccess = false;
			return;
		}
		Double[] dSet = new Double[]{};

		// Query the data based on filled data
		String query = 'select Number_of_hours__c from PCE_Cargo__c where ';
		query += 'Port_name__c = \'' + selPort + '\'';
		query += ' AND Vessel_size__c >= ' + String.valueOf(selVesselLo);
		query += ' AND Vessel_size__c <= ' + String.valueOf(selVesselHi);
		query += ' AND Agent_role__c = \'' + selAgent + '\'';
		query += ' AND Cargo_Group__c = \'' + selCargotype + '\'';
		query += ' AND Number_of_hours__c > 0.0';
		query += ' AND COMM_LOAD_OR_DIS__c >= ' + fromDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
		if (selMonth > 0) {
			query += ' AND 	(CALENDAR_MONTH(COMM_LOAD_OR_DIS__c) = ' + selMonth;
			query += ' or CALENDAR_MONTH(COMP_LOAD_OR_DIS__c) = ' + selMonth+ ')';
		}
		query += ' order by Number_of_hours__c';

		PCE_Cargo__c[] cgData = Database.query(query);
		
		cgNoEntries = cgData.size();

		Integer shaveCount = (cgNoEntries*outlierPerc) / 100;
		cgNoEntriesShaved = cgNoEntries - (shaveCount*2);

		if (cgNoEntries < minimumEntries+(shaveCount*2)) {
			cgSuccess = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'We found less than ' + String.valueOf(minimumEntries) + ' cargo operation data with this selection'));
			return;
		}
		cgChartData = new ChartData[]{};

		Double minVal = Double.valueOf(cgData[0].Number_of_hours__c);
		Double maxVal = Double.valueOf(cgData[cgNoEntries-1].Number_of_hours__c);
		for (Integer i=0;i<chartDiv;i++) {
			cgChartData.add(new ChartData(
				0,
				minVal + ( (maxVal-minVal)/(Double)chartDiv ) * Double.valueOf(i)
				));
		}
		Double point80 = cgNoEntries * 0.8;
		cgMean = 0.0;
		cgBelow80 = null;
		for (Integer i=0; i<cgNoEntries; i++) {
			if (i+1 >= point80 && cgBelow80 == null) {
				cgBelow80 = cgData[i].Number_of_hours__c;
			}
			if (i >= shaveCount && i < cgNoEntries-shaveCount) {
				cgMean = ((cgMean * i) + cgData[i].Number_of_hours__c) / (i+1.0); // running average
				dSet.add(cgData[i].Number_of_hours__c);
				// Get it into graph data
				for (Integer n=0;n<chartDiv;n++) {
					if (cgData[i].Number_of_hours__c <= cgChartData[n].price) {
						cgChartData[n].count += 1;
						break;
					}
					if (n == chartDiv-1) { // We are at the end of the chart div without anything happening
						cgChartData[n].count += 1;
					}
				}
			}
		}
		cgDeviation = AdvancedMath.standardDeviation(dSet, cgMean);
		cgSuccess = true;
	}


	// Utility function to return month name by number
	public String monthName(Integer n) {
		if (n == 1) return 'January';
		if (n == 2) return 'February';
		if (n == 3) return 'March';
		if (n == 4) return 'April';
		if (n == 5) return 'May';
		if (n == 6) return 'June';
		if (n == 7) return 'July';
		if (n == 8) return 'August';
		if (n == 9) return 'September';
		if (n == 10) return 'October';
		if (n == 11) return 'November';
		if (n == 12) return 'December';
		return '';
	}

	// Subclass for chart data
	public class Item {
		public Double xval;
	}
}