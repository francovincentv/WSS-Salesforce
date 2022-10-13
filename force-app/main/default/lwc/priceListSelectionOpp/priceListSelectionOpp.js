import { LightningElement, wire, api } from 'lwc';
import getActivePrices from '@salesforce/apex/QueryCurrentPricelist.queryCurrentPriceList';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import OPP_PRICE_LIST from '@salesforce/schema/Opportunity.Price_List_Version__c';
import OPP_ID from '@salesforce/schema/Opportunity.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class PriceListSelectionOpp extends LightningElement {

    @api recordId;
    error;
    activePrices;
    intialPrice;
    selectedPrice;
    spinner=false;
    showModal=false;

    @wire(getRecord, {recordId : '$recordId', fields : [OPP_PRICE_LIST]})
    wiredOpp({error, data}){
        if(data) {
            this.selectedPrice = data.fields.Price_List_Version__c.value;
            this.intialPrice = this.selectedPrice;
            console.log(data);
        } else if(error) {
            this.error = error;
        }
    }

    handleClick() {
        this.spinner = true;
        this.activePrices = [];
        getActivePrices()
        .then(result=>{
            result.forEach(item=> {this.activePrices.push({label: item, value: item })})
            if(this.activePrices.length == 0) {
                this.closePopup();
                this.showToastEvent('No current prircelist found', '', 'warning');
            } else {
                this.showModal = true;
            }
        })
        .catch(error=> {
            this.error = error;
        })
        .finally(()=>{
            this.spinner = false;
        });
    }

    handleChange(event) {
        this.selectedPrice = event.detail.value;
    }

    //to close the modal
    closePopup() {
        this.showModal = false;
        this.spinner = false;
    }

     //to show the success message
     showToastEvent(title, message, variant) {
        const event = new ShowToastEvent({
            "title" : title,
            "message" : message,
            "variant" : variant
        });
        this.dispatchEvent(event);
    }

    handleSave() {
        if(this.selectedPrice !== this.intialPrice) {
            this.spinner = true;
            const fields  = {};
            fields[OPP_PRICE_LIST.fieldApiName] = this.selectedPrice;
            fields[OPP_ID.fieldApiName] = this.recordId;

            const recordInput = {fields};

            updateRecord(recordInput)
            .then(()=>{
                this.showToastEvent('Record Updated', 'Pricelist Updated Successfully', 'success');
            })
            .catch(error=>{
                this.showToastEvent('Error updating record', error.body.message, 'error');
            })
            .finally(()=>{
                this.closePopup();
            })
        } else {
            this.closePopup();
        }
    }
    
}