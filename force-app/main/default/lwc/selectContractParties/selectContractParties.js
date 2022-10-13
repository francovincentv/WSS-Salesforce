/* eslint-disable no-console */
import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import CONTRACT_PARTY from '@salesforce/schema/ContractParty__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContractAccounts from '@salesforce/apex/LWC_SelectContractParties.getContractAccounts';
import commitDataToDatabase from '@salesforce/apex/LWC_SelectContractParties.commitTheData';
import { helper } from './selectContractPartiesHelper.js';
import labelApprovalAlert from '@salesforce/label/c.ContractPartyApprovalAlert';
import labelExpiredAccError from '@salesforce/label/c.ContractPartyExpiredAccountError';
const regexExpression = /^([dD]{1}[0-9]{6})$/; //example - D605292
const FIELDS = [
    'Opportunity.AccountId',
    'Opportunity.Approval_Scenarios__c',
    'Opportunity.RecordType.DeveloperName',
    'Opportunity.Related_Contract__c',
    'Opportunity.PreviousOpportunity__c'
];


export default class SelectContractParties extends LightningElement {
    @api recordId; //hold the current opportunity id
    @api showDeleteAllIcon;
    @track showModal = false;
    @track accountToShow; //track the accounts that needs to be display on availble screen
    @track error; //track any error messages that occurs in process
    @track spinner = false; //track the spinner activity
    @track recordCount; //to store the number of contracts exist for the current opportunity
    @track contractAccounts; //to store the account that are associtated with the contract number enetered in the contract tab
    @track oppAccountId; //to store the current opportunity account id
    @track gridData; //to store the account hierarchy data from the account hierarchy child component
    @track showAlert = false;
    @track showExpiredAccError = false; //to identify if any expired accounts selected 
    @track specialOfferOpp = false; //to decide whether opportunity record type is 'Special Offer' or not
    contractTab; //to identify contract tab is selected or not
    subAccounts; //hold the customer sub accounts as array
    allAccountsWithKeyAsAccount = {}; //hold the customer sub accounts by its Id
    searchTerm = ''; //to store the search term
    showCount = 49; //number of accounts to show on the list
    label = { labelApprovalAlert, labelExpiredAccError };
    isAmendmentOpp;
    previousOpp;
    prevAmendOppAccounts = new Set();
    

    contractsToDelete = [];
    @track contractsToCreate = []; //track the new contracts to create

    @track existingContractParties = [];
    existingContractPartiesCopy = []; //if any error occurs while deleting existing contract party, use this to show them again in the list
    hierarchySelectedRows = []; //to store the accounts that are selected from hierarchy tab
    heirarchyAccounts = [];
    contractRecordType; //to store the record type id of contract party, use this when creating new records

    //Final list of records that can be commited to salesforce database
    contractsToInsertInDatabase = [];
    contractsToDeleteInDatabase = [];
    
    //Approval Scenario related items
    needToUpdateOpportunity = false;
    approvalScenarios;
    opportunityToUpdate;
    unrelatedAccountFound = false;//to identify if any account is selected that is not exisint the account heirarchy

    //special offer opportunity related items
    relatedContract;
    subDealAccountsMap = new Map();


    //get the current opportuny data
    @wire(getRecord, {recordId: '$recordId',fields: FIELDS})
    opportunity({error, data}) {
        if (data) {
            this.oppAccountId = data.fields.AccountId.value;
            this.approvalScenarios = data.fields.Approval_Scenarios__c.value;
            this.relatedContract = data.fields.Related_Contract__c.value;
            let recordtype = data.fields.RecordType.value.fields.DeveloperName.value;
            this.specialOfferOpp = recordtype === 'Special_Offer' ? true : false;
            this.isAmendmentOpp = recordtype === 'Amendment_Opportunity' ? true : false;
            if(this.isAmendmentOpp) {
                this.previousOpp = data.fields.PreviousOpportunity__c.value;
            }

        } else if (error) {
            this.handleError(error);
        }
    }

    @wire(getObjectInfo, {objectApiName: CONTRACT_PARTY}) objectInfo;

    connectedCallback() {
        this.updateCount();
    }

