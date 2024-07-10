public with sharing class HttpCalloutService implements Database.Batchable<Map<String, Object>>, Database.AllowsCallouts, Database.Stateful {
    private List<Map<String, Object>> subrequests;
    private Map<String, Object> responses = new Map<String, Object>();
    private DateTime jobStartDateTime;

    public HttpCalloutService(List<Map<String, Object>> subrequests) {
        this.subrequests = subrequests;
        this.jobStartDateTime = DateTime.now();
    }

    // chunk the subrequests list into batches of up to 25, ensuring no more than 5 queries
    // This could be a separate method to calculate and return the batched list
    public Iterable<Map<String, Object>> start(Database.BatchableContext bc) {
        // Just returning the original 'subrequests' list here to satisfy the interface's contract
        return subrequests;
    }


    public void execute(Database.BatchableContext bc, List<Map<String, Object>> scope) {
        // Process the subrequests in scope in chunks meeting the criteria
        handleSubrequestsInChunks(scope);
    }

    public void finish(Database.BatchableContext bc) {
        BatchJobComplete__e batchEvent = new BatchJobComplete__e();
        batchEvent.BatchJobId__c = bc.getJobId();
        batchEvent.BatchJobResult__c = JSON.serialize(responses);
        batchEvent.BatchJobStatus__c = 'Completed';
        batchEvent.BatchJobStartedDateTime__c = jobStartDateTime;
        batchEvent.BatchJobCompletedDateTime__c = DateTime.now();
        batchEvent.NumberOfRecordsProcessed__c = responses.size();
        batchEvent.NumberOfErrors__c = 0;
        batchEvent.ErrorMessage__c = null;
        Database.SaveResult eventResult = EventBus.publish(batchEvent);
        if (!eventResult.isSuccess()) {
            System.debug('Error publishing batch completion event: ' + eventResult.getErrors());
        }
    }

    // Helper method to handle subrequests in chunks
    private void handleSubrequestsInChunks(List<Map<String, Object>> subrequests) {
        Integer chunkSize = 25;
        Integer queryLimit = 5;

        for (Integer startIdx = 0; startIdx < subrequests.size(); startIdx += chunkSize) {
            Integer queryCounter = 0;
            List<Map<String, Object>> chunk = new List<Map<String, Object>>();
            
            for (Integer i = startIdx; i < Math.min(startIdx + chunkSize, subrequests.size()); i++) {
                if (subrequests[i].get('method') == 'GET') {
                    queryCounter++;
                }
                if (queryCounter > queryLimit) {
                    break;
                }
                chunk.add(subrequests[i]);
            }
            if (!chunk.isEmpty()) {
                executeCompositeRequest(chunk);
            }
        }
    }

   // Method to execute a composite request with a batch of subrequests
    private void executeCompositeRequest(List<Map<String, Object>> subrequests) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Mako_API_Named/services/data/v58.0/composite');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        // Include the allOrNone flag set to false for handling partial successes
        Map<String, Object> requestBodyMap = new Map<String, Object>{
            'allOrNone' => false,
            'compositeRequest' => subrequests
        };
        String requestBody = JSON.serialize(requestBodyMap);
        req.setBody(requestBody);
        System.debug('Composite request body: ' + requestBody);
        
        // Perform the HTTP callout
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Composite HTTP response: ' + res.toString());
            if (res.getStatusCode() == 200) {
                // Parse and handle the composite response
                handleCompositeResponse(res.getBody());
            } else {
                // Handle error response
                System.debug('Error during HTTP callout: ' + res.getStatusCode() + ' ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception during HTTP callout: ' + e.getMessage());
            // Handle exceptions
        }
    }

    // Method to handle the response from the composite request
    private void handleCompositeResponse(String responseBody) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> compositeResponses = (responseMap.get('compositeResponse') != null) ? (List<Object>) responseMap.get('compositeResponse') : null;
        
        if (compositeResponses != null) {
            for (Object subresponseObj : compositeResponses) {
                Map<String, Object> subresponse = (Map<String, Object>) subresponseObj;
                String referenceId = (String) subresponse.get('referenceId');
                Map<String, Object> body = (Map<String, Object>) subresponse.get('body');
                Integer httpStatusCode = (Integer) subresponse.get('httpStatusCode');
                
                // Even if one request fails, we can still commit the rest that succeeded (partial success with allOrNone=false)
                if (httpStatusCode >= 400) {
                    // Log the error or add custom logic to handle errors based on the StatusCode
                    System.debug('Error in subrequest ' + referenceId + ': ' + body);
                    // Accumulate errors in a collection if there are more error-handling actions needed later
                } else {
                    // Subrequest is successful, process response
                    responses.put(referenceId, body);
                }
            }
        } else {
            // The response is not in the expected format or an overall error occurred
            System.debug('Unexpected composite response format or overall error: ' + responseMap);
        }
        System.debug('Parsed composite response with individual subrequest results: ' + responses);
    }
}