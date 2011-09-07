global with sharing class emoEntry {

    @remoteAction
    global static Emotion__c recordEmotion(Integer val, String valString){
        Emotion__c emo = new Emotion__c();
        emo.Mood__c = valString;
        emo.Mood_Number__c = val;
        insert emo;
        
        return [select id, Mood__c, Mood_Number__c, CreatedDate from Emotion__c where id = :emo.id limit 1];
    }
    
    // Sets up the batch job
    webService static String scoreEmotions(String batchPrepId) {
        
        // Make sure we passed in a record Id
        if (batchPrepId == null || batchPrepId == ''){ return 'A record id is required'; }
        
        // Delete old results for this record
        list<Batch_Result__c> oldResults = [select id from Batch_Result__c where Batch_Prep__c = :batchPrepId];
        if (!oldResults.isEmpty()) { delete oldResults; }
        
        // Find the Batch Prep record
        List<Batch_Prep__c> bps = [select id, Start_Time__c, End_Time__c, Status__c, Batch_Job_Id__c from Batch_Prep__c where id = :batchPrepId limit 1];
        if (bps.size() != 1) { return 'Batch Prep record was not found'; }
        Batch_Prep__c bp = bps[0];
        
        // Confirm the time window size
        if ((bp.end_time__c.gettime() - bp.start_time__c.gettime()) > 7200000){
            //return 'Analysis is limited to 2 hour windows';
        } 
        if ((bp.end_time__c.gettime() - bp.start_time__c.gettime()) < 0){
            return 'End Time cannot be before the Start Time';
        } 
        
        // Update the Prep Record as if it's new
        bp.Status__c = 'New';
        bp.Batch_Job_Id__c = null;
        update bp;
        
        // Create the shell Batch Results record
        list<Batch_Result__c> brs = new list<Batch_Result__c>();
        Boolean done = false;
        Integer counter = 1;
        DateTime wrkTime = bp.Start_Time__c;
        do{
        
            Batch_Result__c r = new Batch_Result__c();
            r.Timestamp__c = wrkTime;
            r.Minute_Number__c = counter;
            r.Batch_Prep__c = bp.id;
            brs.add(r);
        
            wrkTime = wrkTime.addMinutes(1);
            counter++;
            
            if (wrkTime > bp.End_Time__c){ done = true; }
        	
        } while (done == false);
        
        if (!brs.isEmpty()) { insert brs; }
        
        batchScoring job = new batchScoring();
        job.batchPrepId = bp.id;
        Id processId = Database.executeBatch(job, 20);
        
        bp.Status__c = 'Processing';
        bp.Batch_Job_Id__c = processId;
        update bp;


        return 'Success! Batch Job Initialized.';
        
    }
    
}