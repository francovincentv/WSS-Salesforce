/*************************************************************************
 * Class       :   VolumeDiscountRestApiWrapper
 * References  :   VolumeDiscountRestApi.cls
 * Description :   This structure of the Volume discount request input 
 * Change Log	
 * Date Modified		  Modified By 		    Description 
 * ---------------------------------------------------------------------
 * [23.Sep.2020]	    [Lokesh - Fluido]	 [initial development]
 **************************************************************************/
public class VolumeDiscountRestApiWrapper {

	public class DiscountThresholds {
		public String id;
		public Double quantity;
		public Double discountPercentage;
	}

	public String id;
	public Data data;

	public class Data {
		public String productNumber;
		public String modifiedOn;
		public List<DiscountThresholds> discountThresholds;
	}

	public static List<VolumeDiscountRestApiWrapper> parse(String json) {
		return (List<VolumeDiscountRestApiWrapper>) System.JSON.deserialize(json, List<VolumeDiscountRestApiWrapper>.class);
	}
}