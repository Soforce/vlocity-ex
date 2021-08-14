import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import LOCALE from '@salesforce/i18n/locale';
import CURRENCY from '@salesforce/i18n/currency';
import { updateRecord } from 'lightning/uiRecordApi';
import getJSONAttribute from '@salesforce/apex/JSONAttributeSupportEx.getJSONAttribute';
import getAttributeValues from '@salesforce/apex/JSONAttributeSupportEx.getAttributeValues';
import setAttributeValues from '@salesforce/apex/JSONAttributeSupportEx.setAttributeValues';

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
    @api objectApiName;

    // @track record;
    @track jsonAttributeField;
    // Attribute List
    @track attributes;
    
    // Attribute Info
    @track attribute;
    @track attributeValue;
    @track attributeLabel;

    @track columns = columns;
 
    @track viewerCardTitle = 'JSONAttribute Viewer';

    @track jsonAttribute;

    connectedCallback() {
        if(this.objectApiName==='QuoteLineItem') {
            this.jsonAttributeField = 'QuoteLineItem.vlocity_cmt__JSONAttribute__c';
        } else if(this.objectApiName==='OpportunityLineItem') {
            this.jsonAttributeField = 'OpportunityLineItem.vlocity_cmt__JSONAttribute__c';
        } else if(this.objectApiName==='OrderItem') {
            this.jsonAttributeField = 'OrderItem.vlocity_cmt__JSONAttribute__c';
        } else if (this.objectApiName === 'Asset')   {
            this.jsonAttributeField = 'Asset.vlocity_cmt__JSONAttribute__c';
        } else if (this.objectApiName === 'vlocity_cmt__FulfilmentRequestLine__c')   {
            this.jsonAttributeField = 'vlocity_cmt__FulfilmentRequestLine__c.vlocity_cmt__JSONAttribute__c';
        } else if (this.objectApiName === 'vlocity_cmt__InventoryItem__c')   {
            this.jsonAttributeField = 'vlocity_cmt__InventoryItem__c.vlocity_cmt__JSONAttribute__c';
        }
        
    }

    @wire(getJSONAttribute, { recordId: '$recordId'})
    getJSONAttributeEx( { error, data }) {
        if (error) {
            console.log('Error');
        } else {
            if (data) {
                console.log(data);
                var metadata = data.metadata;
                var values = data.values;
                console.log(metadata);
                console.log(values);
                this.attributes = [];
                for (const [key, myAttribute] of Object.entries(metadata.attributes)) {
                    // console.log(`${key}: ${value}`);

                    var attribute = {
                        name: myAttribute.label,
                        code: myAttribute.code,
                        category_name: myAttribute.categoryName,
                        category_code: myAttribute.categoryCode,
                        // active: myAttribute.isactive__c,
                        readonly: myAttribute.readonly,
                        text_color: 'slds-text-color_default',
                        is_changed: false,
                        is_picklist: myAttribute.valueType == 'picklist',
                        is_input: myAttribute.valueType == 'text',
                        is_date: myAttribute.valueType == 'date',
                        is_datetime: myAttribute.valueType == 'datetime',
                        is_number: myAttribute.valueType == 'number',
                        is_currency: myAttribute.valueType == 'currency',
                        is_percent: myAttribute.valueType == 'percent',
                        is_checkbox: myAttribute.valueType == 'checkbox',
                        value: values[key],
                        display_value: values[key],
                    };         
                    
                    console.log(attribute);
                    if (attribute.is_picklist) {
                        attribute.options = [];

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
                    
                    this.attributes.push(attribute);
                }
            }

        }
    }

    // @wire(getRecord, { recordId: '$recordId', fields: '$jsonAttributeField' })
    // getJSONAttribute( { error, data }) {
    //     if (error) {
    //         // TODO
    //         console.log('Error');
    //     } else if (data) {
    //         // this.record = data;
    //         this.jsonAttribute = data.fields.vlocity_cmt__JSONAttribute__c.value;
    //         var attributesByCategory = JSON.parse(this.jsonAttribute);
    //         //debugger;
    //         this.attributes = [];
    //         for (var categoryCode in attributesByCategory) {
    //             var myAttributes = attributesByCategory[categoryCode];
    //             for (var i = 0; i < myAttributes.length; i++) {
    //                 var myAttribute = myAttributes[i];

    //                 var attribute = {
    //                     name: myAttribute.attributedisplayname__c,
    //                     code: myAttribute.attributeuniquecode__c,
    //                     category_name: myAttribute.categoryname__c,
    //                     category_code: myAttribute.categorycode__c,
    //                     active: myAttribute.isactive__c,
    //                     readonly: myAttribute.isreadonly__c,
    //                     text_color: 'slds-text-color_default',
    //                     is_changed: false,
    //                     is_picklist: false,
    //                     is_input: false,
    //                     is_number: false,
    //                     is_checkbox: false,
    //                     is_combobox: false,
    //                 };

    //                 var myRuntimeInfo = myAttribute.attributeRunTimeInfo;
    //                 attribute.data_type = myRuntimeInfo.dataType;

    //                 attribute.value = myRuntimeInfo.value;
    //                 attribute.display_value = attribute.value == null ? "" : attribute.value + ""; 
                    
    //                 if (myRuntimeInfo.dataType === "Currency" ||
    //                     myRuntimeInfo.dataType === "Percent" ||
    //                     myRuntimeInfo.dataType === "Number") {
    //                     attribute.input_type = 'number';
    //                     attribute.is_number = true;
    //                 } else if (myRuntimeInfo.dataType === "Text" || 
    //                     myRuntimeInfo.dataType === "Lookup") {
    //                     attribute.input_type = 'text';
    //                     attribute.is_input = true;
    //                 } else if (myRuntimeInfo.dataType === "Checkbox") {
    //                     attribute.input_type = 'checkbox';                        
    //                     attribute.is_checkbox = true;
    //                 } else if (myRuntimeInfo.dataType === "Date") {
    //                     attribute.input_type = 'date';
    //                     attribute.is_input = true;
    //                 } else if (myRuntimeInfo.dataType === "Datetime") {
    //                     attribute.input_type = 'datetime';
    //                     attribute.is_input = true;
    //                 } else if (myRuntimeInfo.dataType === "Picklist") {
    //                     attribute.is_combobox = true;

    //                     attribute.value = Object.keys(myRuntimeInfo.selectedItem).length === 0 ? null : myRuntimeInfo.selectedItem.value;
    //                     attribute.display_value = Object.keys(myRuntimeInfo.selectedItem).length === 0 ? null : myRuntimeInfo.selectedItem.displayText;
    //                     attribute.options = [];
    //                     for (var j = 0; j < myRuntimeInfo.values.length; j++) {
    //                         attribute.options.push( {
    //                             label: myRuntimeInfo.values[j].displayText,
    //                             value: myRuntimeInfo.values[j].value
    //                         });
    //                     }
                        
    //                 } else if (myRuntimeInfo.dataType === "Multi Picklist") {
    //                     attribute.input_type = 'text';
    //                     attribute.is_input = true;
    //                 } else {
    //                     attribute.input_type = 'text';
    //                     attribute.is_input = true;
    //                 }

    //                 this.attributes.push(attribute);
    //             }

    //         }

    //         console.log(this.attributes);
    //     }
    // }

    // get jsonAttribute() {
    //     if (this.record)
    //         return this.record.fields.vlocity_cmt__JSONAttribute__c.value;
    //     else
    //         return 'Record not found';
    // }

    handleJSONAttributeSaveClick(event) {
        console.log('handleJSONAttributeSaveClick');
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

        // var attributeVals = {};
        // for (var i = 0; i < this.attributes.length; i++) {
        //     attributeVals[this.attributes[i].code] = { 
        //         "value": this.attributes[i].value,
        //         "display_value": this.attributes[i].display_value,
        //     };
        // }

        // var attributesByCategory = JSON.parse(this.jsonAttribute);
        // for (var categoryCode in attributesByCategory) {
        //     var myAttributes = attributesByCategory[categoryCode];
        //     for (var i = 0; i < myAttributes.length; i++) {
        //         var myAttribute = myAttributes[i];
        //         var myRuntimeInfo = myAttribute.attributeRunTimeInfo;
        //         if (myRuntimeInfo.dataType === "Picklist") {
        //             myRuntimeInfo.selectedItem.value = attributeVals[myAttribute.attributeuniquecode__c].value;
        //             myRuntimeInfo.selectedItem.displayText = attributeVals[myAttribute.attributeuniquecode__c].display_value;
        //         } else {
        //             myRuntimeInfo.value = attributeVals[myAttribute.attributeuniquecode__c].value;
        //         }        
        //     }
        // }

        // var updatedJSON = JSON.stringify(attributesByCategory);
        // console.log(updatedJSON);

        // // Create the recordInput object
        // const fields = {};
        // fields['Id'] = this.recordId;
        // fields['vlocity_cmt__JSONAttribute__c'] = updatedJSON; // this.record.fields.vlocity_cmt__JSONAttribute__c.value;

        // const recordInput = { fields };
        // updateRecord(recordInput)
        //     .then(() => {
        //         this.jsonAttribute = updatedJSON;
        //         // this.record.fields.vlocity_cmt__JSONAttribute__c.value = updatedJSON;
        //         for (var i = 0; i < this.attributes.length; i++) {
        //             this.attributes[i].is_changed = false;
        //             this.attributes[i].text_color = 'slds-text-color_default';
        //         }

        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Success',
        //                 message: 'JSONAttribute updated',
        //                 variant: 'success'
        //             })
        //         );
        //     })
        //     .catch(error => {
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Error updating JSONAttribute',
        //                 message: error.message,
        //                 variant: 'error'
        //             })
        //         );
        //     });
            

    }

    handleJSONAttributeRefreshClick(event) {
        getAttributeValues({ recordId: this.recordId } )
            .then((attribValues) => {
                console.log(attribValues);
                this.attributes.forEach(item => {
                    item.value = attribValues[item.code];
                    item.display_value = attribValues[item.code];
                    item.text_color = 'slds-text-color_default';
                });
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
        // // Rebuild the this.attributes to force a datatable refresh
        // this.attributes = JSON.parse(JSON.stringify(this.attributes));

        // var attributeVals = {};
        // var attributesByCategory = JSON.parse(this.jsonAttribute);
        // for (var categoryCode in attributesByCategory) {
        //     var myAttributes = attributesByCategory[categoryCode];
        //     for (var i = 0; i < myAttributes.length; i++) {
        //         var myAttribute = myAttributes[i];
        //         var myRuntimeInfo = myAttribute.attributeRunTimeInfo;
        //         if (myRuntimeInfo.dataType === "Picklist") {
        //             attributeVals[myAttribute.attributeuniquecode__c] = Object.keys(myRuntimeInfo.selectedItem).length === 0 ? null : myRuntimeInfo.selectedItem.displayText;
        //         } else {
        //             attributeVals[myAttribute.attributeuniquecode__c] = myRuntimeInfo.value;
        //         }         
        //     }
        // }

        // for (var i = 0; i < this.attributes.length; i++) {
        //     this.attributes[i].value = attributeVals[this.attributes[i].code];
        //     this.attributes[i].display_value = this.attributes[i].display_value;
        //     this.attributes[i].is_changed = false;
        //     this.attributes[i].text_color = 'slds-text-color_default';
        // }
    }

    handleJSONAttributeCopyClick(event) {
        var inputEle = document.createElement("input");

        //set the value atrribute
        inputEle.setAttribute("value", this.jsonAttribute);
        //append element to document body
        document.body.appendChild(inputEle);

        // selects all the text  in an < input > element that includes a text field.

        inputEle.select();

        document.execCommand("copy");
    }

    handleAttribueValueChange(event) {
        if (event.target.type) {
            console.log('Has Type');
        } else {
            console.log('No Type');
        }
        if (typeof(event.target.type) === 'undefined') {
            if (event.target.options) {
                this.attributeValue = event.target.value;
                this.attributeLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
            }
        } else {
            if (event.target.type === 'checkbox') {
                this.attributeValue = event.target.checked;
            } else {
                this.attributeValue = event.target.value;
            }
            this.attributeLabel = this.attributeValue + "";
        }
    }

    handleAttributeUpdateClick(event) {
        this.attribute.value = this.attributeValue;
        this.attribute.display_value = this.attributeLabel;
        // if (event.target.type === 'combobox') {
        //     this.attribute.display_value = event.target.options.find(opt => opt.value === event.detail.value).label;
        // }

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
        this.attributeLabel = this.attribute.display_value;

        this.viewerCardTitle = 'Edit "' + this.attribute.name + '"';

        // switch (actionName) {
        //     case 'delete':
        //         // alert('delete');
        //         break;
        //     case 'show_details':
        //         // alert('details');
        //         break;
        //     default:
        // }
    }
}