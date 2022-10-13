global class PlugIn_StandardAssignment implements Process.Plugin { 

    @future
    public static void futureLeadReassign(Set<ID> lIdReassignSet) { 

        system.debug('### checkpoint futureLeadReassign ###');
        List<Lead> lUpdList = [SELECT Id FROM Lead WHERE Id IN: lIdReassignSet];
        for (Lead l:lUpdList) {
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;                                         // use leadAssignment rules when updating
            l.setOptions(dmo);
        }

        try {update(lUpdList);}
        catch (DmlException e) {/* do something here like send email to sysad with error */}
    }


    public static Map <String,Object> processAssignment (id sObjectId)
    {
        system.debug('### checkpoint processAssignment ###');
        Map <String,Object> result = new Map <String,Object>();
        result.put('success', true);
        
        // determine the sObject Type
        String objectAPIName = sObjectId.getSObjectType().getDescribe().getName();
        
        // Only allow this process to run for Leads and Cases
        if(objectAPIName != 'Lead' && objectAPIName != 'Case')
        {
            result.put('success', false);
            result.put('errorMessage', 'Only Lead and Case have standard assignment rules');
            return result;
        }
        system.debug('### checkpoint 2 ###');
    
        List <sObject> records = new List <sObject>();
        Set <Id> recordIds = new Set <Id>();
    
        try
        {   
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule= true;

            sObject sObj = Schema.getGlobalDescribe().get(objectAPIName).newSObject();
            sobj.put('id', sObjectId);
            //sobj.setOptions(dmo);

            records.add(sObj);
            recordIds.add(sObjectId);

            if(!system.isFuture()){
                PlugIn_StandardAssignment.futureLeadReassign(recordIds);    
            }
            /*
            // need to call as a list with database to get dmo to work on update
            Database.SaveResult[] srList = database.update(records, dmo);
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully updated lead. Lead ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Lead fields that affected this error: ' + err.getFields());
                    }
                }
            }*/

            system.debug('### checkpoint records: ###'+ records);
        }
        catch (exception e)
        {
            result.put('success', false);
            result.put('errorMessage', e.getMessage());
            system.debug('### checkpoint 4 ###');
        }
        
        return result;
    }

    global Process.PluginResult invoke(Process.PluginRequest request) 
    { 
        system.debug('### checkpoint 5 ###');
        id sObjectId = (Id) request.inputParameters.get('sObjectId');
        
        Map <String,Object> result = processAssignment (sObjectId);
        
        return new Process.PluginResult(result); 
    } 

    // Returns the describe information for the interface
    global Process.PluginDescribeResult describe() 
    { 
        system.debug('### checkpoint 6 ###');
        Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
        result.Name = 'Standard Assignment Rules';
        result.Tag = 'Custom Plugins';
        result.description = 'Push records through standard assignment rules';
        
        //inputs
        result.inputParameters = new List<Process.PluginDescribeResult.InputParameter>
        {                                           
            new Process.PluginDescribeResult.InputParameter('sObjectId', Process.PluginDescribeResult.ParameterType.Id, true)
        }; 
        
        // output
        result.outputParameters = new List<Process.PluginDescribeResult.OutputParameter>
        { 
            new Process.PluginDescribeResult.OutputParameter('success', Process.PluginDescribeResult.ParameterType.Boolean),
            new Process.PluginDescribeResult.OutputParameter('errorMessage', Process.PluginDescribeResult.ParameterType.string)
        }; 
             
        return result; 
    }
    
}