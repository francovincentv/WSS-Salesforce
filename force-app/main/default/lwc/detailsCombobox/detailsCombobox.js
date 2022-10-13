import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import OPE_NAME_FIELD from '@salesforce/schema/OrderProcessException__c.Name';
import OPET_DETAILS_FIELD from '@salesforce/schema/OrderProcessException__c.Exception__r.Details__c';
import OPE_DETAILS_FIELD from '@salesforce/schema/OrderProcessException__c.Details__c';
import ID_FIELD from '@salesforce/schema/OrderProcessException__c.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isEditor from '@salesforce/customPermission/Is_OPEL_Editor';
import isAdmin from '@salesforce/customPermission/Is_OPEL_Admin';

const FIELDS = [
    OPE_NAME_FIELD,
    OPET_DETAILS_FIELD,
    OPE_DETAILS_FIELD
];

export default class DetailsCombobox extends LightningElement {

    @api recordId;    
    @track details = '';
    @track detailText = '';
    isViewMode = true;
    data;


    //retrieve fields
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    excRec({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.data = data;
            this.details = data.fields.Exception__r.value.fields.Details__c.value;
            this.detailText = data.fields.Details__c.value;
        }
    };
    
    renderedCallback() {
        //console.log(this.detailText);
    }

    get noEditPermission() {
        console.log('isAdmin: '+this.isAdmin);
        console.log('isEditor: '+isEditor);
        return !(isEditor||isAdmin);
    }

    get options() {
        var result = [];
        var picklistValues = [];

        //check this part - fix: added null check
        if(this.details && this.details.length > 0)
            picklistValues = this.details.split("\n"); 

        for (let i=0; i < picklistValues.length; i++){
            result.push({label:picklistValues[i],value:picklistValues[i]});
        }
        return result;
    }

    handleChange(event) {
        this.detailText = event.detail.value;

        //set details as the value from the picklist
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[OPE_DETAILS_FIELD.fieldApiName] = this.detailText;

        const recordInput = { fields:fields };

        updateRecord(recordInput)
        .then((record) => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Detail List selection is updated.',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {
            let title = error.body.message;
            let message;
            if(error.body.output && error.body.output.fieldErrors){
                let fieldErrors = error.body.output.fieldErrors;
                message = '';
                for(let fieldName in fieldErrors){
                    fieldErrors[fieldName].forEach(fieldError => {
                        message += fieldError.fieldLabel + ': ' + fieldError.message + '. \n';
                        });
                }
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: title,
                    message: (message?message:'An unexpected error occurred, please try again or contact your Salesforce Administrator if the problem persists.'),
                    variant: 'error',
                }),
            );
            this.detailText = this.data.fields.Details__c.value;
        });

        this.isViewMode = !this.isViewMode;

    }

    switchForm(event){
        this.isViewMode = !this.isViewMode;
    }
}