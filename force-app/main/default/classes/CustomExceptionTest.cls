@isTest
public class CustomExceptionTest {
    
    static testMethod void testException(){
        Test.startTest();
        CustomException c = new CustomException('test', false);
        Test.stopTest();

        System.assertEquals('test', c.errMsg, 'Error Message is not matched');
    }
}