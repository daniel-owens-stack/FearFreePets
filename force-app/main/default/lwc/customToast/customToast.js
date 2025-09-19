import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const handleError = function (error) {
    console.log("🚀 ~ file: customToast.js ~ line 4 ~ toast ~ handleError ~ error");
    console.error(error);
    let errorMessageToDisplay = 'An error occurred \n';

    if(error.body){
        if (Array.isArray(error.body)) {
            errorMessageToDisplay += error.body.map(e => e.message).join(', ');
        } else if(typeof error.body === 'object'){
            let fieldErrors = error.body.fieldErrors;
            let pageErrors = error.body.pageErrors;
            let duplicateResults = error.body.duplicateResults;
            let exceptionError = error.body.message;

            if(exceptionError && typeof exceptionError === 'string') {
                errorMessageToDisplay += exceptionError;
            }
            
            if(fieldErrors){
                for(var fieldName in fieldErrors){
                    let errorList = fieldErrors[fieldName];
                    for(var i=0; i < errorList.length; i++){
                        errorMessageToDisplay += errorList[i].statusCode + ' ' + fieldName + ' ' + errorList[i].message + ' ';
                    }
                }
            }
    
            if(pageErrors && pageErrors.length > 0){
                for(let i=0; i < pageErrors.length; i++){
                    errorMessageToDisplay += pageErrors[i].statusCode + ' '+ pageErrors[i].message;
                }
            }
    
            if(duplicateResults && duplicateResults.length > 0){
                errorMessageToDisplay += 'duplicate result error';
            }
        }  
    }
    if(error.message){
        errorMessageToDisplay += error.message;
    }
    if(error.detail){
        errorMessageToDisplay += error.detail;
    }
    this.showToast(true, errorMessageToDisplay);
}

const showToast = function (isError, message) {
    if (isError) {
        dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    } else {
        dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success'
            })
        );
    }    
}
export{ handleError, showToast };