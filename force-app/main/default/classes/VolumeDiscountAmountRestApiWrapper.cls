/*************************************************************************
 * Class       :   VolumeDiscountAmountRestApiWrapper
 * References  :   VolumeDiscountAmountRestApi.cls
 * Description :   This structure of the Volume discount based on amount request input 
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [19.Nov.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/

public class VolumeDiscountAmountRestApiWrapper {
    public class discountThresholds {
		public String id;
		public Double amount;
		public Double discountPercentage;
		public String currencyCode;
	}

	public String eventType;
	public String dataVersion;
	public String eventTime;
	public String metadataVersion;
	public String topic;
	public Data data;

	public class Data {
		public String productGroupId;
        public String modifiedOn;
        public List<discountThresholds> discountThresholds;
	}

	public static List<VolumeDiscountAmountRestApiWrapper> parse(String json) {
		return (List<VolumeDiscountAmountRestApiWrapper>) System.JSON.deserialize(json, List<VolumeDiscountAmountRestApiWrapper>.class);
	}
}