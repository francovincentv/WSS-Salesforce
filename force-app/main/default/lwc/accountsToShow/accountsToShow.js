/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';

export default class AccountsToShow extends LightningElement {
    @api accountToShow;
    @api selectAllIcon;
    @api icon;
    @api title;
    @api showMutliselectIcon;
    @track noDataMessage;

    handleSelect(event) {
        if(this.title === 'Add'){
            this.dispatcher(event, 'accountselect');
        } else if(this.title === 'Remove') {
            this.dispatcher(event, 'accountdeselect');
        } else if(this.title === 'Delete') {
            this.dispatcher(event, 'contractdelete')
        }
    }

    handleSelectAll() {
        if(this.title === 'Add') {
            this.dispatchEvent(new CustomEvent('selectall'));
        } else if(this.title === 'Remove') {
            this.dispatchEvent(new CustomEvent('removeall'));
        } else if(this.title === 'Delete') {
            this.dispatchEvent(new CustomEvent('deleteall'));
        }
    }

    dispatcher(event, name) {
        let selectedAccountId = event.target.value;
        const accountEvent = new CustomEvent( name , {
            detail  :   selectedAccountId
        });
        this.dispatchEvent(accountEvent);
    }

    get accountToShowCondition() {
        let returnValue = false;

        //if there are accounts to diplay thne return else return false
        if(this.accountToShow.length > 0 ) {
            returnValue = true;
        } else {
            if(this.title === 'Add') {
                this.noDataMessage = 'No data found, please try with another search!';
            } else if(this.title === 'Remove') {
                this.noDataMessage = 'No Accounts Selected!';
            } else if(this.title === 'Delete') {
                this.noDataMessage = 'No contract parties exist!';
            }
        }

        return returnValue;
    }
}