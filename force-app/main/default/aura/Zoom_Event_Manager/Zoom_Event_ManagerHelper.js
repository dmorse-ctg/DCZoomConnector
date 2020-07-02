({
    callServer: function(component, actionName, params, callback) {
        var action = component.get('c.'+actionName);
        if(!$A.util.isEmpty(params))
            action.setParams(params);
        action.setCallback(this, callback);
        $A.enqueueAction(action);
    },
    convertMSToTimeString: function(milliseconds) {
        milliseconds = parseInt(milliseconds);
        var minutes = parseInt((milliseconds / (1000 * 60)) % 60);
        var hours = parseInt((milliseconds / (1000 * 60 * 60)) % 24);      
        hours = hours < 10 ? '0'+hours : hours;
        minutes = minutes < 10 ? ('0'+minutes) : minutes;
        return hours + ':' + minutes + ':00.000';
    },
    timeStringToMilliseconds: function(timeString) {
        if($A.util.isEmpty(timeString))
            return '';
        var arrTime = timeString.split(':');
        var hoursMilliseconds = parseInt(arrTime[0])*3600*1000;
        var minutesMilliseconds = parseInt(arrTime[1])*60*1000;
        return hoursMilliseconds+minutesMilliseconds;
    },
    
    togleButtons: function(component, toggle){
        var buttons = component.find('btn-id');
        if(!$A.util.isEmpty(buttons) && $A.util.isEmpty(buttons.length))
            buttons = [buttons];
        for(var i = 0; i < buttons.length; i++){
            buttons[i].set('v.disabled', toggle);
        }
    },
    
    toggleControls: function(component, helper, toggle, errorObj){
        component.set('v.errorResult', errorObj);
        helper.togleButtons(component, toggle);
    },
    
    gotBackToParentOrRecord: function(component, helper) {
        if(component.get('v.isQuickAction'))
            helper.quickBack(component);
        else{
            var sObectEvent = $A.get("e.force:navigateToSObject");
            var parentId = component.get('v.parentId');
            if(sObectEvent && parentId){
                sObectEvent.setParams({recordId: parentId});
                sObectEvent.fire();
            }
            else
                window.history.back();
        }        
    },
    quickBack: function(component){
        var quickAction = $A.get("e.force:closeQuickAction");
        if(quickAction) quickAction.fire();
        if(component.get('v.recordId')){            
            var refreshView = $A.get('e.force:refreshView');
            if(refreshView) refreshView.fire();
        }
    },
    
    validateThankyouEmailRequired: function(component, event, helper){
        var requireThankyouNotification = component.get("v.eventObj.Thank_you_notification__c");
        if(requireThankyouNotification==false){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "type": "error",
                "message": $A.get("$Label.c.Disabled_Thank_You_Email_Setting_Message")
            });
            toastEvent.fire();  
            return;
        }
    },
    
    validateSurveyLinkRequired: function(component, event, helper){
        var shareSurveyLink = component.get("v.eventObj.Share_Survey_Link__c");
        var surveyLinkUrl = component.get("v.eventObj.Survey_Link_URL__c");
        if(shareSurveyLink==true && $A.util.isEmpty(surveyLinkUrl)){
            component.set('v.showSurveyUrlError',true)
            return;
        }
    },
    
    checkRecordingAvailable: function(component, event, helper){
        var sfZoomEventId = component.get('v.recordId');
        helper.callServer(component, 'getZoomEventDetails', {sfZoomEventId: sfZoomEventId}, function(response){
            if(response.getState() == 'SUCCESS'){
                var eventObj = response.getReturnValue();
                var eventWrap = eventObj['event'];
                if(!$A.util.isEmpty(eventWrap)){
                    eventWrap = eventWrap[0]; 
                    if(!$A.util.isEmpty(eventWrap.Meeting_Recording_URL__c))
                        eventWrap.Meeting_Recording_URL__c = eventWrap.Meeting_Recording_URL__c;
                    component.set('v.eventObj.Meeting_Recording_URL__c', eventWrap.Meeting_Recording_URL__c);
                    component.set('v.serviceExecuted',true);
                }
            }
        });
    }
})