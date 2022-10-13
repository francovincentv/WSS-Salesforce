@isTest
public with sharing class PlugIn_StandardAssignment_Test {

  static testmethod void Testdesc() 
    {
      PlugIn_StandardAssignment plugin = new PlugIn_StandardAssignment();
      plugin.describe();
    }

    static testmethod void Test1() 
    {
      
        Lead l = new Lead();
        l.lastname = 'test';
        l.company = 'test';
        l.email = 'test@test.com';
        insert l;
        
        PlugIn_StandardAssignment plugin = new PlugIn_StandardAssignment();
        Map<String,Object> inputParams = new Map<String,Object>();

        InputParams.put('sObjectId', l.id);

        Process.PluginRequest request = new Process.PluginRequest(inputParams);           
         
        plugin.invoke(request);
    } 
    
    static testmethod void TestFail() 
    {
      
        Account a = new Account();
        a.name = 'test';
        insert a;
        
        PlugIn_StandardAssignment plugin = new PlugIn_StandardAssignment();
        Map<String,Object> inputParams = new Map<String,Object>();

        InputParams.put('sObjectId', a.id);

        Process.PluginRequest request = new Process.PluginRequest(inputParams);           
         
        plugin.invoke(request);
    } 
}