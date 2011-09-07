global class batchScoring implements Database.Batchable<SObject>, Database.Stateful {

    /*
    * To Run:
    
    batchScoring job = new batchScoring();
    job.batchPrepId = batchPrepId;
    Id processId = Database.executeBatch(job, 20);
    
    */
    
    public class BatchException extends Exception {}
    global String batchPrepId; // Batch Prep record Id
    
    // start - Method required by the framework to start the job execution.
    global Database.QueryLocator start(Database.BatchableContext ctx) {
        
        if (batchPrepId == null) { throw new BatchException('A record Id is required'); }
        
        // Select all Batch Result records linked to the Batch Prep record
        String theQuery = 'SELECT Id, Timestamp__c, Score__c, Emotions_Count__c, Description__c, Batch_Prep__c  FROM Batch_Result__c where Batch_Prep__c = \'' + batchPrepId + '\'';
        
        // Set the queryLocator
        return Database.getQueryLocator(theQuery);
        
    }
    
    // execute - Method required by the framework to process the records returned by the query locator created in the start method.
    global void execute(Database.BatchableContext ctx, List<SObject> sobjects) {
        
        for (sObject so : sobjects){
        
            // Get the working Timestamp
            Datetime wrkTimeStart = (datetime)so.get('Timestamp__c');
            Datetime wrkTimeEnd = (datetime)so.get('Timestamp__c');
            wrkTimeEnd = wrkTimeEnd.addSeconds(59);
            
            system.debug(wrkTimeStart);
            system.debug(wrkTimeEnd);
            
            // Query Emotion records in that Timestamp
            List<Emotion__c> emos = [select id, Mood__c, Mood_Number__c from Emotion__c where CreatedDate >= :wrkTimeStart and CreatedDate <= :wrkTimeEnd];
            Decimal sum = 0;
            for (Emotion__c emo : emos){
                sum += emo.Mood_Number__c;
            }
            
            so.put('Emotions_Count__c', emos.size());
            if (emos.size() == 0){
                so.put('Score__c', 0);
            } else {
                so.put('Score__c', sum / emos.size());
            }
        
        }
        
        update sobjects;
        
    }
    
    // finish - Method required and invoked by the framework when a batch job is done.
    global void finish(Database.BatchableContext ctx){
        
        for (Batch_Prep__c bp : [select id, Status__c from Batch_Prep__c where id = :batchPrepId limit 1]){
            bp.Status__c = 'Complete';
            update bp;
        }
        
    }
    
}