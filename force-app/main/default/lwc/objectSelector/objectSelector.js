import { LightningElement, track, wire } from 'lwc';
import getObjectNames from '@salesforce/apex/ObjectSelector.getObjectNames';
import processStandardObjectMetadata from '@salesforce/apex/StandardObjectMetadataComposite.processStandardObjectMetadata';
import processCustomObjectMetadata from '@salesforce/apex/CustomObjectMetadataComposite.processCustomObjectMetadata';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';


export default class ObjectSelector extends LightningElement {
    @track standardObjectOptions = [];
    @track customObjectOptions = [];

    @track selectedStandardObjects = [];
    @track selectedCustomObjects = [];

    @track selectedStandardMetadataOptions = [];
    @track selectedCustomMetadataOptions = [];

    @track standardMetadataOptions = [
        { label: 'Retrieve Field metadata', value: 'standardFieldMetadata' },
        { label: 'Retrieve Validation Rules metadata', value: 'standardValidationRulesMetadata' },
        { label: 'Retrieve Record Type metadata', value: 'standardRecordTypeMetadata' }
    ];
    @track customMetadataOptions = [
        { label: 'Retrieve Field metadata', value: 'customFieldMetadata' },
        { label: 'Retrieve Validation Rules metadata', value: 'customValidationRulesMetadata' },
        { label: 'Retrieve Record Type metadata', value: 'customRecordTypeMetadata' }
    ];
    
    @track metadataResult;  // Variable to hold metadata result
    @track loading = false; // Variable to indicate loading state
    @track jobIds = [];     // Array to track job IDs

    channelName = '/event/BatchJobComplete__e';
    subscription = {};

    // Utility function to sort the array based on 'label'
    sortOptionsAlphabetically(options) {
        return options.sort((a, b) => a.label.localeCompare(b.label));
    }

    @wire(getObjectNames)
    wiredObjects({ error, data }) {
        if (data) {
            const standardObjects = [];
            const customObjects = [];
            data.forEach(obj => {
                if (obj.endsWith('__c')) {
                    customObjects.push({ label: obj, value: obj });
                } else {
                    standardObjects.push({ label: obj, value: obj });
                }
            });

            // Sort the options alphabetically
            this.standardObjectOptions = this.sortOptionsAlphabetically(standardObjects);
            this.customObjectOptions = this.sortOptionsAlphabetically(customObjects);
        } else if (error) {
            console.error('Error fetching objects:', error);
        }
    }

    handleStandardObjectChange(event) {
        this.selectedStandardObjects = event.detail.value;
        console.log('Debug: Selected standard objects:', this.selectedStandardObjects);
        console.log('Debug: Entire Event:', JSON.stringify(event.detail));
    }

    handleCustomObjectChange(event) {
        this.selectedCustomObjects = event.detail.value;
        console.log('Debug: Selected custom objects:', this.selectedCustomObjects);
        console.log('Debug: Entire Event:', JSON.stringify(event.detail));
    }

    handleStandardMetadataOptionChange(event) {
    this.selectedStandardMetadataOptions = event.detail.value;
    console.log('Debug: Selected Metadata Options:', this.selectedStandardMetadataOptions);
    console.log('Debug: Entire Event:', JSON.stringify(event.detail));
    }

    handleCustomMetadataOptionChange(event) {
    this.selectedCustomMetadataOptions = event.detail.value;
    console.log('Debug: Selected Metadata Options:', this.selectedCustomMetadataOptions);
    console.log('Debug: Entire Event:', JSON.stringify(event.detail));
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }

     handleStdObjectProcessing() {
        this.loading = true;
        processStandardObjectMetadata({
            selectedStandardObjects: this.selectedStandardObjects,
            selectedStandardMetadataOptions: this.selectedStandardMetadataOptions
        })
        .then(jobId => {
            this.jobIds.push(jobId);
            this.showToast('Success', 'Processing of standard objects started.', 'success');
            this.loading = false;
        })
        .catch(error => {
            this.loading = false;
            // Improved error handling
            let message = 'Unknown error';
            if(error && error.body && error.body.message) {
                message = error.body.message;
            }
            this.showToast('Error', message, 'error');
        });
    }


    handleCustomObjectProcessing() {
        this.loading = true;  // Set loading to true
        console.log("About to call Apex method");

        processCustomObjectMetadata({
            selectedCustomObjects: this.selectedCustomObjects,
            selectedCustomMetadataOptions: this.selectedCustomMetadataOptions
        })
        .then(jobId => {
            this.jobIds.push(jobId); // Store the job ID
            this.loading = false;
        })
        .catch(error => {
            this.loading = false;
            console.error('Error in processing standard object metadata:', error);
        });
        
        console.log("Apex method called");
        console.log('Selected Custom Objects:', this.selectedCustomObjects);
        console.log('Selected Custom Object Metadata Options:', this.selectedCustomMetadataOptions);
    }

    //handle the async batch job platform event subscription

    connectedCallback() {
        this.registerErrorListener();
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('New message received: ', JSON.stringify(response));
            const batchContextId = response.data.payload.BatchJobId__c;
            if (this.isRelevantBatchJob(batchContextId)) {
                this.metadataResult = JSON.parse(response.data.payload.BatchJobResult__c);
                this.showToast('Success', 'Batch job completed successfully.', 'success');                
                // ... process additional fields from the event if needed ...
            }
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Successfully subscribed to : ', response.channel);
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', response);
            this.subscription = {};
        });
    }

    registerErrorListener() {
        onError(error => {
            let message = 'Unknown error';
            if(error && error.body && error.body.message) {
                message = error.body.message;
            }
            this.showToast('Error', message, 'error');
        });
    }

    fetchResultsFromEvent(batchResponses) {
        // Handle the batch job results here
        // Parse the batch responses JSON and process as needed
        this.metadataResult = JSON.parse(batchResponses);
        // Update the UI accordingly
    }

    // This utility function checks if the job Id of interest matches
    isRelevantBatchJob(batchContextId) {
        // Implement logic to determine if the event received is relevant to this component instance
        return this.jobIds.includes(batchContextId);
    }

    get hasResults() {
        return this.metadataResult && (this.metadataResult.fieldMetadata.length > 0 || this.metadataResult.validationRules.length > 0 || this.metadataResult.recordTypes.length > 0);
    }
}