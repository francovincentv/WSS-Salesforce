public class PCESearchFormController {
    @AuraEnabled
	public static String[] getlports() {
		PCETestpageController ptc = new PCETestpageController();
		return new List<String>(ptc.ports);
	}

	@AuraEnabled
	public static String[] getlcargos() {
		PCETestpageController ptc = new PCETestpageController();
		return new List<String>(ptc.cargotypes);
	}


}