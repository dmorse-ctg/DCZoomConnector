/*
    The MIT License
    Copyright © 2020 DataColada Pty Ltd

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
 */

/******************************************************************************************************************
    Class Name  : SFZoom_LightningEventHandler
    Description : This class is responsible for managing zoom event from the lightning component as well as quick action.
    Date        : 24 Dec 2018.
    Author       : DataColada Pty Ltd
*******************************************************************************************************************/
public with sharing class SFZoom_LightningEventHandler {
    /******************************************************************************************************************
        Method Name  : getZoomEventDetails
        Description  : It fetches complete meeting details from the salesforce database and return to lightning component.
        Date         : 3 Jan 2019.
        Parameter1   : sfZoomEventId - It contains salesforce meeting object record id.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> getZoomEventDetails(String sfZoomEventId){
        Map<String, Object> returnMap;
        try{
            if(String.isNotBlank(sfZoomEventId)){
                List<String> listOfZoomMeetingFields = new List<String>{'Name', 'Agenda__c', 'Duration__c', 
                    'Enforce_Login__c', 'Join_before_Host__c', 'Auto_Register__c', 
                    'Start_Date__c', 'Start_Time__c', 'Time_Zone__c', 'Topic__c',
                    'Start_Participant_Video_on_Meeting_Join__c', 'Meeting_URL__c', 'RecordTypeId',
                    'HD_Video__c', 'Panelist_Video__c', 'Allow_Multiple_Devices__c',
                    'Host_Video__c','Thank_you_notification__c','Share_Survey_Link__c',
                    'Share_Recording_URL__c','Survey_Link_URL__c','Meeting_Recording_URL__c'};
                if(SFZoom_AccessUtil.hasReadAccess(String.escapeSingleQuotes(sfZoomEventId)) 
                   && SFZoom_AccessUtil.objectIsAccessible('Zoom_Meeting__c') 
                   && SFZoom_AccessUtil.objectIsQueryable('Zoom_Meeting__c') 
                   && SFZoom_AccessUtil.fieldsAreAccessible('Zoom_Meeting__c', listOfZoomMeetingFields))
                {
                    List<Zoom_Meeting__c> listOfMeetingToEdit = [SELECT Name, Agenda__c, Duration__c, 
                                                                         Enforce_Login__c,Join_before_Host__c,
                                                                         Start_Date__c, Start_Time__c, Time_Zone__c, 
                                                                         Topic__c,Start_Participant_Video_on_Meeting_Join__c, 
                                                                         Meeting_URL__c, Auto_Register__c, RecordType.Name,
                                                                         Thank_you_notification__c,Share_Survey_Link__c,
                                                                         Share_Recording_URL__c,Survey_Link_URL__c,
                                                                         Meeting_Recording_URL__c
                                                                         FROM Zoom_Meeting__c WHERE ID = :String.escapeSingleQuotes(sfZoomEventId)];
                    String parentId = SFZoom_MeetingManagerUtility.FindParentObjectRecordIdFromZoomMeeting((Id)sfZoomEventId);
                    returnMap = SFZoom_MeetingHandlerExtension.FindInvitationDetails((Id)parentId, (Id)sfZoomEventId);
                    returnMap.put('event', listOfMeetingToEdit);
                    returnMap.put('parentId', parentId);
                }
            }
        }Catch(Exception ex){
            System.debug('SFZoom_LightningEventHandler - getZoomEventDetails - Exception: ' + ex.getMessage());
        }
        return returnMap;
    }

    /******************************************************************************************************************
        Method Name  : getRecordTypeDetails
        Description  : It fetches meeting record type id and name and bind it with a map.
        Date         : 3 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @AuraEnabled
    public static Map<String, String> getRecordTypeDetails(){
        Map<String, String> mapOfZoomEventRecordTypeIdWithName = new Map<String, String>();
        try{
            if(SFZoom_AccessUtil.objectIsAccessible('RecordType') && SFZoom_AccessUtil.objectIsQueryable('RecordType') 
               && SFZoom_AccessUtil.fieldsAreAccessible('RecordType', new List<String>{'DeveloperName', 'SObjectType'}))
            {
                List<RecordType> listOfZoomRecordType = [SELECT DeveloperName FROM RecordType WHERE SObjectType = 'Zoom_Meeting__c'];            
                for(RecordType eventRecordType : listOfZoomRecordType){
                    mapOfZoomEventRecordTypeIdWithName.put(eventRecordType.Id, eventRecordType.DeveloperName);
                }
            }
        }Catch(Exception ex){
            System.debug('SFZoom_LightningEventHandler - getRecordTypeDetails - Exception: ' + ex.getMessage());
        }
        return mapOfZoomEventRecordTypeIdWithName;                         
    }

    /******************************************************************************************************************
        Method Name  : upsertZoomEvent
        Description  : It processes meeting/webinar record to upsert in database.
        Date         : 3 Jan 2019.
        Parameter1   : jsonObj - It contains meeting details in json format
        Parameter2   : parentId - It contains parent id of the meeting record
        Parameter3   : eventType - It contains event type whether the record is a meeting or webinar
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> upsertZoomEvent(String jsonObj, String parentId, String eventType){
        Map<String, Object> returnResult = new Map<String, Object>();
        try{
            Zoom_Meeting__c zoomMeeting = (Zoom_Meeting__c) JSON.deserialize(jsonObj, Zoom_Meeting__c.class);
            SFZoom_MeetingHandlerExtension SFZoomMeetingHandlerInstance; 
            
            if(zoomMeeting.Id == null){
                if(String.isNotBlank(parentId)){
                    SFZoomMeetingHandlerInstance = new SFZoom_MeetingHandlerExtension(null, (Id) parentId, false);
                    SFZoomMeetingHandlerInstance.meetingStartTime = zoomMeeting.Start_Time__c;
                    SFZoomMeetingHandlerInstance.zoomMeeting = zoomMeeting;
                    Boolean isWebinar;
                    eventType = String.isBlank(eventType) ? '' : eventType.toLowerCase();
                    if(eventType.equalsIgnoreCase(Label.Webinar_Record_Type_Name)){
                        isWebinar = true; 
                        SFZoomMeetingHandlerInstance.eventType = Label.Webinar_Record_Type_Name;
                    }
                    else if(eventType.equalsIgnoreCase(Label.Meeting_Record_Type_Name)){
                        isWebinar = false;
                        SFZoomMeetingHandlerInstance.eventType = Label.Meeting_Record_Type_Name;
                    }
                    if(SFZoomMeetingHandlerInstance.eventType != null){
                        String returnMessage = SFZoomMeetingHandlerInstance.CreateMeetingLightning(isWebinar);
                        
                        if(returnMessage instanceof Id){
                            returnResult.put('sfid', returnMessage);
                            returnResult.put('attendees', SFZoom_MeetingHandlerExtension.FindListOfContactOrLeadFromChildRecords((Id)parentId));
                        }else
                            returnResult.put('error', returnMessage);            
                    }
                    else
                        returnResult.put('error', Label.Wrong_event_type);
                }
                else{
                    returnResult.put('error', Label.Invalid_Set_up_Object_Detail); 
                }                     
            }
            else{
                SFZoomMeetingHandlerInstance = new SFZoom_MeetingHandlerExtension(zoomMeeting.Id, (Id)parentId, false);                
                SFZoomMeetingHandlerInstance.zoomMeeting = zoomMeeting;
                SFZoomMeetingHandlerInstance.eventType = eventType;
                Datetime toupdate=  DateTime.newInstanceGMT(zoomMeeting.Start_Date__c, zoomMeeting.Start_Time__c);
                SFZoomMeetingHandlerInstance.meetingStartTime = Time.newInstance(toupdate.hourGMT(),toupdate.minuteGMT(),toupdate.secondGMT(),0);
                String returnMessage = SFZoomMeetingHandlerInstance.UpdateMeetingDetailsLightning();
                if(returnMessage instanceof Id)
                    returnResult.put('success', Label.Event_updated_successfully);
                else
                    returnResult.put('error', returnMessage);
            }            
        }Catch(Exception ex){
            System.debug('SFZoom_LightningEventHandler - upsertZoomEvent - Exception: ' + ex.getMessage());
        }        
        return returnResult;
    }
    
    /******************************************************************************************************************
        Method Name  : getRecordTypeDetails
        Description  : It fetches default meeting/webinar settings.
        Date         : 3 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @AuraEnabled
    public static Zoom_Meeting__c loadExistingConfiguration(){
        try{
            SFZoom_MeetingHandlerExtension SFZoomMeetingHandlerInstance = new SFZoom_MeetingHandlerExtension();
            SFZoomMeetingHandlerInstance.zoomMeeting = new Zoom_Meeting__c();
            return SFZoomMeetingHandlerInstance.LoadExistingConfiguration();  
        }catch(Exception ex){
            System.debug('SFZoom_LightningEventHandler - loadExistingConfiguration - Exception: ' + ex.getMessage());
            return null;
        }
    }
    
   /******************************************************************************************************************
        Method Name  : getRecordTypeDetails
        Description  : It sends invite email to selected attendees.
        Date         : 3 Jan 2019.
        Parameter1   : sfMeetingId - It contains salesforce meeting record id
        Parameter2   : isUpdate - It tells whether it is a update or insert operation
        Parameter3   : jsonAttendees - It contains details of all the selected member in the json format
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @AuraEnabled
    public static Map<Boolean, String> sendInviteEmail(String sfMeetingId,string parent, Boolean isUpdate, String jsonAttendees){
        Map<Boolean, String> returnResult = new Map<Boolean, String>();
        try{
            if(String.isBlank(sfMeetingId))
                returnResult.put(false, Label.Missing_meeting_detail);
            else{
                List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper> lstAttendees = (List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper>) JSON.deserializeStrict(jsonAttendees, List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper>.class);
                if(lstAttendees.isEmpty())
                    returnResult.put(false, Label.Select_Attendee_to_Send_Invite_Error_Message);
                else{
                    SFZoom_MeetingHandlerExtension SFZoomMeetingHandlerInstance = new SFZoom_MeetingHandlerExtension((Id) sfMeetingId, parent, true);
                    SFZoomMeetingHandlerInstance.listOfNotInvitedRecordDetails = lstAttendees;
                    SFZoomMeetingHandlerInstance.SendEmailInviteLightning(isUpdate);
                    returnResult.put(true, Label.Email_Successfully_Sent_Message);
                }
            }
        }catch(Exception ex){
            System.debug('SFZoom_LightningEventHandler - sendInviteEmail - Exception: ' + ex.getMessage());
            returnResult.put(false, ex.getMessage());
        }
        return returnResult;
    }
    
    /******************************************************************************************************************
        Method Name  : SendThankyou Email
        Description  : It sends Thankyou email to attendees.
        Date         : 3 Jan 2019.
        Parameter1   : sfMeetingId - It contains salesforce meeting record id
        Parameter2   : jsonAttendees - It contains details of all the selected member in the json format
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @AuraEnabled
    public static Map<Boolean, String> sendThankyouEmail(String sfMeetingId, String jsonAttendees){
        Map<Boolean, String> returnResult = new Map<Boolean, String>();
        try{
            if(String.isBlank(sfMeetingId))
                returnResult.put(false, Label.Missing_meeting_detail);
            else{
                List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper> lstAttendees = (List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper>) JSON.deserializeStrict(jsonAttendees, List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper>.class);
                if(lstAttendees.isEmpty())
                    returnResult.put(false, Label.No_Attendees);
                else{
                    SFZoom_MeetingHandlerExtension SFZoomMeetingHandlerInstance = new SFZoom_MeetingHandlerExtension((Id) sfMeetingId, null, true);
                    SFZoomMeetingHandlerInstance.listOfAttendedInvitedRecordDetails = lstAttendees;
                    SFZoomMeetingHandlerInstance.sfMeetingId = sfMeetingId;
                    SFZoomMeetingHandlerInstance.isFromLightning = true;
                    SFZoomMeetingHandlerInstance.sendThankYouEmail();
                    returnResult.put(true, Label.Email_Successfully_Sent_Message);
                }
            }
        }catch(Exception ex){
            System.debug('SFZoom_LightningEventHandler - send Thankyou Email - Exception: ' + ex.getMessage());
            returnResult.put(false, ex.getMessage());
        }
        return returnResult;
    }
    
}