public  class PortIntegrationRestApiWrapper {
    public String schema;
	public Data data;
	public String subject;
	public String id;
	public String eventType;
	public String dataVersion;
	public String metadataVersion;
	public String eventTime;
	public String topic;

	public class Data {
		public String portId;
		public String portCountryCode;
		public String portCountryName;
		public String portName;
		public String modifiedOn;
	}

	
	public static List<PortIntegrationRestApiWrapper> parse(String json) {
        return (List<PortIntegrationRestApiWrapper>) System.JSON.deserialize(json, List<PortIntegrationRestApiWrapper>.class);
    }
}