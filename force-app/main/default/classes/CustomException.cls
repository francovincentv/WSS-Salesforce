/*************************************************
* Class                 : CustomException
* References            : CustomerContractIntegrationHelper.cls
* Description           : This class is used to create custom exception in other classes
* Change Log    
* Date Modified     Modified By         Description of the update
* [10.Aug.2020]     [Lokesh - Fluido]   [Initial development]
*************************************************/
public class CustomException extends Exception{

    public Boolean escape;
    public String errMsg ; 

    public CustomException(String errMsg, boolean escape){
        this.errMsg = errMsg;
        this.escape = escape;
    }
}