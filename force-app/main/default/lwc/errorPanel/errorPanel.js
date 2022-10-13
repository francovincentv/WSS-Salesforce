import { LightningElement, api } from 'lwc';
import { reduceErrors } from './errorUtils';

export default class ErrorPanel extends LightningElement {
    /** Generic / user-friendly message */
    @api friendlyMessage = 'Error while retrieve/manipulating data';

    viewDetails = false;

    /** Single or array of LDS errors */
    @api errors;

    get errorMessages() {
        return reduceErrors(this.errors);
    }

    handleCheckboxChange(event) {
        this.viewDetails = !this.viewDetails;
    }
}

export function getErrorMessage(error) {
    return reduceErrors(error);
}