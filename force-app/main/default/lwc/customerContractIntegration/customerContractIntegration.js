import { LightningElement, api, track } from 'lwc';
import initiateCalloutFromContract from '@salesforce/apex/CustomerContractIntegration.initiateCalloutFromContract';
import initiateCalloutFromQuote from '@salesforce/apex/CustomerContractIntegration.initiateCalloutFromQuote';
import getOppRecordtypeFromQuote from '@salesforce/apex/CustomerContractIntegrationHelper.getOppRecordtypeFromQuote';
import getContract from '@salesforce/apex/CustomerContractIntegrationHelper.getContract';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import ID_FIELD from '@salesforce/schema/Contract.Id';
import INT_STATUS_FIELD from '@salesforce/schema/Contract.Integration_Status__c';
import { getErrorMessage } from 'c/errorPanel';
const QUOTE = 'SBQQ__Quote__c';
const CONTRACT = 'Contract';

export default class CustomerContractIntegration extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track spinner;

    handleClick() {
        this.spinner = true;
        if(this.objectApiName === CONTRACT) {
            this.calloutFromContract();
        } else if(this.objectApiName === QUOTE) {
            this.calloutFromQuote();
        }
    }

    calloutFromContract() {
        getContract({
            contractId : this.recordId
        })
        .then(contract=>{
            if(contract.Status.toLowerCase() === 'active') {
                if(!contract.Contract_Integrated__c) {
                    console.log('in here', contract.SBQQ__Quote__r);
                    if(contract.ActivatedDate < contract.SBQQ__Quote__r.SBQQ__StartDate__c) {
                        this.spinner = false;
                        this.showToastNotifiaction('Alert!', 'The Contract Activated Date cannot be earlier than the Quote Start Date', 'warning');
                    }else {
                        this.calloutFromContractHelper();
                    }
                } else {
                    this.spinner = false;
                    this.showToastNotifiaction('Alert!', 'Contract info already sent', 'warning');
                }
            } else {
                this.spinner = false;
                this.showToastNotifiaction('Alert!', 'You cannot send Contract info when status is not active', 'warning');
            }
        })
        
    }

    calloutFromContractHelper() {
        let success = false;
        initiateCalloutFromContract({
            contractIds : [this.recordId]
        })
        .then(response=>{
            if(response === 200) {
                console.log('response ', response);
                this.showToastNotifiaction('Success', 'Request sent successfully', 'success');
                success = true;
            } else {
                this.showToastNotifiaction('Error on sending request', 'Please contact System Admin', 'error');
            }
        })
        .catch(error=>{
            let errorMsg = getErrorMessage(error).join('.');
            //this.showToastNotifiaction('Error', errorMsg , 'error');
            let messages = errorMsg.split('Record Details : ');
            if(messages.length > 1) {
                this.showToastNotifiactionWithLink('Error!', messages, 'error');
            } else {
                this.showToastNotifiaction('Error!', messages[0] , 'error');
            }
        }).finally(()=>{
            if(success) this.updateContract(); else this.spinner = false;
        })
    }

    calloutFromQuote() {
        //let special_offer = false;

        //get the opportunity record of the current quote
        getOppRecordtypeFromQuote({
            quoteId : this.recordId
        })
        .then(response=>{
            var quote = response;
            //only special offer quote can send contract info
            if(quote.Opportunity_Record_Type_Name__c.toLowerCase() === 'special_offer'){
                //only active quotes can send the information
                if(quote.SBQQ__Status__c.toLowerCase() === 'approved') {
                    //only one time can send the contract info
                    if(!quote.Contract_Integrated__c) {
                        this.calloutFromQuoteHelper();
                    } else {
                        this.spinner = false;
                        this.showToastNotifiaction('Alert!', 'Contract info already sent', 'warning');
                    }
                } else {
                    this.spinner = false;
                    this.showToastNotifiaction('Alert!', 'You cannot send Contract info when Quote status is not active', 'warning');
                }
            } else {
                this.spinner = false;
                this.showToastNotifiaction('Alert!', 'You cannot send Contract info for this Quote', 'warning');
            }
        })
        .catch(error=>{
            console.error(error);
            this.showToastNotifiaction('Error', 'Something went wrong, Please contact system admin', 'error');
        })
    }

    calloutFromQuoteHelper() {
        initiateCalloutFromQuote({
            quoteId : this.recordId
        })
        .then(response=>{
            if(response === 200) {  
                this.showToastNotifiaction('Success', 'Request sent successfully', 'success');
            } else {
                this.showToastNotifiaction(response + ' Error!', 'Error on sending request', 'error');
            }
        })
        .catch(error=>{
            let errorMsg = getErrorMessage(error).join('.');
            let messages = errorMsg.split('Record Details : ');
            if(messages.length > 1) {
                this.showToastNotifiactionWithLink('Error!', messages, 'error');
            } else {
                this.showToastNotifiaction('Error!', messages[0] , 'error');
            }

        })
        .finally(()=>{
            this.spinner = false;
        })
    }

    updateContract() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[INT_STATUS_FIELD.fieldApiName] = 'Status Code=200,Status=OK';

        const recordInput = {fields};
        try {
            updateRecord(recordInput)
            .then(()=>{
                this.showToastNotifiaction('Record Updated', 'Contract Updated Successfully', 'success')
            })
        } catch (error) {
            this.showToastNotifiaction('Error', 'Error on updating Contract', 'error');
        } finally {
            this.spinner = false;
        }
    }

    showToastNotifiaction(title, message, variant) {
        const notification = new ShowToastEvent({
            title : title,
            message : message,
            variant : variant
        });

        this.dispatchEvent(notification);
    }

    showToastNotifiactionWithLink(title, message, variant) {
        let msg = message[0];
        let record = JSON.parse(message[1]);
        const event = new ShowToastEvent({
            "title": title,
            "message": msg+ "See it {0}!",
            "messageData": [
                {
                    url: window.location.origin + '/' + record.Id,
                    label: record.Name
                }
            ],
            "variant" : variant
        });
        this.dispatchEvent(event);
    }
}