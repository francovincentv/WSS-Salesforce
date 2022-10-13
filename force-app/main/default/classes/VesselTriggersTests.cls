/*
 * (C) 2015 Finn Arild Aasheim, Fluido Oy. No liabilities accepted.
 * 
 */
@isTest
private class VesselTriggersTests
{
/*
	@isTest
	static void testCreateVesselNewBuildOpportunity() {
		Product2[] ps = new Product2[] {
			new Product2(IsActive=true, Name='BW/CW Treatment', ProductCode='S100'),
			new Product2(IsActive=true, Name='Welding', ProductCode='S132')
		};
		insert ps;

		Vessel_Product__c[] vps = new Vessel_Product__c[] {
			new Vessel_Product__c(Product__c=ps[0].Id, Scenario__c='Dry-docking', Product_Code__c='S100', VesselStatcode5__c='A33A2CC', Price__c=0.0, Gt_category__c='0-999999', Quantity__c=1.0, Interval__c=60),
			new Vessel_Product__c(Product__c=ps[1].Id, Scenario__c='Dry-docking', Product_Code__c='S132', VesselStatcode5__c='A12B2TR', Price__c=5000.0, Gt_category__c='15000-29999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[0].Id, Scenario__c='New build', Product_Code__c='S100', VesselStatcode5__c='A33A2CC', Price__c=10000.0, Gt_category__c='100000-999999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[0].Id, Scenario__c='New build', Product_Code__c='S100', VesselStatcode5__c='A33A2CC', Price__c=5000.0, Gt_category__c='50000-99999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[0].Id, Scenario__c='New build', Product_Code__c='S100', VesselStatcode5__c='A33A2CC', Price__c=5000.0, Gt_category__c='20000-49999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[0].Id, Scenario__c='New build', Product_Code__c='S100', VesselStatcode5__c='A33A2CC', Price__c=0.0, Gt_category__c='10000-19999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[0].Id, Scenario__c='New build', Product_Code__c='S100', VesselStatcode5__c='A33A2CC', Price__c=0.0, Gt_category__c='5000-9999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[0].Id, Scenario__c='New build', Product_Code__c='S100', VesselStatcode5__c='A33A2CC', Price__c=0.0, Gt_category__c='1000-4999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[0].Id, Scenario__c='New build', Product_Code__c='S100', VesselStatcode5__c='A33A2CC', Price__c=0.0, Gt_category__c='0-999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[1].Id, Scenario__c='New build', Product_Code__c='S132', VesselStatcode5__c='A33A2CC', Price__c=10000.0, Gt_category__c='100000-999999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[1].Id, Scenario__c='New build', Product_Code__c='S132', VesselStatcode5__c='A33A2CC', Price__c=5000.0, Gt_category__c='50000-99999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[1].Id, Scenario__c='New build', Product_Code__c='S132', VesselStatcode5__c='A33A2CC', Price__c=5000.0, Gt_category__c='20000-49999', Quantity__c=1.0),
			new Vessel_Product__c(Product__c=ps[1].Id, Scenario__c='New build', Product_Code__c='S132', VesselStatcode5__c='A33A2CC', Price__c=0.0, Gt_category__c='10000-19999', Quantity__c=1.0)
		};
		insert vps;

		Id stdPB = Test.getStandardPricebookId();

		PricebookEntry[] standardProductEntries = new PricebookEntry[] {
			new PricebookEntry(Pricebook2Id=stdPB, Product2Id=ps[0].Id, IsActive=true, UnitPrice=0.0),
			new PricebookEntry(Pricebook2Id=stdPB, Product2Id=ps[1].Id, IsActive=true, UnitPrice=0.0)
		};
		insert standardProductEntries;

    	UserRole[] rls = [select Id from UserRole where DeveloperName = 'AccountManagerEASTSOUTHAFRICA'];
		
		// Create users 
		Profile pf = [select Id from Profile where Name = 'WSS - International Sales & Head Office'];

		//Create two different Users
		User whu = new User(email='standarduser1@testorg.com', emailencodingkey='UTF-8', lastname='Testing', ProfileId=pf.Id,
						  		    languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles',
						  		    username='wilhelm@i.no', Alias='willhelm', CommunityNickname='willyouhaveahelm', UserRoleId=rls[0].Id);
		insert whu;

		Account a = new Account(Name='kake', OwnerId=whu.Id);
		System.debug('### a: ' + a);
		insert a;

		IHS_Fairplay_Company__c fpc = new IHS_Fairplay_Company__c(Name='Johnnyboy', WSS_Account__c=a.Id, IHS_Company_Id__c='40000');
		insert fpc;

		Date deliverDate = Date.today().addDays(60);
		Vessel__c[] vsls = new Vessel__c[]{ // TODO - Add Create_Automatic_Opportunity__c 
			new Vessel__c(Name='SkattenMin', IHS_Manager__c=fpc.Id, Manager_Account__c=a.Id, Default_Account__c=a.Id, Statcode5__c='A33A2CC', Gt__c=6000.0, Status__c='On Order', Due_or_delivered__c=deliverDate),
			new Vessel__c(Name='GjeldaMi', IHS_Manager__c=fpc.Id, Manager_Account__c=a.Id, Default_Account__c=a.Id, Statcode5__c='A33A2CC', Gt__c=6000.0, Status__c='On Order'),
			new Vessel__c(Name='ElskerinnaMi', IHS_Manager__c=fpc.Id, Manager_Account__c=a.Id, Default_Account__c=a.Id, Statcode5__c='A33A2CC', Gt__c=6000.0, Status__c='Delivered', Due_or_delivered__c=deliverDate.addMonths(-30)),
			new Vessel__c(Name='GubbenHennes', IHS_Manager__c=fpc.Id, Manager_Account__c=a.Id, Default_Account__c=a.Id, Statcode5__c='A33A2CC', Gt__c=6000.0, Status__c='Delivered')
		};
		
		insert vsls;

		Opportunity[] ops = [select Id from Opportunity];
		System.assertEquals(ops.size(), 2);

		OpportunityLineItem[] olis = [select Id from OpportunityLineItem where OpportunityId = :ops[0].Id];
		System.assert(olis.size() > 0);

		// Test change of date
		deliverDate = deliverDate.addDays(20);
		vsls[0].Due_or_delivered__c = deliverDate;
		update vsls[0];

		ops = [select Id from Opportunity];
		System.assertEquals(ops.size(), 2);

		Opportunity o = [select CloseDate from Opportunity where Vessel__c = :vsls[0].Id];
		System.assertEquals(o.CloseDate, deliverDate);

		// Test update vessel so it fits the date
		vsls[1].Due_or_delivered__c = deliverDate;
		// And update the delivered due & delivered with 30 months so it should create a new one11
		vsls[2].Due_or_delivered__c = deliverDate.addMonths(30);
		update vsls;

		ops = [select Id from Opportunity];
		System.assertEquals(ops.size(), 4);

	}
*/
	@isTest
	static void testLookupVesselValues() {
    	UserRole[] rls = [select Id from UserRole where DeveloperName = 'AccountManagerEASTSOUTHAFRICA'];
		
		// Create users 
		Profile pf = [select Id from Profile where Name = 'WSS - International Sales & Head Office'];
		// Create users
		User whu = new User(email='standarduser1@testorg.com', emailencodingkey='UTF-8', lastname='Testing', ProfileId=pf.Id,
						  		    languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles',
						  		    username='wilhelm@i.no', Alias='willhelm', CommunityNickname='willyouhaveahelm', UserRoleId=rls[0].Id);
		insert whu;

		Account[] acs = new Account[] {
			new Account(Name='bake', IFS_Account_Id__c = '80000', OwnerId=whu.Id, Account_Number__c='8000040041'),
			new Account(Name='kake', IFS_Account_Id__c = '81000', OwnerId=whu.Id, Account_Number__c='8000040042'),
			new Account(Name='kake', IFS_Account_Id__c = '82000', OwnerId=whu.Id, Account_Number__c='8000040043'),
			new Account(Name='kake', IFS_Account_Id__c = '83000', OwnerId=whu.Id, Account_Number__c='8000040044'),
			new Account(Name='kake', IFS_Account_Id__c = '84000', OwnerId=whu.Id, Account_Number__c='8000040045'),
			new Account(Name='kake', IFS_Account_Id__c = '85000', OwnerId=whu.Id, Account_Number__c='8000040046'),
			new Account(Name='kake', IFS_Account_Id__c = '86000', OwnerId=whu.Id, Account_Number__c='8000040047'),
			new Account(Name='kake', IFS_Account_Id__c = '87000', OwnerId=whu.Id, Account_Number__c='8000040048')
		};
		insert acs;
		acs[1].ParentId = acs[0].Id;
		update acs[1];
		IHS_Fairplay_Company__c[] fpcs = new IHS_Fairplay_Company__c[] {
			new IHS_Fairplay_Company__c(Name='Bakeriet', WSS_Account__c=acs[0].Id, IHS_Company_Id__c='40000'),
			new IHS_Fairplay_Company__c(Name='Kakeriet', WSS_Account__c=acs[1].Id, IHS_Company_Id__c='41000'),
			new IHS_Fairplay_Company__c(Name='Kakeriet', WSS_Account__c=acs[1].Id, IHS_Company_Id__c='42000'),
			new IHS_Fairplay_Company__c(Name='Kakeriet', WSS_Account__c=acs[1].Id, IHS_Company_Id__c='43000'),
			new IHS_Fairplay_Company__c(Name='Kakeriet', WSS_Account__c=acs[1].Id, IHS_Company_Id__c='44000'),
			new IHS_Fairplay_Company__c(Name='Kakeriet', WSS_Account__c=acs[1].Id, IHS_Company_Id__c='45000'),
			new IHS_Fairplay_Company__c(Name='Kakeriet', WSS_Account__c=acs[1].Id, IHS_Company_Id__c='46000'),
			new IHS_Fairplay_Company__c(Name='Kakeriet', WSS_Account__c=acs[1].Id, IHS_Company_Id__c='47000')
		};
		insert fpcs;

		Vessel__c[] vls = new Vessel__c[] {
			new Vessel__c(Default_Payer_Account_ID_del__c='80000', IHS_Builder_ID_del__c='41000', Vessel_Sub_Type__c='A33A2C', Gt__c=25.0, Status__c='Delivered', Due_or_delivered__c=Date.today()),
			new Vessel__c(Default_Payer_Account_ID_del__c='81000', IHS_Manager_ID__c='42000', Vessel_Sub_Type__c='A33A2C', Gt__c=25.0, Status__c='Delivered', Due_or_delivered__c=Date.today()),
			new Vessel__c(Default_Payer_Account_ID_del__c='82000', IHS_Operator_ID__c='43000', Vessel_Sub_Type__c='A33A2C', Gt__c=25.0, Status__c='Delivered', Due_or_delivered__c=Date.today()),
			new Vessel__c(Default_Payer_Account_ID_del__c='83000', IHS_Owner_ID__c='44000', Vessel_Sub_Type__c='A33A2C', Gt__c=25.0, Status__c='Delivered', Due_or_delivered__c=Date.today()),
			new Vessel__c(Default_Payer_Account_ID_del__c='84000', IHS_P_and_I_ID__c='45000', Vessel_Sub_Type__c='A33A2C', Gt__c=25.0, Status__c='Delivered', Due_or_delivered__c=Date.today()),
			new Vessel__c(Default_Payer_Account_ID_del__c='52524', IHS_Registered_Owner_ID__c='46000', Vessel_Sub_Type__c='A33A2C', Gt__c=25.0, Status__c='Delivered', Due_or_delivered__c=Date.today()),
			new Vessel__c(Default_Payer_Account_ID_del__c='86000', IHS_Technical_Manager_ID__c='47000', Vessel_Sub_Type__c='A33A2C', Gt__c=25.0, Status__c='Delivered', Due_or_delivered__c=Date.today())
		};

		insert vls;

		vls = [select Default_Payer_Account__c, IHS_Builder__c, Default_Account__c from Vessel__c where Id in :vls];

		System.assertEquals(vls[0].Default_Payer_Account__c, acs[0].Id);
		System.assertEquals(vls[1].Default_Account__c, acs[0].Id);
		System.assertEquals(vls[2].Default_Account__c, null);
		System.assertEquals(vls[0].IHS_Builder__c, fpcs[1].Id);
		// TODO - needs all the permutations tested.
	}
}