    //get the accounts with record type 'Customer Sub-Account'
    queryCustomerSubAccounts() {
        this.contractAccounts = [];
        this.accountToShow = [];
        this.contractsToCreate = [];
        this.contractsToDelete = [];
        this.hierarchySelectedRows = [];
        this.existingContractParties = this.existingContractPartiesCopy;
        this.opportunityToUpdate = {'sobjecttype': 'Opportunity',Id:this.recordId};

        
        if(this.specialOfferOpp === true) {
            helper.getSubDealsAcctsFromContract.call(this);
        } else{
            //for amendment opportunities, get the previous opp contract party account ids
            if(this.previousOpp && this.isAmendmentOpp) {
                helper.queryAmendmentOppContratParty.call(this);
            }

            //query the sub contract accounts, if the opportunity record type is not special offer
            helper.qeurySubAccounts.call(this);

        }
    }

    //filte the accounts based on the search keyword
    filterAccounts(event) {
        this.spinner = true;
        const searchTerm = event.target.value; //get the search term

        if (this.contractTab) {
            this.queryContractAccounts(searchTerm);
        } else {
            this.filterAvailableAccounts(searchTerm);
        }
    }

    //helper method for filterAccounts()
    //this method will query the data after 1000 ms of search term entered
    //query the contracts to get the related opportunity contract parties
    queryContractAccounts(searchTerm) {
        this.contractAccounts = [];
        let validSearch = this.validateSearchTeam(searchTerm);

        //if searchTerm is not blank then query the data
        if (searchTerm && validSearch) {
            window.clearTimeout(this.delayTimeout);

            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.delayTimeout = setTimeout(() => {
                getContractAccounts({
                        searchKey: searchTerm
                    })
                    .then(data => {
                        if (data) {
                            this.setContractAccounts(data);
                        }
                        this.spinner = false;
                    })
                    .catch(error => {
                        this.handleError(error);
                        this.spinner = false;
                    });
            }, 1000);
        } else {
            this.spinner = false;
        }
    }

    validateSearchTeam(searchTerm) {
        return regexExpression.test(searchTerm);
    }

    //helper method for queryContractAccounts()
    //this method will format contract accounts based on the account ids from the query data
    setContractAccounts(data) {
        //get the existing contract parties account id
        let existContractPartyAccIds = this.existingContractParties.map(curr => curr.Account__c);
        let selectedContractPartyAccIds = this.contractsToCreate.map(acc => acc.Id);

        data.forEach(opp => {
            if (opp.Contract_Parties__r) {
                
                opp.Contract_Parties__r.forEach(cp => {
                    let acc = this.allAccountsWithKeyAsAccount[cp.Account__c];
                    if (acc) {
                        //if the account is not exist in existing acccount then add it to the array
                        if (existContractPartyAccIds.indexOf(acc.Id) === -1 && selectedContractPartyAccIds.indexOf(acc.Id) === -1)
                            this.contractAccounts.push(acc);
                    }
                })
            }
        })
    }

