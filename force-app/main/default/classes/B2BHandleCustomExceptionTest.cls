@isTest
public class B2BHandleCustomExceptionTest {
    
    public class B2BCustomException extends Exception {}
    
	@isTest
    static void testLogExceptionWithoutRelatedToId() {
        // Create a new custom exception
        B2BCustomException testException = new B2BCustomException('Test exception message');
        
        // Call the LogException method
        Test.startTest();
        B2BHandleCustomException.LogException(testException, 'TestCategory', 'TestSubcategory');
        Test.stopTest();
    }
}