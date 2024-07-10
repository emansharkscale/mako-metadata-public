public with sharing class ObjectSelector {
    @AuraEnabled(cacheable=true)
    public static List<String> getObjectNames() {
        List<String> objectNames = new List<String>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); // Get a map of all sObject types

        // Loop through all sObject types to get their metadata
        for(Schema.SObjectType d : gd.values()) {
            Schema.DescribeSObjectResult ds = d.getDescribe();

            // Check if the user has read access to the object, if it's createable, and not a custom setting
            if(ds.isAccessible() && ds.isCreateable() && !ds.isCustomSetting()) {
                objectNames.add(ds.getName());  // Add the object name to the list
            }
        }
        return objectNames;  // Return the list of object names
    }
}