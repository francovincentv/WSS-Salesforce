public with sharing class PurchaseHistoryRestApiWrapper {
    public String id;
	public String eventTime;
	public String eventType;
	public String dataVersion;
	public String metadataVersion;
	public String topic;
	public String subject;
	public Data data;

	public class OrderLines {
		public String modifiedOn;
		public String productId;
		public String lineNo;
		public String relNo;
		public Integer lineItemNo;
		public String createdDate;
		public String deliveryDate;
		public String invoiceNo;
		public String invoiceDate;
		public String qty;
		public String qtyRefr;
		public String transactionCurrencyId;
		public String amount;
		public String accountSalesIncome;
		public String invoiceSeries;
	}

	public class Data {
		public String modifiedOn;
		public String orderNo;
		public String site;
		public String port;
		public String vessel;
		public String salesActivity;
		public String payer;
		public String orderType;
		public List<OrderLines> orderLines;
	}

	
	public static List<PurchaseHistoryRestApiWrapper> parse(String json) {
		return (List<PurchaseHistoryRestApiWrapper>) System.JSON.deserialize(json, List<PurchaseHistoryRestApiWrapper>.class);
	}
}