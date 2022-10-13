/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';
import getAccountHierarchy from '@salesforce/apex/LWC_SelectContractParties.getAccountHierarchy';

export default class AccountHierarchy extends LightningElement {
    @api accId;
    @track error;
    @track showError;
    heirarchyAccounts = [];

    gridColumns = [{
        type: 'text',
        fieldName: 'name',
        label: 'Account Name',
    },
    {
        type: 'text',
        fieldName: 'recordTypeName',
        label: 'RecordType',
    },
    {
        type: 'text',
        fieldName: 'accountNumber',
        label: 'Account Number',
    }];
    @api gridData;
    @track selectedRows=[];

    connectedCallback() {
        //query the data for firsttime
        if(undefined === this.gridData)
            this.queryAccountHierarchy(this.accId);
    }

    //query the account heirarchy whenever opportunity is loaded
    queryAccountHierarchy() {
        this.showError = false;
        getAccountHierarchy({accountId : this.accId})
        .then(input=>{
            //filter the data that we need only necessary data in the 
            input = input.map(account=>{
                this.heirarchyAccounts.push(account);
                return this.generateGridObject(account);
            });

            let output = [];

            const foundChild = (o,  account) => {
                if (Array.isArray(o._children)) {
                    const index = o._children.findIndex(c => c.id === account.ParentId);
                    if (-1 !== index) {
                        o._children[index]._children = o._children[index]._children || [];
                        o._children[index]._children.push(account);
                    } else {
                        o._children.map(c=>{
                            c = foundChild(c, account);
                            return c;
                        });
                    }
                }
                return o;
            }

            input.forEach(curr => {
                if ('ParentId' in curr) {
                    const index = output.findIndex(v => v.id === curr.ParentId);
                    if (-1 !== index) {
                        output[index]._children = output[index]._children || [];
                        output[index]._children.push(curr);
                    } else {
                        output = output.map(o=>{
                            o = foundChild(o, curr);
                            return o
                        })
                    }
                } else {
                    output.push(curr);
                }
            });

            this.gridData = output;
            this.dispatcher('dataload',  { gridData : this.gridData, accounts : this.heirarchyAccounts});
        })
        .catch(error=>{
            this.showError = true;
            this.error = JSON.stringify(error);
        });
    }

    generateGridObject(account) {
        let obj = {};
        obj.name = (this.accId === account.Id ? account.Name+' (Current Account)' : account.Name);
        obj.id = account.Id;
        obj.recordTypeName = account.RecordType ? account.RecordType.Name : ''; //found that for some old records record type will not exist
        obj.accountNumber = account.Account_Number__c;
        obj.ownerId = account.OwnerId;
        obj.accountOwnerTerritory = account.Owner.SM_Territory__c;
        obj.accountOwnerSalesArea = account.Owner.Sales_Area__c;
        if(account.ParentId) {
            obj.ParentId = account.ParentId;
        }
        return obj;
    }

    handleRowSelection() {
        let selectedRows = this.template.querySelector('lightning-tree-grid').getSelectedRows();
        this.selectedRows = selectedRows.map(curr=>curr.id);
        this.dispatcher('rowselect', this.selectedRows);
    }

    dispatcher(name, data){
        const event = new CustomEvent(name, {
            detail : data
        });
        this.dispatchEvent(event);
    }
}