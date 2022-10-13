global class SCH_BatchFollowAccount implements Schedulable {

   global void execute(SchedulableContext ctx) {
       Database.executeBatch(new BatchFollowAccount(), 100);
   }   
}