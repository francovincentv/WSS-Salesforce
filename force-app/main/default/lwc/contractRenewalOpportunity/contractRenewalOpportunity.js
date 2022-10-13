import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import createRenewalOpportunity from '@salesforce/apex/LWC_ContractRenewalOpportunityHelper.createRenewalOpportunity';

const FIELDS = [
    'Contract.SBQQ__Opportunity__c',
    'Contract.SBQQ__ExpirationDate__c',
    'Contract.Deal_Value_per_annum__c',
    'Contract.ContractNumber',
    'Contract.Id'
]

export default class ContractRenewalOpportunity extends NavigationMixin(LightningElement) {

    @api recordId;
    @track error;
    @track spinner;
    contract;

    @wire (getRecord , { recordId : '$recordId', fields : FIELDS})
    wiredContract({data, error}){
        if(data) {
            this.contract = data;
            this.handlClick();
        } else{
            this.error = error;
        }
    }

    handlClick() {

        const record = {'sobjectType': 'Contract' };
        record.SBQQ__Opportunity__c = this.contract.fields.SBQQ__Opportunity__c.value;
        record.SBQQ__ExpirationDate__c = this.contract.fields.SBQQ__ExpirationDate__c.value;
        record.Deal_Value_per_annum__c = this.contract.fields.Deal_Value_per_annum__c.value;
        record.ContractNumber = this.contract.fields.ContractNumber.value;
        record.Id = this.contract.fields.Id.value;

        this.spinner = true;

        if(record.SBQQ__Opportunity__c) {
            createRenewalOpportunity(
                {
                    contract    : record
                }
            )
            .then(data=>{
                this.successToast(data);
                this.closeModel();
            })
            .catch(error=>{
                this.error = error;
                this.showNotification('Error', 'Error on Creating Renewal Opportunity', 'error')
            });
        } else {
            this.showNotification('Info', 'Please Select Opportunity to Create Renewal Opportunity', 'warning');
            this.closeModel();
        }
    }

    closeModel() {
        const event = new CustomEvent('close');
        this.dispatchEvent(event);
    }

    successToast(newRecord) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: newRecord.Id,
                actionName: 'view',
            },
        }).then(url => {
            const event = new ShowToastEvent({
                "variant": "success",
                "title": "Success!",
                "message": "Renewal {0} Sucessfully created! See it {1}!",
                "messageData": [
                    'Opportunity',
                    {
                        url,
                        label: newRecord.Name
                    }
                ]
            });
            this.dispatchEvent(event);
        });

    }

    showNotification(title, message, variant) {
        this.spinner = false;
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    get showError() {
        return this.error ? true : false;
    }
}