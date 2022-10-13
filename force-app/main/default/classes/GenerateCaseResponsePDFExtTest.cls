@isTest
@testVisible
private class GenerateCaseResponsePDFExtTest{

	public static Port__c[] ports;
	static void exData() {
		// Create some Locations
		Location__c[] locs = new Location__c[] {
			new Location__c(Type__c='Country', Global_Region__c='EMEA', isocode__c='AE', Name='United Arab Emirates'),
			new Location__c(Type__c='Country', Global_Region__c='EMEA', isocode__c='DK', Name='Denmark'),
			new Location__c(Type__c='Country', Global_Region__c='EMEA', isocode__c='NO', Name='Norway'),
			new Location__c(Type__c='Country', Global_Region__c='APAC', isocode__c='AU', Name='Australia'),
			new Location__c(Type__c='Country', Global_Region__c='APAC', isocode__c='US', Name='USA'),
			new Location__c(Type__c='Country', Global_Region__c='APAC', isocode__c='IN', Name='India')
		};
		insert locs;

		// Create some ports
		ports = new Port__c[] {
			new Port__c(Country_Code__c='AE', Name='Abu Dhabi', Port_Code__c='AEAUH', Location__c=locs[0].Id),
			new Port__c(Country_Code__c='AE', Name='Jebel Dhanna', Port_Code__c='AEJED', Location__c=locs[0].Id),
			new Port__c(Country_Code__c='DK', Name='Odense', Port_Code__c='DKODE', Location__c=locs[1].Id),
			new Port__c(Country_Code__c='DK', Name='Aalborg', Port_Code__c='DKAAL', Location__c=locs[1].Id),
			new Port__c(Country_Code__c='NO', Name='Leknes', Port_Code__c='NOLKN', Location__c=locs[2].Id),
			new Port__c(Country_Code__c='NO', Name='Tananger', Port_Code__c='NOTAE', Location__c=locs[2].Id),
			new Port__c(Country_Code__c='AU', Name='Dampier', Port_Code__c='AUDAM', Location__c=locs[3].Id),
			new Port__c(Country_Code__c='AU', Name='Melbourne', Port_Code__c='AUMEL', Location__c=locs[3].Id),
			new Port__c(Country_Code__c='US', Name='Baltimore', Port_Code__c='USBAL', Location__c=locs[4].Id),
			new Port__c(Country_Code__c='US', Name='Seattle', Port_Code__c='USSEA', Location__c=locs[4].Id),
			new Port__c(Country_Code__c='IN', Name='Hazira', Port_Code__c='INHZ1', Location__c=locs[5].Id),
			new Port__c(Country_Code__c='IN', Name='Mumbai', Port_Code__c='INBO1', Location__c=locs[5].Id)
		};
		insert ports;

		Channel__c[] chans = new Channel__c[] {
			new Channel__c(Name='West', Port__c=ports[0].Id),
			new Channel__c(Name='East', Port__c=ports[0].Id),
			new Channel__c(Name='West', Port__c=ports[1].Id),
			new Channel__c(Name='East', Port__c=ports[1].Id),
			new Channel__c(Name='West', Port__c=ports[2].Id),
			new Channel__c(Name='East', Port__c=ports[2].Id),
			new Channel__c(Name='West', Port__c=ports[3].Id),
			new Channel__c(Name='East', Port__c=ports[3].Id),
			new Channel__c(Name='West', Port__c=ports[4].Id),
			new Channel__c(Name='East', Port__c=ports[4].Id),
			new Channel__c(Name='West', Port__c=ports[5].Id),
			new Channel__c(Name='East', Port__c=ports[5].Id),
			new Channel__c(Name='West', Port__c=ports[6].Id),
			new Channel__c(Name='East', Port__c=ports[6].Id),
			new Channel__c(Name='West', Port__c=ports[7].Id),
			new Channel__c(Name='East', Port__c=ports[7].Id),
			new Channel__c(Name='West', Port__c=ports[8].Id),
			new Channel__c(Name='East', Port__c=ports[8].Id),
			new Channel__c(Name='West', Port__c=ports[9].Id),
			new Channel__c(Name='East', Port__c=ports[9].Id),
			new Channel__c(Name='West', Port__c=ports[10].Id),
			new Channel__c(Name='East', Port__c=ports[10].Id),
			new Channel__c(Name='West', Port__c=ports[11].Id),
			new Channel__c(Name='East', Port__c=ports[11].Id)
		};
		insert chans;

		Terminal__c[] terms = new Terminal__c[] {
			new Terminal__c(Name='One', Port__c=ports[0].Id),
			new Terminal__c(Name='Two', Port__c=ports[0].Id),
			new Terminal__c(Name='One', Port__c=ports[1].Id),
			new Terminal__c(Name='Two', Port__c=ports[1].Id),
			new Terminal__c(Name='One', Port__c=ports[2].Id),
			new Terminal__c(Name='Two', Port__c=ports[2].Id),
			new Terminal__c(Name='One', Port__c=ports[3].Id),
			new Terminal__c(Name='Two', Port__c=ports[3].Id),
			new Terminal__c(Name='One', Port__c=ports[4].Id),
			new Terminal__c(Name='Two', Port__c=ports[4].Id),
			new Terminal__c(Name='One', Port__c=ports[5].Id),
			new Terminal__c(Name='Two', Port__c=ports[5].Id),
			new Terminal__c(Name='One', Port__c=ports[6].Id),
			new Terminal__c(Name='Two', Port__c=ports[6].Id),
			new Terminal__c(Name='One', Port__c=ports[7].Id),
			new Terminal__c(Name='Two', Port__c=ports[7].Id),
			new Terminal__c(Name='One', Port__c=ports[8].Id),
			new Terminal__c(Name='Two', Port__c=ports[8].Id),
			new Terminal__c(Name='One', Port__c=ports[9].Id),
			new Terminal__c(Name='Two', Port__c=ports[9].Id),
			new Terminal__c(Name='One', Port__c=ports[10].Id),
			new Terminal__c(Name='Two', Port__c=ports[10].Id),
			new Terminal__c(Name='One', Port__c=ports[11].Id),
			new Terminal__c(Name='Two', Port__c=ports[11].Id)
		};
		insert terms;

		Berth__c[] berths = new Berth__c[] {
			new Berth__c(Port__c=ports[0].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[0].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[0].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[0].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[1].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[1].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[1].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[1].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[2].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[2].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[2].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[2].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[3].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[3].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[3].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[3].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[4].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[4].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[4].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[4].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[5].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[5].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[5].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[5].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[6].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[6].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[6].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[6].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[7].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[7].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[7].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[7].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[8].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[8].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[8].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[8].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[9].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[9].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[9].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[9].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[10].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[10].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[10].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[10].Id, Berth_Length__c=400, Name='Berth 4'),
			new Berth__c(Port__c=ports[11].Id, Berth_Length__c=100, Name='Berth 1'),
			new Berth__c(Port__c=ports[11].Id, Berth_Length__c=200, Name='Berth 2'),
			new Berth__c(Port__c=ports[11].Id, Berth_Length__c=300, Name='Berth 3'),
			new Berth__c(Port__c=ports[11].Id, Berth_Length__c=400, Name='Berth 4')
		};	
		insert berths;

		Berth_Terminal__c[] bts = new Berth_Terminal__c[] {
			new Berth_Terminal__c(Berth__c=berths[0].Id, Terminal__c=terms[0].Id, Name='Berth 1, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[1].Id, Terminal__c=terms[0].Id, Name='Berth 2, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[2].Id, Terminal__c=terms[1].Id, Name='Berth 3, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[3].Id, Terminal__c=terms[1].Id, Name='Berth 4, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[4].Id, Terminal__c=terms[2].Id, Name='Berth 1, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[5].Id, Terminal__c=terms[2].Id, Name='Berth 2, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[6].Id, Terminal__c=terms[3].Id, Name='Berth 3, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[7].Id, Terminal__c=terms[3].Id, Name='Berth 4, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[8].Id, Terminal__c=terms[4].Id, Name='Berth 1, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[9].Id, Terminal__c=terms[4].Id, Name='Berth 2, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[10].Id, Terminal__c=terms[5].Id, Name='Berth 3, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[11].Id, Terminal__c=terms[5].Id, Name='Berth 4, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[12].Id, Terminal__c=terms[6].Id, Name='Berth 1, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[13].Id, Terminal__c=terms[6].Id, Name='Berth 2, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[14].Id, Terminal__c=terms[7].Id, Name='Berth 3, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[15].Id, Terminal__c=terms[7].Id, Name='Berth 4, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[16].Id, Terminal__c=terms[8].Id, Name='Berth 1, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[17].Id, Terminal__c=terms[8].Id, Name='Berth 2, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[18].Id, Terminal__c=terms[9].Id, Name='Berth 3, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[19].Id, Terminal__c=terms[9].Id, Name='Berth 4, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[20].Id, Terminal__c=terms[10].Id, Name='Berth 1, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[21].Id, Terminal__c=terms[10].Id, Name='Berth 2, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[22].Id, Terminal__c=terms[11].Id, Name='Berth 3, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[23].Id, Terminal__c=terms[11].Id, Name='Berth 4, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[24].Id, Terminal__c=terms[12].Id, Name='Berth 1, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[25].Id, Terminal__c=terms[13].Id, Name='Berth 2, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[26].Id, Terminal__c=terms[14].Id, Name='Berth 3, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[27].Id, Terminal__c=terms[15].Id, Name='Berth 4, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[28].Id, Terminal__c=terms[16].Id, Name='Berth 1, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[29].Id, Terminal__c=terms[17].Id, Name='Berth 2, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[30].Id, Terminal__c=terms[18].Id, Name='Berth 3, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[31].Id, Terminal__c=terms[19].Id, Name='Berth 4, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[32].Id, Terminal__c=terms[20].Id, Name='Berth 1, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[33].Id, Terminal__c=terms[21].Id, Name='Berth 2, Terminal 1'),
			new Berth_Terminal__c(Berth__c=berths[34].Id, Terminal__c=terms[22].Id, Name='Berth 3, Terminal 2'),
			new Berth_Terminal__c(Berth__c=berths[35].Id, Terminal__c=terms[23].Id, Name='Berth 4, Terminal 2')
		};
		insert bts;
	}

	@isTest
    static void testGenerateCaseResponsePDF() {

    	GenerateCaseResponsePDFExtTest.exData();

		Account a = new Account(Name='Daname');
		insert a;

		Case c = new Case(AccountId=a.Id,Additional_Emails__c='test.test@test.com,test1.test1@test.com',Respond_to__c='test2.test2@test.com');
		insert c;

		Port_Request__c pr = new Port_Request__c(Case__c=c.Id,Generate_Pdf__c=true,Send_Mail__c=true,Port__c=ports[0].id);
		insert pr;

		List<Port_Request__c> portRqList = new List<Port_Request__c>();
		portRqList.add(pr);

		ApexPages.StandardController stc = new ApexPages.StandardController(pr);
    	GenerateCaseResponsePDFExt obj = new GenerateCaseResponsePDFExt(stc);

    	Port__c sel = obj.selPort;
    	//obj.berthCGMap;
    	//obj.berthCTMap;
    	//obj.berths;
    	//obj.selPort;
    	Channel__c[] cha = obj.channels;
    	Terminal__c[] ter = obj.terminals;
    	Map<Id, Berth_Alternative__c> selBerth2AlternativeMap = obj.selBerth2Alternative;
    	Berth_Alternative__c[] balt = obj.balts;
    	List<Cargo_Type__c> cargoTypes = obj.cargoTypes;
    	Map<Id,String> berthCGMap = obj.berthCGMap;
    	Map<Id,String> berthCTMap = obj.berthCTMap;

    	PortReqInvocableClass.initiateProcess(portRqList);
    }
}