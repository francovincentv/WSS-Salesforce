/*************************************************
* Class       	: QuotePdfWrapper
* References  	: QuotePdfRestApi.cls
* Description 	: This is the helper class for QuotePdfRestApi.cls
*                   This is a wrapper class to maintain the structure of the JSON body for the callout
* Change Log	
* Date Modified		Modified By 		Description 
* -----------------------------------------------------------
* [28.May.2020]	    [Lokesh - Fluido]	[initial development]
**************************************************/
public class QuotePdfWrapper{
    
	public List<String> customers;					//quote -> opportunity -> Contract parties->account number
    public Decimal orderSizeOverride;				//Order_Size_Improvement__c of the quote
    public Decimal predictabilityOverride;			//Predictability_Improvement__c  of the quote
    public Decimal fleetSize;                       //Fleet_size__ of the quote
    public List<salesOverride> salesOverrides;      //productGroup and ? of the quotelineitem
    public List<volumeOverride> volumeOverrides;	//productCode and quantity of the quotelineitem
    
	public class VolumeOverride {
		public String productId;
        public Integer qty;
        public Decimal finalDiscount;
    }
    
    public class SalesOverride {
        public String productGroup;
        public Decimal salesUsd;
    }
    
    //empty consturctor
    public QuotePdfWrapper() {
        
    }
}