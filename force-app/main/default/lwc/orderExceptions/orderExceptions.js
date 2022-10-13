/**
 * Created by Andrej Tazky on 01-Dec-21.
 */
import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import getExceptionsDataWrapperForCase from '@salesforce/apex/OrderExceptionsController.getExceptionsDataWrapperForCase';
import loadExceptions from '@salesforce/apex/OrderExceptionsController.loadExceptions';

export default class OrderExceptions extends LightningElement {

    @api recordId;

    @track inputData;
    @track exceptions;
    @track error;

    @track isModalOpen = false;
    @track showSpinner = false;

    @track data = [];

    get columns() {
        return [

//            {
//
//                label: "Exception",
//                fieldName: "url",
//                type: "url",
//                sortable: false,
//                initialWidth: 150,
//
//                typeAttributes: {
//                    target: "_blank",
//                    label: {
//                        fieldName: "exception"
//                    }
//                }
//            },
//            {
//                            label: 'Details',
//                            fieldName: 'details',
//                            initialWidth: 150,
//                        },
//            {
//                label: 'Type',
//                fieldName: 'type',
//                initialWidth: 150,
//            },
//            {
//                            label: 'Type code',
//                            fieldName: 'typeCode',
//                            initialWidth: 100,
//                        },
//            {
//                label: 'Role',
//                fieldName: 'role',
//                initialWidth: 75,
//            },
//            {
//                label: 'Ports',
//                fieldName: 'ports',
//                initialWidth: 100,
//            },
//            {
//                label: 'Vessels',
//                fieldName: 'vessels',
//                initialWidth: 100,
//            },
//            {
//                label: 'Products',
//                fieldName: 'products',
//                initialWidth: 100,
//            },
//            {
//                label: 'Country of customer',
//                fieldName: 'countyOfCustomer',
//                initialWidth: 175,
//            },
//            {
//                label: 'Customer segment ',
//                fieldName: 'customerSegment',
//                initialWidth: 175,
//            },
//            {
//                label: 'Vessel flag',
//                fieldName: 'vesselFlag',
//                initialWidth: 125,
//            },
//            {
//                label: 'Vessel type',
//                fieldName: 'vesselType',
//                initialWidth: 125,
//            },
//            {
//                label: 'Port country ',
//                fieldName: 'portCountry',
//                initialWidth: 125,
//            },
//            {
//                label: 'Order value',
//                fieldName: 'orderValue',
//                initialWidth: 125,
//            },
            {
                label: 'Account number',
                fieldName: 'accNumber',
                initialWidth: 150,
            },
            {
                label: 'Account name',
                fieldName: 'name',
                initialWidth: 300,
            },
            {
                label: 'Requester',
                fieldName: 'isRequester',
                type:"boolean",
                initialWidth: 75,
            },
            {
                label: 'Payer',
                fieldName: 'isPayer',
                type:"boolean",
                initialWidth: 75,
            },
            {

                            label: "Report link",
                            fieldName: "link",
                            type: "url",
                            sortable: false,
                            initialWidth: 150,

                            typeAttributes: {
                                target: "_blank",
                                label: 'Click here'
                            }
                        },
        ];
    }

    @wire(getExceptionsDataWrapperForCase, {
        caseId: '$recordId'
    })
    wiredJsonString(result) {

        if (result.data) {

            console.log(result.data);
            this.inputData = JSON.parse(result.data);

            this.inputData.accounts.forEach(a => a.portsCodes = a.portsCodes.join());
            this.inputData.accounts.forEach(a => a.vesselCodes = a.vesselCodes.join());


            this.inputData.accounts.forEach(a => a.roles = a.roles.join());
            this.inputData.accounts.forEach(a => a.objs = a.objs.join());
            this.inputData.accounts.forEach(a => a.vesselTypes = a.vesselTypes.join());
            this.inputData.accounts.forEach(a => a.vesselFlags = a.vesselFlags.join());
            this.inputData.accounts.forEach(a => a.portsCountries = a.portsCountries.join());
            this.inputData.accounts.forEach(a => a.orderValues = a.orderValues.join());

           // this.inputData.accounts.forEach(a => a.link = '/apex/AccountTest?id='+a.id);
            this.inputData.accounts.forEach(a => a.link = '/lightning/cmp/c__OPEReportDisplay?c__recordId='+a.id);


        } else if (result.error) {
            console.log("OOOPS: " + JSON.stringify(result.error, null, 2));
        }
    }

