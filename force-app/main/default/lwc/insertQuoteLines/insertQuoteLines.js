import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createQuoteLines from '@salesforce/apex/QuoteInitializationAutomation.initializeQuoteLines';
import { refreshApex } from '@salesforce/apex';

import OPP_FIELD from '@salesforce/schema/SBQQ__Quote__c.SBQQ__Opportunity2__c';
import ACC_FIELD from '@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__c';
import INSERT_STATUS_FIELD from '@salesforce/schema/SBQQ__Quote__c.Quote_Line_Insert_Status__c';
import ID_FIELD from '@salesforce/schema/SBQQ__Quote__c.Id';
const INPROGRESS = 'In Progress';
const COMPLETED = 'Completed';

const FIELDS = [
    'SBQQ__Quote__c.SBQQ__Opportunity2__c',
    'SBQQ__Quote__c.SBQQ__Account__c',
    'SBQQ__Quote__c.Id',
    'SBQQ__Quote__c.Quote_Line_Insert_Status__c'

]
export default class InsertQuoteLines extends LightningElement {
    @api recordId;
    @track spinner;

    @wire(getRecord, {recordId : '$recordId', fields : FIELDS})
    quote;

    handleClick() {
        refreshApex(this.quote);

        if(this.lineStatusValue === INPROGRESS) {
            this.showToast('In Progress', 'This process is already in progress.','warning');
        } else if(this.lineStatusValue === COMPLETED) {
            this.showToast('Completed', 'Quote Lines are already inserted.','success');
        } else {
            this.spinner = true;

            const quote = () => {
                return {
                    'sobjecttype': 'SBQQ__Quote__c',
                    'SBQQ__Account__c' : this.accValue,
                    'Id' : this.quoteIdValue,
                    'SBQQ__Opportunity2__c' : this.oppValue
                }
            };

            createQuoteLines({
                quote : quote()
            })
            .then(response=>{
                this.showToast('Success', 'Sucessfully submited for Queue with JobId: ' +response , 'success');
            })
            .catch(error=>{
                console.error('error' ,error);
                this.showToast('Error!' , error, 'error');
            })
            .finally(()=>{
                this.spinner = false;
                refreshApex(this.quote);
            })
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title   :   title,
            message :   message,
            variant :   variant
        });

        this.dispatchEvent(event);
    }

    get oppValue() {
        return getFieldValue(this.quote.data, OPP_FIELD);
    }

    get accValue() {
        return getFieldValue(this.quote.data, ACC_FIELD);
    }

    get lineStatusValue() {
        return getFieldValue(this.quote.data, INSERT_STATUS_FIELD);
    }

    get quoteIdValue() {
        return getFieldValue(this.quote.data, ID_FIELD);
    }


}