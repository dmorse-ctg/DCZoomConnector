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
        Class Name  : SFZoomServiceToUpdateParticipantsDetails
        Description : This class is responsible for handling webhook operation and update the meeting participants detail in the Salesforce.
        Date        : 01 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    @RestResource(urlMapping='/UpdateMeetingParticipantsDetail')
    global without sharing class SFZoomServiceToUpdateParticipantsDetails {
    /******************************************************************************************************************
        Method Name  : UpdateMeetingParticipantDetails
        Description  : It process the webhook response and updates the meeting participant details in the salesforce based on the response 
                       which comes after meeting ends.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
        *******************************************************************************************************************/
    @HttpPost
    global static void UpdateMeetingParticipantDetails(){
        Zoom_Meeting__c meetingDetails;
        try{
            RestRequest req = RestContext.request;
            Blob body = req.requestBody;
            String contentToParse = body.toString();
            Map<String,Object> mapOfResponse = (Map<String,Object>) JSON.deserializeUntyped(contentToParse);
            
            String webhookEvent = mapOfResponse.containsKey('event') ? String.valueOf(mapOfResponse.get('event')): '';
            if(mapOfResponse!= null && !mapOfResponse.isEmpty() && String.isNotBlank(webhookEvent)){
                Map<String,Object> mapOfPayloadData = (Map<String,Object>)mapOfResponse.get('payload');
                Map<String,Object> mapOfMeetingData;
                Map<String,Object> mapOfRegistrantsData;
                Map<String,String> mapOfRegistrantsId = new Map<String, String>();

                String meetingId;
                if(mapOfPayloadData != null && !mapOfPayloadData.isEmpty()){
                    mapOfMeetingData = (Map<String,Object>)mapOfPayloaddata.get('meeting');
                }
                if(mapOfMeetingData == null || mapOfMeetingData.isEmpty()){
                    mapOfMeetingData = (Map<String,Object>)mapOfPayloaddata.get('object');
                } 

                if(mapOfMeetingData != null && !mapOfMeetingData.isEmpty()){
                    meetingId = String.valueOf(mapOfMeetingData.get('id'));
                    mapOfRegistrantsData = (Map<String,Object>)mapOfMeetingData.get('registrant');
                    if(mapOfRegistrantsData != null && !mapOfRegistrantsData.isEmpty())
                    {
                        mapOfRegistrantsId.put('id', String.valueOf(mapOfRegistrantsData.get('id'))) ;
                    }
                }

                // Handle the Meeting End Event from the webhook
                if((webhookEvent.equalsIgnoreCase(Label.Webhook_Meeting_Ended_Event_Name)
                   || webhookEvent.equalsIgnoreCase(Label.Meeting_Ended_Event_Name)
                   || webhookEvent.equalsIgnoreCase(Label.Webinar_Ended_Event_Name))){
                        List<Zoom_Meeting__c> listOfZoomMeeting;
                        if(String.isNotBlank(meetingId)){
                            // False Positive - We have to query meeting details regardless of user's permission.  
                            listOfZoomMeeting = [SELECT Name, Status__c, Event_Type__c,
                                                Host_Id__c, Auto_Register__c,Thank_you_notification__c,
                                                Share_Recording_URL__c, Meeting_Recording_URL__c, 
                                                Survey_Link_URL__c, Share_Survey_Link__c, Topic__c
                                                FROM Zoom_Meeting__c 
                                                WHERE Name = : String.escapeSingleQuotes(meetingId) 
                                                ORDER BY CREATEDDATE DESC LIMIT 1];
                        
                        }                
                        if(listOfZoomMeeting != null && !listOfZoomMeeting.isEmpty()){
                            listOfZoomMeeting[0].Status__c = mapOfMeetingData.get('status') != null ? String.valueOf(mapOfMeetingData.get('status')) : null;
                            listOfZoomMeeting[0].Host_Id__c = mapOfMeetingData.get('host_id') != null ? String.valueOf(mapOfMeetingData.get('host_id')) : null;
                            listOfZoomMeeting[0].Webhook_Response__c = contentToParse;
                            //Fetching Meeting Actual Pariticpants or Attendees Details
                            getMeetingParticipantDetails(listOfZoomMeeting);
                            // False Positive - We have to update meeting details regardless of user's permission.
                            UPDATE listOfZoomMeeting;
                        }
                       
                // Handle Registrant Cancellation Event
                }else if((webhookEvent.equalsIgnoreCase(Label.Meeting_Registration_Cancelled_Event_Name)
                   	   || webhookEvent.equalsIgnoreCase(Label.Webinar_Registration_Cancelled_Event_Name))){
                       
                       if(!mapOfRegistrantsData.isEmpty()){
                                                       
                           List<Zoom_Meeting__c> listOfZoomMeeting;
                           if(String.isNotBlank(meetingId)){
                               //False Positive - We have to query meeting details regardless of user's permission.  
                               listOfZoomMeeting = [SELECT Id, Name, Status__c
                                                    FROM Zoom_Meeting__c 
                                                    WHERE Name = : String.escapeSingleQuotes(meetingId) 
                                                    ORDER BY CREATEDDATE DESC LIMIT 1];
                               
                           }
                           
                           List<Event> listOfEventRecordsToUpdate = FindListOfEventsToTrackAttendance(listOfZoomMeeting[0].Id);
                           // Asumption here is the response will corresponds to one meeting attendance and will have same parent recordId for all Attendees.
                           UpdateEventAndCorrespondingChildRecords(listOfEventRecordsToUpdate, mapOfRegistrantsId, Label.Meeting_Cancelled_Value);
                          
                       }
                }
            }
        }Catch(Exception ex){
            System.debug('SF Zoom Service To Update Participants Details - Update Meeting Participant Details - Exception: ' + ex.getMessage());
        }
    }
        
    /******************************************************************************************************************
        Method Name  : getMeetingParticipantDetails
        Description  : It calls the Zoom API and get all the participant details based on the meeting UUID.
        Parameter1   : listOfMeetingInfo - It holds meeting information
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private static void getMeetingParticipantDetails(List<Zoom_Meeting__c> listOfMeetingInfo){
        try{
            if(!listOfMeetingInfo.isEmpty()){
                String meetingId = listOfMeetingInfo[0].Name;
                String eventType = listOfMeetingInfo[0].Event_Type__c;
                Boolean requireRecordingUrl = listOfMeetingInfo[0].Share_Recording_URL__c;
                Boolean requireThankyouNotification = listOfMeetingInfo[0].Thank_you_notification__c;
                String endPointUrl;
                
                if(String.isNotBlank(meetingId) && String.isNotBlank(eventType)){
                    if(eventType.equalsIgnoreCase(Label.Meeting_Record_Type_Name)){
                        endPointUrl = Label.Get_Participant_Details_From_Zoom_API + meetingID + '/participants';
                    }else{
                        endPointUrl = Label.Zoom_Base_EndPoint_URL + 'report/webinars/'+ meetingID + '/participants';
                    }
                    HttpRequest req = SFZoom_MeetingManagerUtility.constructHttpRequestHeader('GET', endPointUrl); 
                    Http http = new Http();
                    HTTPResponse response = new HTTPResponse();
                    if(!Test.isRunningTest()){
                        response = http.send(req);
                    }else{
                        String responseBody = '{"page_count":"1","page_size":"1","total_records":"2","next_page_token":"","participants": [{"id":"P_MG9VXuSECtK3FTvI2DPQ","name":"Ghanshyam Kumar"}, {"id":"Qi79NR8_TXqkvj4uV5GBzg","name":"Shrav Malkani"}]}';
                        response.setBody(responseBody);
                        response.setStatusCode(200);
                    }
                    if(!listOfMeetingInfo.isEmpty()){
                        listOfMeetingInfo[0].Meeting_Participant_Details__c = response.getBody();
                    }
                    if(response.getStatusCode() == 200 && String.isNotBlank(response.getBody())){
                        Map<String, String> mapOfParticipantsIdAndName = FindParticipantsIdWithName(response.getBody());
                                                
                        if(!mapOfParticipantsIdAndName.isEmpty()){
                            List<Event> listOfEventRecordsToUpdate = FindListOfEventsToTrackAttendance(listOfMeetingInfo[0].Id);
                            
                            //Set meeting recorded url on Meeting Recording URL field
                            if(requireRecordingUrl){
                                setMeetingUrlForAttendees(listOfMeetingInfo);
                            }

                             // Asumption here is the response will corresponds to one meeting attendance and will have same parent recordId for all Attendees.
                             UpdateEventAndCorrespondingChildRecords(listOfEventRecordsToUpdate, mapOfParticipantsIdAndName, Label.Meeting_Attended_Value);

                             //Send email notification to attendees                             
                             if(requireThankyouNotification){
                                 sendEmailNotificationToAttendees(listOfEventRecordsToUpdate, listOfMeetingInfo);
                             }
                           
                        }
                    }
                    
                }
            }
        }Catch(Exception ex){
            System.debug('SF Zoom Service To Update Participants Details - Get Meeting Participant Details - Exception: ' + ex.getMessage() +' >>>>>>' + ex.getStackTraceString());
        }
    }

    /******************************************************************************************************************
        Method Name  : getMapChildandWho
        Description  : It finds map of Who id (ContactID) and its corresponding Child record ID
        Parameter1   : lstChildRecords List of child object records for the ParentRecordID
        currentzoomSetting   : currentzoomSetting Zoom Setting correspomding to parent record ID
        Date         : 28 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/

    public static Map<string,string> getMapChildandWho(List<SObject> lstChildRecords,Zoom_Metadata__mdt currentzoomSetting)
    {
        Map<string, string> mapChildIdAndWho = new Map<string, string>();
        if(lstChildRecords != null && !lstChildRecords.isEmpty())
        {
            for(sobject sobj : lstChildRecords)
            {
                mapChildIdAndWho.put( string.valueof(sobj.get(currentzoomSetting.Contact_Lookup_Field__c)), string.valueof(sobj.get('Id')));
            }
        }
        return mapChildIdAndWho;
    }
    
    public static void UpdateEventAndCorrespondingChildRecords(List<Event> listOfEventRecordsToUpdate, Map<String, String> mapOfParticipantsIdAndName, String strUpdateStatusTo){

        String parentObjectName = String.valueOf(listOfEventRecordsToUpdate[0].WhatId.getSObjectType());
        String zoomRegistrationId;
        List<SObject> lstChildRecords = new List<SObject> ();
        List<SObject> lstUpdateChildRecords = new List<SObject>();
        Map<string, string> mapChildIdAndWho = new Map<string, string>();
        Map<ID, SObject> mapChildRecords = new Map<Id, SObject>();

        List<Zoom_Metadata__mdt> lstzoomSetting = SFZoom_MeetingHandlerExtension.getMetadataDetails(parentObjectName);
        Set<Id> setOfAttendees = new Set<Id>();
        for(Event eventVar : listOfEventRecordsToUpdate){
           setOfAttendees.add(eventVar.whoId);           
        }
         //False Positive - We have to query lead details regardless of user's permission.
        List<Lead> LeadEmails = [SELECT Id, Email,Name from Lead WHERE ID IN : setOfAttendees];
        String inClause = String.format( '(\'\'{0}\'\')', new List<String> { String.join( new List<Id>(setOfAttendees) , '\',\'') });
        String contactQuery = 'SELECT ID, FirstName, LastName, Name, Email FROM Contact WHERE ID IN '+inClause;
       	
        //False Positive - We have to query contact details regardless of user's permission.
        List<Contact> ContactEmails = (List<Contact>)SFZoom_HandleEventOperation.FetchRecordsWithoutAccessCheck(contactQuery);
        
        Map<String,String> mapOfAttendeeIdWithEmail = new Map<String,String>();
       
        
        for(Contact contactToAdd : ContactEmails ){
            mapOfAttendeeIdWithEmail.put(contactToAdd.Id, contactToAdd.Email);            
        }
        for(Lead leadToAdd : LeadEmails){
            mapOfAttendeeIdWithEmail.put(leadToAdd.Id, leadToAdd.Email);            
        }        
        if(lstzoomSetting != null && !lstzoomSetting.isEmpty())
        {            
            if(lstzoomSetting[0].Attendance_Status_Field_Api_Name__c != null){
                lstChildRecords = ZoomUtils.extractChildEntries(listOfEventRecordsToUpdate[0].WhatId,lstzoomSetting[0]);
                mapChildRecords.putAll(lstChildRecords); 
                mapChildIdAndWho = getMapChildandWho(lstChildRecords, lstzoomSetting[0]);
            }
     
            if(strUpdateStatusTo == Label.Meeting_Cancelled_Value && mapOfParticipantsIdAndName!= null && mapOfParticipantsIdAndName.size()>0){
                zoomRegistrationId = String.valueOf(mapOfParticipantsIdAndName.get('id'));
            }

            if(listOfEventRecordsToUpdate != null && !listOfEventRecordsToUpdate.isEmpty()){
                for(Event eventToUpdate : listOfEventRecordsToUpdate){                    
                    // Update Event Record
                    if(strUpdateStatusTo == Label.Meeting_Attended_Value){
                        if(mapOfParticipantsIdAndName.containsKey(eventToUpdate.Zoom_Registration_Id__c)){
                            eventToUpdate.Zoom_Meeting_Attendance__c = strUpdateStatusTo; //Label.Meeting_Attended_Value;
                        }else if(mapOfAttendeeIdWithEmail != null && mapOfAttendeeIdWithEmail.size()>0 && mapOfParticipantsIdAndName.containsKey(mapOfAttendeeIdWithEmail.get(eventToUpdate.whoId))){
                            eventToUpdate.Zoom_Meeting_Attendance__c = strUpdateStatusTo; //Label.Meeting_Attended_Value;
                        }
                    }else if(strUpdateStatusTo == Label.Meeting_Cancelled_Value){
                        if(zoomRegistrationId==eventToUpdate.Zoom_Registration_Id__c){
                            eventToUpdate.Zoom_Meeting_Attendance__c = strUpdateStatusTo;
                        }
                    }
                    // Update Corresponding child record.
                    if(mapChildIdAndWho!= null && mapChildIdAndWho.size() >0 && mapChildIdAndWho.containsKey(eventToUpdate.WhoId))
                    {
                        if(mapOfParticipantsIdAndName.containsKey(eventToUpdate.Zoom_Registration_Id__c) 
                           || zoomRegistrationId==eventToUpdate.Zoom_Registration_Id__c
                           || mapOfParticipantsIdAndName.containsKey(mapOfAttendeeIdWithEmail.get(eventToUpdate.whoid))){
                            sobject sobj =  mapChildRecords.get(mapChildIdAndWho.get(eventToUpdate.WhoId)); 
                            sobj.put(lstzoomSetting[0].Attendance_Status_Field_Api_Name__c,strUpdateStatusTo);
                            lstUpdateChildRecords.add(sobj);  
                        }
                                              
                    }
                }
                // False Positive - We have to update Event status regardless of user's permission.
                SFZoom_HandleEventOperation.UpdateEventAttendeeStatus(listOfEventRecordsToUpdate);
                // False Positive - We have to update corresponding Atendee Status details regardless of user's permission.
                if(lstUpdateChildRecords != null && lstUpdateChildRecords.size() >0){
                    UPDATE lstUpdateChildRecords;
                }                
            }

        }

    }
    /******************************************************************************************************************
        Method Name  : FindParticipantsIdWithName
        Description  : It finds participants Details with the id and name
        Parameter1   : response - It contains the response which we got from the API
        Date         : 28 Nov 2018.
        Author       : DataColada Pty Ltd    
    *******************************************************************************************************************/
    private static Map<String, String> FindParticipantsIdWithName(String response){
        Map<String,object> mapOfResponse = (Map<String,object>) JSON.deserializeUntyped(response);
        List<object> listOfParticipantDetails = (List<object>)mapOfResponse.get('participants');
        Map<String, String> mapOfParticipantsIdAndName = new Map<String, String>();
        if(listOfParticipantDetails != null && !listOfParticipantDetails.isEmpty()){
            for(Object participantDetail : listOfParticipantDetails){
                Map<String,object> mapOfParticipantDetails = (Map<String,object>) JSON.deserializeUntyped(JSON.serialize(participantDetail));
                String participantId = String.valueOf(mapOfParticipantDetails.get('id'));
                String participantEmail = String.valueOf(mapOfParticipantDetails.get('user_email'));
                if(String.isNotBlank(participantId)){
                    mapOfParticipantsIdAndName.put(participantId, String.valueOf(mapOfParticipantDetails.get('name')));
                }
                if(String.isNotBlank(participantEmail)){
                    mapOfParticipantsIdAndName.put(participantEmail, String.valueOf(mapOfParticipantDetails.get('name')));
                }
            }
        }        
        return mapOfParticipantsIdAndName;
    }    
    
    /******************************************************************************************************************
        Method Name  : FindListOfEventsToTrackAttendance
        Description  : It tracks attendance of actual attendee during meeting.
        Parameter1   : sfMeetingRecordId - It contains salesforce meeting record id.
        Date         : 26 Dec 2018.
        Author       : DataColada Pty Ltd    
    *******************************************************************************************************************/
    private static List<Event> FindListOfEventsToTrackAttendance(Id sfMeetingRecordId){
        List<Event> listOfEvents;
        // False Positive - We have to get the event details regardless of user's permission.
        String eventQuery = 'SELECT Zoom_Registration_Status__c, Joining_URL__c,Whoid, '+
                        'Zoom_Registration_Id__c, Zoom_Meeting_Attendance__c, WhatId '+
                        'FROM Event WHERE Zoom_Meeting__c = \'' + String.escapeSingleQuotes(sfMeetingRecordId) +'\'';
        listOfEvents = (List<Event>)SFZoom_HandleEventOperation.FetchRecordsWithoutAccessCheck(eventQuery);
        return listOfEvents;
    }
    
     /******************************************************************************************************************
        Method Name  : SendEmailToAttendedInvitees
        Description  : It sends Thank you email to all the attendee member 
        Date         : 04 Mar 2019.
        Parameter1   : List of event records
        Parametet2   : Checkbox value of thank you email
        Author       : DataColada Pty Ltd    
    *******************************************************************************************************************/
    private static String sendEmailNotificationToAttendees( List<Event> listOfEventRecordsToUpdate, List<Zoom_Meeting__c> listOfMeetingInfo){        
        String meetingRecordedUrl;
        String shareSurveyLinkUrl;
        String meetingId;
        String eventType;
        String meetingTopic;
        Boolean requireThankyouNotification;
        Boolean requireSurveyLinkNotification;
        Boolean requireRecordedUrlNotification;

        //If meeting is not empty
        if(!listOfMeetingInfo.isEmpty()){
            meetingRecordedUrl = listOfMeetingInfo[0].Meeting_Recording_URL__c;
            shareSurveyLinkUrl = listOfMeetingInfo[0].Survey_Link_URL__c;
            meetingId = listOfMeetingInfo[0].Name;
            eventType = listOfMeetingInfo[0].Event_Type__c;
            meetingTopic = listOfMeetingInfo[0].Topic__c;
            requireThankyouNotification = listOfMeetingInfo[0].Thank_you_notification__c;
            requireSurveyLinkNotification = listOfMeetingInfo[0].Share_Survey_Link__c;
            requireRecordedUrlNotification = listOfMeetingInfo[0].Share_Recording_URL__c;
        }
        
        Set<Id> setOfAttendees = new Set<Id>();
        
        for(Event eventVar : listOfEventRecordsToUpdate){
            if('Event'.equalsIgnoreCase(String.valueOf(eventVar.whoId))){
                setOfAttendees.add(eventVar.whoId);
            }else{
                setOfAttendees.add(eventVar.whoId);
            }
        }
        //False Positive - We have to query lead details regardless of user's permission.
        List<Lead> LeadEmails = [SELECT Id, Email,Name from Lead WHERE ID IN : setOfAttendees];
        String inClause = String.format( '(\'\'{0}\'\')', new List<String> { String.join( new List<Id>(setOfAttendees) , '\',\'') });
        String contactQuery = 'SELECT FirstName, LastName, Name, Email FROM Contact WHERE ID IN '+inClause;
       	
        //False Positive - We have to query contact details regardless of user's permission.
        List<Contact> ContactEmails = (List<Contact>)SFZoom_HandleEventOperation.FetchRecordsWithoutAccessCheck(contactQuery);
        

        Map<String,String> mapOfAttendeeIdWithEmail = new Map<String,String>();
        Map<String,String> mapOfAttendeeIdWithName = new Map<String,String>();
        
        for(Contact contactToAdd : ContactEmails ){
            mapOfAttendeeIdWithEmail.put(contactToAdd.Id, contactToAdd.Email);
            mapOfAttendeeIdWithName.put(contactToAdd.Id, contactToAdd.Name);
        }
        for(Lead leadToAdd : LeadEmails){
            mapOfAttendeeIdWithEmail.put(leadToAdd.Id, leadToAdd.Email);
            mapOfAttendeeIdWithName.put(leadToAdd.id, leadToAdd.Name);
        }

        String errorMessage;
        String emailSenderName;
        String mailBody;
        /*String userName = UserInfo.getUserName();
        User activeUser = [SELECT Email FROM User WHERE Username = : userName LIMIT 1];
        String userEmail = activeUser.Email;*/
        String userEmail = UserInfo.getUserEmail();
        List<EmailTemplate> emailTemplateToSend;

        try{
            //False Positive - We have to query template details regardless of user's permission.
            emailTemplateToSend = [SELECT htmlValue FROM EmailTemplate 
                                   WHERE developername = :Label.Attendee_Email_Notification_Template LIMIT 1];

            If(!emailTemplateToSend.isEmpty()){
                mailBody = emailTemplateToSend[0].htmlValue;
            }

            for(Event attendee : listOfEventRecordsToUpdate){
                String attendeeName = mapOfAttendeeIdWithName.get(attendee.whoId);
                String attendeeEmailId = mapOfAttendeeIdWithEmail.get(attendee.whoId);         

                if(String.isBlank(mailBody)){
                    mailBody = 'Hello '+attendeeName ;
                }
                else{
                    if(requireThankyouNotification){
                        if(String.isNotBlank(mailBody) && mailBody.containsIgnoreCase(Label.Attendee_Name)){
                            mailBody = mailBody.replace(Label.Attendee_Name, attendeeName);
                        }
                    }
                    mailBody = mailBody.replace(Label.Meeting_Name, String.format(Label.Meeting_Name, new List<String>{meetingId}));
                    mailBody = mailBody.replace(Label.Event_Type, String.format(Label.Event_Type, new List<String>{eventType}));
                    mailBody = mailBody.replace(Label.Event_Topic, String.format(Label.Event_Topic, new List<String>{meetingTopic}));
                    
                    if(requireRecordedUrlNotification && String.isNotBlank(meetingRecordedUrl)){
                           mailBody = mailBody.replace(Label.Recording_Url_Details, String.format(Label.Recording_Url_Details, new List<String>{meetingRecordedUrl}));
                    }else{
                           mailBody = mailBody.replace(Label.Recording_Url_Details,String.format('', new List<String>{''})); 
                    }
                    
                    if(requireSurveyLinkNotification && String.isNotBlank(shareSurveyLinkUrl)){
                           mailBody = mailBody.replace(Label.Survey_Link_Url_Details,String.format(Label.Survey_Link_Url_Details, new List<String>{shareSurveyLinkUrl})); 
                    }else{
                           mailBody = mailBody.replace(Label.Survey_Link_Url_Details,String.format('', new List<String>{''})); 
                    }
                }  
                
                if(String.isNotBlank(attendeeEmailId)){
                   SFZoom_MeetingManagerUtility.sendEmail(new List<String> {attendeeEmailId}, null,mailBody, null, emailSenderName, userEmail,Label.Thank_you_email_subject_label, attendee.whoId, null );
                }
            }
         }Catch(Exception e){
            System.debug('SF Zoom Service To Update Participants Details - Send Thank You Email To Attendees- Exception: ' + e.getMessage());
         }
        return errorMessage;
  }
   
    /******************************************************************************************************************
        Method Name  : setMeetingUrlForAttendees
        Description  : It sets the recording url on Meeting Recording Url field for attendees to sent in email notification
        Date         : 06 Mar 2019.
        Parameter1   : List of event records
        Author       : DataColada Pty Ltd
        *******************************************************************************************************************/
    public static void setMeetingUrlForAttendees(List<Zoom_Meeting__c> listOfMeetingInfo){
      try{
          if(!listOfMeetingInfo.isEmpty()){
              String meetingId = listOfMeetingInfo[0].Name;
              String zoomMeetingId = listOfMeetingInfo[0].Id;
              String endPointUrl;
              
              if(String.isNotBlank(meetingId)){
                  endPointUrl = Label.Zoom_Base_EndPoint_URL + 'meetings/'+ meetingId + '/recordings';
              }
              HttpRequest req = SFZoom_MeetingManagerUtility.constructHttpRequestHeader('GET', endPointUrl); 
              Http http = new Http();
              HTTPResponse response = new HTTPResponse();
              
              if(!Test.isRunningTest()){
                  response = http.send(req);
              }else{
                  response.setStatusCode(200);
              }
              
              if(!listOfMeetingInfo.isEmpty()){
                  String playURL = FindRecordingPlayUrl(response.getBody());                    
                  // False Positive - We have to update meeting details regardless of user's permission.
                  if(string.isNotBlank(playURL)){
                       listOfMeetingInfo[0].Meeting_Recording_URL__c = playURL; 
                       UPDATE listOfMeetingInfo;
                  }
              }
             
          }
      }Catch(Exception ex){
          System.debug('SF Zoom Service To Update Participants Details - set Meeting Url For Attendees - Exception: ' + ex.getMessage());
      }
    }
    
    /******************************************************************************************************************
        Method Name  : FindRecordingPlayUrl
        Description  : It fetches the recorded url from zoom and the recent recorded url link.
        Date         : 08 Mar 2019.
        Parameter1   : Response Body
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String FindRecordingPlayUrl(String responseBody){
        String playURL;
        if(String.isNotBlank(responseBody)){
            Map<String,Object> mapOfResponseData = new Map<String, Object>();
            mapOfResponseData = (Map<String,Object>)JSON.deserializeUntyped(responseBody) ;
            if(!mapOfResponseData.isEmpty()){
                List<Object> listOfRecordings = (List<Object>) mapOfResponseData.get('recording_files'); 
                if(listOfRecordings != null && !listOfRecordings.isEmpty()){
                    playUrl = String.valueOf(((Map<String, Object>)listOfRecordings[listOfRecordings.size()-1]).get('play_url'));
                }                
            }
        }
       return playURL;
    }   
}