    //helper method for filterAccounts()
    //this function will filter accounts based on the seach keyword
    filterAvailableAccounts(searchTerm) {
        let selectedAccountIds = this.contractsToCreate.map(acc => acc.Id);
        window.clearTimeout(this.delayTimeout);

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            try{
                this.searchTerm = searchTerm;
                
                //if the search term is not blank then filter the accounts, else show the first 50 accounts
                if (this.searchTerm) {
                    
                    this.accountToShow = this.subAccounts.filter(account => 
                        (
                            account.Name.toUpperCase().includes(searchTerm.toUpperCase()) || 
                            (
                                account.Account_Number__c && account.Account_Number__c.includes(searchTerm)
                            )
                        )   && 
                        selectedAccountIds.indexOf(account.Id) === -1
                    );

                    //if the result has morethan 50 records, show the first 50 records
                    if (this.accountToShow.length > 49) {
                        this.accountToShow = this.accountToShow.slice(0, this.showCount)
                    }
                } else {
                    this.accountToShow = this.subAccounts.filter(account => selectedAccountIds.indexOf(account.Id) === -1).slice(0, this.showCount);
                }
                this.sortAccounts();
                this.spinner = false;
            } catch(error) {
                console.error(error);
            }
        }, 500);
    }


    //funtion to handle which is account is selected from available list
    handleSelection(event) {
        let selectedAccount = event.detail;
        //
        let account;
        //for special offer opportunity
        if(this.specialOfferOpp === true) {
            account = this.subDealAccountsMap.get(selectedAccount);
        } else  { //other than special offer opportunity
            account = this.allAccountsWithKeyAsAccount[selectedAccount];
            //remove the selected account from the selection list, if exist
            this.accountToShow = this.accountToShow.filter(acc => selectedAccount !== acc.Id);
            this.sortAccounts();
        }
        this.contractsToCreate.push(account);
        //remove the selected account from the contract tab, if exist
        this.contractAccounts = this.contractAccounts.filter(acc => selectedAccount !== acc.Id);
    }

    //funtion to handle which is account is removed from Account Basket Tab
    handleDesection(event) {
        let deselectedAccount = event.detail;
         //for special offer opportunity
         if(this.specialOfferOpp === true) {
            this.contractAccounts.push(this.subDealAccountsMap.get(deselectedAccount));
        } else  { //other than special offer opportunity
            //add the de-selected account to the Sub-Accouts tab
            this.accountToShow.push(this.allAccountsWithKeyAsAccount[deselectedAccount]);
            this.sortAccounts();
        }
        //remove the account from Account Basket Tab
        this.contractsToCreate = this.contractsToCreate.filter(account => deselectedAccount !== account.Id);
    }

    //funtion to handle which is contract party is deleted
    handleDelete(event) {
        //remove the selected account from contract parties tab
        this.existingContractParties = this.existingContractParties.filter(curr => {
            if (event.detail === curr.Id) {
                this.contractsToDelete.push(curr.Id);

                //for special offer opportunity the deleted contract party account should be available on contracts tab
                if(this.specialOfferOpp === true && this.subDealAccountsMap.has(curr.Account__c)) {
                    this.contractAccounts.push(this.subDealAccountsMap.get(curr.Account__c));
                }
                return false;
            } else {
                return true;
            }
        });
    }

    //remove all accounts from Account Basket Tab
    handleRemoveAll() {
        //for special offer opportunity
        if(this.specialOfferOpp === true) {
            this.contractAccounts = this.contractAccounts.concat(this.contractsToCreate);
        } else {//other than special offer opportunity
            this.accountToShow = this.accountToShow.concat(this.contractsToCreate);
        }
        this.contractsToCreate = [];
    }

    //select all account from available list
    handleSelectAll() {
        //get the current selected account ids
        let availableAccountsIds = this.accountToShow.map(acc => acc.Id);

        //filter the contract list, to remove the selected accounts from contract list
        this.contractAccounts = this.contractAccounts.filter(acc => availableAccountsIds.indexOf(acc.Id) === -1);

        //select all the account form availabe list
        this.contractsToCreate = this.contractsToCreate.concat(this.accountToShow);
        this.accountToShow = [];
    }

    //funciton to handle the delete all items from the related list
    handleDeleteAll() {
        if (this.existingContractParties) {
            this.existingContractParties.forEach(curr => {
                this.contractsToDelete.push(curr.Id);

                //for special offer opportunity the deleted contract party account should be available on contracts tab
                if(this.specialOfferOpp === true && this.subDealAccountsMap.has(curr.Account__c)) {
                    this.contractAccounts.push(this.subDealAccountsMap.get(curr.Account__c));
                }
            });
            this.existingContractParties = [];
        }
    }

    handleContractSelectAll() {
        
        if(this.specialOfferOpp === false) {
            //get the current selected account ids
            let contractAccountsIds = this.contractAccounts.map(acc => acc.Id);
            //filter the availble list, to remove the selected accounts from available list
            this.accountToShow = this.accountToShow.filter(acc => contractAccountsIds.indexOf(acc.Id) === -1);
        }

        //add all the accounts currently availale under contract tab
        this.contractsToCreate = this.contractsToCreate.concat(this.contractAccounts);
        this.contractAccounts = [];
    }

    //handle the save action
    handleSave() {
        this.contractsToInsertInDatabase = [];
        this.contractsToDeleteInDatabase = [];

        //check if any expired accounts are selected
        let exipredAccIndex = this.contractsToCreate.findIndex(acc=>acc.Account_Status__c === 'Expired');
        
        if(exipredAccIndex === -1) {
            exipredAccIndex = this.heirarchyAccounts.filter(acc=>this.hierarchySelectedRows.indexOf(acc.Id)!==-1).findIndex(acc=>acc.Account_Status__c==='Expired');
        }

        //if any expired account found, show error messsge and stop the process being processed
        if(exipredAccIndex !== -1) {
            this.showExpiredAccError = true;
        } else {
            //prepare the date to commit 
            this.deleteList(this.contractsToDeleteInDatabase);
            this.insertList();

            //if nothing changed close the modal
            if(this.contractsToDeleteInDatabase.length === 0 && this.contractsToInsertInDatabase.length === 0) {
                this.closePopup();
            } else {
                this.checkConditionsBeforeSave();
            }
        }
    }

    checkConditionsBeforeSave() {
        helper.checkExistingAccounts.call(this);
       
        if (this.unrelatedAccountFound) {
            this.showAlert = true;
        } else {
            this.continueSaveProcess();
        }
    }

    closeAlert() {
        this.showAlert = false;
        this.continueSaveProcess();
    }

    continueSaveProcess() {
        this.spinner = true;
        this.commitTheData();
    }

    commitTheData() {
        commitDataToDatabase({
            deleteList: this.contractsToDeleteInDatabase,
            insertList: this.contractsToInsertInDatabase,
            opp: this.opportunityToUpdate,
            updateOpp: this.needToUpdateOpportunity
        }).then(() => {
            //clear the existing contracts after data successfully commited
            this.existingContractParties = [];
            this.contractsToDelete = [];
            this.contractsToCreate = [];
            this.hierarchySelectedRows = [];

            //handle the post save activities
            this.postSave();
        }).catch(error => {
            this.handleError(error);
            this.spinner = false;
        });
        
    }


    deleteList(itemsToDelete) {
        if (this.contractsToDelete.length > 0) {
            itemsToDelete = helper.deleteList(itemsToDelete, this.contractsToDelete);
        }
    }

    insertList() {
        //add the accounts selected in hierarchy
        if(this.hierarchySelectedRows.length > 0){
            this.addHeirarchyAccountToCreate();
        }

        if (this.contractsToCreate.length > 0) {
            //itemsToinsert = helper.insertList(itemsToinsert, this.contractsToCreate, this.recordTypeId(), this.recordId);
            helper.insertList.call(this);
        }
    }

    //add the accounts selcted from account hierarchy to the contractsToCreate array
    addHeirarchyAccountToCreate() {
        helper.addHeirarchyAccountToCreate.call(this);
    }
    
    //this will execute, once the records are deleted (and/or) created
    postSave() {
        this.updateCount();
        this.closePopup();
        this.showToastEvent();
    }

    //helper funtion for postSave()
    //once the records are created/delete update the count of contract parties
    updateCount() {
        helper.updateCount.call(this);
    }


    //to show the success message
    showToastEvent() {
        const event = new ShowToastEvent({
            "title": "Success!",
            "message": "Contract Parties sucesfully updated",
            "variant": "success"
        });
        this.dispatchEvent(event);
    }

    //to show the modal
    showPopup() {
        this.showModal = true;
        this.spinner = true;
        this.error = '';
        this.queryCustomerSubAccounts();
    }

    //to close the modal
    closePopup() {
        this.showModal = false;
        this.spinner = false;
        this.needToUpdateOpportunity = false;
        this.unrelatedAccountFound = false;
    }

    recordTypeId() {
        try {
            // Returns a map of record type Ids 
            const rtis = this.objectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find(rti => rtis[rti].name === 'Customer');
        } catch (error) {
            this.handleError(error);
        }
    }

    sortAccounts() {
        this.accountToShow.sort((a, b) => a.Name.localeCompare(b.Name));
    }

    handleHierarchyError(event) {
        this.handleError(event.detail);
    }

    //to handle the error
    handleError(error) {
        this.spinner = false;
        this.error = error;
    }

    loadGridDataFromChild(event) {
        this.gridData = event.detail.gridData;
        this.heirarchyAccounts = event.detail.accounts;
    }

    handleHierarchyRowSelection(event) {
        this.hierarchySelectedRows = event.detail;
    }

    //to decide contract tab is selected or not
    contractTabSelected() {
        this.contractTab = true;
    }
    availableTabSelected() {
        this.contractTab = false;
    }
    selectedTabSelected() {
        this.contractTab = false;
    }
    relatedTabSelected() {
        this.contractTab = false;
    }
    heirarchyTabSelected() {
        this.contractTab = false;
    }

    closeExipredAccError() {
        this.showExpiredAccError = false;
    }

    get selectedItemsLength() {
        return this.contractsToCreate.length + this.hierarchySelectedRows.length;
    }

    get showHeirarchyInfo() {
        return this.hierarchySelectedRows.length > 0 ? true : false;
    }


}