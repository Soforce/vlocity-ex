import { LightningElement, api, wire, track } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import CURRENCY from '@salesforce/i18n/currency';


import getJSONAttribute from '@salesforce/apex/vJsonAttributeViewerController.getJSONAttribute';
import getAttributeValues from '@salesforce/apex/vJsonAttributeViewerController.getAttributeValues';
import setAttributeValues from '@salesforce/apex/vJsonAttributeViewerController.setAttributeValues';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const actions = [
    { label: 'Details', name: 'show_details' }
];
const columns = [
    // { label: 'Code', fieldName: 'code', sortable: true },
    { label: 'Name', fieldName: 'name', sortable: true },
    { label: 'Value', fieldName: 'display_value', sortable: true, cellAttributes: { class: { fieldName: 'text_color' } } },
    { label: 'Code', fieldName: 'code', sortable: true },
    { label: 'Category', fieldName: 'category_name', sortable: true },
    {
        type: 'button-icon',
        typeAttributes: { iconName: 'utility:edit', iconClass: "slds-button__icon", name: 'edit', variant: 'bare' },
        fixedWidth:30,
    }

];

export default class JsonAttributeViewer extends LightningElement {
    @api recordId;
    // wiredAttributeData;

    // @track record;
    // @track jsonAttributeField;
    // Attribute List
    @track attributes;
    
    @track sortBy;
    @track sortDirection;

    // Attribute Info
    @track attribute;
    @track attributeValue;

    @track columns = columns;
 
    @track viewerCardTitle = 'JSONAttribute Viewer';

    connectedCallback() {
    }

