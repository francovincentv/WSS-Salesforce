@isTest
private class ReportComponentControllerTest {
    
    @isTest(seeAllData=true) static void getReportMetadata_validID(){
        Report aReport = [ SELECT Id, Name FROM Report LIMIT 1];
        Test.startTest();
            String reportJSON = ReportComponentController.getReportMetadata(aReport.Id, ',1000000027,,Transactional,Algeria,,,Transactional,,Algeria');
        Test.stopTest();

        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(reportJSON);
        Map<String, Object> reportMetadata = (Map<String, Object>)m.get('reportMetadata');
        System.assertEquals( aReport.Name, reportMetadata.get('name'), 'The correct report should be returned' );
    }

    @isTest static void getReportMetadata_invalidID(){
        Id bogusId = '00Q000000000000';
        NoDataFoundException expectedEx;
        String reportJSON;
        try{
            Test.startTest();
                reportJSON = ReportComponentController.getReportMetadata(bogusId, ',1000000027,,Transactional,Algeria,,,Transactional,,Algeria');
            Test.stopTest();
        } catch( NoDataFoundException ex ){
            expectedEx = ex;
        }

        System.assertEquals( null, reportJSON, 'No report json should be returned' );
        System.assertNotEquals( null, expectedEx, 'An exception should been thronw to be handled by the front-end' );
    }
    
    @isTest(seeAllData=true) static void getReportIdFromDeveloperName_TestMethod(){
        String repId = ReportComponentController.getReportIdFromDeveloperName('Active_OPEs_Related_to_SubAccounts_JeC');
        System.assertEquals( repId.length(), 18 );
    }
}