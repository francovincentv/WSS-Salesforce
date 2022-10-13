@isTest
private class PITTests
{
    @testVisible
    private static Location__c[] regs;
    @testVisible
    private static Location__c[] locs;
    @testVisible
    private static Port__c[] ports;
    @testVisible
    private static Channel__c[] chans;
    @testVisible
    private static Terminal__c[] terms;
    @testVisible
    private static Berth__c[] berths;
    @testVisible
    private static Berth_Terminal__c[] bts;
    @testVisible
    private static Cargo_Type__c[] cts;

    static void exData() {
        // Create some Regions
        regs = new Location__c[] {
            new Location__c(Type__c='Region', Name='Europe'),
            new Location__c(Type__c='Region', Name='Asia Pacific'),
            new Location__c(Type__c='Region', Name='Americas')
        };
        insert regs;
        // Create some Locations
        locs = new Location__c[] {
            new Location__c(Type__c='Country', Global_Region__c='EMEA', isocode__c='AE', Name='United Arab Emirates', Location__c=regs[1].Id),
            new Location__c(Type__c='Country', Global_Region__c='EMEA', isocode__c='DK', Name='Denmark', Location__c=regs[0].Id),
            new Location__c(Type__c='Country', Global_Region__c='EMEA', isocode__c='NO', Name='Norway', Location__c=regs[0].Id),
            new Location__c(Type__c='Country', Global_Region__c='APAC', isocode__c='AU', Name='Australia', Location__c=regs[1].Id),
            new Location__c(Type__c='Country', Global_Region__c='APAC', isocode__c='US', Name='USA', Location__c=regs[2].Id),
            new Location__c(Type__c='Country', Global_Region__c='APAC', isocode__c='IN', Name='India', Location__c=regs[1].Id)
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

        chans = new Channel__c[] {
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

        terms = new Terminal__c[] {
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

        berths = new Berth__c[] {
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

        bts = new Berth_Terminal__c[] {
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

        cts = new Cargo_Type__c[] {
            new Cargo_Type__c(Berth__c=berths[0].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[1].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[2].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[3].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[4].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[5].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[6].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[7].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[8].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[9].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[10].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[11].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[12].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[13].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[14].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[15].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[16].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[17].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[18].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[19].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[20].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[21].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[22].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[23].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[24].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[25].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[26].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[27].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[28].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[29].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[30].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[31].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[32].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[33].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[34].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes'),
            new Cargo_Type__c(Berth__c=berths[35].Id, Cargo_Group__c='Breakbulk', Cargo_Handling__c='Loading', Cargo_Type__c='Aluminium', Load_Methods__c='Cranes')
        };
        insert cts;
    }

    @isTest
    static void testPitExt() {
        PITTests.exData();

        Account a = new Account(Name='Daname');
        insert a;

        Case c = new Case(AccountId=a.Id,Respond_to__c='test.test@test.com');
        insert c;

        Port_Request__c pr = new Port_Request__c(Case__c=c.Id);
        insert pr;

        ApexPages.StandardController stc = new ApexPages.StandardController(pr);
        PITExt pe = new PITExt(stc);
        pe.init();



        pe.selCountry = locs[2].ID;

        GenerateCaseResponsePDFExt obj = new GenerateCaseResponsePDFExt(stc);

        // Select port
        System.assertEquals(pe.getHasPort(), false);

        // Div. coverage:
        System.debug('### recTypes: ' + pe.portRecTypes);
        pe.selPortReq.Port__c = ports[4].Id;
        System.debug('### channels: ' + pe.channels);
        System.debug('### termSelected: ' + pe.termsSelected);
        System.debug('### getSelTerminals: ' + pe.getSelTerminals());
        System.debug('### berthSelMap: ' + pe.berthSelMap);
        System.debug('### mapType: ' + pe.mapType);
        System.debug('### ports: ' + pe.ports);
        System.debug('### portchanged: ' + pe.portChanged);
        pe.updatePortRequest();
        pe.selectPort();
        pe.selectCountry();
        pe.selectRegion();
        pe.addChannel();
        pe.editChannel();
        pe.stopEditChannel();
        pe.editPort();
        pe.savePort();
        pe.changePort();
        pe.createNewCargoType();
        pe.addBerth();
        pe.selPortReq.Port__c = ports[4].Id;
        system.debug('### selPort: ' + pe.selPort);
        pe.selBerth();
        pe.selTerminal();
        pe.unselTerminal();
        pe.submitToPortResponsible();
        pe.editTerminal();
        pe.doneEditTerminal();
        pe.addTerminal();
        pe.actBerthId = berths[0].Id;
        pe.selCargoType();
        for (Berth__c b:pe.berthsForAssignment) {
            pe.berthAssignMap.put(b.Id, true);  
        }
        System.debug('### pe.portLocMap: ' + pe.portLocMap);
        System.debug('### pe.portOpts: ' + pe.portOpts);
        System.debug('### berthAssignMap: ' + pe.berthAssignMap);
        System.debug('### gethaslocation: ' + pe.getHasLocation());
        System.debug('### cargohandlings: ' + pe.cargoHandlings);
        System.debug('### cargogroups: ' + pe.cargoGroups);
        System.debug('### geartypes: ' + pe.gearTypes);
        System.debug('### berthCargoTypesMap: ' + pe.berthCargoTypesMap);
        System.debug('### availCargoTypes: ' + pe.availCargoTypes);
        System.debug('### cargotypes: ' + pe.cargoTypes);
        pe.createBerthAlternatives();
        pe.cloneBerths();
        pe.completePortRequest();
        pe.resetCargoFilters();
        pe.zoomIn();
        pe.zoomOut();
        pe.assignBerthToNewTer();
        pe.saveNewBerth();
        pe.showNewBerth();
        pe.AssignBerth();
        //pe.saveCargoType();
        //pe.deleteCargoType();
        pe.cancelNewBerth();
        pe.actChanId = chans[10].Id;
        pe.deleteChannel();
        System.debug('### canDeleteChannel' + pe.canDeleteChannel);
        pe.portSearchSelectId = ports[0].Id;
        pe.portSearchSelect();
        pe.portSearch = 'Aalb';
        System.debug('### searchResults: ' + pe.searchResults);
        pe.selBerth = pe.berths[1];
        System.debug('### berthTerms: ' + pe.berthTerms);
        pe.berthTermDeleteId = bts[0].Id;
        System.debug('### canDeleteBerthTerm: ' + pe.canDeleteBerthTerm);
        pe.deleteBerthTerm();
        pe.showMyPorts();
        pe.hideMyPorts();
        pe.showRecentPorts();
        pe.hideRecentPorts();
        System.debug('### newCT: ' + pe.newCT);
        pe.showNewCT();
        pe.saveNewCT();
        pe.cancelNewCT();
        pe.actCargoTypeId = cts[0].Id;
        pe.selCargoType = cts[0];
        pe.saveCargoType();
        pe.selCargoType = cts[0];
        pe.deleteCargoType();
        System.debug('### canDeleteTerminal: ' + pe.canDeleteTerminal);
        pe.termEditId = terms[0].Id;
        pe.deleteTerminal();
        System.debug('### recentPorts: ' + pe.recentPorts);
        System.debug('### pe.cargoHandlingsDisabled: ' + pe.cargoHandlingsDisabled);
        System.debug('### pe.gearTypesDisabled: ' + pe.gearTypesDisabled);
        System.debug('### pe.zoomLevel' + pe.zoomLevel);
        System.debug('### locations: ' + pe.countries);
        System.debug('### dummyPortRequest: ' + pe.dummyPortRequest);
        System.debug('### regionCountries: ' + pe.regionCountries);
        pe.prId = null;
        pe.init();
        pe.selectedBertId = berths[0].Id;
        pe.berthClone();
        pe.savePortRequest();
        pe.resetTerminalFilter();

        pr.Status__c='Submitted';
        update pr;
        Attachment att = new Attachment(parentid = c.Id,Body=Blob.valueOf('UNIT.TEST'),isPrivate = false,name='test');
        insert att;
        ApexPages.StandardController stcCase = new ApexPages.StandardController(c);
        submitAllPortReqExt objCase = new submitAllPortReqExt(stcCase);
        objCase.submitPR();
        objCase.submitPRWithpoutAtt();

        pr.Status__c='Answered';
        update pr;
        
        sendMailWithPRPDFExt sendMailCtrl = new sendMailWithPRPDFExt(stcCase);
        sendMailCtrl.sendMail();
        sendMailWithPRPDFExt.checksendMail(c.Id);
    }
}