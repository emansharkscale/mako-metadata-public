public with sharing class CustomObjectMetadataProcessor {

    // Create a wrapper class to hold the metadata
    public class MetadataWrapper {
        public List<String> fieldMetadata;
        public List<String> validationRules;
        public List<RecordType> recordTypes;
    }
 /*
    @AuraEnabled
    public static MetadataWrapper processCustomObjectMetadata(List<String> selectedCustomObjects, List<String> selectedCustomMetadataOptions) {
        MetadataWrapper wrapper = new MetadataWrapper();

        for (String sObjectName : selectedCustomObjects) {
            if (selectedCustomMetadataOptions.contains('customFieldMetadata')) {
                wrapper.fieldMetadata = fetchFieldMetadata(sObjectName);
            }
            if (selectedCustomMetadataOptions.contains('customValidationRulesMetadata')) {
                wrapper.validationRules = fetchValidationRulesMetadata(sObjectName);
            }
            if (selectedCustomMetadataOptions.contains('customRecordTypeMetadata')) {
                wrapper.recordTypes = fetchRecordTypeMetadata(sObjectName);
            }
        }

        return wrapper;
    } */


    // Modify fetchFieldMetadata and fetchValidationRulesMetadata to be added as a subrequest per object, for the composite resource
    // instead of as individual httpcallouts 
/*
    public static List<String> fetchFieldMetadata(String sObjectName) {
        String query = 'SELECT EntityDefinition.QualifiedApiName, DeveloperName, DataType, Label ' +
                       'FROM FieldDefinition ' +
                       'WHERE EntityDefinition.QualifiedApiName = \'' + sObjectName + '\'';

        HttpResponse res = HttpCalloutService.executeToolingApiCallout(query);
        // For now, we'll assume you've parsed the JSON response into a List<String>
        // You'll need to replace this with actual parsing logic
        return new List<String>{res.getBody()};
    }

    public static List<String> fetchValidationRulesMetadata(String sObjectName) {
        String query = 'SELECT EntityDefinition.QualifiedApiName, Active, Description, ErrorMessage ' +
                       'FROM ValidationRule ' +
                       'WHERE EntityDefinition.QualifiedApiName = \'' + sObjectName + '\'';

        HttpResponse res = HttpCalloutService.executeToolingApiCallout(query);
        // For now, we'll assume you've parsed the JSON response into a List<String>
        // You'll need to replace this with actual parsing logic
        return new List<String>{res.getBody()};
    } */

    public static List<RecordType> fetchRecordTypeMetadata(String sObjectName) {
        List<RecordType> recordTypes = [SELECT Id, Name, Description FROM RecordType WHERE SObjectType=:sObjectName WITH USER_MODE];
        return recordTypes;
    }
}