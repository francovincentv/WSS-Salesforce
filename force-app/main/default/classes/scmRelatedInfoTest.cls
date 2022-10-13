@isTest
public class scmRelatedInfoTest {
    @isTest static void scmRelatedInfoTest(){
        ScmRelatedInfo scmRelatedInfo;
        scmRelatedInfo = new ScmRelatedInfo();
        scmRelatedInfo.scmName = 'Test Name';
        
        WSS_Solution__c wssSolution;
        wssSolution = new WSS_Solution__c();
        wssSolution.Name = 'Test Solution';
        wssSolution.Solution_Category__c = WSS_Solution__c.Solution_Category__c.getDescribe().getPicklistValues()[0].getValue();
        insert wssSolution;
        
        Product2 product;
        product = new Product2();
        product.Name = 'Test Product';
        insert product;
        
        Site__c site;
        site = new Site__c();
        site.Name = 'Test Site';
        site.Site_Abbreviation__c = 'TS';
        insert site;
        
        SCM_Implementation__c scmImplementation;
        scmImplementation = new SCM_Implementation__c();
        scmImplementation.Name = scmRelatedInfo.scmName;
        scmImplementation.Solution__c = wssSolution.id;
        scmImplementation.Campaign_start_date__c = date.parse('28.05.2021');
        scmImplementation.Reason__c = 'Sales Driven';
        scmImplementation.Define_the_problem__c = 'Test problem';
        scmImplementation.Describe_your_solution__c = 'Test problem solution';
        scmImplementation.Know_your_market_target__c = 'know market';
        scmImplementation.Describe_your_competition__c = 'Describe competition';
        scmImplementation.Financial_summary__c = 'Financial summary';
        scmImplementation.Show_traction_with_milestones__c = 'traction';
        scmImplementation.Exit_strategy__c = 'Exit Area';
        insert scmImplementation;
        
        
        ProdSite_SCMTEST__c prodSiteSCMTEST;
        prodSiteSCMTEST = new ProdSite_SCMTEST__c();
        prodSiteSCMTEST.SCM_Implementation__c = scmImplementation.id;
        prodSiteSCMTEST.Product__c = product.id;
        prodSiteSCMTEST.Site_Name__c = site.Id;
        prodSiteSCMTEST.Initial_stock_qty_at_launch__c = decimal.valueOf('100');
        prodSiteSCMTEST.Q1__c = decimal.valueOf('101');
        prodSiteSCMTEST.Q2__c = decimal.valueOf('102');
        prodSiteSCMTEST.Q3__c = decimal.valueOf('103');
        prodSiteSCMTEST.Q4__c = decimal.valueOf('104');
        insert prodSiteSCMTEST;
        system.debug(prodSiteSCMTEST.SCM_Implementation__c);
        
        List<ProdSite_SCMTEST__c> prodSites;
        prodSites = scmRelatedInfo.getProdSites();
        
        system.debug(prodSites);
        system.debug(scmRelatedInfo.scmName);
            system.assert(prodSites.size() == 1);
    }
}