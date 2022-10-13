public class ProductUpsertRestApiWrapper {
    public String id;
	public String eventTime;
	public String eventType;
	public String dataVersion;
	public String metadataVersion;
	public String topic;
	public String subject;
	public String deadLetterReason;
	public Integer deliveryAttempts;
	public String lastDeliveryOutcome;
	public Integer lastHttpStatusCode;
	public String publishTime;
	public String lastDeliveryAttemptTime;
    public Data data;
    
    public class Data {
		public String productId;
		public String classification;
		public String productName;
		public String mainProductGroupId;
		public String mainProductGroupName;
		public String productGroupId;
		public String productGroupName;
		public String assetClass;
		public String assetClassName;
		public String productClass;
		public String productFamilyCode;
		public String productFamilyName;
		public String salesProductGroup;
		public String uomId;
		public String catalogType;
		public String solution;
		public String businessUnitId;
		public String partProductCode;
		public String partProductName;
		public String partStatusCode;
		public String partStatusName;
		public String site;
		public String masterType;
		public List<String> replicatedSites;
		public Double netWeight;
		public String netWeightUom;
		public String hazardClassCode;
		public String hazardClassName;
		public String modifiedOn;
	}

	
	public static List<ProductUpsertRestApiWrapper> parse(String json) {
		return (List<ProductUpsertRestApiWrapper>) System.JSON.deserialize(json, List<ProductUpsertRestApiWrapper>.class);
	}
}