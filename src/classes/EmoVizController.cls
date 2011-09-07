global class EmoVizController {
	
	public Batch_Prep__c batchPrep {get; private set;}
	
	public String selectedBatch {get; set;}
	
	public EmoVizController() {
		
		if(ApexPages.CurrentPage().getParameters().containsKey('bpid')) {
			selectedBatch = ApexPages.CurrentPage().getParameters().get('bpid');
		}
		
	}
	
	public List<SelectOption> getBatchOptions() {
		
		List<SelectOption> opts = new List<SelectOption>();
		
		for(Batch_Prep__c bp : [SELECT Id, Name, Status__c, Start_Time__c, End_Time__c FROM Batch_Prep__c WHERE Status__c = 'Complete']) {
			opts.add(new SelectOption(bp.Id, bp.Name));
		}
		
		return opts;
		
	}
	
	public Batch_Prep__c getBatch() {
		
		if(selectedBatch != null) {
			return [SELECT Id, Name, Batch_Job_Id__c, Start_Time__c, End_Time__c, Results__c, 
					(SELECT Id, Name, Emotions_Count__c, Minute_Number__c, Score__c, Timestamp__c FROM Batch_Results__r)
					FROM Batch_Prep__c WHERE Id = :selectedBatch];
		}
		
		return null;
		
	}
	
	@RemoteAction
	global static Batch_Result__c[] getResults(String batchPrepId) {
		
		return [SELECT Id, Name, Emotions_Count__c, Minute_Number__c, Score__c, Timestamp__c, Batch_Prep__c 
				FROM Batch_Result__c
				WHERE Batch_Prep__c = :batchPrepId
				ORDER BY Minute_Number__c];

	}
	

}