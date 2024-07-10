public with sharing class CustomObjectMetadataComposite {

    // Wrapper class to hold metadata
    public class MetadataWrapper {
        @AuraEnabled
        public String jobId;
        @AuraEnabled
        public List<String> fieldMetadata;
        @AuraEnabled
        public List<String> validationRules;
        @AuraEnabled
        public List<RecordType> recordTypes;
        // Other fields as needed
    }

    // Method to process custom object metadata
    @AuraEnabled(cacheable=true)
    public static MetadataWrapper processCustomObjectMetadata(List<String> selectedCustomObjects, List<String> selectedCustomMetadataOptions) {
        MetadataWrapper wrapper = new MetadataWrapper();
        List<Map<String, Object>> subrequests = new List<Map<String, Object>>();

        // Construct subrequests based on selected metadata options
        for (String sObjectName : selectedCustomObjects) {
            if (selectedCustomMetadataOptions.contains('customFieldMetadata')) {
                String fieldMetadataQuery = fetchFieldMetadataQuery(sObjectName);
                subrequests.add(generateSubrequest(fieldMetadataQuery, 'FieldMetadata_' + sObjectName));
            }
            if (selectedCustomMetadataOptions.contains('customValidationRulesMetadata')) {
                String validationRulesMetadataQuery = fetchValidationRulesMetadataQuery(sObjectName);
                subrequests.add(generateSubrequest(validationRulesMetadataQuery, 'ValidationRules_' + sObjectName));
            }
            if (selectedCustomMetadataOptions.contains('customRecordTypeMetadata')) {
                wrapper.recordTypes = fetchRecordTypeMetadata(sObjectName);
            }
        }

        // Execute batch job if there are subrequests to process
        if (!subrequests.isEmpty()) {
            HttpCalloutService calloutService = new HttpCalloutService(subrequests);
            Id jobId = Database.executeBatch(calloutService);
            wrapper.jobId = String.valueOf(jobId);
        }

        return wrapper;
    }

    // Generate a subrequest map for a given query and reference ID
    private static Map<String, Object> generateSubrequest(String query, String referenceId) {
        return new Map<String, Object>{
            'method' => 'GET',
            'url' => '/services/data/v58.0/tooling/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8'),
            'referenceId' => referenceId
        };
    }

    // Fetch the SOQL query for field metadata
    public static String fetchFieldMetadataQuery(String sObjectName) {
        return 'SELECT EntityDefinition.QualifiedApiName, DeveloperName, DataType, Label ' +
               'FROM FieldDefinition ' +
               'WHERE EntityDefinition.QualifiedApiName = \'' + sObjectName + '\'';
    }

    // Fetch the SOQL query for validation rules metadata
    public static String fetchValidationRulesMetadataQuery(String sObjectName) {
        return 'SELECT EntityDefinition.QualifiedApiName, Active, Description, ErrorMessage ' +
               'FROM ValidationRule ' +
               'WHERE EntityDefinition.QualifiedApiName = \'' + sObjectName + '\'';
    }

    // Fetch record type metadata directly using SOQL
    public static List<RecordType> fetchRecordTypeMetadata(String sObjectName) {
        return [SELECT Id, Name, Description FROM RecordType WHERE SObjectType=:sObjectName WITH USER_MODE];
    }
}
