import * as angular from 'angular';
import * as _ from "underscore";
import { Component, Input } from '@angular/core';
import { PolicyInputFormService } from '../policy-input-form/PolicyInputFormService';
import {FormControl, Validators, FormGroupDirective, NgForm, FormGroup} from '@angular/forms';

export function MultipleEmail(control: FormControl) {

    var EMAIL_REGEXP = /^(?=.{1,254}$)(?=.{1,64}@)[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+(\.[-!#$%&'*+/0-9=?A-Z^_`a-z{|}~]+)*@[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$/;
    let emails :string = control.value;
    let invalidEmail  = emails.split(',').find((email: string) => !EMAIL_REGEXP.test(email.trim()));
    let isValid = invalidEmail == undefined;
    return isValid ? null : { 'multipleEmails': 'invalid email' }

}

@Component({
    selector: 'thinkbig-policy-input-form',
    templateUrl: 'js/feed-mgr/shared/policy-input-form/policy-input-form.html'
})
export class PolicyInputFormController {

    editChips:any={};
    queryChipSearch:any;
    transformChip:any;

    @Input() theForm:any;
    @Input() onPropertyChange:any;
    @Input() rule:any;
    @Input() feed:any;
    @Input() mode:any;

    formGroup :FormGroup;


    disabled: boolean = false;
    chipAddition: boolean = true;
    chipRemoval: boolean = true;
    before: boolean = false;

    constructor(private PolicyInputFormService:PolicyInputFormService) {}
    
    ngOnInit(): void {

        this.formGroup = new FormGroup({});

        this.editChips.selectedItem = null;
        this.editChips.searchText = null;
        
        this.queryChipSearch = this.PolicyInputFormService.queryChipSearch;
        this.transformChip = this.PolicyInputFormService.transformChip;

        //call the onChange if the form initially sets the value
        if(this.onPropertyChange != undefined && angular.isFunction(this.onPropertyChange)) {
            _.each(this.rule.properties, (property:any) => {
                if ((property.type == 'select' || property.type =='feedSelect' || property.type == 'currentFeed') && property.value != null) {
                    this.onPropertyChange(property);
                }
            });
        }
        _.each(this.rule.properties,(property) => this.createFormControls(property));

    }

    private createFormControls(property:any) {
        let validatorOpts :any[] = [];
        let formControlConfig = {}
        if(property.patternRegExp){
            validatorOpts.push(Validators.pattern(property.patternRegExp))
        }
        if(property.required){
            validatorOpts.push(Validators.required)
        }
        if(property.type == "emails"){
            validatorOpts.push(MultipleEmail)
        }
        if(property.type == "email"){
            validatorOpts.push(Validators.email)
        }
        if(!this.rule.editable){
            formControlConfig = {value:property.value,disabled:true}
        }
        let fc = new FormControl(formControlConfig,validatorOpts);
        this.formGroup.addControl(property.formKey,fc)
    }

    filterStrings(value: string, strings : string[], selectedItems: string[]): any {
        if(value == null){
            return strings;
        } else{
            return strings.filter((item: any) => {
        if (value) {
            return item.toLowerCase().indexOf(value.toLowerCase()) > -1;
        } else {
            return false;
        }
        }).filter((filteredItem: any) => {
            return selectedItems ? selectedItems.indexOf(filteredItem) < 0 : true;
        });
        }
    }

    onPropertyChanged = (property:any) => {
        if(this.onPropertyChange != undefined && angular.isFunction(this.onPropertyChange)){
            this.onPropertyChange(property);
        }
    }
    validateRequiredChips = (property:any) => {
        return this.PolicyInputFormService.validateRequiredChips(this.theForm, property);
    }
   
}