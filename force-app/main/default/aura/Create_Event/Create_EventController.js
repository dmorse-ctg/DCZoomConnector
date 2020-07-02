({
    handleInit: function(component, event, helper) { 
        if($A.util.isEmpty(component.get("v.recordId"))){
            var value = helper.getParameterByName(component, event, 'inContextOfRef');
            var context = JSON.parse(window.atob(value));
            if(context.attributes.recordId)
                component.set("v.recordId", context.attributes.recordId);
            else
                component.set("v.errorResult", {collapsable: false, message: JSEncode($A.get('$Label.c.Invalid_Set_up_Object_Detail')), type: 'error'});
        }
        var pageReference = component.get("v.pageReference");
        if(!$A.util.isEmpty(pageReference) && !$A.util.isEmpty(pageReference.state))
            component.set('v.eventObj.RecordTypeId', pageReference.state.recordTypeId);
        component.set('v.initializationDone', true);
    }
})