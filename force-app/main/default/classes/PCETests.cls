/*
 * (C) 2015 Finn Arild Aasheim, Fluido Oy. No liabilities accepted.
 *
 * All PCE related tests
 *
 */
@isTest
private class PCETests {
	
	@isTest
	static void testAll() {
		PCE_DA__c[] das = new PCE_DA__c[]{};
		PCE_Port_Call__c[] pcs = new PCE_Port_Call__c[]{};
		PCE_Cargo__c[] cgs = new PCE_Cargo__c[]{};
		for (Integer i=0;i<20;i++) {
			das.add(new PCE_DA__c(
				Port_Name__c='Porten', 
				FDA_AMT_USD__c=22.3, 
				Vessel_Size__c=56.0, 
				Agent_Role__c='Full Agent',
				Cargo_Group__c='Dagroup'
				));

			pcs.add(new PCE_Port_Call__c(
				Port_Name__c='Porten',
				Vessel_Size__c=56.0,
				Agent_Role__c='Full Agent',
				Cargo_Group__c='Dagroup',
				Arrival_Date__c=Datetime.now(),
				Departure_Date__c=Datetime.now().addDays(2)
				));
			cgs.add(new PCE_Cargo__c(
				Port_Name__c = 'Porten',
				Vessel_Size__c=56.0,
				Agent_Role__c='Full Agent',
				Cargo_Group__c='Dagroup',
				COMM_LOAD_OR_DIS__c=Datetime.now(),
				COMP_LOAD_OR_DIS__c=Datetime.now().addDays(2)
				));
		}
		insert pcs;
		insert cgs;
		insert das;
		PCE_Cargo__c ncg = cgs[0].clone();
		ncg.COMM_LOAD_OR_DIS__c=Datetime.now().addDays(-12);
		ncg.COMP_LOAD_OR_DIS__c=Datetime.now().addDays(-1);
		insert ncg;

		Test.startTest();
		PCETestpageController cnt = new PCETestpageController();
		System.debug(cnt.portSelection);
		System.debug(cnt.cargoSelection);
		cnt.selPort = 'Porten';
		cnt.selVesselLo = 20.0;
		cnt.selVesselHi = 80.0;
		cnt.selAgent = 'Full Agent';
		cnt.selCargoType = 'Dagroup';
	//	cnt.selMonth = Date.today().month();

		cnt.calcIt();
		cnt.storeIt();
		system.assertEquals(false, cnt.storeable);
		Integer totCount = 0;
		for (PCEBase.ChartData cd:cnt.cgChartData) {
			totCount += cd.count;
		}
		Test.stopTest();
		system.assertEquals(19, totCount, 'Total count should be 19 - after the shaving ...');
		system.assertEquals(20, cnt.cgChartData.size(), 'Chart data should be 20');
		//system.debug('### cgChartData: ' + cnt.cgChartData);

	}

	@isTest
	static void TestWeirdError() {
		PCE_Port_Call__c[] pcs = new PCE_Port_Call__c[] {
			new PCE_Port_Call__c(Departure_Date__c=DateTime.newInstance(2015,10,07,03,55,00), Port_name__c='Port Hedland, Australia', Vessel_size__c=169631, Agent_role__c='Full Agent', Cargo_Group__c='Dry bulk - Iron ore', Arrival_Date__c=DateTime.newInstance(2015,09,28,13,42,00)),
			new PCE_Port_Call__c(Departure_Date__c=DateTime.newInstance(2015,12,22,19,06,00), Port_name__c='Port Hedland, Australia', Vessel_size__c=169631, Agent_role__c='Full Agent', Cargo_Group__c='Dry bulk - Iron ore', Arrival_Date__c=DateTime.newInstance(2015,12,14,14,48,00)),
			new PCE_Port_Call__c(Departure_Date__c=DateTime.newInstance(2015,09,22,15,15,00), Port_name__c='Port Hedland, Australia', Vessel_size__c=170000, Agent_role__c='Full Agent', Cargo_Group__c='Dry bulk - Iron ore', Arrival_Date__c=DateTime.newInstance(2015,09,15,20,30,00)),
			new PCE_Port_Call__c(Departure_Date__c=DateTime.newInstance(2015,08,26,07,48,00), Port_name__c='Port Hedland, Australia', Vessel_size__c=169092, Agent_role__c='Full Agent', Cargo_Group__c='Dry bulk - Iron ore', Arrival_Date__c=DateTime.newInstance(2015,08,20,03,18,00)),
			new PCE_Port_Call__c(Departure_Date__c=DateTime.newInstance(2015,09,20,23,36,00), Port_name__c='Port Hedland, Australia', Vessel_size__c=169056, Agent_role__c='Full Agent', Cargo_Group__c='Dry bulk - Iron ore', Arrival_Date__c=DateTime.newInstance(2015,09,13,14,42,00)),
			new PCE_Port_Call__c(Departure_Date__c=DateTime.newInstance(2015,08,15,11,15,00), Port_name__c='Port Hedland, Australia', Vessel_size__c=169056, Agent_role__c='Full Agent', Cargo_Group__c='Dry bulk - Iron ore', Arrival_Date__c=DateTime.newInstance(2015,08,13,17,36,00)),
			new PCE_Port_Call__c(Departure_Date__c=DateTime.newInstance(2015,10,25,18,25,00), Port_name__c='Port Hedland, Australia', Vessel_size__c=170000, Agent_role__c='Full Agent', Cargo_Group__c='Dry bulk - Iron ore', Arrival_Date__c=DateTime.newInstance(2015,10,21,23,36,00)),
			new PCE_Port_Call__c(Departure_Date__c=DateTime.newInstance(2015,08,30,10,30,00), Port_name__c='Port Hedland, Australia', Vessel_size__c=169001, Agent_role__c='Full Agent', Cargo_Group__c='Dry bulk - Iron ore', Arrival_Date__c=DateTime.newInstance(2015,08,24,11,05,00)),
			new PCE_Port_Call__c(Departure_Date__c=DateTime.newInstance(2015,12,14,23,42,00), Port_name__c='Port Hedland, Australia', Vessel_size__c=170000, Agent_role__c='Full Agent', Cargo_Group__c='Dry bulk - Iron ore', Arrival_Date__c=DateTime.newInstance(2015,12,08,21,30,00))
		};

		insert pcs;

		PCETestpageController cnt = new PCETestpageController();
		cnt.selPort = 'Port Hedland, Australia';
		cnt.selVesselLo = 150000.0;
		cnt.selVesselHi = 170000.0;
		cnt.selAgent = 'Full Agent';
		cnt.selCargoType = 'Dry bulk - Iron ore';
		cnt.calcIt();
		Integer totCount = 0;
		for (PCEBase.ChartData cd:cnt.pcChartData) {
			totCount += cd.count;
		}
		System.assertEquals(9, totCount);

	}
}