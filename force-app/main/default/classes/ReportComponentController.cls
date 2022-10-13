public with sharing class ReportComponentController {
    @AuraEnabled
    public static String getReportMetadata ( Id reportId, String filters ){
        System.debug(reportId);
        System.debug(filters);
        
        List<String> filterList = new List<String>();
        List<String> helperFilterList = new List<String>();
        Reports.ReportMetadata reportMd;
        if(!String.isEmpty(filters)){
            helperFilterList = filters.split(',');
            for(Integer i=0; i<helperFilterList.size(); i++) {
                if(!String.isBlank(helperFilterList[i])) {
                    if(i<helperFilterList.size()) {
                        if(! helperFilterList[i].contains('"')) {
                            filterList.add(helperFilterList[i]);
                        } else if(helperFilterList[i].substring(0,1) == '"' && helperFilterList[i+1].substring(helperFilterList[i+1].length()-1) == '"'  ) {
                            filterList.add(helperFilterList[i]+','+helperFilterList[i+1]);
                        }
                    }
                }
                else filterList.add(helperFilterList[i]);
            }
            
        }
        System.debug(helperFilterList);

        if(!filterList.isEmpty()){
            // Apply report filters
            // Get the report metadata
            Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
            reportMd = describe.getReportMetadata();
            List<Reports.ReportFilter> reportFilters = reportMd.getReportFilters();
            for (Integer i = 0; i < reportFilters.size(); i++) {
                System.debug(filterList.size()+': '+String.valueOf(filterList.size()<i));
                if(filterList.size()==i)
                    break;
                System.debug(filterList[i]);
                System.debug(reportFilters[i].getColumn());
                System.debug(reportFilters[i].getValue());
                if(!String.isEmpty(filterList[i]))
                reportFilters[i].setValue(filterList[i]);
            }
        }
        Reports.ReportResults results;
        if(reportMd != null)
        results = Reports.ReportManager.runReport(reportId, reportMd, true);
        else
        results = Reports.ReportManager.runReport(reportId, true);
        
        return JSON.serializePretty(results);
    }
    
    @AuraEnabled(cacheable=false)
    public static String getReportIdFromDeveloperName(String developerName){
        System.debug(developerName);
        return String.valueOf([SELECT Id FROM Report WHERE DeveloperName = :developerName]?.Id);
    }
}