    openModal() {
        this.isModalOpen = true;
        this.data = this.inputData.accounts;

//        loadExceptions({
//                exceptionsIds: JSON.stringify(this.inputData.exceptionsIds)
//            })
//            .then((result) => {
//                console.log(result);
//                this.exceptions = result;
//                let preparedExceptions = [];
//                this.exceptions.forEach(exception => {
//                    let preparedException = {};
//
//                    preparedException.exception = exception.Name;
//                    preparedException.details = exception.Details__c;
//                    preparedException.url = '/' + exception.Id;
//                    preparedException.type = exception.Exception__r.Title__c;
//                    preparedException.typeCode = exception.Exception__r.Code__c;
//                    preparedException.role = exception.CustomerRole__c;
//                    if (exception.PortOfDelivery__c) {
//                        if (exception.PortOfDeliveryLogic__c == 'Applies to') {
//                            preparedException.ports = '=';
//                        } else if (exception.PortOfDeliveryLogic__c == 'Doesn’t apply to') {
//                            preparedException.ports = '≠';
//                        }
//                        preparedException.ports = preparedException.ports + ' ' + exception.PortOfDelivery__c;
//                    }
//                    if (exception.Vessel__c) {
//                        if (exception.VesselLogic__c == 'Applies to') {
//                            preparedException.vessels = '=';
//                        } else if (exception.VesselLogic__c == 'Doesn’t apply to') {
//                            preparedException.vessels = '≠';
//                        }
//                        preparedException.vessels = preparedException.vessels + ' ' + exception.Vessel__c;
//                    }
//                    if (exception.Product__c) {
//                        if (exception.ProductLogic__c == 'Applies to') {
//                            preparedException.products = '=';
//                        } else if (exception.ProductLogic__c == 'Doesn’t apply to') {
//                            preparedException.products = '≠';
//                        }
//                        preparedException.products = preparedException.products + ' ' + exception.Product__c;
//                    }
//                    if (exception.CountryOfCustomer__c) {
//                        if (exception.CountryOfCustomerLogic__c == 'Applies to') {
//                            preparedException.countyOfCustomer = '=';
//                        } else if (exception.CountryOfCustomerLogic__c == 'Doesn’t apply to') {
//                            preparedException.countyOfCustomer = '≠';
//                        }
//                        preparedException.countyOfCustomer = preparedException.countyOfCustomer + ' ' + exception.CountryOfCustomer__c;
//                    }
//                    if (exception.CustomerSegmentList__c) {
//                        if (exception.CustomerSegmentLogic__c == 'Applies to') {
//                            preparedException.customerSegment = '=';
//                        } else if (exception.CustomerSegmentLogic__c == 'Doesn’t apply to') {
//                            preparedException.customerSegment = '≠';
//                        }
//                        preparedException.customerSegment = preparedException.customerSegment + ' ' + exception.CustomerSegmentList__c;
//                    }
//                    if (exception.VesselTypeList__c) {
//                        if (exception.VesselTypeLogic__c == 'Applies to') {
//                            preparedException.vesselType = '=';
//                        } else if (exception.VesselTypeLogic__c == 'Doesn’t apply to') {
//                            preparedException.vesselType = '≠';
//                        }
//                        preparedException.vesselType = preparedException.vesselType + ' ' + exception.VesselTypeList__c;
//                    }
//                    if (exception.VesselFlag__c) {
//                        if (exception.VesselFlagLogic__c == 'Applies to') {
//                            preparedException.vesselFlag = '=';
//                        } else if (exception.VesselFlagLogic__c == 'Doesn’t apply to') {
//                            preparedException.vesselFlag = '≠';
//                        }
//                        preparedException.vesselFlag = preparedException.vesselFlag + ' ' + exception.VesselFlag__c;
//                    }
//                    if (exception.CountryOfDelivery__c) {
//                        if (exception.CountryOfDeliveryLogic__c == 'Applies to') {
//                            preparedException.portCountry = '=';
//                        } else if (exception.CountryOfDeliveryLogic__c == 'Doesn’t apply to') {
//                            preparedException.portCountry = '≠';
//                        }
//                        preparedException.portCountry = preparedException.portCountry + ' ' + exception.CountryOfDelivery__c;
//                    }
//                    if (exception.OrderValue__c) {
//                        console.log('exception.OrderValueLogic__c '+exception.OrderValueLogic__c);
//                        if (exception.OrderValueLogic__c == 'Equal To') {
//                            preparedException.orderValue = '=';
//                        } else if (exception.OrderValueLogic__c == 'Less Than') {
//                            preparedException.orderValue = '<';
//                        }else if (exception.OrderValueLogic__c == 'More Than') {
//                             preparedException.orderValue = '>';
//                         }
//                        preparedException.orderValue = preparedException.orderValue + ' ' + exception.OrderValue__c;
//                    }
//                    preparedExceptions.push(preparedException);
//
//                });
//
//                this.data = preparedExceptions;
//                this.error = undefined;
//            })
//            .catch((error) => {
//                this.error = error;
//                this.exceptions = undefined;
//            });
    }


    closeModal() {
        this.isModalOpen = false;
    }

    get expCount() {

        return this.inputData?.exceptionsIds?.length;

    }

    get disableShow() {

        if(this.inputData?.exceptionsIds?.length)    {
            if(this.inputData?.exceptionsIds?.length>0){
                return false;
            }
        }

         return true

    }

}