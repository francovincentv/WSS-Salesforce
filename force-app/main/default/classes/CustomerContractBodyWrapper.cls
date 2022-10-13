public with sharing class CustomerContractBodyWrapper {

    public CustomerContractBodyWrapper() {

    }

    public class SpecialCommitmentOffer {
        public String currencyId;
        public String commitmentId;
        public String createdOn;
        public String modifiedOn;
        public String activeOn;
        public String expiresOn;
        public String title;
        public String accountId;
        public List<Customers> customers;
        public List<ContractLines> contractLines;
    }

    public String eventType;
    public String subject;
    public String id;
    public Data data;
    public String dataVersion;
    public String eventTime;
    public String topic;

    public class Customers {
        public String currencyId;
        public String customerId;
        public String activeOn;
        public String createdOn;
        public String expiresOn;
    }

    public class ContractLines {
        public Integer qty;
        public String productOrGroupNumber;
        public String activeOn;
        public Decimal additionalDiscountPercentage;
        public Boolean isProductGroup;
        public List<ProductPrice> productPrices;
    }

    public class ProductPrice {
        public Decimal discountPercentage;
        public Decimal productPrice;
        public Set<String> validPorts;
        public Boolean validForAllPorts;
    }

    public class Data {
        public String currencyId;
        public String contractNumber;
        public String createdOn;
        public String modifiedOn;
        public String activeOn;
        public String expiresOn;
        public String title;
        public String accountId;
        public Integer contractedFleet;
        public List<Customers> customers;
        public List<ContractLines> contractLines;
        public List<SpecialCommitmentOffer> specialCommitmentOffer;
        public CustomerBonus customerBonus;
    }

    public class CustomerBonus {
        public Boolean applicableForRebateScheme;
        public BrokerageFee brokerageFee;
        public ShipManagerBonus shipManagerBonus;
        public String oppRecType; //added for spg thresholds
		public Boolean newPartiesAdded; //added for spg thresholds
		public String relatedContr; //added for spg thresholds
        public PortfolioRebateScheme portfolioRebateScheme; 
    }

    public class PortfolioRebateScheme {
		public Integer minimumSales;	
		public List<SpgThresholds_z> spgThresholds;	
		public List<RebateThresholds> rebateThresholds;	
	}

    public class SpgThresholds_z {	
		public Decimal amount;	
		public String currencyCode;	
		public String salesProductGroupId;
        public String salesProductGroupName;
	}

    public class RebateThresholds {	
		public String id;	
		public Decimal rebatePercentage;	
		public Decimal salesProductGroupCount;	
	}
    
    public class BrokerageFee {
        public Decimal bonusPercentage;
    }

    public class SpgThresholds {
        public List<String> spgs;
        public List<Thresholds> thresholds;
    }

    public class ProductGroupThresholds {
        public List<String> productGroupIds;
        public List<Thresholds> thresholds;
    }

    public class ShipManagerBonus {
        public List<SpgThresholds> spgThresholds;
        public List<ProductGroupThresholds> productGroupThresholds;
    }

    public class Thresholds {
        public Decimal lowAmount;
        public String currencyId;
        public Decimal bonusPercentage;
    }
    /* 
    public static List<CustomerContractBodyWrapper> parse(String json) {
        return (List<CustomerContractBodyWrapper>) System.JSON.deserialize(json, List<CustomerContractBodyWrapper>.class);
    } */
}