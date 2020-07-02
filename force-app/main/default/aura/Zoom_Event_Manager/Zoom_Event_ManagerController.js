({
    handleInit: function(component, event, helper) {
        var sfZoomEventId = component.get('v.recordId');
        if(!$A.util.isEmpty(sfZoomEventId)){             
            helper.callServer(component, 'getZoomEventDetails', {sfZoomEventId: sfZoomEventId}, function(response){
                if(response.getState() == 'SUCCESS'){
                    var eventObj = response.getReturnValue();
                    if(!$A.util.isEmpty(eventObj)){
                        var eventWrap = eventObj['event'];
                        if(!$A.util.isEmpty(eventWrap)){
                            eventWrap = eventWrap[0];
                            if(!$A.util.isEmpty(eventWrap.RecordType))
                                component.set('v.eventType', eventWrap.RecordType.Name); 
                            if(!$A.util.isEmpty(eventWrap.Start_Time__c))
                                eventWrap.Start_Time__c = helper.convertMSToTimeString(eventWrap.Start_Time__c);
                            component.set('v.eventObj', eventWrap);
                            
                            if(!$A.util.isEmpty(eventWrap.Thank_you_notification__c) && eventWrap.Thank_you_notification__c==false){
                                component.set('v.eventObj.Share_Survey_Link__c', false);
                                component.set('v.eventObj.Share_Recording_URL__c', false); 
                                component.set('v.disableCheckbox',true);
                            }else{
                                component.set('v.disableCheckbox',false);
                            }
                        }
                        component.set("v.parentId", eventObj['parentId']);
                        component.set('v.attendees', eventObj['attendees']);
                        component.set('v.attended', eventObj['attended']);
                        component.set('v.newAttendees', eventObj['newAttendees']);
                        
                    }
                }
                component.set('v.initializationDone', true);
            });
        }
        else {
            helper.callServer(component, 'loadExistingConfiguration', {}, function(configuration){
                if(configuration.getState() == 'SUCCESS'){
                    var eventObj = component.get('v.eventObj');
                    var config = configuration.getReturnValue();
                    if($A.util.isEmpty(config)){
                        if($A.util.isEmpty(component.get('v.errorResult'))){
                            var message = $A.get("$Label.c.Zoom_Setting_Not_Configured_Error_Message");
                            component.set('v.errorResult', {message: message, type: 'error', collapsable: false});
                            component.set('v.uiControls', {isDMLInProcess: false, isDisabled: true});
                        }
                    }else
                        eventObj = configuration.getReturnValue();
                    var now = new Date();
                    var timeMilliseconds = helper.timeStringToMilliseconds(now.getHours()+':'+now.getMinutes());
                    eventObj['Start_Time__c'] = helper.convertMSToTimeString(timeMilliseconds);
                    eventObj['Start_Date__c'] = now.toISOString().split('T')[0];                    
                    helper.callServer(component, 'getRecordTypeDetails', {}, function(recordTypes){
                        if(recordTypes.getState() == 'SUCCESS'){
                            var mapRecordType = recordTypes.getReturnValue();
                            component.set('v.mapRecordType', mapRecordType);
                            var eventRecordType = component.get('v.eventObj.RecordTypeId');
                            if($A.util.isEmpty(eventRecordType)){
                                var values = Object.values(mapRecordType);
                                component.set('v.recordTypes', values);
                                component.set('v.eventType', values[0]);
                                component.set('v.isQuickAction', true);
                            }
                            else{
                                var keys = Object.keys(mapRecordType);
                                for(var i = 0; i < keys.length; i++){
                                    if(keys[i].includes(eventRecordType)){
                                        component.set('v.eventType', mapRecordType[keys[i]]);
                                        break;
                                    }
                                }
                            }                    
                        }
                        component.set('v.eventObj', eventObj);
                        var requireThankyou = component.get('v.eventObj.Thank_you_notification__c');
                        if(!$A.util.isEmpty(requireThankyou) && requireThankyou==false){
                            component.set('v.disableCheckbox',true);
                        }else{
                            component.set('v.disableCheckbox',false);
                        }
                        component.set('v.initializationDone', true);
                    });
                }
                else
                    component.set('v.initializationDone', true);
            })
            if(!$A.util.isEmpty(component.get('v.errorResult')))
                component.set('v.uiControls', {isDMLInProcess: false, isDisabled: true});
        }
    },
    
    createEvent: function(component, event, helper) {
        //helper.toggleControls(component, helper, true, {});
        var goodToGo = component.find('eventField').reduce(function (validFields, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true);
        if(!goodToGo) {
            helper.toggleControls(component, helper, false, {message: $A.get("$Label.c.Blank_Field_on_Meeting_Form_Error_Message"), type: 'error'});
            return;
        }
        var shareSurveyLink = component.get("v.eventObj.Share_Survey_Link__c");
        var surveyLinkUrl = component.get("v.eventObj.Survey_Link_URL__c");
        if(shareSurveyLink==true && $A.util.isEmpty(surveyLinkUrl)){
            component.set('v.showSurveyUrlError',true)
            return;
        }
        
        var eventObj = JSON.parse(JSON.stringify(component.get('v.eventObj')));//To get fresh set of records
        var startTime = helper.timeStringToMilliseconds(eventObj.Start_Time__c);
        if(!$A.util.isEmpty(startTime))
            eventObj.Start_Time__c = startTime;
        eventObj.Duration__c = parseInt(eventObj.Duration__c);
        helper.callServer(component, 'upsertZoomEvent', {jsonObj: JSON.stringify(eventObj), parentId: component.get('v.parentId'), eventType: component.get('v.eventType')}, function(response){
            var errorObj = {};
            if(response.getState() == 'SUCCESS'){
                var result = response.getReturnValue();
                if(result.error)
                    errorObj = {message: result.error, type: 'error'};
                else{
                    if(!$A.util.isEmpty(eventObj.Id))
                        errorObj = {message: result.success, type: 'success'};
                    else{
                        component.set('v.uiControls', {isDMLInProcess: false, isDisabled: true});
                        component.set('v.newAttendees', result.attendees);
                        component.set('v.recordId', result.sfid);
                    }
                }
            }else 
                errorObj = {message: $A.get("$Label.c.Something_Went_Wrong_Error_Message"), type: 'error'};
            helper.toggleControls(component, helper, false, errorObj);
        });
    },
    cancelEventPopup: function(component, event, helper) {
        helper.gotBackToParentOrRecord(component, helper); 
    },
    
    sendInvitation: function(component, event, helper) {
        helper.toggleControls(component, helper, true, {});
        var allAttendees = component.get('v.newAttendees');
        var attendees = [];
        for(var i = 0; i < allAttendees.length; i++){
            if(allAttendees[i].isSelected)
                attendees.push(allAttendees[i]);
        }
        if($A.util.isEmpty(attendees)){
            var message = $A.get("$Label.c.Select_Attendee_to_Send_Invite_Error_Message");
            helper.toggleControls(component, helper, false, {message: message, type: 'error'});
            return;
        }
        var isUpdate = component.get('v.eventObj.Id') ? true : false;
        helper.callServer(component, 'sendInviteEmail', {sfMeetingId: component.get('v.recordId'),parent: component.get('v.parentId'), isUpdate: isUpdate, jsonAttendees: JSON.stringify(attendees)}, function(response){
            var errorObj = {message: $A.get("$Label.c.Something_Went_Wrong_Error_Message"), type: 'error'};
            if(response.getState() == 'SUCCESS'){
                var result = response.getReturnValue();
                if(result.true){
                    errorObj = {message: result.true, type: 'success'};
                    setTimeout(function(){helper.gotBackToParentOrRecord(component, helper);}, 1000);
                    return;
                }else
                    errorObj = {message: result.false, type: 'error'};
            }
            helper.toggleControls(component, helper, false, errorObj);
        })
    },
    
    sendThankyouEmailToAttendees : function(component, event, helper) {
        helper.validateSurveyLinkRequired(component, event, helper);
        helper.validateThankyouEmailRequired(component, event, helper);        
        //helper.toggleControls(component, helper, true, {});
        var allAttendedAttendees = component.get('v.attended');
        var attendedAttendees = [];
        
        if(!$A.util.isUndefinedOrNull(allAttendedAttendees)){
            for(var i = 0; i < allAttendedAttendees.length; i++){
                attendedAttendees.push(allAttendedAttendees[i]);
            }
        }
        
        if($A.util.isEmpty(attendedAttendees)){
            var message = $A.get("$Label.c.Select_Attendee_to_Send_Invite_Error_Message");
            var message = $A.get("$Label.c.No_Attendees");
            helper.toggleControls(component, helper, false, {message: message, type: 'error'});
            return;
        }
        
        //Send Thankyou Email if all condtions are satisfied
        var action = component.get('c.sendThankyouEmail');
        action.setParams({
            "sfMeetingId" : component.get('v.recordId'),
            "jsonAttendees" : JSON.stringify(attendedAttendees)
        });
        action.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS'){
                var result = response.getReturnValue();
            }
        });
        
        //Fetch recording from zoom if available, if recording is found for meeting then update eventObj 
        //on client side
        helper.checkRecordingAvailable(component, event, helper);
        
        //If recording is not found for meeting then display toast error message
        window.setTimeout(
            $A.getCallback(function() {
            if(component.get("v.serviceExecuted")==true){
                var shareRecordingLink = component.get("v.eventObj.Share_Recording_URL__c");
                var recordingLinkUrl = component.get("v.eventObj.Meeting_Recording_URL__c");
                
                if(shareRecordingLink==true && $A.util.isUndefinedOrNull(recordingLinkUrl)){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "type": "error",
                        "message": $A.get("$Label.c.Recording_Not_Received")
                    });
                    toastEvent.fire();  
                }     
                return;
            }
        }), 2000);
        $A.enqueueAction(action);
    },
    
    changeThankyouValue: function(component, event, helper) {
        var requireThankyou = component.get('v.eventObj.Thank_you_notification__c');
        
        if(!$A.util.isEmpty(requireThankyou) && requireThankyou==false){
            component.set('v.eventObj.Share_Survey_Link__c',false);
            component.set('v.eventObj.Share_Recording_URL__c',false);
            component.set('v.disableCheckbox',true);
        }else{ 
            component.set('v.disableCheckbox',false);
        }
    },
    
    changeSurveyLink: function(component, event, helper) {
        var shareSurveyLink = component.get('v.eventObj.Share_Survey_Link__c');
        var surveyUrlLink = component.get('v.eventObj.Survey_Link_URL__c');
        
        if(!$A.util.isEmpty(surveyUrlLink))
            component.set('v.showSurveyUrlError',false);
        if(shareSurveyLink==false)
            component.set('v.showSurveyUrlError',false);
    },
    
    changeSurveyLinkUrl: function(component, event, helper) {
        var surveyUrlLink = component.get('v.eventObj.Survey_Link_URL__c');
        
        if(!$A.util.isEmpty(surveyUrlLink))
            component.set('v.showSurveyUrlError',false);
    }
})