    /**
     * @description wired Apex method to load JSON attributes for the given xLI by Id
     */
    @wire(getJSONAttribute, { recordId: '$recordId'})
    getJSONAttribute( { error, data }) {
        if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading JSONAttributes',
                    message: error.message,
                    variant: 'error'
                })
            );            
        } else {
            if (data) {
                // this.wiredAttributeData = data;

                console.log(data);
                var metadata = data.metadata;
                var values = data.values;
                console.log(metadata);
                console.log(values);
                this.attributes = [];
                for (const [key, myAttribute] of Object.entries(metadata.attributes)) {
                    var attribute = {
                        name: myAttribute.label,
                        code: myAttribute.code,
                        category_name: myAttribute.categoryName,
                        category_code: myAttribute.categoryCode,
                        readonly: myAttribute.readonly,
                        text_color: 'slds-text-color_default',
                        valueType:  myAttribute.valueType,
                        // this following properties are used to render UI input element
                        is_changed: false,
                        is_picklist: myAttribute.valueType == 'picklist',
                        is_input: myAttribute.valueType == 'text',
                        is_date: myAttribute.valueType == 'date',
                        is_datetime: myAttribute.valueType == 'datetime',
                        is_number: myAttribute.valueType == 'number',
                        is_currency: myAttribute.valueType == 'currency',
                        is_percent: myAttribute.valueType == 'percent',
                        is_checkbox: myAttribute.valueType == 'checkbox',
                        // values
                        value: values[key],
                        display_value: values[key], // formatted value for display purpose
                    };         
                    
                    // Populate the picklist options
                    if (attribute.is_picklist) {
                        attribute.options = [];
                        attribute.options.push ( { label: '', value: null });

                        myAttribute.values.forEach(item => {
                            // console.log(item);
                            attribute.options.push( {
                                label: item.label,
                                value: item.value
                            });  

                            if (item.value == attribute.value) {
                                attribute.display_value = item.label;
                            }
                        });
                    } 
                    
                    attribute.display_value = this.formatAttributeValue(attribute.value, attribute.valueType, attribute.options);
                     
                    this.attributes.push(attribute);
                }
            }

        }
    }

    /**
     * 
     * @param {*} value attribute value
     * @param {*} valueType attribute value data type
     * @returns formatted display value
     */
    formatAttributeValue(value, valueType, options) {
        if (value == null || value === '') {
            return '';
        }

        if (valueType == 'datetime') {
            return new Date(value).toLocaleString();
        } else if (valueType == 'checkbox') {
            return value.toString();
        } else if (valueType == 'date') {
            return new Date(value).toLocaleDateString();
        } else if (valueType == 'number') {
            return new Intl.NumberFormat(LOCALE, { style: 'decimal'}).format(new Number(value));
        } else if (valueType == 'percent') {
            // CPQ engine does not use native percent control 
            return new Intl.NumberFormat(LOCALE, {style: 'decimal'}).format(new Number(value));
            // return new Intl.NumberFormat(LOCALE, {style: 'percent'}).format(new Number(value));
        } else if (valueType == 'currency') {
            return new Intl.NumberFormat(LOCALE, { style: 'currency', currency: CURRENCY, currencyDisplay: 'symbol'}).format(new Number(value));
        } else if (valueType == 'picklist') {
            var dispVal = value;
            options.forEach(item => {
                if (item.value == value) {
                    dispVal = item.label;
                }
            });           
            return dispVal;
        } else {
            return value;
        }     
    }

    /**
     * 
     * @param {*} event 
     */
    handleSortClick(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortJsonAttributes(this.sortBy, this.sortDirection);
    }

    /**
     * 
     * @param {*} fieldname sort field name
     * @param {*} direction sort direction
     */
    sortJsonAttributes(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.attributes));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.attributes = parseData;
    }    

    /**
     * 
     * @param {*} event 
     * @description save the JSON attribute
     */
    handleJSONAttributeSaveClick(event) {
        var attributeVals = {};
        for (var i = 0; i < this.attributes.length; i++) {
            attributeVals[this.attributes[i].code] = this.attributes[i].value;
        }

        const recordInput = {};
        recordInput['recordId'] = this.recordId;
        recordInput['values'] = attributeVals;

        setAttributeValues(recordInput)   
            .then(() => {     
                for (var i = 0; i < this.attributes.length; i++) {
                    this.attributes[i].is_changed = false;
                    this.attributes[i].text_color = 'slds-text-color_default';
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'JSONAttribute updated',
                        variant: 'success'
                    })
                );
                this.attributes = this.attributes.slice();

            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating JSONAttribute',
                        message: error.message,
                        variant: 'error'
                    })
                );
            });
    }

    /**
     * 
     * @param {*} event 
     * @description refresh the attribute values from server side
     */
    handleJSONAttributeRefreshClick(event) {
        
        getAttributeValues({ recordId: this.recordId } )
            .then((attribValues) => {
                console.log(attribValues);
                this.attributes.forEach(item => {
                    item.value = attribValues[item.code];
                    // item.display_value = attribValues[item.code];
                    item.display_value = this.formatAttributeValue(item.value, item.valueType, item.options);
                    item.text_color = 'slds-text-color_default';
                });

                this.attributes = this.attributes.slice();

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'JSONAttribute has been refreshed.',
                        variant: 'success'
                    })
                );                
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error refreshing JSONAttribute',
                        message: error.message,
                        variant: 'error'
                    })
                );

            });
    }

    /**
     * 
     * @param {*} event 
     */
    handleAttribueValueChange(event) {
        if (typeof(event.target.type) === 'undefined') {
            if (event.target.options) {
                this.attributeValue = event.target.value;
            }
        } else {
            if (event.target.type === 'checkbox') {
                this.attributeValue = event.target.checked;
            } else {
                this.attributeValue = event.target.value;
            }
        }
    }

    /**
     * 
     * @param {*} event 
     */
    handleAttributeUpdateClick(event) {
        this.attribute.value = this.attributeValue;
        this.attribute.display_value = this.formatAttributeValue(this.attribute.value, this.attribute.valueType, this.attribute.options);

        this.attribute.is_changed = true;
        this.attribute.text_color = 'slds-text-color_error';

        this.handleAttributeCloseClick(event);
    }

    handleAttributeCloseClick(event) {
        this.attribute = null;
        this.viewerCardTitle = 'JSONAttribute Viewer';
    }

    handleAttributeRowAction(event) {
        const actionName = event.detail.action.name;
        this.attribute = event.detail.row;
        this.attributeValue = this.attribute.value;

        this.viewerCardTitle = 'Edit "' + this.attribute.name + '"';

    }
}