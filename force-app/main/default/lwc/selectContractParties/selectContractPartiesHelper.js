/* eslint-disable no-console */
// helper for selectContractParteis.js
import getContractParties from '@salesforce/apex/LWC_SelectContractParties.getContractParties';
import getSubAccounts from '@salesforce/apex/LWC_SelectContractParties.getSubAccounts';
import getSubDealsForContract from '@salesforce/apex/LWC_SelectContractParties.getSubDealsForContract';


export const helper = {

    deleteList(itemsToDelete, contractsToDelete) {
        contractsToDelete.forEach(contractId => {
            let cp = {
                'sobjecttype': 'ContractParty__c'
            };
            cp.Id = contractId;
            itemsToDelete.push(cp);
        });

        return itemsToDelete;
    },

    insertList() {
        console.log('now adding contract parties');
        //format the records to insert
        this.contractsToCreate.forEach(account => {
            let cp = {
                'sobjecttype': 'ContractParty__c'
            };
            cp.Account__c = account.Id;
            cp.Opportunity__c = this.recordId;
            cp.RecordTypeId = this.recordTypeId();

            //for only amendment opportunity 
            if(this.isAmendmentOpp) {
                //if account is not belongs to previous opportunity of Amendment, then mark AmendedParty__c to true
                cp.AmendedParty__c = this.prevAmendOppAccounts.has(account.Id) ? false : true;
            }

            this.contractsToInsertInDatabase.push(cp);
        });

    },

    queryAmendmentOppContratParty() {
        getContractParties({
            oppId : this.previousOpp
        })
        .then(result => {
            result.forEach(cp=>this.prevAmendOppAccounts.add(cp.Account__c));
        })
        .catch(error=> {
            this.handleError(error)
        })
    }
    ,

    //query all the Sub_Deal__c records related to the contractId
    //return accountIds
    getSubDealsAcctsFromContract() {
        getSubDealsForContract({
            contractId : this.relatedContract
        })
        .then(result=>{
            result.forEach(acc=>this.subDealAccountsMap.set(acc.Id, acc));

            //get the existing contract account ids
            let existingContractPartyAccIds = this.existingContractParties.map(cp=>cp.Account__c);
            
            this.subDealAccountsMap.forEach((value,key)=>{
                if(existingContractPartyAccIds.indexOf(key)===-1){
                    this.contractAccounts.push(value);
                }
            })
            
            this.spinner = false;
        })
        .catch(error=>{
            this.spinner = false;
            this.handleError(error);
        })
    }
    ,
    //add the accounts selcted from account hierarchy to the contractsToCreate array
    addHeirarchyAccountToCreate() {
        let exitContractAccIds = this.existingContractPartiesCopy.map(curr => curr.Account__c);
        let newContractAccIds = this.contractsToCreate.map(acc => acc.Id);

        let hierarchyAccountsById = {};
        this.heirarchyAccounts.forEach(account=>{
            hierarchyAccountsById[account.Id] = account;
        });
        //console.log('hierarchyAccountsById',JSON.stringify(hierarchyAccountsById));

        this.hierarchySelectedRows.forEach(curr => {
            //if the account is availble in selected list then don't add to the contactsToCreate array
            //if the account has already contact party then dont add to the contactsToCreate array
            if (newContractAccIds.indexOf(curr) === -1 && exitContractAccIds.indexOf(curr) === -1) {
                let acc = hierarchyAccountsById[curr];
                this.contractsToCreate.push(acc);
            }
        });
    },

    updateCount() {
        this.existingContractParties = [];
        getContractParties({
                oppId: this.recordId
            })
            .then(response => {
                this.recordCount = response.length;

                //load the existing contact parties 
                response.forEach(curr => {
                    let obj = {};
                    obj.Id = curr.Id;
                    obj.Account__c = curr.Account__c;
                    obj.Name = curr.Account__r.Name;
                    obj.Account_Number__c = curr.Account__r.Account_Number__c;
                    obj.CurrencyIsoCode = curr.Account__r.CurrencyIsoCode;
                    obj.exist = false;
                    obj.AccountRecordTypeName = curr.Account__r.RecordType.DeveloperName;
                    obj.AccountOwner = curr.Account__r.OwnerId;
                    obj.AccountOwnerTerritory = curr.Account__r.Owner.SM_Territory__c;
                    obj.AccountOwnerSalesArea = curr.Account__r.Owner.Sales_Area__c;
                    obj.Account_Status__c = curr.Account__r.Account_Status__c;
                    this.existingContractParties.push(obj);
                });
                this.existingContractPartiesCopy = this.existingContractParties;
            })
            .catch(error => {
                this.handleError(error)
            });
    },

    qeurySubAccounts() {
        getSubAccounts()
            .then(data => {
                //filter the account that are not exist for the current opp
                this.subAccounts = data.filter(curAcc => {
                    let accountId = curAcc.Id;
                    let returnValue = true;
                    this.allAccountsWithKeyAsAccount[accountId] = curAcc;
                    if (curAcc.Contract_Parties__r) {
                        curAcc.exist = true; //to identify the account is already added for other contract party
                        curAcc.Contract_Parties__r.forEach(element => {
                            if (element.Opportunity__c === this.recordId) {
                                returnValue = false;
                            }
                        });
                    } else {
                        curAcc.exist = false;
                    }
                    return returnValue;
                });

                this.accountToShow = this.subAccounts.slice(0, this.showCount);
                this.sortAccounts(); //sort the accounts by name
                this.spinner = false;
            })
            .catch(error => {
                this.handleError(error);
                this.spinner = false;
            });
    },

    checkExistingAccounts() {
        const recordTypesToConsider = ['Customer_Sub_Account', 'Customer_Account'];

        let approvalScenarioCopy = this.approvalScenarios;
        let unrelatedAccountsIds = new Set();
        let unrelatedAccountsOwnerIds = new Set();
        let unrelatedAccountsOwnerTerritory = new Set();
        let unrelatedAccountsOwnerSalesArea = new Set();
        let heirarchyAccountIds = this.heirarchyAccounts.map(acc=>acc.Id);

        this.needToUpdateOpportunity = false;
        
        //console.log('approval scenarions before ', this.approvalScenarios);
        
        //first check :  the selected accounts
        this.contractsToCreate.forEach(acc => {
            //console.log('account>>',acc.Name,'Owner>>>',acc.OwnerId,' Terr>>',acc.Owner.SM_Territory__c, ' area>>',acc.Owner.Sales_Area__c);
            if (heirarchyAccountIds.indexOf(acc.Id) === -1) {
                unrelatedAccountsIds.add(acc.Id);
            }
            if(acc.Owner.SM_Territory__c) {
                unrelatedAccountsOwnerTerritory.add(acc.Owner.SM_Territory__c);
            }
            if(acc.Owner.Sales_Area__c) {
                unrelatedAccountsOwnerSalesArea.add(acc.Owner.Sales_Area__c);
            }
            if (recordTypesToConsider.indexOf(acc.RecordType.DeveloperName) !== -1 ) {
                unrelatedAccountsOwnerIds.add(acc.OwnerId);
            }
        });


        //Second check : get the account owner ids that are selected from account hierarchy
        /* this.heirarchyAccounts.forEach(acc => {
            if (recordTypesToConsider.indexOf(acc.RecordType.DeveloperName) !== -1 && this.hierarchySelectedRows.indexOf(acc.Id) !== -1) {
                unrelatedAccountsOwnerIds.add(acc.OwnerId);
            }
            if(acc.AccountOwnerTerritory) {
                unrelatedAccountsOwnerTerritory.add(acc.AccountOwnerTerritory);
            }
            if(acc.AccountOwnerSalesArea) {
                unrelatedAccountsOwnerSalesArea.add(acc.AccountOwnerSalesArea);
            }
        });
 */
        //third check : the existing accounts
        this.existingContractParties.forEach(cp => {
            if (recordTypesToConsider.indexOf(cp.AccountRecordTypeName) !== -1) {
                if (heirarchyAccountIds.indexOf(cp.Account__c) === -1) {
                    unrelatedAccountsIds.add(cp.Account__c);
                }
                if(cp.AccountOwnerTerritory) {
                    unrelatedAccountsOwnerTerritory.add(cp.AccountOwnerTerritory);
                }
                if(cp.AccountOwnerSalesArea) {
                    unrelatedAccountsOwnerSalesArea.add(cp.AccountOwnerSalesArea);
                }
                unrelatedAccountsOwnerIds.add(cp.AccountOwner);
            }
        });

        //if there is any unrelated account found, then add the scenarion 2 else remove it
        if(unrelatedAccountsIds.size>0) {
            approvalScenarioCopy = helper.addApprovalScenario('Scenario2', approvalScenarioCopy);
            this.unrelatedAccountFound = true;
        } else  {
            approvalScenarioCopy = helper.removeApprovalScenario('Scenario2', approvalScenarioCopy);
        }

        //if there are two or more accounts having different owners then add 'Scenario3', else remove it
        if (unrelatedAccountsOwnerIds.size > 1) {
            this.unrelatedAccountFound = true;
            approvalScenarioCopy = helper.addApprovalScenario('Scenario3', approvalScenarioCopy);
        } else {
            approvalScenarioCopy = helper.removeApprovalScenario('Scenario3', approvalScenarioCopy);
        }

        //if there are two or more accounts having different owners with different SM_Territory__c then add 'Scenario4', else remove it
        if (unrelatedAccountsOwnerTerritory.size > 1) {
            this.unrelatedAccountFound = true;
            approvalScenarioCopy = helper.addApprovalScenario('Scenario4', approvalScenarioCopy);
        } else {
            approvalScenarioCopy = helper.removeApprovalScenario('Scenario4', approvalScenarioCopy);
        }

        //if there are two or more accounts having different owners with different Sales_Area__c then add 'Scenario5', else remove it
        if (unrelatedAccountsOwnerSalesArea.size > 1) {
            this.unrelatedAccountFound = true;
            approvalScenarioCopy = helper.addApprovalScenario('Scenario5', approvalScenarioCopy);
        } else {
            approvalScenarioCopy = helper.removeApprovalScenario('Scenario5', approvalScenarioCopy);
        }
        
        //console.log('before>>',this.approvalScenarios,' after>>', approvalScenarioCopy);
        if (approvalScenarioCopy !== this.approvalScenarios) {
            this.approvalScenarios = approvalScenarioCopy;
            this.opportunityToUpdate.Approval_Scenarios__c = this.approvalScenarios;
            this.needToUpdateOpportunity = true;
        }
        //console.log('Opp,', JSON.stringify(this.opportunityToUpdate), 'updated:', this.needToUpdateOpportunity);
    }
    ,
    removeApprovalScenario(scenario, approvalScenarioCopy) {
        //console.log('removing process of :', scenario, 'from ', approvalScenarioCopy);
        if (approvalScenarioCopy) {
            let approvalScenariosArray = approvalScenarioCopy.split(';');
            let index = approvalScenariosArray.indexOf(scenario);
            if (index !== -1) {
                approvalScenariosArray.splice(index, 1);
                approvalScenarioCopy = approvalScenariosArray.join(';');
            }
        }
        return approvalScenarioCopy;
    },
    addApprovalScenario(scenario, approvalScenarioCopy) {
        //console.log('adding process of :', scenario, 'from ', approvalScenarioCopy);
        if (approvalScenarioCopy) {
            if (!approvalScenarioCopy.includes(scenario)) {
                approvalScenarioCopy += ';' + scenario;
            }
        } else {
            approvalScenarioCopy = scenario;
        }
        return approvalScenarioCopy;
    }
}