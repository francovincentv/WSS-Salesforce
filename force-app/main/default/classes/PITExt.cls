public class PITExt {

    private Location__c[] locations {
        get {
            if (locations == null) {
                locations = [select Name, Type__c, isocode__c, Global_Region__c, Location__c, OwnerId from Location__c order by Name asc]; // Get them all into this list.
            }
            return locations;
        }
        private set;
    }
    public Boolean dummyPortRequest {get;set;}

    @testVisible
    private Location__c[] countries {
        get {
            if (countries == null) {
                countries = new Location__c[]{};
                for (Location__c l:locations) {
                    if (l.Type__c == 'Country') {
                        countries.add(l);
                    }
                }
            }
            return countries;
        }
        private set;
    }

    private RecordType[] recTypes {
        get {
            if (recTypes == null) {
                recTypes = [select Id, DeveloperName, SObjectType from RecordType];
            }
            return recTypes;
        }
        private set;
    }

    public Map<String, Id> portRecTypes {
        get {
            if (portRecTypes == null) {
                portRecTypes = new Map<String, Id>();
                for (RecordType rt:recTypes) {
                    if (rt.SObjectType == 'Port__c') {
                        portRecTypes.put(rt.DeveloperName, rt.Id);
                    }
                }
            }
            return portRecTypes;
        }
        private set;
    }
/*
    private Location__c[] districts {
        get {
            if (districts == null) {
                districts = new Location__c[]{};
                for (Location__c l:locations) {
                    if (l.Type__c == 'District') {
                        districts.add(l);
                    }       
                }
            }
            return districts;
        }
        private set;
    }
*/
    @testVisible
    private Map<Id,SelectOption[]> regionCountries {
        get {
            if (regionCountries == null) {
                regionCountries = new Map<Id,SelectOption[]>();
                for (Location__c l:countries) {
                    System.debug('### loc: ' + l);
                    if (l.Type__c == 'Country' && l.Location__c != null) { // Is country and has region
                        if(!regionCountries.containsKey(l.Location__c)) {
                            regionCountries.put(l.Location__c, new SelectOption[]{});
                        }
                        regionCountries.get(l.Location__c).add(new SelectOption(l.Id, l.name));
                    }
                    /* OLD WAY:
                    if (!regionCountries.containsKey(l.Global_Region__c)) {
                        regionCountries.put(l.Global_Region__c, new SelectOption[]{});
                    }
                    regionCountries.get(l.Global_Region__c).add(new SelectOption(l.isocode__c, l.name));
                    */
                }
            }
            return regionCountries;
        }
        private set;
    }
/*
    private Map<Id, SelectOption[]> countryDistricts {
        get {
            if (countryDistricts == null) {
                countryDistricts = new Map<Id, SelectOption[]>();
                for (Location__c l:districts) {
                    if (!countryDistricts.containsKey(l.Location__c)) {
                        countryDistricts.put(l.Location__c, new SelectOption[]{});
                    }
                    countryDistricts.get(l.Location__c).add(new SelectOption(l.id, l.name));
                }
            }
            return countryDistricts;
        }
        private set;
    }
*/

    public Boolean showChanEdit {get;set;}
    public Id actChanId {get;set;}
    public void editChannel() {
        showChanEdit = true;
    }
    public Boolean canDeleteChannel {
        get {
            return Schema.sObjectType.Channel__c.isDeletable();
        }
        private set;
    }
    public void deleteChannel() {
        Map<Id,Channel__c> chanMap = new Map<Id,Channel__c>(channels);
        Channel__c toDel = chanMap.get(actChanId);
        if (toDel != null) {
            try {
                delete toDel;
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to delete channel: ' + e.getMessage()));
            }
            channels = null;
            terminals = null;
            termBerths = null;
            berths = null;
            berthAssignMap = null;
            actChanId = null;
            selPort = null;
            selPortReq = null;

        }
    }
    public void stopEditChannel() {
        showChanEdit = false;
        channels = null;
    }
    public void addChannel() {
        Channel__c chan = new Channel__c(Port__c = selPort.Id, Name='NEW CHANNEL');
        insert chan;
        actChanId = chan.Id;
        channels = null;
        showChanEdit = true;
    }
    public Channel__c[] channels {
        get {
            if (channels == null && selPort != null) {
                channels = [select Id, Max_Sailing_Draft__c, Min_UKC__c, Max_LOA__c, Max_Beam__c, Max_DWT_Displacement__c, Max_Airdraft_Mast__c, Max_Airdraft_Hatch__c, Last_modified_date__c,
Daylight_Restriction__c, Channel_UKC__c, Channel_Width__c, Channel_Depth__c, Name, LastModifiedDate
                             from Channel__c
                            where port__c = :selPort.Id];
            }
            return channels;
        }
        set;
    }

    public Set<Id> selTerminals;

    public Set<Id> getSelTerminals() {
        if (selTerminals == null) {
            selTerminals = new Set<Id>();
        }
        if (selTerminals.size() == 0) {
            return new Map<Id,Terminal__c>(terminals).keySet();
        }
        return selTerminals;        
    }

    public Boolean termsSelected {
        get {
            if (selTerminals != null && selTerminals.size() > 0) {
                return true;
            }
            return false;
        }
        private set;
    }

    public Terminal__c[] terminals {
        get {
            if (terminals == null && selPort != null) {
                if(terminalSelType == null){
                    terminals = [select Id, Name, Terminal_Type__c, Storage_type__c, Number_of_Berths__c, Working_hours_weekdays__c, Terminal_Name_local__c, Operator_Manager_Name__c,
                                    Working_hours_weekends__c, Working_hours_holidays__c, Gang_Size__c, Security__c, LastModifiedDate
                               from Terminal__c
                              where port__c = :selPort.Id
                           order by Name];
                }
                else{
                    terminals = [select Id, Name, Terminal_Type__c, Storage_type__c, Number_of_Berths__c, Working_hours_weekdays__c, Terminal_Name_local__c, Operator_Manager_Name__c,
                                    Working_hours_weekends__c, Working_hours_holidays__c, Gang_Size__c, Security__c, LastModifiedDate
                               from Terminal__c
                              where port__c = :selPort.Id and Terminal_Type__c =: terminalSelType 
                           order by Name];
                }                
            }            
            return terminals;
        }
        set;
    }

    public Map<Id,Boolean> berthSelMap {
        get {
            if (berthSelMap == null) {
                berthSelMap = new Map<Id,Boolean>();
            }
            return berthSelMap;
        }
        set;
    }
    public Map<Id,Boolean> berthAssignMap {
        get {
            if (berthAssignMap == null) {
                berthAssignMap = new Map<Id,Boolean>();
            }
            return berthAssignMap;
        }
        set;
    }
    public Berth__c[] berthsForAssignment {
        get{
            berthsForAssignment = [select Name, Berth_Length__c, Port__c, Selected__c, Berth_Length_Depth__c, Berth_No__c, 
                                          Berth_Type__c, Description__c, LastModifiedDate, Max_DWT__c, Berth_Depth__c
                            from Berth__c 
                           where Port__c = :selPort.Id];
            for(Berth__c b : berthsForAssignment){
                berthAssignMap.put(b.Id, false);                
            }
            return berthsForAssignment;
        }
        set;
    }
    public Berth__c[] berths {
        get {
            System.debug('### berths in getter: ' + berths);
            System.debug('### selPort: ' + selPort);
            if (berths == null && selPort != null) {
                Set<Id> daBerths = new Set<Id>();
                for (Id tId:termBerths.keySet()) {
                    for (Id bId:termBerths.get(tId)) {
                        if (selCargoTypesBerths.contains(bId) &&
                            selCargoGearBerths.contains(bId) &&
                            selCargoHandlingBerths.contains(bId)) {
                            daBerths.add(bId);
                        }
                    }
                }
                berths = [select Name, Berth_Length__c, Port__c, Selected__c, Berth_Length_Depth__c, Berth_No__c, Berth_Type__c, 
                                 Description__c,Primary_Terminal__c, LastModifiedDate, Max_DWT__c, Max_Sailing_Draft__c, Max_Sailing_Draft_Comment__c, 
                                 Min_UKC_mtr__c, Max_LOA__c, Max_Beam__c, Max_DWT_Displacement__c, Max_Airdraft_Mast__c, 
                                 Max_Airdraft_Hatch__c, Berth_Depth__c
                            from Berth__c 
                           where Id in :daBerths];

                for (Berth__c b:berths) {
                    system.debug('---b---'+b.Name);
                    if (selBerth2Alternative.containsKey(b.Id)) {
                        b.Selected__c = true;
                    }
                    if (berthSelMap.containsKey(b.Id)) {
                        b.Selected__c = berthSelMap.get(b.Id);
                    } else {
                        berthSelMap.put(b.Id, b.Selected__c);
                    }
                    
                }
            }

            return berths;
        }
        set;
    }

    public void addBerth() {

    }

    public Berth_Alternative__c[] balts {
        get {
            if (balts == null) {
                balts = [select Name, Berth__c, Description__c, Status__c
                           from Berth_Alternative__c
                          where Port_Request__c = :selPortReq.ID];
            }
            return balts;
        }
        set;
    }

    public Map<Id, Berth_Alternative__c> selBerth2Alternative {
        get {
            if (selBerth2Alternative == null) {
                selBerth2Alternative = new Map<Id, Berth_Alternative__c>();
                for (Berth_Alternative__c bal:balts) {
                    if (bal.Status__c == 'Suggested') {
                        selBerth2Alternative.put(bal.Berth__c, bal);
                    }
                }
            }
            return selBerth2Alternative;
        }
        set;
    }

    public Map<Id, Berth_Alternative__c> berth2Alternative {
        get {
            if (berth2Alternative == null) {
                berth2Alternative = new Map<Id, Berth_Alternative__c>();
                for (Berth_Alternative__c bal:balts) {
                    berth2Alternative.put(bal.Berth__c, bal);
                }
            }
            return berth2Alternative;
        }
        set;
    }
    public Set<Id> recentPorts {
        get {
            recentPorts = new Set<Id>();
            for (RecentlyViewed rv:[SELECT Id
                                      FROM RecentlyViewed 
                                     WHERE Type = 'Port__c'
                                     ORDER BY LastViewedDate DESC
                                     LIMIT 20]) {
                recentPorts.add(rv.Id);

            }
            return recentPorts;
        }
        private set;
    }
    public Port__c[] ports {
        get {
            if (ports == null && selCountry != null) { // if country has changed
                // TODO add filter search here if it is not null.
                String sql = 'select Name, OwnerId, Latitude_Longitude__c, Country_Code__c, Country_Code_ISO_formula__c, Crew_Change__c, ';
                sql +=              'Customs_Immigration__c, Daylight_Restriction__c, Documents_Required__c, General_Overview__c, ';
                sql +=              'Location__c, Location_Description__c, Medical_Facilities__c, Officials_Visitors__c, ';
                sql +=              'Pilot_Escort__c, Port_Administration_WH_holidays__c, Port_Administration_WH_weekdays__c, ';
                sql +=              'Port_Administration_WH_weekends__c, Port_Code__c, Port_Name_local__c, Pre_Arrival_Notification__c, ';
                sql +=              'Repairs__c, Salinity__c, Sludge__c, Tidal_Restriction__c, Time_Zone__c, Public_Holidays__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s, ';
                sql +=              'Responsible_WSS_Site__c, Salinity_range__c, Other_names__c, Local_Currency__c, Local_Currency_formula__c, Official_Website__c, State__c, LastModifiedDate, ';
                sql +=              'Code_of_nearest_Domestic_Airport__c, Code_of_nearest_International_Airport__c,Name_of_nearest_Domestic_Airport__c,Name_of_nearest_International_Airport__c,Nearest_Domestic_Airport_km__c,Nearest_International_Airport_km__c    , ';
                sql +=              'Transport_Inland__c, Tugs_availble__c, Tugs_required__c from port__c where ';
                if (showMyPorts == true) {
                    sql += 'OwnerId = \'' + UserInfo.getUserId() + '\'';
                } else if (showRecentPorts == true) {
                    sql += 'Id in :recentPorts';
                } else {
                    sql += 'Location__c = \'' + selCountry + '\'';
                }
                sql += ' ORDER BY name LIMIT 1000';
    
                system.debug('----sql--'+sql);
                ports = Database.query(sql);
            }
            return ports;
        }
        set;
    }

    public Location portLoc {
        public get {
            if (selPort != null) {
                return selPort.Latitude_Longitude__c;
            }
            return null;
        }
        private set;
    }

    public Map<String, Double> portLocMap {
        get {
            if (portLoc != null) {
                return new Map<String, Double>{'latitude'=>portLoc.getLatitude(), 'longitude'=>portLoc.getLongitude()};
            }
            return null;
        }
        private set;
    }
    public String portSearchSelectId {get;set;}
    public void portSearchSelect() {
        Port__c p = [select Port_Code__c, Location__c, Location__r.Location__c from Port__c where Id = :portSearchSelectId];
        regions = null;
        countryOpts = null;
        portOpts = null;
        //selPortReq = null;
        selRegion = p.Location__r.Location__c;
        selCountry = p.Location__c;
        selPortCode = p.Port_Code__c;
        selectCountry();

    }
    public String portSearch {get;set;}
    public String selPortCode {get;set;}
    public Map<String,String> searchResults {
        get {
            searchResults = new Map<String,String>();
            if (portSearch == null) {
                return searchResults;
            }
            if (portSearch.length() < 3) {
                searchResults.put('-', 'Need at least 3 characters to search');
                return searchResults;
            }
            List<List<SObject>> srchList = [find :portSearch in all fields returning Port__c (Id, Name, Location__r.Name) LIMIT 20];
            Port__c p; // Define outside of loop to be nice to stack
            for (SObject o:srchList[0]) {
                p = (Port__c)o;
                searchResults.put(p.Id, p.Location__r.Name + ' - ' + p.Name);
            }
            return searchResults;
        }
        set;
    }

    public SelectOption[] portOpts {
        get {
            portOpts = new SelectOption[]{};
            if (ports != null) {
                for (Port__c port:ports) {
                    portOpts.add(new SelectOption(port.Port_Code__c, port.name + ', ' + port.Port_Code__c));
                }
            }
           // PortOpts = sortSelectOptions(portOpts);
            return PortOpts;
        }
        private set;
    }

    public Boolean getHasPort() {
        if (selPort != null) {
            return true;
        }
        return false;
    }

    public Boolean getHasLocation() {
        if (selLocation != null) {
            return true;
        }
        return false;
    }

    public String selRegion {get;set;}
    public SelectOption[] regions {
        get {
            if (regions == null) {
                regions = new SelectOption[]{};
                for (Location__c l:locations) {
                    if (l.Type__c == 'Region') {
                        regions.add(new SelectOption(l.Id, l.Name));
                    }
                }
                /* OLD WAY:
                Schema.DescribeFieldResult fieldResult = Location__c.Global_Region__c.getDescribe();
                Schema.PicklistEntry[] ple = fieldResult.getPicklistValues();
                for (Schema.PicklistEntry p:ple) {
                    regions.add(new SelectOption(p.getLabel(), p.getValue()));
                }
                */
            }
            //regions.sort();
            return regions;
        }
        private set;
    }

    public String selCountry {
        get;
        set {
            selCountry = value;
            ports = null;
        }
    }
    public SelectOption[] countryOpts {
        get {
            if (selRegion != null) {
                System.debug('### selRegion name: ' + selRegion + ' and map: ' + regionCountries);
                System.debug('### regions: ' + regions);
               return regionCountries.get(selRegion);
            }
            return new SelectOption[]{}; // just return an empty one ...
        }
        private set;
    }
    //Sort FUnction
    /*public List<SelectOption> sortSelectOptions(List<SelectOption> sortingList) {
        for (Integer i =0; i < sortingList.size(); i++) {
            for (Integer j = i; j > 0; j--) {
                if (sortingList[j-1].getLabel() > sortingList[j].getLabel()){
                    SelectOption temp = sortingList[j];
                    sortingList[j] = sortingList[j-1];
                    sortingList[j-1] = temp;
                }
            }
        }
    return sortingList;
    }*/

    public Berth_Terminal__c[] berthTerms {
        get {
            return [select Terminal__r.Name, Terminal__r.Terminal_Name_local__c, Terminal__r.Operator_Manager_Name__c,
                           Terminal__r.Terminal_Type__c, Terminal__r.LastModifiedDate
                      from Berth_Terminal__c
                     where Berth__c = :selBerth.Id];
        }
        set;
    }
    public Id berthTermDeleteId {get;set;}
    public Boolean canDeleteBerthTerm {
        get {
            return Schema.sObjectType.Berth_Terminal__c.isDeletable();
        }
        private set;
    }
    public void deleteBerthTerm() {
        if (berthTermDeleteId != null) {
            Berth_Terminal__c bt = new Berth_Terminal__c(Id=berthTermDeleteId);
            try {
                delete bt;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to delete Berth Terminal: ' + e.getMessage()));
            }
            berthTerms = null;
        }
    }
    public Map<Id, Set<Id>> termBerths {
        get {
            if (termBerths == null) {
                termBerths = new Map<Id, Set<Id>>();
                Berth_Terminal__c[] bts = [select Terminal__c, Berth__c
                                             from Berth_Terminal__c
                                            where Terminal__c in :getSelTerminals()];
                System.debug('### selTerminals: ' + getSelTerminals());
                System.debug('### bts: ' + bts);
                for (Berth_Terminal__c bt:bts) {
                    if (!termBerths.containsKey(bt.Terminal__c)) {
                        termBerths.put(bt.Terminal__c, new Set<Id>());
                    }
                    termBerths.get(bt.Terminal__c).add(bt.Berth__c);
                }
            }
            return termBerths;
        }
        set;
    }

    Set<Id> allBerthIds {
        get {
            if (allBerthIds == null) {
                allBerthIds = new Set<Id>();
                for (Id tId:termBerths.keySet()) {
                    allBerthIds.addAll(termBerths.get(tId));
                }
            }
            return allBerthIds;
        }
        private set;
    }

    public Cargo_Type__c[] berthCargoTypes {
        get {
            if (berthCargoTypes == null) {
                berthCargoTypes = [select Cargo_Type__c, Cargo_Handling__c, Discharge_Methods__c, Load_Methods__c, Berth__c, 
                                          Description__c, Cargo_Group__c
                                     from Cargo_Type__c
                                    where Berth__c in :allBerthIds];
            }
            return berthCargoTypes;
        }
        private set;
    }

    public Map<Id, Cargo_Type__c[]> berthCargoTypesMap {
        get {
            if (berthCargoTypesMap == null) {
                berthCargoTypesMap = new Map<Id, Cargo_Type__c[]>();
                system.debug('---berthCargoTypes----'+berthCargoTypes);
                for (Cargo_Type__c ct:berthCargoTypes) {
                    if (!berthCargoTypesMap.containsKey(ct.Berth__c)) {
                        berthCargoTypesMap.put(ct.Berth__c, new Cargo_Type__c[]{});
                    }
                    berthCargoTypesMap.get(ct.Berth__c).add(ct);
                }
            }
            return berthCargoTypesMap;
        }
        private set;
    }
    public Set<String> hTypes { // Cargo Handling Types [Load/Discharge]
        get {
            hTypes = new Set<String>();
            for (Cargo_Type__c ct:berthCargoTypes) {
                if (berthSelCargoHandling != null && new Set<String>(berthSelCargoTypes).contains(ct.Cargo_Type__c)) {
                    if (ct.Discharge_Methods__c != null && (berthSelCargoHandling == 'Discharge' || berthSelCargoHandling == 'Loading and Discharge'))  {   
                        for (String dm:ct.Discharge_Methods__c.split(';')) {
                            if (dm != null) {
                                hTypes.add(dm);
                            }
                        }
                    }
                    if (ct.Load_Methods__c != null && (berthSelCargoHandling == 'Loading' || berthSelCargoHandling == 'Loading and Discharge')) {
                        for (String lm:ct.Load_Methods__c.split(';')) {
                            if (lm != null) {
                                hTypes.add(lm);
                            }
                        }
                    }
                }
            }
            return hTypes;
        }
        private set;
    } 

    public SelectOption[] gearTypes {
        get {
            gearTypes = new SelectOption[]{};
            for (String ht:hTypes) {
                gearTypes.add(new SelectOption(ht, ht));
            }
            return gearTypes;
        }
        private set;
    }

    public Set<String> cGroups {
        get {
            if (cGroups == null) {
                cGroups = new Set<String>();
                for (Cargo_Type__c ct:berthCargoTypes) {
                    cGroups.add(ct.Cargo_Group__c);
                }
            }
            return cGroups;
        }
        private set;
    }
    public SelectOption[] cargoGroups {
        get {
            if (cargoGroups == null) {
                cargoGroups = new SelectOption[]{};
                for (String s:cGroups) {
                    if (s != null) {
                        cargoGroups.add(new SelectOption(s, s));
                    }
                }
            }
            return cargoGroups;
        }
        private set;
    }
    public SelectOption[] termType {
        get {
            if (termType == null) {
                termType = new SelectOption[]{};

                List<Schema.PicklistEntry> picklistValues = Schema.getGlobalDescribe().get('Terminal__c').getDescribe().fields.getMap().get('Terminal_Type__c').getDescribe().getPicklistValues();
                        
                for(Schema.PicklistEntry picklistEntry : picklistValues) {
                    //system.debug('-picklistEntry.getValue()--'+picklistEntry.getValue());
                    termType.add(new SelectOption(picklistEntry.getValue(), picklistEntry.getLabel()));
                }
            }
            return termType;
        }
        private set;
    }

    public Set<String> availCargoTypes { // Cargo Types
        get {    
            availCargoTypes = new Set<String>();
            for (Cargo_Type__c ct:berthCargoTypes) {
                if(ct.Cargo_Group__c != null && berthSelCargoGroups != null) {
                    if(new Set<String>(berthSelCargoGroups).contains(ct.Cargo_Group__c)) {
                        availCargoTypes.add(ct.Cargo_Type__c);
                    }
                }
            }
            return availCargoTypes;
        }
        private set;
    }

    public SelectOption[] cargoTypes {
        get {
            cargoTypes = new SelectOption[]{};
            for (String s:availCargoTypes) {
                if (s != null) {
                    cargoTypes.add(new SelectOption(s, s));
                }
            }
            return cargoTypes;
        }
        private set;
    }

    public Set<String> availCargoHandlings {
        get {
            availCargoHandlings = new Set<String>();
            for (Cargo_Type__c ct:berthCargoTypes) {
                if (ct.Cargo_Handling__c != null && berthSelCargoTypes != null) {
                    if (new Set<String>(berthSelCargoTypes).contains(ct.Cargo_Type__c)) {
                        availCargoHandlings.add(ct.Cargo_Handling__c);
                    }
                }
            }
            return availCargoHandlings;
        }
        private set;
    }

    public SelectOption[] cargoHandlings {
        get {
            cargoHandlings = new SelectOption[]{};
            for (String s:availCargoHandlings) {
                cargoHandlings.add(new SelectOption(s,s));
            }
            return cargoHandlings;
        }
        private set;
    }


    // Returns all berths with the selected cargo types - or all cargo types if none are selected
    public Set<Id> selCargoTypesBerths {
        get {
            selCargoTypesBerths = new Set<Id>();
            Set<String> selCts = new Set<String>(); // If nothing is selected just return all
            if (berthSelCargoTypes == null || berthSelCargoTypes.size() == 0) {
                //selCargoTypesBerths.addAll(allBerthIds);
                for (Id tId:termBerths.keySet()) {
                    for (Id bId:termBerths.get(tId)) {
                        selCargoTypesBerths.add(bId);
                    }
                }
                return selCargoTypesBerths;
            } 
            selCts.addAll(berthSelCargoTypes);
            for (Cargo_Type__c ct:berthCargoTypes) {
                if (selCts.contains(ct.Cargo_Type__c)) {
                    selCargoTypesBerths.add(ct.Berth__c);
                }
            }
            return selCargoTypesBerths;
        }
        private set;
    }

    // Returns all berths with the selected cargo handlings
    public Set<Id> selCargoHandlingBerths {
        get {
            selCargoHandlingBerths = new Set<Id>();
            if (berthSelCargoHandling == null) {
                //selCargoHandlingBerths.addAll(allBerthIds);
                for (Id tId:termBerths.keySet()) {
                    for (Id bId:termBerths.get(tId)) {
                        selCargoHandlingBerths.add(bId);
                    }
                }

                return selCargoHandlingBerths;
            }
            for (Cargo_Type__c ct:berthCargoTypes) {
                if (ct.Cargo_Handling__c == berthSelCargoHandling) {
                    selCargoHandlingBerths.add(ct.Berth__c);
                }
            }
            return selCargoHandlingBerths;
        }
        private set;
    }

    // Returns all berths with the selected cargo gear - or all if none are selected
    public Set<Id> selCargoGearBerths {
        get {
            selCargoGearBerths = new Set<Id>();
            if (berthSelGearTypes == null || berthSelGearTypes.size() == 0) {
                //selCargoGearBerths.addAll(allBerthIds);
                for (Id tId:termBerths.keySet()) {
                    for (Id bId:termBerths.get(tId)) {
                        selCargoGearBerths.add(bId);
                    }
                }
                return selCargoGearBerths;
            }
            Set<String> berthCargoGear;
            for (Cargo_Type__c ct:berthCargoTypes) {
                berthCargoGear = new Set<String>();
                if (ct.Discharge_Methods__c != null) {
                    berthCargoGear.addAll(ct.Discharge_Methods__c.split(';'));
                }
                if (ct.Load_Methods__c != null) {
                    berthCargoGear.addAll(ct.Load_Methods__c.split(';'));
                }
                for (String s:berthSelGearTypes) {                  
                    if (berthCargoGear.contains(s)) {
                        selCargoGearBerths.add(ct.Berth__c);
                        break;
                    }
                }
            }
            return selCargoGearBerths;
        }
        private set;
    }

    public Boolean showMyPorts {get;set;}
    public void showMyPorts() {
        showMyPorts = true;
        showRecentPorts = false;
    }
    public void hideMyPorts() {
        showMyPorts = false;
        showRecentPorts = false;
    }
    public Boolean showRecentPorts {get;set;}
    public void showRecentPorts() {
        showRecentPorts = true;
        showMyPorts = false;
    }
    public void hideRecentPorts() {
        showRecentPorts = false;
    }
    @testVisible
    private Id prId;
/*
    public String selDistrict {get;set;}
    public selectOption[] districtOpts {
        get {
            if (selCountry != null) {
                return countryDistricts.get(selCountry);
            }
            return new SelectOption[]{};
        }
        private set;
    }
*/
    public Port_Request__c selPortReq {
        get {
            if (selPortReq == null) {
                Port_Request__c[] reqs = [select Id, Status__c, Description__c, Name, Port__c, OwnerId, Submitted_By__c, Location__c,
                                                 Case__r.Subject, Case__r.Description, Case__r.CaseNumber, Case__r.Status, Case__r.Vessel__c,
                                                 Submitted_By__r.Name, Submitted_By__r.Email, Submitted_By__r.Phone
                                            from Port_Request__c
                                           where Id = :prId];
                if (reqs.size() > 0) {
                    selPortReq = reqs[0];
                }
            }
            return selPortReq;
        }
        set;
    }
    public Port__c selPort {
        get {
            //selPort.recordTypeId = portRecTypes.get('PIT');
            if (this.selPortReq.Port__c != null) {
                selPort = [select Name, OwnerId,Name__c,Email__c,Phone__c, Latitude_Longitude__c, Country_Code__c, Country_Code_ISO_formula__c, Crew_Change__c,
                                  Customs_Immigration__c, Daylight_Restriction__c, Documents_Required__c, General_Overview__c,
                                  Location__c, Location_Description__c, Medical_Facilities__c, Officials_Visitors__c,
                                  Pilot_Escort__c, Port_Administration_WH_holidays__c, Port_Administration_WH_weekdays__c,
                                  Port_Administration_WH_weekends__c, Port_Code__c, Port_Name_local__c, Pre_Arrival_Notification__c,
                                  Repairs__c, Salinity__c, Sludge__c, Tidal_Restriction__c, Time_Zone__c, Traffic_Figures__c, 
                                  LastModifiedDate, Transport_Inland__c, Tugs_availble__c, Tugs_required__c,Responsible_WSS_Site__c, 
                                  Salinity_range__c, Other_names__c, Local_Currency__c, Local_Currency_formula__c, Official_Website__c, State__c,Public_Holidays__c,
                                  Code_of_nearest_Domestic_Airport__c,Code_of_nearest_International_Airport__c,Name_of_nearest_Domestic_Airport__c,
                                  Name_of_nearest_International_Airport__c,Nearest_Domestic_Airport_km__c,Nearest_International_Airport_km__c,
                                  Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s  
                             from port__c
                            where Id = :this.selPortReq.Port__c];
            }
            return selPort;
        }
        set;
    }
    public void init() {       
        if (prId == null) {
            Port_Request__c[] dPReqs = [select Id from Port_Request__c where Dummy__c=true];
            if (dPReqs.size() == 0) {
                dPReqs.add(new Port_Request__c(Description__c='DUMMY PORT REQUEST - system data - do not change this text',Dummy__c=true));
                insert dPReqs;
            }
            prId = dPReqs[0].Id;
            dummyPortRequest = true;
        } else {
            dummyPortRequest = false;
        }
        selRegion = regions[0].getValue();
        regionChanged();
        zoomLevel = 3;
    }
    public PITExt(ApexPages.StandardController stdController) {
        prId = stdController.getId();
    }
    public PITExt() {
        dummyPortRequest = true;
    }


    public Cargo_Type__c newCT {
        get {
            if (newCT == null) {
                newCT = new Cargo_Type__c(OwnerId=UserInfo.getUserId());
            }
            if (selBerth != null) {
                newCT.Berth__c = selBerth.Id;
            }
            return newCT;
        }
        set;
    }
    public Boolean addingCT {get;set;}
    public void showNewCT() {
        addingCT = true;
    }
    public void saveNewCT() {
        insert newCT;
        newCT = null;
        termBerths = null;
        addingCT = false;
    }
    public void cancelNewCT() {
        addingCT = false;
    }
    public Berth__c newBerth {
        get {
            if (newBerth == null) {
                newBerth = new Berth__c(OwnerId=UserInfo.getUserId());
            }
            if (selPort != null) {
                newBerth.Port__c = selPort.Id;
            }
            return newBerth;
        }
        set;
    }    

    public Boolean addingBerth {get;set;}
    public void showNewBerth() {
        addingBerth = true;
    }
    public Boolean assignBerth {get;set;}
    public void AssignBerth() {
        assignBerth = true;
    }
    public void saveNewBerth() {
        insert newBerth;
        Berth_Terminal__c[] bts = new Berth_Terminal__c[]{};
        Map<Id, Terminal__c> tMap = new Map<Id, Terminal__c>(terminals);
        for (Id tId:selTerminals) {
            bts.add(new Berth_Terminal__c(
                Berth__c = newBerth.Id,
                Terminal__c = tId,
                Name = newBerth.Name + ', ' + tMap.get(tId).Name
                ));
        }
        insert bts;
        termBerths = null;
        newBerth = null;
        berths = null;
        addingBerth = false;
    }
    public void assignBerthToNewTer() {
        
        Set<Id> berthIdSet = new Set<Id>();
        Map<Id, Terminal__c> tMap = new Map<Id, Terminal__c>(terminals);
        Berth_Terminal__c[] btsToInsert = new Berth_Terminal__c[]{};
        Map<Id,Berth_Terminal__c> btsToDelete = new Map<Id,Berth_Terminal__c>();
        For(Id bId : berthAssignMap.keySet()){

            if(berthAssignMap.get(bId) == true){
                berthIdSet.add(bId);
            }
        }
        Berth_Terminal__c[] bts = [select Terminal__c,Name, Berth__c,Berth__r.Name 
                                             from Berth_Terminal__c
                                            where Berth__c in :berthIdSet];

        Map<Id,String> btMap = new Map<Id,String>();
        Map<String,Berth_Terminal__c> btMapForSelectedBerths = new Map<String,Berth_Terminal__c>();

        for(Berth_Terminal__c b : bts){
            String key = b.Terminal__c+','+b.Berth__c;
            btMapForSelectedBerths.put(key, b);
            btMap.put(b.Berth__c, b.Berth__r.name);
        }

        for(Id tId : selTerminals){

            for(Id selectedBerthId : berthIdSet){

                String key = tId+','+selectedBerthId;

                if(btMapForSelectedBerths.get(key) == null){
                    //Create a new connection of Berth and Terminal selected
                    btsToInsert.add(new Berth_Terminal__c(
                        Berth__c = selectedBerthId,
                        Terminal__c = tId,
                        Name = btMap.get(selectedBerthId) + ', ' + tMap.get(tId).Name
                        ));

                    //Delete the existing connection
                    for(String keyString : btMapForSelectedBerths.keySet()){

                        String Terminal = keyString.split(',')[0];
                        String Berth = keyString.split(',')[1];

                        if(Berth == selectedBerthId){
                            btsToDelete.put(btMapForSelectedBerths.get(keyString).Id, btMapForSelectedBerths.get(keyString));
                        }
                    }

                }

            }

        }
        
        insert btsToInsert;
        delete btsToDelete.values();

        termBerths = null;
        berths = null;
        assignBerth = false;
        berthAssignMap = null;
    }
    public void saveCargoType() {
        update selCargoType;
        selCargoType = null;
        cargoTypeSelected = false;
    }
    public void deleteCargoType() {
        delete selCargoType;
        selCargoType = null;
        cargoTypeSelected = false;
    }
    public void cancelNewBerth() {
        addingBerth = false;
    }
    public void regionChanged() {
        selCountry = countryOpts[0].getValue();
    }

    public void countryChanged() {
        ports = null;
    }

    public Location__c selLocation {
        get {
            if (selPortReq.Location__c != null) {
                return [select Name, isocode__c, Type__c, OwnerId from Location__c where Id = :selPortReq.Location__c];
            }
            return null;
        }
        set;
    }

    public void selectRegion() {
        selPortReq.Location__c = selRegion;
    }
    public void selectCountry() {
        selPortReq.Location__c = selCountry;

    }
    public void selectPort() {
        System.debug('### ports: ' + ports);
        for (Port__c p:ports) {
            System.debug('### port: ' + p);
            if (p.Port_Code__c == selPortCode) {
                //selLocation = null;
                selPortReq.Location__c = null;
                selPort = p;
                selPortReq.Port__c = p.Id;
                if (!dummyPortRequest) {
                    update selPortReq;
                }
                return;
            }
        }
    }
    public List<String> terminalSelType {
        get;
        set {
            terminals = null;
            system.debug('-----ter value'+value);
            terminalSelType = value;
        }
    }
    public String berthSelCargoHandling {
        get;
        set {
            System.debug('### berthSelCargoHandling');
            berths = null;
            berthSelCargoHandling = value;
        }
    }

    public List<String> berthSelCargoGroups {
        get;
        set {
            berths = null;
            berthSelCargoGroups = value;
        }
    }
    public List<String> berthSelCargoTypes {
        get;
        set {
            System.debug('### berthSelCargoTypes');
            berths = null;
            berthSelCargoTypes = value;
        }
    }

    public String[] berthSelGearTypes {
        get;
        set {
            System.debug('### berthSelGearTypes');
            berths = null;
            berthSelGearTypes = value;
        }
    }

    public Boolean cargoHandlingsDisabled {
        get {
            if (berthSelCargoTypes == null || berthSelCargoTypes.size() == 0) {
                return true;
            }
            return false;
        }
        private set;
    }

    public Boolean gearTypesDisabled {
        get {
            if (cargoHandlingsDisabled == true || berthSelCargoHandling == null || berthSelCargoHandling == '') {
                return true;
            }
            return false;
        }
        private set;
    }

    public Id termEditId {get;set;}
    public Boolean editingTerminal {get;set;}
    public void editTerminal() {
        editingTerminal = true;
        system.debug('----editingTerminal------'+editingTerminal);
    }
    public void doneEditTerminal() {
        editingTerminal = false;
        terminals = null;
        system.debug('----editingTerminal------'+editingTerminal);
    }

    public void addTerminal() {
        Terminal__c term = new Terminal__c(Name='NEW TERMINAL', Port__c=selPort.Id);
        insert term;
        termEditId = term.Id;
        editingTerminal = true;
    }
    public Boolean canDeleteTerminal {
        get {
            return Schema.sObjectType.Terminal__c.isDeletable();
        }
        private set;
    }
    public void deleteTerminal() {
        Terminal__c delTerm = new Terminal__c(Id=termEditId);
        try {
            delete delTerm;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to delete terminal: ' + e.getMessage()));
        }
    }

    public Id actTermId {get;set;}
    public void clearSelTerminal() {
        selTerminals = null;
    }
    public void selTerminalCtrl() {
        berths = null;
        termBerths = null;
        berthselcargotypes = null; 
        if (selTerminals == null) {
            selTerminals = new Set<Id>();
        }
        selTerminals.add(actTermId);

    }
    public void selTerminal() {
        clearSelTerminal();
        selTerminalCtrl();
    }
    public void unselTerminal() {
        System.debug('### unselTerminal');
        berths = null;
        termBerths = null;
        berthselcargotypes = null; 

        if (selTerminals == null) {
            selTerminals = new Set<Id>();
        }
        selTerminals.remove(actTermId);
    }

    public Boolean berthSelected {get;set;}
    public Id actBerthId {get;set;}
    public Berth__c selBerth {get;set;}
    public void selBerth() {
        berthSelected = true;
        System.debug('### berths: ' + Berths);
        Map<Id, Berth__c> bmap = new Map<Id, Berth__c>(Berths);
        selBerth = bmap.get(actBerthId);
    }

    public Boolean cargoTypeSelected {get;set;}
    public Id actCargoTypeId {get;set;}

    public Cargo_Type__c selCargoType {get;set;}
    public void selCargoType() {
        cargoTypeSelected = true;
        Map<Id, Cargo_Type__c> ctmap = new Map<Id, Cargo_Type__c>(actBerthCargoTypes);
        selCargoType = ctmap.get(actCargoTypeId);
    }
    public Cargo_Type__c[] actBerthCargoTypes {
        get {
            if (actBerthId != null) {
                actBerthCargoTypes = [select Name, Berth__c, Cargo_Group__c, Cargo_Handling__c, Cargo_Type__c, 
                                             Discharge_Methods__c, Load_Methods__c, Description__c
                                        from Cargo_Type__c
                                       where Berth__c = :actBerthId];
            }
            return actBerthCargoTypes;
        }
        private set;
    }
    public void createNewCargoType() {
        if (actBerthId != null && berthSelected == true) {
            insert new Cargo_Type__c(Berth__c=actBerthId);
        }
    }
    public PageReference changePort() {
        ports   = null;
        selPort = null;
        this.selPortReq.Port__c = null;
        channels = null;
        terminals = null;
        System.debug('### changePort');
        berths = null;
        termBerths = null;
        portChanged = true;
        return null;
    }

    public PageReference submitToPortResponsible() {
        selPortReq.Status__c = 'Submitted';
        selPortReq.Submitted_By__c = UserInfo.getUserId();
        if (selPort == null) {
            selPortReq.OwnerId = selLocation.OwnerId;
        } else {
            selPortReq.OwnerId = selPort.OwnerId;
            selPortReq.Port__c = selPort.Id;
        }
        if (!dummyPortRequest) {
            update selPortReq;
        }
        Schema.DescribeSObjectResult PRDSObjectSchema = Port_Request__c.SObjectType.getDescribe();
        String objectIdPrefix = PRDSObjectSchema.getKeyPrefix();

        PageReference pr = new PageReference('/'+objectIdPrefix+'/o');
        //PageReference pr = new PageReference('/'+selPortReq.Id);
        return pr;
    }

    public Boolean portChanged {get;set;}
    public void updatePortRequest() {
        portChanged = false;
        if (!dummyPortRequest) {
            update selPortReq;
        }
    }
    public Port__c editingPort {get;set;}
    public Boolean portedit {get;set;}
    public void editPort() {
        editingPort = selPort;
        portedit = true;
    }
    public void savePort() {
        portedit = false;
        update editingPort;
        selPort = editingPort;
    }
    public void cancelPort() {
        portedit = false;
        selPort = editingPort;
    }

    public PageReference cloneBerths() {
        Map<Id, Cargo_Type__c[]> bctMap = new Map<Id, Cargo_Type__c[]>();
        Map<Id, Berth__c> bMap = new Map<Id, Berth__c>(); // Map containing Id of original and cloned berth
        Berth__c[] iBerths  = new Berth__c[]{}; // List of berths to insert
        for (Berth__c b:berths) {
            if (b.Selected__c == true) {
                Berth__c nb = b.clone();
                nb.Name = 'Copy of ' + nb.Name;
                bMap.put(b.Id, nb);
                iBerths.add(nb);
            }
        }
        insert iBerths; // Insert cloned berths
        Cargo_Type__c[] cts = new Cargo_Type__c[]{};
        for (Cargo_Type__c ct:[select Name, Berth__c, Cargo_Group__c, Cargo_Handling__c, Cargo_Type__c, 
                                      Discharge_Methods__c, Load_Methods__c, Description__c
                                 from Cargo_Type__c
                                where Berth__c in :bMap.keySet()]) {
            Cargo_Type__c nct = ct.clone();
            nct.Berth__c = bMap.get(ct.Berth__c).Id;
            cts.add(nct);
        }
        insert cts;
        return null;
    }

    public PageReference createBerthAlternatives() {
        selPortReq.Status__c = 'Describing';
        Berth_Alternative__c balt; // outside of loop - take care of stack
        for (Berth__c b:berths) {
            balt = berth2Alternative.get(b.Id);
            System.debug('### balt: ' + balt);
            System.debug('### b.Selected__c: ' + b.Selected__c);
            if (b.Selected__c == true) {
                if (balt == null) {
                    balt = new Berth_Alternative__c(
                        Name = selPort.name + b.name,
                        Port_Request__c = selPortReq.Id,
                        Berth__c = b.Id);
                    balt.Description__c = '';
                    if (b.Description__c != null) {
                        balt.Description__c += 'Comment copied in from Berth - delete/add as appropriate:\n';
                        balt.Description__c += b.Description__c;
                        balt.Description__c += '\n\n';
                    }
                    Boolean first = true;
                    system.debug('----berthCargoTypesMap----'+berthCargoTypesMap);
                    system.debug('----b.Id----'+b.Id);
                    if(berthCargoTypesMap.get(b.Id) != null){

                        for (Cargo_Type__c ct:berthCargoTypesMap.get(b.Id)) {
                            if (ct == null) {
                                continue;
                            }
                            if (ct.Description__c != null) {
                                if (first) {
                                    balt.Description__c += 'Comments copied in from Cargo types - delete/add as appropriate:\n';
                                    first = false;
                                }
                                balt.Description__c += 'Cargo type: ' + ct.Cargo_Type__c + '\n';
                                balt.Description__c += ct.Description__c + '\n\n';

                            }
                        }
                    }
                        
                    selBerth2Alternative.put(b.Id, balt);
                    berth2Alternative.put(b.Id, balt);
                    balts.add(balt);
                }
                balt.Status__c = 'Suggested';
            } else if (b.Selected__c == false) {
                if (balt != null) {
                    balt.Status__c = 'Retracted';
                }
            }
            balt = null; // ready for next loop (should not be necessary, but hey ...)
        }
        return null;
    }

    public PageReference completePortRequest() {
        selPortReq.Status__c = 'Answered';
        if (!dummyPortRequest) {
            update selPortReq;
        }
        upsert balts;
        //PageReference ret = new PageReference('/');
        //return ret;
        //return null; // just stay here.

        Schema.DescribeSObjectResult PRDSObjectSchema = Port_Request__c.SObjectType.getDescribe();
        String objectIdPrefix = PRDSObjectSchema.getKeyPrefix();

        PageReference pr = new PageReference('/'+objectIdPrefix+'/o');
        //PageReference pr = new PageReference('/'+selPortReq.Id);
        return pr;
    }
    public Boolean showPreview{
        get{
            if(showPreview == null){
                showPreview = false;
            }
            return showPreview;
        }set;}
    public PageReference savePortRequest() {
        selPortReq.Status__c = 'Submitted';
        showPreview = true;
        if (!dummyPortRequest) {
            update selPortReq;
        }
        upsert balts;
        return null;
    }
    public PageReference cancelPortRequest() {
        selPortReq.Status__c = 'Submitted';
        return null;
    }
    public String mapType {
        get {
            if (zoomLevel <= 3) {
                return 'roadmap';
            }
            return 'satellite';
        }
        private set;
    }
    public Integer zoomLevel {get;set;}
    public void zoomIn() {
        zoomLevel = 15;
    }
    public void zoomOut() {
        zoomLevel = 3;
    }

    public void resetCargoFilters() {
        berthSelGearTypes = null;
        berthSelCargoHandling = null;
        berthSelCargoTypes = null;
        berthSelCargoGroups = null;
    }
    public void resetTerminalFilter() {
        terminalSelType = null;
    }

    ////////////////clone/////////

    public String selectedBertId {get; set {
            selectedBertId = value;
            System.debug('value: '+value);
        }}
    public PageReference berthClone(){

        Map<Id, Cargo_Type__c[]> bctMap = new Map<Id, Cargo_Type__c[]>();
        Map<Id, Berth__c> bMap = new Map<Id, Berth__c>(); // Map containing Id of original and cloned berth
        Berth__c[] iBerths  = new Berth__c[]{}; // List of berths to insert

        Berth__c selectedBert = [select Name,Primary_Terminal__c, Berth_Length__c, Port__c, Selected__c, Berth_Length_Depth__c, Berth_No__c, Berth_Type__c, 
                                 Description__c, LastModifiedDate, Max_DWT__c, Max_Sailing_Draft__c, Max_Sailing_Draft_Comment__c, 
                                 Min_UKC_mtr__c, Max_LOA__c, Max_Beam__c, Max_DWT_Displacement__c, Max_Airdraft_Mast__c, 
                                 Max_Airdraft_Hatch__c, Berth_Depth__c
                                 from Berth__c where id = : selectedBertId];

        Berth__c nb = selectedBert.clone();
        //nb.Name = 'Copy of ' + nb.Name;
        bMap.put(selectedBert.Id, nb);
        iBerths.add(nb);
        system.debug('-iBerths--------'+iBerths);
        insert iBerths; // Insert cloned berths
        Cargo_Type__c[] cts = new Cargo_Type__c[]{};
        for (Cargo_Type__c ct:[select Name, Berth__c, Cargo_Group__c, Cargo_Handling__c, Cargo_Type__c, 
                                      Discharge_Methods__c, Load_Methods__c, Description__c
                                 from Cargo_Type__c
                                where Berth__c in :bMap.keySet()]) {
            Cargo_Type__c nct = ct.clone();
            nct.Berth__c = bMap.get(ct.Berth__c).Id;
            cts.add(nct);
        }
        system.debug('-cts--------'+cts);
        insert cts;

        ///Bert terminal
        List<Berth_Terminal__c> bertTerList = new List<Berth_Terminal__c>();
        for(Berth_Terminal__c bt : [select Terminal__r.Name,Berth__c, Terminal__r.Terminal_Name_local__c, Terminal__r.Operator_Manager_Name__c,
                        Terminal__r.Terminal_Type__c, Terminal__r.LastModifiedDate
                        from Berth_Terminal__c
                        where Berth__c =: bMap.keySet()]){

            Berth_Terminal__c nbt = bt.clone();
            nbt.Berth__c = bMap.get(bt.Berth__c).Id;
            nbt.Terminal__c = bt.Terminal__c;
            nbt.Name = bt.Berth__c+', '+bt.Terminal__r.name;
            bertTerList.add(nbt);
        }
        insert bertTerList;
        termBerths = null;
        return null;
    }
}