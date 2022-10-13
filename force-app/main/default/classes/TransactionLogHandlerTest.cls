@isTest
public class TransactionLogHandlerTest {
    

    static testMethod void testInsertErrorWithAttach(){
        Test.startTest();
        TransactionLogHandler.insertErrorWithAttchment('testing', 'TransactionLogHandlerTest', 'test');
        Test.stopTest();

        List<Transaction_Log__c> tlLogs = [SELECT Id FROM Transaction_Log__c];

        System.assertEquals(1, tlLogs.size(), 'Error record not found');
        System.assertEquals(1, [SELECT Count() FROM ContentDocumentLink WHERE LinkedEntityId =: tlLogs[0].Id], 'Attachment not found');
    }
}