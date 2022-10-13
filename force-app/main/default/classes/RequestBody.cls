/*************************************************
* Class       	: RequestBody
* References  	: CPQ_PricingTest.cls
* Description 	: This class is called by the class CPQ_Pricing, which defines the structure of the request body that sends to the external system
* Change Log	
* Date Modified		Modified By 		Description of the update
* [02.Mar.2020]	    [Lokesh - Fluido]	[initial development]
**************************************************/
public class RequestBody{
    
	public List<String> customers;					//The related Contract parties account numbers
    public List<volume_override> volume_overrides;	//productCode and quantity of the quotelineitem
    public Integer order_size_override;				//Order_Size_Improvement__c of the quote
    public Integer predictability_override;			//Predictability_Improvement__c  of the quote
    
	public class volume_override {
		public String product_code;
		public Integer qty;
	}
    
    //empty consturctor
    public RequestBody() {
        
    }
}