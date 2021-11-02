// import { Component, Renderer, QueryList, ElementRef, ViewChildren } from '@angular/core';
// import { FormBuilder, AbstractControl } from '@angular/forms';
// import { Field, FormlyPubSub, FormlyMessages, FormlyValueChangeEvent } from 'ng2-formly';
// import { SingleFocusDispatcher } from 'ng2-formly/lib/templates';
// import { MatCheckbox } from '@angular/material/checkbox';

// @Component({
// 	selector: 'formly-field-multicheckbox',
// 	template: `
//         <div [formGroup]="form">
//             <div [formGroupName]="key" class="form-group">
//                 <label class="form-control-label" for="">{{templateOptions.label}}</label>
//                 <div *ngFor="let option of templateOptions.options">
//                     <label class="c-input c-radio">
//                         <mat-checkbox type="checkbox" [formControlName]="option.key"
//                           [(ngModel)]="model[option.key]" (change)="inputChange($event, option.key)"
//                           (focus)="onInputFocus()" [disabled]="templateOptions.disabled" #inputElement>{{option.value}}
//                         </mat-checkbox>
//                         <span class="c-indicator"></span>
//                     </label>
//                 </div>
//                 <small class="text-muted">{{templateOptions.description}}</small>
//             </div>
//         </div>
//     `,
// 	queries: { inputComponent: new ViewChildren('inputElement') }
// })
// export class FormlyFieldMultiCheckbox extends Field {
// 	constructor(
// 		fm: FormlyMessages,
// 		private fps: FormlyPubSub,
// 		private formBuilder: FormBuilder,
// 		renderer: Renderer,
// 		focusDispatcher: SingleFocusDispatcher
// 	) {
// 		super(fm, fps, renderer, focusDispatcher);
// 	}

// 	createControl(): AbstractControl {
// 		let controlGroupConfig = this.templateOptions.options.reduce((previous, option) => {
// 			previous[option.key] = [ this.model ? this.model[option.key] : undefined ];
// 			return previous;
// 		}, {});
// 		return (this._control = this.formBuilder.group(controlGroupConfig));
// 	}

// 	inputComponent: QueryList<MatCheckbox>;

// 	inputChange(e, val) {
// 		this._model[val] = e.checked;
// 		this.changeFn.emit(new FormlyValueChangeEvent(this.key, this._model));
// 		this.fps.setUpdated(true);
// 	}

// 	protected setNativeFocusProperty(newFocusValue: boolean): void {
// 		if (this.inputComponent.length > 0) {
// 			// this.inputComponent.first.focus();
// 		}
// 	}
// }
