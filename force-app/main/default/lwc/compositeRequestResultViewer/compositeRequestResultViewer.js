import { LightningElement, api } from 'lwc';

export default class CompositeRequestResultViewer extends LightningElement {
    @api compositeResults; // To receive the results from ObjectSelector
    @api debugLogs; // To receive the debug logs from ObjectSelector

    // Helper to determine if there are results
    get hasResults() {
        // Logging the contents of compositeResults
        console.log('compositeResults:', JSON.stringify(this.compositeResults));
        // Check if there are results to display
        const resultsAvailable = this.compositeResults && Object.keys(this.compositeResults).length > 0;
        console.log('Results available:', resultsAvailable);
        return resultsAvailable;
    }
}
