global class BatchFollowAccount implements Database.Batchable<sObject> {

    String query;
    List<EntitySubscription> ESList;
    List<EntitySubscription> ESListToInsert = new List<EntitySubscription>();
    Map<String,EntitySubscription> ESMap;
    global BatchFollowAccount() {
        query = 'SELECT Id, RecordTypeId,lastmodifieddate, Type,ParentId,(SELECT Id, AccountId, UserId,User.isActive, TeamMemberRole, Title FROM AccountTeamMembers),(select id,lastmodifieddate from opportunities where lastmodifieddate = THIS_YEAR)  FROM Account where RecordTypeId != null and lastmodifieddate = THIS_YEAR and Type != \'INACTIVE\'';
           
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC,List<sObject> scopeAcc) {
       //system.debug('--in execute---------');
       //List<Account> accList = (List<Account>)scopeAcc;
       //system.debug('--accList---------'+accList);
       List<Id> accIdList = new List<Id>();
       if(!scopeAcc.isEmpty()){
         for(Account acc : (List<Account>)scopeAcc){
            accIdList.add(acc.Id);
         }
      }
      ESList = [SELECT Id, ParentId, SubscriberId FROM EntitySubscription where ParentId IN: accIdList];
      ESMap = new Map<String,EntitySubscription>();
      if(!ESList.isEmpty()){

        for(EntitySubscription esRec : ESList){
            String key = esRec.ParentId+','+esRec.SubscriberId;
            ESMap.put(key,esRec);
        }
      }
       if(!scopeAcc.isEmpty()){
          for(Account acc : (List<Account>)scopeAcc){
            // if(!acc.AccountTeamMembers.isEmpty() && !acc.opportunities.isEmpty()){

                  for(AccountTeamMember accTeamMemberRec : acc.AccountTeamMembers){

                      String key = acc.Id+','+accTeamMemberRec.UserId;
                      if(ESMap.get(key) == null && accTeamMemberRec.User.isActive){

                          EntitySubscription e = new EntitySubscription();
                          e.subscriberId = accTeamMemberRec.userId;
                          e.parentId = acc.Id;

                          ESListToInsert.add(e);
                      }
                  }
            // }
          }
       }
       system.debug('---ESListToInsert-----'+ESListToInsert);
       database.upsert(ESListToInsert,false);
    }
    global void finish(Database.BatchableContext BC) {
    }
}