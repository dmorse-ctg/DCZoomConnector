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
    Class Name  : SFZoom_MeetingHandlerExtension
    Description : This class is responsible for creating, updating and cancelling the Zoom meeting.
    Date        : 01 Nov 2018.
    Author      : DataColada Pty Ltd
*******************************************************************************************************************/
global with sharing class SFZoom_MeetingHandlerExtension{
    public Zoom_Meeting__c zoomMeeting {get; set;}
    public Boolean isEditEnabled {get; set;}
    public Time meetingStartTime {get; set;}  
    public String eventType {get; set;}
    public List<InviteeDetailsWrapper> listOfInvitedRecordDetails {get; set;}
    public List<InviteeDetailsWrapper> listOfNotInvitedRecordDetails {get; set;}
    public List<InviteeDetailsWrapper> listOfAttendedInvitedRecordDetails {get; set;}
    public Boolean isMeetingCreated {get; set;}
    public Boolean isZoomSettingConfigured {get; set;}
    public Boolean isSelectedAllLeadsAndContacts {get; set;}
    public Boolean isFromLightning;
    
    private Datetime meetingStartDateTime;
    private String updateMeetingId;
    public String sfMeetingId;
    private String objectName;
    private String childObjectName;
    private String setupObjectRecordId;
    private String contactEmailFieldAPIName;
    private String leadEmailFieldAPIName;
    private String zoomMeetingId;
    private Integer minimumMeetingDuration;
    private Integer maximumMeetingDuration;
    private String parentObjectFieldAPIName;
    private List<Zoom_Metadata__mdt> listOfMetaData;
    private Boolean isAnyContactOrLeadSelected;
    private String emailSenderName;

    private Id eventRecordTypeId;
    private String retURL;
    private String meetingIdToDelete;
    private Boolean isWebinar;
    
    public SFZoom_MeetingHandlerExtension(){}
    
    // constructor for handling lightning component operations
    public SFZoom_MeetingHandlerExtension(Id sfMeetingId, Id parentId, Boolean inviteAttendees){
        try{
            
            if(sfMeetingId != null){
                this.sfMeetingId = sfMeetingId;
                isFromLightning = false;
            }
              
           // if(inviteAttendees){
                zoomMeeting = new Zoom_Meeting__c();
                isSelectedAllLeadsAndContacts = true;
                listOfNotInvitedRecordDetails = new List<InviteeDetailsWrapper>();
                isAnyContactOrLeadSelected = false;
                objectName = String.valueOf(Id.valueOf(parentId).getSObjectType());
                listOfMetaData = getMetadataDetails(objectName);
                if(listOfMetaData != null && !listOfMetaData.isEmpty()){
                    parentObjectFieldAPIName = listOfMetaData[0].Lookup_Field_API_Name__c;
             //   }
                
                if(sfMeetingId != null){
                    EditMeetingDetails(parentObjectFieldAPIName);
                }
                if(parentId != null){                
                    setupObjectRecordId = parentId;
                }
                LoadExistingConfiguration();
            } 
        }Catch(Exception ex){
            System.debug('SFZoom_MeetingHandlerExtension - Lightning Constructor - Exception: ' + ex.getMessage());
        }        
    } 
    
    // Constructor for extenstion controller to get record and object details
    public SFZoom_MeetingHandlerExtension(ApexPages.StandardController stdController){
            
        try{
            zoomMeeting = new Zoom_Meeting__c();
            isSelectedAllLeadsAndContacts = true;
            listOfInvitedRecordDetails = new List<InviteeDetailsWrapper>();
            listOfNotInvitedRecordDetails = new List<InviteeDetailsWrapper>();
            listOfAttendedInvitedRecordDetails = new List<InviteeDetailsWrapper>();
            
            isFromLightning = false;
            isMeetingCreated = false;
            isEditEnabled = false;
            isAnyContactOrLeadSelected = false;
            meetingStartTime = System.now().time();
            Zoom_Meeting__c zoomSetting = LoadExistingConfiguration();
            if(zoomSetting == null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Zoom_Setting_Not_Configured_Error_Message));
                isZoomSettingConfigured = false;
            }else{
                isZoomSettingConfigured = true;

                sfMeetingId = stdController.getRecord().Id;
                SObject recordDetails = stdController.getRecord();
                String recordDetailsJson = JSON.serialize(recordDetails);
                Map<String, Object> mapOfRecordDetails = (Map<String, Object>)JSON.deserializeUntyped(recordDetailsJson);
                for(String fieldName : mapOfRecordDetails.keySet()){
                    if(fieldName.equalsIgnoreCase('Name')){
                        setupObjectRecordId = sfMeetingId;
                        sfMeetingId = null;                    
                    } else if(fieldName.containsIgnoreCase('__c')){
                        setupObjectRecordId = (String)mapOfRecordDetails.get(fieldName);
                    } else if(fieldName.containsIgnoreCase('RecordTypeId')){
                        eventRecordTypeId = (String)mapOfRecordDetails.get(fieldName);
                    }
                }

                if(String.isNotBlank(setupObjectRecordId)){                    
                    objectName = String.valueOf(Id.valueOf(setupObjectRecordId).getSObjectType());                    
                    listOfMetaData = getMetadataDetails(objectName);                    
                    if(listOfMetaData != null && !listOfMetaData.isEmpty()){
                        parentObjectFieldAPIName = listOfMetaData[0].Lookup_Field_API_Name__c;
                    }   
                    listOfNotInvitedRecordDetails = FindListOfContactOrLeadFromChildRecords(setupObjectRecordId);
                }
                
                FindEventType(eventRecordTypeId);
                retURL = apexpages.currentpage().getparameters().get('retURL');
                meetingIdToDelete = apexpages.currentpage().getparameters().get('delID');
                
                if(String.isBlank(meetingIdToDelete) && String.isNotBlank(sfMeetingId)){
                    EditMeetingDetails(parentObjectFieldAPIName);
                    Map<String, Object> mapOfAttendeeDetails = FindInvitationDetails(setupObjectRecordId, sfMeetingId);
                    if(!mapOfAttendeeDetails.isEmpty()){
                        listOfInvitedRecordDetails = (List<InviteeDetailsWrapper>) mapOfAttendeeDetails.get('attendees');
                        listOfAttendedInvitedRecordDetails = (List<InviteeDetailsWrapper>) mapOfAttendeeDetails.get('attended');
                        listOfNotInvitedRecordDetails = (List<InviteeDetailsWrapper>) mapOfAttendeeDetails.get('newAttendees');
                    }
                }
            }
        }Catch(Exception ex){
            System.debug('SFZoom_MeetingHandlerExtension - Constructor - Exception: ' + ex.getMessage());
        }
    }
    
    /******************************************************************************************************************
        Method Name  : sendThankYouEmail
        Description  : It sends thank you email notification to all the attendee.
        Date         : 18 Mar 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
     public pageReference sendThankYouEmail(){
         try{
             
             if(isFromLightning){
                 List<String> listOfZoomMeetingFields = new List<String>{'Name', 'Agenda__c', 'Duration__c', 
                'Enforce_Login__c', 'Join_before_Host__c', 'Auto_Register__c', 
                'Start_Date__c', 'Start_Time__c', 'Time_Zone__c', 'Topic__c',
                'Start_Participant_Video_on_Meeting_Join__c', 'Meeting_URL__c', 'RecordTypeId',
                'HD_Video__c', 'Panelist_Video__c', 'Allow_Multiple_Devices__c',
                'Host_Video__c','Thank_you_notification__c', 'Share_Recording_URL__c',
                'Share_Survey_Link__c','Survey_Link_URL__c','Meeting_Recording_URL__c'};
                
                if(SFZoom_AccessUtil.hasReadAccess(String.escapeSingleQuotes(sfMeetingId)) 
                    && SFZoom_AccessUtil.objectIsAccessible('Zoom_Meeting__c') 
                    && SFZoom_AccessUtil.objectIsQueryable('Zoom_Meeting__c') 
                    && SFZoom_AccessUtil.fieldsAreAccessible('Zoom_Meeting__c', listOfZoomMeetingFields)){
                    
                    String query = 'SELECT Name, Agenda__c, Duration__c,Meeting_Recording_URL__c,Survey_Link_URL__c, ';
                    query += 'Enforce_Login__c, Join_before_Host__c, Host_Video__c,Thank_you_notification__c,';
                    query += 'Start_Date__c, Start_Time__c, Time_Zone__c, Topic__c,Share_Survey_Link__c, ';
                    query += 'RecordTypeId, HD_Video__c, Panelist_Video__c, Allow_Multiple_Devices__c,Share_Recording_URL__c, ';
                    query += 'Start_Participant_Video_on_Meeting_Join__c, Meeting_URL__c, Auto_Register__c ';
                    query += ' FROM Zoom_Meeting__c WHERE ID = \''+String.escapeSingleQuotes(sfMeetingId)+'\'  LIMIT 1';
                                        
                    List<Zoom_Meeting__c> listOfMeetingToEdit = Database.query(query);
                    if(!listOfMeetingToEdit.isEmpty()){
                        zoomMeeting = listOfMeetingToEdit[0];
                    }
               }
             }
             
             if(zoomMeeting.Thank_you_notification__c){
                 String playUrl;
                 String inviteeListNotReceivedEmail;
                 String mailSentVerificationMsg;
                 String emailLimitErrorMsg = Label.SINGLE_EMAIL_LIMIT_EXCEEDED_Error_Message + Label.Email_Error_Header_Msg;
                 HTTPResponse recordingResponse;                 
                 
                 playUrl = zoomMeeting.Meeting_Recording_URL__c;
                 
                 if(String.isBlank(playUrl)){
                    recordingResponse = SFZoom_MeetingManagerUtility.getMeetingRecordingDetails(zoomMeeting.Name);
                    String responseDetails = recordingResponse.getBody();
                    if(String.isNotBlank(responseDetails)){
                        playURL = SFZoomServiceToUpdateParticipantsDetails.FindRecordingPlayUrl(responseDetails);
                    } 
                 }                 
                 
                 if(listOfAttendedInvitedRecordDetails.isEmpty()){
                         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.No_Attendees));
                         return null;
                 }
                 
                 if((String.isBlank(playURL) && (zoomMeeting.Share_Recording_URL__c))){
                     ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Label.Recording_Not_Received));
                     return null;
                 }else if((String.isBlank(zoomMeeting.Survey_Link_URL__c) && (zoomMeeting.Share_Survey_Link__c))){
                     ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Please_Enter_Survey_Link_Error_Label));
                     return null;
                 }else{
                     String mailBody;
                     /*String userName = UserInfo.getUserName();
                    User activeUser = [SELECT Email FROM User WHERE Username = : userName LIMIT 1];
                    String userEmail = activeUser.Email;*/
                    String userEmail = UserInfo.getUserEmail();
                     List<EmailTemplate> emailTemplateToSendEventNotification;
                     if(SFZoom_AccessUtil.objectIsAccessible('EmailTemplate') 
                        && SFZoom_AccessUtil.objectIsQueryable('EmailTemplate') 
                        && SFZoom_AccessUtil.fieldsAreAccessible('EmailTemplate', new List<String>{'htmlValue'}))
                     {
                         emailTemplateToSendEventNotification = [SELECT htmlValue FROM EmailTemplate 
                                                                 WHERE developername = :Label.Attendee_Email_Notification_Template LIMIT 1];
                     }
                     If(!emailTemplateToSendEventNotification.isEmpty()){
                         mailBody = emailTemplateToSendEventNotification[0].htmlValue;
                     }
                     
                     for(InviteeDetailsWrapper invitee : listOfAttendedInvitedRecordDetails){
                         if(String.isNotBlank(invitee.email)){
                             if(String.isBlank(mailBody)){
                                 mailBody = 'Hello '+invitee.name;
                             }
                             else{                             
                                 if(String.isNotBlank(mailBody) && mailBody.containsIgnoreCase(Label.Attendee_Name)){
                                     mailBody = mailBody.replace(Label.Attendee_Name, invitee.name);
                                 }
                                 
                                 if(zoomMeeting.Share_Recording_URL__c && String.isNotBlank(zoomMeeting.Meeting_Recording_URL__c)){
                                     if(String.isNotBlank(mailBody)){
                                     mailBody = mailBody.replace(Label.Recording_Url_Details, String.format(Label.Recording_Url_Details, new List<String>{zoomMeeting.Meeting_Recording_URL__c}));
                                   }
                                 }else{
                                       mailBody = mailBody.replace(Label.Recording_Url_Details,String.format('', new List<String>{''})); 
                                 }
                                 
                                 if(zoomMeeting.Share_Survey_Link__c && String.isNotBlank(zoomMeeting.Survey_Link_URL__c)){
                                     if(String.isNotBlank(mailBody)){
                                       mailBody = mailBody.replace(Label.Survey_Link_Url_Details,String.format(Label.Survey_Link_Url_Details, new List<String>{zoomMeeting.Survey_Link_URL__c})); 
                                     }
                                 }else{
                                       mailBody = mailBody.replace(Label.Survey_Link_Url_Details,String.format('', new List<String>{''})); 
                                 }
                                 
                                 mailSentVerificationMsg = SFZoom_MeetingManagerUtility.sendEmail(new List<String>{invitee.email}, null,
                                                                                                         mailBody, null, emailSenderName, userEmail, 
                                                                                                         Label.Thank_you_email_subject_label, 
                                                                                                         invitee.RecordId, null );
                                 if(!String.isBlank(mailSentVerificationMsg) && mailSentVerificationMsg.containsIgnoreCase('SINGLE_EMAIL_LIMIT_EXCEEDED')){
                                     String recordLink = '<a href="/'+invitee.RecordId+'" target="_blank">'+invitee.name+'</a>';
                                     inviteeListNotReceivedEmail = String.isBlank(inviteeListNotReceivedEmail) ? recordLink : (inviteeListNotReceivedEmail + recordLink);
                                 }
                             }
                         }
                     }
                 }

                 zoomMeeting.Meeting_Recording_URL__c = playUrl;
                 if(SFZoom_AccessUtil.fieldsAreUpdateable('Zoom_Meeting__c', new List<String> {'Meeting_Recording_URL__c'}) &&
                    SFZoom_AccessUtil.hasEditAccess(zoomMeeting.Id))
                 {
                     UPDATE zoomMeeting;
                 }
                 
                 if(!String.isBlank(mailSentVerificationMsg)){
                     ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, emailLimitErrorMsg + '<br/><br/>'+ inviteeListNotReceivedEmail));
                 }else {
                     String pageIdToReturn = String.isNotBlank(setupObjectRecordId) ? setupObjectRecordId : sfMeetingId;
                     return String.isNotBlank(retURL) ? new PageReference(retURL) : new PageReference('/'+pageIdToReturn);
                 }
             }else{
                     ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Disabled_Thank_You_Email_Setting_Message));                                
             }
           
         }Catch(Exception ex){
             System.debug('SF Zoom Meeting Handler Extension - send Thank You Email - Exception: ' + ex.getMessage());
         }
        return null;
    }
    
    /******************************************************************************************************************
        Method Name  : resetThankYouSetting
        Description  : It resets share survey link and share recording url checkboxes if thank you notification checkbox made unchecked 
        Date         : 12 Mar 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
     public pageReference resetThankYouSetting(){
        if(!zoomMeeting.Thank_you_notification__c){
            zoomMeeting.Share_Survey_Link__c = false;
            zoomMeeting.Share_Recording_URL__c = false;
        }
        return null;
    }

    /******************************************************************************************************************
        Method Name  : VerifyDeleteOperation
        Description  : It verifies whether user clicked on delete button of the standard UI page
        Date         : 24 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference VerifyDeleteOperation(){
        try{
            if(String.isNotBlank(meetingIdToDelete) && 
                (meetingIdToDelete.contains(SFMeetingId) || SFMeetingId.contains(meetingIdToDelete))){
                if(eventType.equalsIgnoreCase(Label.Webinar_Record_Type_Name)){
                    CancelMeetingOrWebinar(SFMeetingId, true);
                }else{
                    CancelMeetingOrWebinar(SFMeetingId, false);
                }
                
                return String.isNotBlank(retURL) ? new PageReference(retURL) : null;
            }
        }Catch(Exception ex){
            System.debug('SFZoom Meeting Handler Extension - Verify Delete Operation - Exception: ' + ex.getMessage());
        }
        return null;
    }

    /******************************************************************************************************************
        Method Name  : isValidEventDetail
        Description  : It validates the meeting/webinar field information
        Date         : 24 Dec 2018.
        Parameter1   : isClassic - It tells whehter this method is called from classic or lightning.
                        if it contains true means it is called from classic otherwise lightning
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private String isValidEventDetail(Boolean isClassic){
        String errorMessage;
        if(String.isBlank(zoomMeeting.Topic__c) || zoomMeeting.Start_Date__c == null || zoomMeeting.Duration__c == null ){
            errorMessage = Label.Blank_Field_on_Meeting_Form_Error_Message;
            if(isClassic){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errorMessage));
            }
            return errorMessage;
        } 
        else if(meetingStartTime == null){
            errorMessage = Label.Meeting_Start_Time_Error_Message;
            if(isClassic){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errorMessage));
            }
            return errorMessage;
        } 
        minimumMeetingDuration = minimumMeetingDuration != null ? minimumMeetingDuration : Integer.valueOf(Label.Minimum_Meeting_Duration);
        maximumMeetingDuration = maximumMeetingDuration != null ? maximumMeetingDuration : Integer.valueOf(Label.Maximum_Meeting_Duration);
        
        Final String Meeting_Duration_Error_Message = eventType.capitalize()+' duration should be minimum of '+minimumMeetingDuration+' and maximum of '+maximumMeetingDuration + ' minutes';
        if(zoomMeeting.Duration__c != null && (Integer.valueOf(zoomMeeting.Duration__c) < minimumMeetingDuration || Integer.valueOf(zoomMeeting.Duration__c) > maximumMeetingDuration)){
            if(isClassic)
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Meeting_Duration_Error_Message));
            return Meeting_Duration_Error_Message;
        }
        
        if(zoomMeeting.Start_Date__c < Date.today()){
            Final String dateErrorMessage = eventType.capitalize()+' '+Label.Event_Start_Time_Error_Message;
            if(isClassic){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, dateErrorMessage));
            }
            return dateErrorMessage; 
        }
        return null;
    }

    /******************************************************************************************************************
        Method Name  : FindEventType
        Description  : It find event type (Meeting/Webinar) based on the recordtypeid passed
        Date         : 24 Dec 2018.
        Parameter1   : recordTypeId - It contains zoom meeting event record type id to identify record type
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private void FindEventType(String recordTypeId){
        if(String.isNotBlank(recordTypeId)){
            String MeetingRecordTypeId = Schema.SObjectType.Zoom_Meeting__c.getRecordTypeInfosByName().get(Label.Meeting_Record_Type_Name).getRecordTypeId();
            if(recordTypeId.containsIgnoreCase(MeetingRecordTypeId) || MeetingRecordTypeId.containsIgnoreCase(recordTypeId)){
                eventType = Label.Meeting_Record_Type_Name;
                isWebinar = false;
            }else{
                String webinarRecordTypeId = Schema.SObjectType.Zoom_Meeting__c.getRecordTypeInfosByName().get(Label.Webinar_Record_Type_Name).getRecordTypeId();
                if(recordTypeId.containsIgnoreCase(webinarRecordTypeId) || webinarRecordTypeId.containsIgnoreCase(recordTypeId)){
                    eventType = Label.Webinar_Record_Type_Name;
                    isWebinar = true;
                 }
            }
        }
    }

    /******************************************************************************************************************
        Method Name  : SelectAllInvitees
        Description  : It selects all invitee after selecting the Invite All Contacts/Leads checkbox.
        Date         : 24 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public void SelectAllInvitees(){
        try{
            for (InviteeDetailsWrapper inviteeDetails : listOfNotInvitedRecordDetails) {
                inviteeDetails.isSelected = true;   
            }          
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Handler Extension - Select All Invitees - Exception: ' + ex.getMessage());
        }        
    }
    
    /******************************************************************************************************************
        Method Name  : CreateWebinar
        Description  : It creates webinar in the Salesforce and Zoom Org based on the user input.
        Date         : 24 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference CreateWebinar(){
        String returnMessage;
        try{
            returnMessage = CreateMeetingOrWebinar(true, true);
            if(String.isNotBlank(returnMessage) && !(returnMessage instanceof Id)){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, returnMessage));
            }
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Handler Extension - Create Webinar - Exception: ' + ex.getMessage());
        }
        return null; 
    }
    
    /******************************************************************************************************************
        Method Name  : CreateMeetingClassic
        Description  : It creates meeting in zoom and called from the classic user interface
        Date         : 24 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference CreateMeetingClassic(){
        String returnMessage;
        try{
            returnMessage = CreateMeetingOrWebinar(true, false);
            if(String.isNotBlank(returnMessage) && !(returnMessage instanceof Id)){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, returnMessage));
            }
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Handler Extension - Create Meeting Classic - Exception: ' + ex.getMessage());
        }
        return null; 
    }
    
    /******************************************************************************************************************
        Method Name  : CreateMeetingLightning
        Description  : It creates meeting in zoom and called from the lightning component class
        Date         : 24 Dec 2018.
        Parameter1   : isWebinar - Tells whether method is called to create webinar
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public String CreateMeetingLightning(Boolean isWebinar){
        try{
            return CreateMeetingOrWebinar(false, isWebinar);
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Handler Extension - Create Meeting Lightning - Exception: ' + ex.getMessage());
        }
        return null;
    }
    
    /******************************************************************************************************************
        Method Name  : CreateMeeting
        Description  : It creates meeting/webinar in the Salesforce and Zoom Org based on the user input.
        Date         : 01 Nov 2018.
        Parameter1   : isClassic - Tells whether method is called from classic UI
        Parameter2   : isWebinar - Tells whether method is called to create webinar
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private String CreateMeetingOrWebinar(Boolean isClassic, Boolean isWebinar){
        try{
            String errorMessage = isValidEventDetail(isClassic);
            if(String.isBlank(errorMessage)){
                String response;
                String webinarStartURL;
                if(!isWebinar){
                    String meetingDetails = JSON.serialize(BindMeetingDetails());
                    response = SFZoom_MeetingManagerUtility.CreateMeetingInZoomAccount(meetingDetails);
                }else{
                    String webinarDetails = JSON.serialize(BindZoomWebinarDetails());
                    response = SFZoom_MeetingManagerUtility.CreateWebinarInZoomAccount(webinarDetails);
                }
                
                listOfMetaData = getMetadataDetails(objectName);
                String fieldName;
                String parentId;
                String childRelationshipName;
                String contact_Lookup_FieldName;
                String lead_Lookup_FieldName;
                
                if(listOfMetaData != null && !listOfMetaData.isEmpty()){
                                   
                    fieldName = listOfMetaData[0].Lookup_Field_API_Name__c;
                    parentId = setupObjectRecordId;
                    childRelationshipName = listOfMetaData[0].Child_Relationship_Name__c;
                    contact_Lookup_FieldName = listOfMetaData[0].Contact_Lookup_Field__c;
                    lead_Lookup_FieldName = listOfMetaData[0].Lead_Lookup_Field__c;
                    contactEmailFieldAPIName = listOfMetaData[0].Email_Field_API_Name_of_Contact__c;
                    leadEmailFieldAPIName = listOfMetaData[0].Email_Field_API_Name_of_Lead__c;
                    parentObjectFieldAPIName = listOfMetaData[0].Lookup_Field_API_Name__c;
                }
               
                Map<String,Object> mapOfResponseData = new Map<String, Object>();
                if(String.isNotBlank(response)){
                    mapOfResponseData = (Map<String,Object>)JSON.deserializeUntyped(response) ;
                    String zoomURL = SFZoom_MeetingManagerUtility.FindZoomURLFromCustomSetting();
                    zoomMeeting.Meeting_URL__c = (String)mapOfResponseData.get('join_url');
                    zoomMeeting.Start_URL__c = (String)mapOfResponseData.get('start_url');
                    zoomMeeting.Host_Id__c = (String)mapOfResponseData.get('host_id');
                    zoomMeeting.UUID__c = (String)mapOfResponseData.get('uuid');
                    zoomMeeting.Registration_URL__c = (String)mapOfResponseData.get('registration_url');
                    zoomMeeting.Status__c = Label.Meeting_Created_Status;
                    zoomMeeting.Name = String.valueOf(mapOfResponseData.get('id'));
                    //zoomMeeting.Campaign__c = parentId;
                    zoomMeetingId = zoomMeeting.Name;
                    
                    if(String.isNotBlank(fieldName)){
                        zoomMeeting.put(fieldName, parentId);
                    }
                    List<String> zoomMeetingFieldsToInsert = new List<String>{'Name', 'Agenda__c','Survey_Link_URL__c', 
                        'Duration__c', 'Enforce_Login__c', 'Join_before_Host__c',
                        'Auto_Register__c', 'Start_Date__c', 'Start_Time__c', 
                        'Time_Zone__c', 'Topic__c', 'Start_URL__c', 
                        'Start_Participant_Video_on_Meeting_Join__c', 'Meeting_URL__c', 
                        'RecordTypeId', 'HD_Video__c', 'Panelist_Video__c', 
                        'Allow_Multiple_Devices__c', 'Host_Video__c', 'UUID__c',
                        'Registration_URL__c', 'Status__c', 'Host_Id__c','Thank_you_notification__c',
                        'Share_Survey_Link__c','Share_Recording_URL__c'};
                    
                    List<String> listOfSetupObjectFields = SFZoom_MeetingManagerUtility.FindListOfSetupObjectFeildNameFromZoomMeeting();
                    for(String lookup_FieldName : listOfSetupObjectFields){
                        if(listOfSetupObjectFields.indexOf(lookup_FieldName) != -1){
                            zoomMeetingFieldsToInsert.add(lookup_FieldName);
                        }                        
                    }

                    If(SFZoom_AccessUtil.objectIsCreatable('Zoom_Meeting__c') 
                        && SFZoom_AccessUtil.fieldsAreCreatable('Zoom_Meeting__c', zoomMeetingFieldsToInsert)){
                        if(isWebinar){
                            zoomMeeting.RecordTypeId = Schema.SObjectType.Zoom_Meeting__c.getRecordTypeInfosByName().get(Label.Webinar_Record_Type_Name).getRecordTypeId();
                        }else{
                            zoomMeeting.RecordTypeId = Schema.SObjectType.Zoom_Meeting__c.getRecordTypeInfosByName().get(Label.Meeting_Record_Type_Name).getRecordTypeId();                    
                        }
                        INSERT zoomMeeting;
                        SFMeetingId = zoomMeeting.Id;
                    }
                    isMeetingCreated = true;
                    return zoomMeeting.Id;
                }else{
                    errorMessage = Label.Meeting_Webinar_Creation_Error_Message;
                    return errorMessage;
                }       
                                
            }else{
                return errorMessage;
            }
            
        }catch(Exception ex){
            System.debug('SF Zoom Meeting Handler Extension - Create Meeting Or Webinar - Exception: ' + ex.getMessage());
            return Label.Meeting_Or_Webinar_Creation_Exception_Msg;
        }
    }

    /******************************************************************************************************************
        Method Name  : SendEmailInvite
        Description  : It sends email invite and called from the classic user interface
        Date         : 04 Jan 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference SendEmailInviteClassic(){
        String errorMessage;
        try{
            errorMessage = CreateEventsForSelectedInvitees(isEditEnabled);
            if(!isAnyContactOrLeadSelected){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Select_Attendee_to_Send_Invite_Error_Message));
            }else if(String.isBlank(errorMessage)){
                return (String.isNotBlank(retURL) ? new PageReference(retURL) : null);
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errorMessage));
            }
        }Catch(Exception ex){
            System.debug('SFZoom Meeting Handler Extension - Send Email Invite Classic - Exception: ' + ex.getMessage());
        }
        return null;
    }

    /******************************************************************************************************************
        Method Name  : SendEmailInviteLightning
        Description  : It sends email invite and called from the lightning component class
        Date         : 04 Jan 2018.
        Parameter1   : isUpdate - It tells whether it is called from update meeting form
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public String SendEmailInviteLightning(Boolean isUpdate){
        String errorMessage;
        try{
            errorMessage = CreateEventsForSelectedInvitees(false);
        }Catch(Exception ex){
            System.debug('SFZoom Meeting Handler Extension - Send Email Invite Lightning - Exception: ' + ex.getMessage());
        }
        return errorMessage;
    }

    /******************************************************************************************************************
        Method Name  : CreateEventsAndSendEmailInvite
        Description  : It creates events for all the selected child records and send email invite to them
        Date         : 04 Jan 2018.
        Parameter1   : isUpdate - It tells whether it is called from update meeting form
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private String CreateEventsForSelectedInvitees(Boolean isUpdate){
        String errorMessage;
        List<String> listOfZoomMeetingFields = new List<String>{'Name', 'Agenda__c', 'Duration__c', 
            'Enforce_Login__c', 'Join_before_Host__c', 'Auto_Register__c', 
            'Start_Date__c', 'Start_Time__c', 'Time_Zone__c', 'Topic__c',
            'Start_Participant_Video_on_Meeting_Join__c', 'Meeting_URL__c', 'RecordTypeId',
            'HD_Video__c', 'Panelist_Video__c', 'Allow_Multiple_Devices__c',
            'Host_Video__c','Thank_you_notification__c', 'Share_Recording_URL__c',
            'Meeting_Recording_URL__c','Share_Survey_Link__c','Survey_Link_URL__c'};
            
            if(SFZoom_AccessUtil.hasReadAccess(String.escapeSingleQuotes(SFMeetingId)) 
                && SFZoom_AccessUtil.objectIsAccessible('Zoom_Meeting__c') 
                && SFZoom_AccessUtil.objectIsQueryable('Zoom_Meeting__c') 
                && SFZoom_AccessUtil.fieldsAreAccessible('Zoom_Meeting__c', listOfZoomMeetingFields)){
                
                String query = 'SELECT Name, Agenda__c, Duration__c,Meeting_Recording_URL__c,  ';
                query += 'Enforce_Login__c, Join_before_Host__c, Host_Video__c,Thank_you_notification__c,';
                query += 'Start_Date__c, Start_Time__c, Time_Zone__c, Topic__c,Share_Survey_Link__c, ';
                query += 'RecordTypeId, HD_Video__c, Panelist_Video__c, Allow_Multiple_Devices__c,Share_Recording_URL__c,Survey_Link_URL__c, ';
                query += 'Start_Participant_Video_on_Meeting_Join__c, Meeting_URL__c, Auto_Register__c ';
                query += ' FROM Zoom_Meeting__c WHERE ID = \''+String.escapeSingleQuotes(SFMeetingId)+'\'  LIMIT 1';
                
                
                List<Zoom_Meeting__c> listOfMeetingToEdit = Database.query(query);
                if(!listOfMeetingToEdit.isEmpty()){
                    zoomMeeting = listOfMeetingToEdit[0];
                }
                FindEventType(zoomMeeting.RecordTypeId);
            }

        DateTime startDateTime = DateTime.newInstance(zoomMeeting.Start_Date__c, zoomMeeting.Start_Time__c);
        List<Event> listOfEventsToCreate = new List<Event>();
        Map<Id, Id> mapOfContactOrLeadIdWithChildRecordId = new Map<Id, Id>();
        String strInviteType;
        //string lookupApiName = ZoomUtils.getlookupApiName(objectName,listOfMetaData[0].Child_Relationship_Name__c);
        if(listOfNotInvitedRecordDetails != null && !listOfNotInvitedRecordDetails.isEmpty()){
            for (InviteeDetailsWrapper inviteeDetails : listOfNotInvitedRecordDetails) {
                if(inviteeDetails.isSelected){
                    strInviteType = String.valueOf(Id.valueOf(inviteeDetails.RecordId).getSObjectType());  
                    Event eventToCreateForInvitee = new Event();
                    eventToCreateForInvitee.StartDateTime = startDateTime;
                    eventToCreateForInvitee.EndDateTime = startDateTime.addMinutes(Integer.valueOf(zoomMeeting.Duration__c));
                    eventToCreateForInvitee.Subject = zoomMeeting.Topic__c;
                    eventToCreateForInvitee.Zoom_Meeting__c = zoomMeeting.Id;
                    eventToCreateForInvitee.WhoId = inviteeDetails.RecordId;
                    if(strInviteType == 'Contact'){
                        eventToCreateForInvitee.WhatId = setupObjectRecordId;//ZoomUtils.getWhatId(setupObjectRecordId, inviteeDetails.RecordId,listOfMetaData[0],lookupApiName);
                    }                    
                    eventToCreateForInvitee.Description = zoomMeeting.Meeting_URL__c;
                    eventToCreateForInvitee.Zoom_Registration_Status__c = Label.Invitee_Event_Status_Initiated;
                    listOfEventsToCreate.add(eventToCreateForInvitee);
                }
            }
        }
        
        if(!listOfEventsToCreate.isEmpty() && listOfEventsToCreate.size() <= 50){
            List<String> eventFieldsToInsert = new List<String>{'StartDateTime', 
            'EndDateTime', 'Subject', 'Zoom_Meeting__c', 'WhoId', 'Description', 'Zoom_Registration_Status__c'};
            if(SFZoom_AccessUtil.objectIsCreatable('Event') 
                && SFZoom_AccessUtil.fieldsAreCreatable('Event', eventFieldsToInsert)){
                INSERT listOfEventsToCreate;

                Boolean isWebinar = eventType.equalsIgnoreCase(Label.Webinar_Record_Type_Name) ? true : false;
                errorMessage = SendEmailToSelectedInvitees(isUpdate, isWebinar);
                if(String.isNotBlank(errorMessage) && !listOfEventsToCreate.isEmpty()){
                    if(SFZoom_AccessUtil.hasDeleteAccessMulti(new map<Id, Event>(listOfEventsToCreate).keyset())){
                        SFZoom_AccessUtil.deleteRecordsWithAccessCheck(listOfEventsToCreate, true);
                    }
                }
            }
        }else if(!listOfEventsToCreate.isEmpty() && listOfEventsToCreate.size() > 50){
            errorMessage = Label.Maximum_Number_of_Invitee_Selection_To_Send_Email_Msg;
        }
                 
        return errorMessage;
    }

    /******************************************************************************************************************
        Method Name  : SendEmailToSelectedInvitees
        Description  : It sends email invite to all the member who are selected by the admin
        Date         : 04 Jan 2018.
        Parameter1   : isUpdate - It tells whether it is called from update meeting form
        Parameter2   : isWebinar - It tells whether it is meeting or webinar
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private String SendEmailToSelectedInvitees(Boolean isUpdate, Boolean isWebinar){
        String errorMessage;
        
        String siteURL;
        String dateToSend = SFZoom_MeetingManagerUtility.changeDateFormat(zoomMeeting.Start_Date__c);
        String timeToSend = SFZoom_MeetingManagerUtility.changeTimeFormat(zoomMeeting.Start_Time__c);
        String emailContent = isUpdate ? Label.Email_Invitation_Update_Email_Event_Line_1 : Label.Event_Invitation_Email_Line1;
        String mailBody;
        /*String userName = UserInfo.getUserName();
        User activeUser = [SELECT Email FROM User WHERE Username = : userName LIMIT 1];
        String userEmail = activeUser.Email;*/
        String userEmail = UserInfo.getUserEmail();
        List<EmailTemplate> emailTemplateToSendEventNotification;
        if(SFZoom_AccessUtil.objectIsAccessible('EmailTemplate') 
            && SFZoom_AccessUtil.objectIsQueryable('EmailTemplate') 
            && SFZoom_AccessUtil.fieldsAreAccessible('EmailTemplate', new List<String>{'htmlValue'})
        ){
            emailTemplateToSendEventNotification = [SELECT htmlValue FROM EmailTemplate 
                WHERE developername = :Label.Event_Invitation_Email_Template_Name LIMIT 1];
        }
        If(!emailTemplateToSendEventNotification.isEmpty()){
            mailBody = emailTemplateToSendEventNotification[0].htmlValue;
        }

        Zoom_Configuration_Settings__c zoomConfigurationDetails = Zoom_Configuration_Settings__c.getValues(Label.Config_Details_Custom_Setting_Name);
        If(zoomConfigurationDetails != null){
            if(String.isNotBlank(zoomConfigurationDetails.Site_URL__c)){
                siteURL =  zoomConfigurationDetails.Site_URL__c.endsWith('/') ? zoomConfigurationDetails.Site_URL__c
                                                                    : zoomConfigurationDetails.Site_URL__c + '/';
            }
            emailSenderName = zoomConfigurationDetails.Email_Sender_Name__c;
        }
        String emailLimitErrorMsg = Label.SINGLE_EMAIL_LIMIT_EXCEEDED_Error_Message + Label.Email_Error_Header_Msg;
        String mailSentVerificationMsg;
        String inviteeListNotReceivedEmail;
        isAnyContactOrLeadSelected = false;
        
        for(InviteeDetailsWrapper invitee : listOfNotInvitedRecordDetails){
            String meetingDetails;
            mailBody = emailTemplateToSendEventNotification[0].htmlValue;
            if(invitee.isSelected){
                isAnyContactOrLeadSelected = true;
                if(!zoomMeeting.Auto_Register__c && String.isBlank(mailSentVerificationMsg)){
                    meetingDetails = ' Type: '+(isWebinar ? Label.Webinar_Record_Type_Name : Label.Meeting_Record_Type_Name) + 
                        ' Topic: '+ zoomMeeting.Topic__c + '<br/> Start Date: '+dateToSend + 
                        '<br/> Start Time: '+timeToSend +'<br/> Duration: '+zoomMeeting.Duration__c + ' Minutes' +
                        '<br/> Agenda: '+(String.isNotBlank(zoomMeeting.Agenda__c) ? zoomMeeting.Agenda__c : '' );
                    if(String.isBlank(mailBody)){
                        mailBody = 'Hello '+invitee.LastName+ emailContent + meetingDetails;
                    }
                    else{
                        if(String.isNotBlank(mailBody) && mailBody.containsIgnoreCase(Label.Invitee_Name)){
                            mailBody = mailBody.replace(Label.Invitee_Name, invitee.lastName);
                        }
                        if(String.isNotBlank(mailBody) && mailBody.containsIgnoreCase(Label.Meeting_or_Webinar_Details)){
                            mailBody = mailBody.replace(Label.Meeting_or_Webinar_Details, meetingDetails);
                        }                                                               
                    }

                    if(!zoomMeeting.Auto_Register__c){
                        String encryptedId = SFZoom_MeetingManagerUtility.EncryptData(invitee.childRecordId);
                        String encryptedConId = SFZoom_MeetingManagerUtility.EncryptData(invitee.RecordId);
                        String encryptedMeetingId = SFZoom_MeetingManagerUtility.EncryptData(zoomMeeting.Id);                        

                        meetingDetails = Label.Event_Invitation_Email_Registration_Details+' <a href="'+siteURL+
                                        Label.Event_Invitation_VF_Page_Name+'?id='+encryptedId+
                            '&meetingid='+encryptedMeetingId+'&setupobj='+invitee.setupObjectName;
                        meetingDetails += (invitee.type.equalsIgnoreCase('Contact') ? '&conid=' : '&leadid=')
                                + encryptedConId + '" target="_blank">'+Label.Email_Click_Link_Message+'</a> <br/><br/>';
                                                
                        if(!emailTemplateToSendEventNotification.isEmpty()
                            && String.isNotBlank(emailTemplateToSendEventNotification[0].htmlValue) 
                            && String.isNotBlank(mailBody) && mailBody.containsIgnoreCase(Label.Registration_Details))
                        {
                            mailBody = mailBody.replace(Label.Registration_Details, meetingDetails);
                        }
                    }else if((isUpdate || zoomMeeting.Auto_Register__c)
                        && String.isNotBlank(mailBody) && mailBody.containsIgnoreCase(Label.Registration_Details)){
                        mailBody = mailBody.replace(Label.Registration_Details, '');
                    }
                }
                
                if(String.isNotBlank(invitee.email) && !zoomMeeting.Auto_Register__c){
                    if(String.isBlank(mailSentVerificationMsg)){
                       mailSentVerificationMsg = SFZoom_MeetingManagerUtility.sendEmail(new List<String>{invitee.email}, null,
                                                                mailBody, null, emailSenderName, userEmail, 
                                                                Label.Event_Invitation_Subject_Label, invitee.RecordId, null );
                    }
                    if(!String.isBlank(mailSentVerificationMsg) && mailSentVerificationMsg.containsIgnoreCase('SINGLE_EMAIL_LIMIT_EXCEEDED')){
                        String recordLink = '<a href="/'+invitee.RecordId+'" target="_blank">'+invitee.name+'</a>';
                        inviteeListNotReceivedEmail = String.isBlank(inviteeListNotReceivedEmail) ? recordLink
                                                                            : (inviteeListNotReceivedEmail + recordLink);
                    }else if(!String.isBlank(mailSentVerificationMsg)){
                        return mailSentVerificationMsg;
                    }                       
                }
                if(zoomMeeting.Auto_Register__c){
                    // False Positive - We are making API call in loop as the Zoom API doesn't support to add more than
                    // one registrants for a meeting in one API call. We have already checked the list size and we are
                    // only processing 50 selected records and not allowing to invite more than 50 registratns.
                    AddMeetingOrWebinarRegistrantForAutoRegistration(invitee.FirstName, invitee.LastName, invitee.email, 
                        zoomMeeting.Name, invitee.RecordId, null, zoomMeeting.Id, isWebinar);
                }
            }            
        }
        if(!String.isBlank(mailSentVerificationMsg)){
            errorMessage = emailLimitErrorMsg + '<br/><br/>'+ inviteeListNotReceivedEmail;
        }
        return errorMessage;
    }
    
    
    /******************************************************************************************************************
        Method Name  : BindMeetingDetails
        Description  : It binds all the meeting information/details with SFZoom_MeetingInformation wrapper class to send details to API
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private SFZoom_MeetingInformation BindMeetingDetails(){
        zoomMeeting.Start_Time__c = meetingStartTime;
        meetingStartDateTime = DateTime.newInstance(zoomMeeting.Start_Date__c, zoomMeeting.Start_Time__c);
        String timestampToSend = string.valueOfGmt(meetingStartDateTime);
        timestampToSend = timestampToSend.replace(' ', 'T')+'Z';
        
        SFZoom_MeetingInformation informationWrapper = new SFZoom_MeetingInformation();
        informationWrapper.start_time = timestampToSend;
        
        informationWrapper.duration = String.valueOf(Integer.valueOf(zoomMeeting.Duration__c));
        informationWrapper.topic = zoomMeeting.Topic__c;
        informationWrapper.type = '2';
        informationWrapper.timezone = String.valueOf(UserInfo.getTimeZone());
        informationWrapper.password = '';
        informationWrapper.agenda = zoomMeeting.Agenda__c;
        
        SFZoom_MeetingInformation.SFZoom_MeetingSettings settingsToSend = new SFZoom_MeetingInformation.SFZoom_MeetingSettings();
        settingsToSend.host_video = 'true';
        settingsToSend.participant_video = String.valueOf(zoomMeeting.Start_Participant_Video_on_Meeting_Join__c);
        settingsToSend.cn_meeting = 'false';
        settingsToSend.in_meeting = 'false';
        settingsToSend.join_before_host = String.valueOf(zoomMeeting.Join_before_Host__c);
        //settingsToSend.join_before_host = String.valueOf(zoomMeeting.Thank_you_notification__c);
        settingsToSend.mute_upon_entry = 'true';
        settingsToSend.watermark = 'false';
        settingsToSend.use_pmi = 'false';
        // approval_type 2 tells no registration required and 0 tells automatically approve
        settingsToSend.approval_type = '0';
        settingsToSend.registration_type = '1';
        settingsToSend.audio = 'both';
        settingsToSend.auto_recording = 'none';
        settingsToSend.enforce_login = String.valueOf(zoomMeeting.Enforce_Login__c);
        settingsToSend.enforce_login_domains = '';
        settingsToSend.alternative_hosts = '';
        
        informationWrapper.settings = settingsToSend;
        return informationWrapper;
    }

    /******************************************************************************************************************
        Method Name  : BindZoomWebinarDetails
        Description  : It binds all the meeting information/details with SFZoom_MeetingInformation wrapper class to send details to API
        Date         : 17 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private SFZoom_WebinarInformation BindZoomWebinarDetails(){
        zoomMeeting.Start_Time__c = meetingStartTime;
        meetingStartDateTime = DateTime.newInstance(zoomMeeting.Start_Date__c, zoomMeeting.Start_Time__c);
        String timestampToSend = string.valueOfGmt(meetingStartDateTime);
        timestampToSend = timestampToSend.replace(' ', 'T')+'Z';

        SFZoom_WebinarInformation webinarDetails = new SFZoom_WebinarInformation();
        webinarDetails.start_time = timestampToSend;
        webinarDetails.duration = String.valueOf(Integer.valueOf(zoomMeeting.Duration__c));
        webinarDetails.topic = zoomMeeting.Topic__c;
        // type - Webinar Type (5-Webinar, 6-Recurring Webinar with no fixed time, 9-Recurring Webinar with fixed time)
        webinarDetails.type = '5';
        webinarDetails.timezone = String.valueOf(UserInfo.getTimeZone());
        webinarDetails.password = '';
        webinarDetails.agenda = zoomMeeting.Agenda__c;
        
        SFZoom_WebinarInformation.SFZoom_WebinarSettings weinarSettingsToSend = new SFZoom_WebinarInformation.SFZoom_WebinarSettings();
        // host_video - start video when host joins webinar
        weinarSettingsToSend.host_video = String.valueOf(zoomMeeting.Host_Video__c);
        // panelists_video - start video when panelists join webinar
        weinarSettingsToSend.panelists_video = String.valueOf(zoomMeeting.Panelist_Video__c);
        // practice_session - Enable Practice Session
        weinarSettingsToSend.practice_session = 'true';
        // hd_video - Defaults to hd video
        weinarSettingsToSend.hd_video = String.valueOf(zoomMeeting.HD_Video__c);
        
        // approval_type - 0-Automatically Approve, 1-Manually Approve, 2-No Registration Required
        weinarSettingsToSend.approval_type = '0';
        //registration_type - Registration type. Used for recurring webinar with fixed time only.
        // (1-Attendees register once and can attend any of the occurrences, 2-Attendees need to register for each occurrence to attend,
        // 3- Attendees register once and can choose one or more occurrences to attend)
        weinarSettingsToSend.registration_type = '1';
        // audio - Determine how participants can join the audio portion of the meeting. (both-Both Telephony and VoIP, 
        // telephony-Telephony only, voip-VoIP only)
        weinarSettingsToSend.audio = 'both';
        // auto_recording - local-Record to local device, cloud-Record to cloud, none-No Recording
        weinarSettingsToSend.auto_recording = 'none';
        // enforce_login - Only signed-in users can join this meeting
        weinarSettingsToSend.enforce_login = '';
        //enforce_login_domains - Only signed-in users with specified domains can join meetings
        weinarSettingsToSend.enforce_login_domains = '';
        // alternative_hosts - Alternative hosts emails or IDs. Multiple values separated by comma
        weinarSettingsToSend.alternative_hosts = '';
        // close_registration - Close registration after event date
        weinarSettingsToSend.close_registration = 'true';
        // show_share_button - Show social share buttons on registration page
        weinarSettingsToSend.show_share_button = 'false';
        // allow_multiple_devices - Allow attendees to join from multiple devices
        weinarSettingsToSend.allow_multiple_devices = String.valueOf(zoomMeeting.Allow_Multiple_Devices__c);
        // Make the webinar on demand
        weinarSettingsToSend.on_demand = 'false';
        
        webinarDetails.settings = weinarSettingsToSend;
        return webinarDetails;
    }

    /******************************************************************************************************************
        Method Name  : LoadExistingConfiguration
        Description  : It loads all the existing global configuration which are saved in custom setting from the Zoom Config Page.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public Zoom_Meeting__c LoadExistingConfiguration(){
        Zoom_Configuration_Settings__c zoomConfigurationDetails = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        If(zoomConfigurationDetails != null){
            zoomMeeting.Join_before_Host__c = zoomConfigurationDetails.Join_Before_Host__c;
            zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = zoomConfigurationDetails.Start_Participant_Video_on_Join__c;
            zoomMeeting.Enforce_Login__c = zoomConfigurationDetails.Enforce_Login__c;            
            zoomMeeting.Thank_you_notification__c= zoomConfigurationDetails.Send_Thank_you_email_notification__c;
            zoomMeeting.Allow_Multiple_Devices__c = zoomConfigurationDetails.Allow_Multiple_Devices__c;
            zoomMeeting.HD_Video__c = zoomConfigurationDetails.HD_Video__c;
            zoomMeeting.Host_Video__c = zoomConfigurationDetails.Host_Video__c;
            zoomMeeting.Panelist_Video__c = zoomConfigurationDetails.Panelist_Video__c;
            
            zoomMeeting.Share_Survey_Link__c= zoomConfigurationDetails.Share_Survey_Link__c;
            zoomMeeting.Share_Recording_URL__c= zoomConfigurationDetails.Share_Recording_URL__c;
                                                                                                                                    
            minimumMeetingDuration = Integer.valueOf(zoomConfigurationDetails.Minimum_Meeting_Duration__c);
            maximumMeetingDuration = Integer.valueOf(zoomConfigurationDetails.Maximum_Meeting_Duration__c);
            emailSenderName = zoomConfigurationDetails.Email_Sender_Name__c;
            
            return zoomMeeting;
        }
        return null;
    }
    
    /******************************************************************************************************************
        Method Name  : getMetadataDetails
        Description  : It gets the metadaDetails for that particular object where user want to setup Zoom Meeting.
        Parameter1   : objectNameToFind - It stores object name of the record where the inline VF Page is placed. 
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static List<Zoom_Metadata__mdt> getMetadataDetails(String objectNameToFind){
        List<Zoom_Metadata__mdt> listOfZoomMetaData = new List<Zoom_Metadata__mdt>();
       
        try{
            
           List<String> listOfZoomMeetingConfigFields = new List<String>{'DeveloperName', 
                'Child_Object_API_Name__c', 'Child_Relationship_Name__c', 
                'Contact_Lookup_Field__c', 'Lead_Lookup_Field__c',
                'Lookup_Field_API_Name__c', 'Email_Field_API_Name_of_Contact__c',
                'Email_Field_API_Name_of_Lead__c','Attendance_Status_Field_Api_Name__c', 'Parent_Object_Name__c'};
           
           if(SFZoom_AccessUtil.objectIsAccessible('Zoom_Metadata__mdt') 
                && SFZoom_AccessUtil.objectIsQueryable('Zoom_Metadata__mdt') 
                && SFZoom_AccessUtil.fieldsAreAccessible('Zoom_Metadata__mdt', listOfZoomMeetingConfigFields)
           ){                
                listOfZoomMetaData = [SELECT DeveloperName, Email_Field_API_Name_of_Lead__c, 
                    Email_Field_API_Name_of_Contact__c, Child_Object_API_Name__c, 
                    Child_Relationship_Name__c, Contact_Lookup_Field__c, 
                    Lookup_Field_API_Name__c, Lead_Lookup_Field__c, Attendance_Status_Field_Api_Name__c
                    FROM Zoom_Metadata__mdt 
                    WHERE Parent_Object_Name__c = :String.escapeSingleQuotes(objectNameToFind)];
            } 
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Handler Extension - get Metadata Details - Exception: ' + ex.getMessage());
        }
        
        return listOfZoomMetaData.isEmpty() ? null : listOfZoomMetaData;
    }
    
    /******************************************************************************************************************
        Method Name  : EditMeetingDetails
        Description  : It fetches the existing zoom meeting details and allows user to update the zoom meeting details.
        Date         : 01 Nov 2018.
        Parameter1   : parentObjectFieldAPIName - It contains field api name of the zoom meeting for setup/parent object
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private void EditMeetingDetails(String parentObjectFieldAPIName){
        isEditEnabled = true;
        List<Zoom_Meeting__c> listOfMeetingToEdit;
        if(String.isNotBlank(SFMeetingId)){
            List<String> listOfZoomMeetingFields = new List<String>{'Name', 'Agenda__c', 'Duration__c', 
            'Enforce_Login__c', 'Join_before_Host__c', 'Auto_Register__c', 'Thank_you_notification__c',
            'Share_Recording_URL__c','Share_Survey_Link__c','Survey_Link_URL__c',
            'Start_Date__c', 'Start_Time__c', 'Time_Zone__c', 'Topic__c',
            'Start_Participant_Video_on_Meeting_Join__c', 'Meeting_URL__c', 'RecordTypeId',
            'HD_Video__c', 'Panelist_Video__c', 'Allow_Multiple_Devices__c',
            'Host_Video__c', 'Meeting_Recording_URL__c'};
            if(String.isBlank(parentObjectFieldAPIName)){
                setupObjectRecordId = SFZoom_MeetingManagerUtility.FindParentObjectRecordIdFromZoomMeeting(SFMeetingId);
            }
            if(SFZoom_AccessUtil.hasReadAccess(String.escapeSingleQuotes(SFMeetingId)) && SFZoom_AccessUtil.objectIsAccessible('Zoom_Meeting__c') 
                && SFZoom_AccessUtil.objectIsQueryable('Zoom_Meeting__c') 
                && SFZoom_AccessUtil.fieldsAreAccessible('Zoom_Meeting__c', listOfZoomMeetingFields)){
                
                String query = 'SELECT Name, Agenda__c, Duration__c, Meeting_Recording_URL__c, ';
                query += 'Enforce_Login__c, Join_before_Host__c, Host_Video__c,Thank_you_notification__c,';
                query += 'Share_Survey_Link__c, Share_Recording_URL__c,Survey_Link_URL__c,';
                query += 'Start_Date__c, Start_Time__c, Time_Zone__c, Topic__c ,';
                query += 'RecordTypeId, HD_Video__c, Panelist_Video__c, Allow_Multiple_Devices__c, ';
                query += 'Start_Participant_Video_on_Meeting_Join__c, Meeting_URL__c, Auto_Register__c ';
                query =  String.isNotBlank(parentObjectFieldAPIName) ? (query + ', '+parentObjectFieldAPIName) : query;
                query += ' FROM Zoom_Meeting__c WHERE ID = \''+String.escapeSingleQuotes(SFMeetingId)+'\'  LIMIT 1';
                
                listOfMeetingToEdit = Database.query(query);
            }
            
            if(listOfMeetingToEdit != null && !listOfMeetingToEdit.isEmpty()){
                FindEventType(listOfMeetingToEdit[0].RecordTypeId);
                updateMeetingId = listOfMeetingToEdit[0].Name;
                zoomMeeting = listOfMeetingToEdit[0];
                meetingStartTime = zoomMeeting.Start_Time__c;

                if(String.isBlank(setupObjectRecordId)){
                    setupObjectRecordId = String.isNotBlank(parentObjectFieldAPIName) && parentObjectFieldAPIName !=null 
                                    ? (String)zoomMeeting.get(parentObjectFieldAPIName) : null;
                }
            }            
        }
    }

    /******************************************************************************************************************
        Method Name  : UpdateWebinarDetailsClassic
        Description  : It updates webinar in the Salesforce and Zoom Org based on the user input.
        Date         : 31 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference UpdateWebinarDetailsClassic(){
        try{
            String returnMessage = UpdateMeetingOrWebinarDetails(true, true);
            if(String.isNotBlank(returnMessage) && !(returnMessage instanceof Id)){
                return null;
            }else {
                return (String.isNotBlank(retURL) ? new PageReference(retURL) : null);
            }
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Handler Extension - Update Webinar Details Classic - Exception: ' + ex.getMessage());
        }
        return null;
    }
    
    /******************************************************************************************************************
        Method Name  : UpdateMeetingDetails
        Description  : It updates zoom meeting details in the salesforce as well as Zoom org from classic interface.
        Date         : 31 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference UpdateMeetingDetailsClassic(){
        String errorMessage = UpdateMeetingOrWebinarDetails(true, false);
        if(String.isNotBlank(errorMessage) && !(errorMessage instanceof Id)){
            return null;
        }
        else{
            return new PageReference(String.isNotBlank(retURL) ? retURL : null);
        }
    }
    
    /******************************************************************************************************************
        Method Name  : UpdateMeetingDetailsLightning
        Description  : It updates zoom meeting details in the salesforce as well as Zoom org from the lightning interface.
        Date         : 31 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public String UpdateMeetingDetailsLightning(){
        Boolean isWebinar;
        if(eventType.equalsIgnoreCase(Label.Webinar_Record_Type_Name))
            isWebinar = true;
        else if(eventType.equalsIgnoreCase(Label.Meeting_Record_Type_Name))
            isWebinar = false;
        return UpdateMeetingOrWebinarDetails(false, isWebinar);
    }
    
    /******************************************************************************************************************
        Method Name  : UpdateMeetingDetails
        Description  : It updates zoom meeting details in the salesforce as well as Zoom org.
        Date         : 01 Nov 2018.
        Parameter1   : isClassic - It tells method is called from the classic UI or lightning component
        Parameter2   : isWebinar - It tells whether it is meeting or webinar
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private String UpdateMeetingOrWebinarDetails(Boolean isClassic, Boolean isWebinar){
        String errorMessage;
        try{
            errorMessage = isValidEventDetail(isClassic);
            if(String.isBlank(errorMessage)){
                String response;
                if(isEditEnabled && String.isNotBlank(updateMeetingId) && String.isNotBlank(SFMeetingId)){
                    if(!isWebinar){
                        String meetingDetails = JSON.serialize(BindMeetingDetails());
                        response = SFZoom_MeetingManagerUtility.UpdateMeetingInZoomAccount(meetingDetails, updateMeetingId);
                    }else{
                        String webinarDetails = JSON.serialize(BindZoomWebinarDetails());
                        response = SFZoom_MeetingManagerUtility.UpdateWebinarInZoomAccount(webinarDetails, updateMeetingId);
                    }
                    List<String> zoomMeetingFieldsToUpdate = new List<String>{'Name', 'Agenda__c',
                        'Duration__c', 'Enforce_Login__c', 'Allow_Multiple_Devices__c',
                        'Join_before_Host__c','Start_Date__c', 'Start_Time__c', 
                        'Time_Zone__c', 'Topic__c', 'Panelist_Video__c',
                        'Start_Participant_Video_on_Meeting_Join__c', 'Meeting_URL__c',
                        'Auto_Register__c', 'HD_Video__c', 'Host_Video__c','Thank_you_notification__c',
                        'Share_Survey_Link__c','Share_Recording_URL__c','Survey_Link_URL__c'};
                    
                    if(SFZoom_AccessUtil.objectIsUpdateable('Zoom_Meeting__c') 
                       && SFZoom_AccessUtil.fieldsAreUpdateable('Zoom_Meeting__c', zoomMeetingFieldsToUpdate)
                       && SFZoom_AccessUtil.hasEditAccess(zoomMeeting.Id)){
                       UPDATE zoomMeeting;
                    }
                    
                    errorMessage = UpdateEvents(meetingStartDateTime, Integer.valueOf(zoomMeeting.Duration__c), zoomMeeting.Topic__c, SFMeetingId);
                    isEditEnabled = false;
                }
                return (String) zoomMeeting.Id;
            }
        }catch(Exception ex){
            System.debug('SF Zoom Meeting Handler Extension - Update Meeting Or Webinar Details - Exception: ' + ex.getMessage());
            errorMessage = Label.Meeting_Or_Webinar_Creation_Exception_Msg;
        }
        return errorMessage;
    }
    
    /******************************************************************************************************************
        Method Name  : CancelOperation
        Description  : It allows user to cancel the operation after clicking on the VF Page.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference CancelOperation(){
        try{
            String pageIdToReturn = String.isNotBlank(setupObjectRecordId) ? setupObjectRecordId : sfMeetingId;
            return String.isNotBlank(retURL) ? new PageReference(retURL) : new PageReference('/'+pageIdToReturn);
        }Catch(Exception ex){
            System.debug('SFZoom Meeting Handler Extension - Cancel Operation - Exception: ' + ex.getMessage());
        }
        return null;
    }
    
    /******************************************************************************************************************
        Method Name  : UpdateEvents
        Description  : It updates the event details when the user update the Zoom meeting information.
        Parameter1   : startDateTime - It stores start date time of the meeting to update event with same information
        Parameter2   : duration - It stores duration of the meeting to update event with same information
        Parameter3   : startDateTime - It stores subject of the meeting to update event with same information
        Parameter3   : meetingID - It stores salesforce record id of the meeting
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private String UpdateEvents(DateTime startDateTime, Integer duration, String subject, String meetingID){
        String errorMessage;
        Map<Id, Event> mapOfEventsToUpdate = new Map<Id, Event>();
        List<String> listOfEventFields = new List<String>{'Subject', 'StartDateTime', 'EndDateTime', 
                                            'Description', 'whoId', 'Zoom_Meeting__c'};
        if(SFZoom_AccessUtil.hasReadAccess(meetingID) && SFZoom_AccessUtil.objectIsAccessible('Event') 
            && SFZoom_AccessUtil.objectIsQueryable('Event') 
            && SFZoom_AccessUtil.fieldsAreAccessible('Event', listOfEventFields)){
            
            mapOfEventsToUpdate = new Map<Id, Event>([SELECT Subject, StartDateTime, 
                        EndDateTime, Description, whoId FROM Event
                        WHERE Zoom_Meeting__c = :String.escapeSingleQuotes(meetingID)]);
        }
        Map<Id, Id> mapOfContactOrLeadIdWithChildRecordId = new Map<Id, Id>();
        Set<Id> setOfLeadOrContactIds = new Set<Id>();
        if(!mapOfEventsToUpdate.values().isEmpty()){
            for(Event e : mapOfEventsToUpdate.values()){
                e.StartDateTime = startDateTime;
                e.EndDateTime = startDateTime.addMinutes(duration);
                e.Subject = subject;
                setOfLeadOrContactIds.add(e.whoId);
            }
            if(SFZoom_AccessUtil.hasEditAccessMulti(mapOfEventsToUpdate.keyset()) 
                && SFZoom_AccessUtil.objectIsUpdateable('Event') && 
                SFZoom_AccessUtil.fieldsAreUpdateable('Event', listOfEventFields)){        
                   Database.UPDATE(mapOfEventsToUpdate.values());
               If(!setOfLeadOrContactIds.isEmpty()){
                    String meetingURL = !mapOfEventsToUpdate.values().isEmpty() ? mapOfEventsToUpdate.values()[0].Description : '';
                    Boolean isWebinar = eventType.equalsIgnoreCase(Label.Webinar_Record_Type_Name) ? true : false;
               }
           }
        }
        return errorMessage;
    }
    
    /******************************************************************************************************************
        Method Name  : CancelMeeting
        Description  : It cancels the created/existing meeting. It deletes zoom meeting from the Salesforce and the Zoom Org and also updates one 
                       checkbox 'Is_Cancelled__c' to true on the standard event object.
        Parameter1   : isWebinar - It tells whether the event is meeting or webinar
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private static void CancelMeetingOrWebinar(String sfMeetingId, Boolean isWebinar){
        if(String.isNotBlank(sfMeetingId)){
            List<String> listOfMeetingFields = new List<String>{'Name'};
            List<Zoom_Meeting__c> listOfMeetingToCancel;
            if(SFZoom_AccessUtil.hasReadAccess(String.escapeSingleQuotes(SFMeetingId)) && SFZoom_AccessUtil.objectIsAccessible('Zoom_Meeting__c') 
               && SFZoom_AccessUtil.objectIsQueryable('Zoom_Meeting__c') 
               && SFZoom_AccessUtil.fieldsAreAccessible('Zoom_Meeting__c', listOfMeetingFields)){
                   
                   listOfMeetingToCancel = [SELECT Name FROM Zoom_Meeting__c 
                                            WHERE ID = :String.escapeSingleQuotes(sfMeetingId)];
            }
            
            HTTPResponse response = new HTTPResponse();
            If(!listOfMeetingToCancel.isEmpty()){
                if(isWebinar){
                    response = SFZoom_MeetingManagerUtility.CancelWebinarInZoomAccount(listOfMeetingToCancel[0].Name);
                }else{
                    response = SFZoom_MeetingManagerUtility.CancelMeetingInZoomAccount(listOfMeetingToCancel[0].Name);
                }
                
                if(response.getStatusCode() == 204){
                    List<String> listOfEventFields = new List<String>{'Subject', 'StartDateTime', 'EndDateTime', 'Description'};
                    Map<Id, Event> mapOfEventsToCancel = new Map<Id, Event>();
                    if(SFZoom_AccessUtil.hasReadAccess(listOfMeetingToCancel[0].Id) && SFZoom_AccessUtil.objectIsAccessible('Event') 
                       && SFZoom_AccessUtil.objectIsQueryable('Event') 
                       && SFZoom_AccessUtil.fieldsAreAccessible('Event', listOfEventFields)){
                            
                           mapOfEventsToCancel = new Map<Id, Event>(
                               [SELECT Subject, StartDateTime, EndDateTime, Description 
                                FROM Event WHERE Zoom_Meeting__c = :listOfMeetingToCancel[0].Id]);
                    }
                    
                    // Code to send email notification after cancelling the event - starts here
                    List<EventRelation> eventRelations = new List<EventRelation>();
                    List<String> listOfEventRelationFields = new List<String>{'RelationId', 'isInvitee', 'Status'};
                    if(SFZoom_AccessUtil.objectIsAccessible('EventRelation') 
                        && SFZoom_AccessUtil.objectIsQueryable('EventRelation') 
                        && SFZoom_AccessUtil.fieldsAreAccessible('EventRelation', listOfEventRelationFields)){
                        
                        eventRelations = [SELECT RelationId, isInvitee FROM EventRelation 
                                            WHERE eventid IN : mapOfEventsToCancel.keySet()];
                    }
                    
                    for(EventRelation eventRelationVar : eventRelations){
                        eventRelationVar.isInvitee = false;
                        eventRelationVar.Status = 'New';
                    }
                    Database.DMLOptions dlo = new Database.DMLOptions();
                    dlo.EmailHeader.triggerUserEmail  = false;
                    dlo.EmailHeader.triggerOtherEmail  = true;
                    dlo.EmailHeader.triggerAutoResponseEmail = false;
                    if(SFZoom_AccessUtil.objectIsUpdateable('EventRelation') 
                        && SFZoom_AccessUtil.fieldsAreUpdateable('EventRelation', listOfEventRelationFields)){
                        
                        Database.update(eventRelations,dlo);
                    }
                    // Code to send email notification after cancelling the event - ends here
                    if(!listOfMeetingToCancel.isEmpty()){
                        if(SFZoom_AccessUtil.hasDeleteAccess(listOfMeetingToCancel[0].Id)){ 
                            SFZoom_AccessUtil.deleteRecordsWithAccessCheck(listOfMeetingToCancel, true);
                        }
                    }
                    
                    for(Event eventVar : mapOfEventsToCancel.values()){
                        eventVar.Is_Cancelled__c = true;
                    }
                    Boolean hasEditAccess = !mapOfEventsToCancel.isEmpty() && !mapOfEventsToCancel.values().isEmpty() ? 
                        SFZoom_AccessUtil.hasEditAccess(mapOfEventsToCancel.values()[0].Id) : false;
                    if(SFZoom_AccessUtil.objectIsUpdateable('Event') && hasEditAccess 
                       && SFZoom_AccessUtil.fieldsAreUpdateable('Event', new List<String>{'Is_Cancelled__c'})){
                       
                       UPDATE mapOfEventsToCancel.values();
                    }                  
                }
            }
        }
    }
    
    /******************************************************************************************************************
        Method Name  : AddMeetingOrWebinarRegistrantForAutoRegistration
        Description  : It creates meeting in the Zoom Account if the auto register checkbox is checked.
        Parameter1   : firstName - It holds firstName of the contact/lead
        Parameter2   : lastName - It holds lastName of the contact/lead
        Parameter3   : email - It holds email of the contact/lead
        Parameter4   : zoomMeetingId - It holds zoom meeting id which is kept in salesforce meeting record name
        Parameter5   : contactId - It holds invite salesforce contact id
        Parameter6   : leadId - It holds invite salesforce lead id
        Parameter7   : salesforceZoomMeetingId - It holds saleforce meeting record id
        Parameter8   : isWebinar - It tells whether the event is meeting or webinar
        Date         : 07 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @future(callout=true)
    public static void AddMeetingOrWebinarRegistrantForAutoRegistration(String firstName, String lastName, String email, String zoomMeetingId, 
                                                                String contactId, String leadId, String salesforceZoomMeetingId, 
                                                                Boolean isWebinar){
        try{
            ParticipantRegistrationDetails registrationDetails = new ParticipantRegistrationDetails();
            if(String.isNotBlank(firstName) && String.isNotBlank(lastName) && String.isNotBlank(email)){
                registrationDetails.first_name = firstName;
                registrationDetails.last_name = lastName;
                registrationDetails.email = email;
                String requestBody = JSON.serialize(registrationDetails);
                HTTPResponse response;
                if(isWebinar){
                    response = SFZoom_MeetingManagerUtility.AddWebinarRegistrants(zoomMeetingId, requestBody);
                }else{
                    response = SFZoom_MeetingManagerUtility.AddMeetingRegistrants(zoomMeetingId, requestBody);
                }
                 
                if(response != null && String.isNotBlank(response.getBody())){
                    Map<String,Object> mapOfResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    String whoId;
                    if(String.isNotBlank(contactId)){
                        whoId = contactId;
                    }else if(String.isNotBlank(leadId)){
                        whoId = leadId;
                    }
                    List<Event> listOfEvents = new List<Event>();
                    List<String> listOfFields = new List<String>{'Zoom_Registration_Status__c', 
                        'Joining_URL__c', 'Zoom_Registration_Id__c', 'WhoId', 'Zoom_Meeting__c' };
                    if(String.isNotBlank(whoId) && String.isNotBlank(salesforceZoomMeetingId)){
                        /*if(SFZoom_AccessUtil.objectIsAccessible('Event') && SFZoom_AccessUtil.objectIsQueryable('Event') 
                           && SFZoom_AccessUtil.fieldsAreAccessible('Event', listOfFields))
                        {*/
                            listOfEvents = [SELECT Zoom_Registration_Status__c, Joining_URL__c,
                                            Zoom_Registration_Id__c FROM Event 
                                            WHERE WhoId = :String.escapeSingleQuotes(whoId)
                                            AND Zoom_Meeting__c = :String.escapeSingleQuotes(salesforceZoomMeetingId)];
                        //}
                    }

                    if(String.isNotBlank(whoId) && String.isNotBlank(salesforceZoomMeetingId)){
                        if(!listOfEvents.isEmpty()){
                            listOfEvents[0].Zoom_Registration_Status__c = Label.Registered_Meeting_Status;
                            listOfEvents[0].Zoom_Registration_Id__c = String.valueOf(mapOfResponse.get('registrant_id'));
                            listOfEvents[0].Joining_URL__c = String.valueOf(mapOfResponse.get('join_url'));
                            UPDATE listOfEvents;
                            /*if(SFZoom_AccessUtil.objectIsUpdateable('Event') && SFZoom_AccessUtil.hasEditAccess(listOfEvents[0].Id) && 
                              SFZoom_AccessUtil.fieldsAreUpdateable('Event', listOfFields)){
                                UPDATE listOfEvents;
                            }*/
                        }
                    }   
                }
            }
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Handler Extension - Add Meeting Or Webinar Registrant For Auto Registration - Exception: ' + ex.getMessage());
        }        
    }

    /******************************************************************************************************************
        Method Name  : FindListOfContactOrLeadFromChildRecords
        Description  : It finds all the leads and contacts from the child records of setup object
        Date         : 24 Dec 2018.
        Parameter1   : parentRecordId - It contains parent/setup object record id
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static List<InviteeDetailsWrapper> FindListOfContactOrLeadFromChildRecords(Id parentRecordId){
        List<InviteeDetailsWrapper> listOfInviteeDetailsToSend = new List<InviteeDetailsWrapper>();
        try{
            if(string.isNotBlank(parentRecordId)){
                String parentObjectName = String.valueOf(parentRecordId.getSObjectType());
                List<Zoom_Metadata__mdt> listOfMetaData = getMetadataDetails(parentObjectName);
                String childRelationshipName;
                String contactLookupFieldAPINameOnChildObject; 
                String leadLookupFieldAPINameOnChildObject;
                String contactEmailFieldAPIName;
                String leadEmailFieldAPIName;
                String childObjectAPIName;
                String contactRelationField;
                String leadRelationField;
                
                if(!listOfMetaData.isEmpty()){
                    childObjectAPIName = listOfMetaData[0].Child_Object_API_Name__c;
                    childRelationshipName = listOfMetaData[0].Child_Relationship_Name__c;
                    if(childObjectAPIName.endsWithIgnoreCase('__c')){
                        childRelationshipName = childRelationshipName.endsWithIgnoreCase('__r') ? 
                            childRelationshipName : childRelationshipName + '__r';
                    }
                    
                    contactLookupFieldAPINameOnChildObject = listOfMetaData[0].Contact_Lookup_Field__c;
                    leadLookupFieldAPINameOnChildObject = listOfMetaData[0].Lead_Lookup_Field__c;
                    contactEmailFieldAPIName = listOfMetaData[0].Email_Field_API_Name_of_Contact__c;
                    leadEmailFieldAPIName = listOfMetaData[0].Email_Field_API_Name_of_Lead__c;                 
                }

                String contactFieldsToQuery;
                String leadFieldsToQuery;
                List<String> listOfLeadFields = new List<String>{'Id', 'FirstName', 'LastName', 'Name'};
                List<String> listOfContactFields = new List<String>{'Id', 'FirstName', 'LastName', 'Name'};

                if(String.isNotBlank(contactLookupFieldAPINameOnChildObject)){
                    if(contactLookupFieldAPINameOnChildObject.endsWithIgnoreCase('Id')){
                        contactRelationField = contactLookupFieldAPINameOnChildObject.subStringBefore('Id');
                    }else If(contactLookupFieldAPINameOnChildObject.endsWithIgnoreCase('__c')){
                        contactRelationField = contactLookupFieldAPINameOnChildObject.replace('__c', '__r');
                    }
                    listOfContactFields.add(contactEmailFieldAPIName);
                    if(childRelationshipName.equalsIgnoreCase('Contacts')){
                        contactFieldsToQuery = 'FirstName, LastName, Name, ' +contactEmailFieldAPIName;
                    }else{
                        contactFieldsToQuery = contactRelationField + '.FirstName, ' + contactRelationField + '.LastName, ' 
                        + contactRelationField + '.Name, ' + contactRelationField +'.'+ contactEmailFieldAPIName;
                    }
                }
                if(String.isNotBlank(leadLookupFieldAPINameOnChildObject)){
                    if(leadLookupFieldAPINameOnChildObject.endsWithIgnoreCase('Id')){
                        leadRelationField = leadLookupFieldAPINameOnChildObject.subStringBefore('Id');
                    }else If(leadLookupFieldAPINameOnChildObject.endsWithIgnoreCase('__c')){
                        leadRelationField = leadLookupFieldAPINameOnChildObject.replace('__c', '__r');
                    }
                    listOfLeadFields.add(leadEmailFieldAPIName);
                    if(childRelationshipName.equalsIgnoreCase('Leads')){
                        contactFieldsToQuery = 'FirstName, LastName, Name, ' +leadEmailFieldAPIName;
                    }else{
                        leadFieldsToQuery = leadRelationField + '.FirstName, ' + leadRelationField + '.LastName, ' + 
                            leadRelationField + '.Name, ' + leadRelationField +'.'+ leadEmailFieldAPIName;
                    }                    
                }

                String query = 'SELECT (SELECT ';
                if(String.isNotBlank(contactFieldsToQuery)){
                    query += contactFieldsToQuery + ', ';
                }
                if(String.isNotBlank(leadFieldsToQuery)){
                    query += leadFieldsToQuery + ', ';
                }
                if(String.isNotBlank(contactLookupFieldAPINameOnChildObject)){
                    query += contactLookupFieldAPINameOnChildObject;
                }
                if(String.isNotBlank(leadLookupFieldAPINameOnChildObject)){
                    query += ', '+leadLookupFieldAPINameOnChildObject;
                }
                query += ' FROM '+childRelationshipName;
                query += String.isBlank(leadLookupFieldAPINameOnChildObject) && String.isNotBlank(contactLookupFieldAPINameOnChildObject) ? ' WHERE '+contactLookupFieldAPINameOnChildObject+' != null' : '';
                query += ' ORDER BY Name ) FROM '+parentObjectName +' WHERE ID = \''+String.escapeSingleQuotes(parentRecordId)+'\' ';
                
                List<sObject> parentWithlistOfChildRecords = new List<sObject>();
                parentWithlistOfChildRecords = Database.query(query);
                
                
                InviteeDetailsWrapper inviteeDetails;
                if(!parentWithlistOfChildRecords.isEmpty()){
                    List<sObject> listOfChildRecords = parentWithlistOfChildRecords[0].getSObjects(childRelationShipName);
                    for(sObject childRecord : listOfChildRecords){
                        inviteeDetails = new InviteeDetailsWrapper();
                        inviteeDetails.childRecordId = (Id) childRecord.get('Id');
                        inviteeDetails.setupObjectName = parentObjectName;
                        if(String.isNotBlank(contactLookupFieldAPINameOnChildObject)){
                            sObject contact;
                            if(childRelationshipName.equalsIgnoreCase('Contacts')){
                                contact = (Contact)childRecord;
                            }else{
                                Integer relationCount = 1;
                                if(contactLookupFieldAPINameOnChildObject.contains('.') 
                                   && (contactLookupFieldAPINameOnChildObject.contains('__r') || 
                                       contactLookupFieldAPINameOnChildObject.endsWithIgnoreCase('Id'))){
                                    List<String> listOfRelationFields = contactLookupFieldAPINameOnChildObject.split('\\.');
                                    Sobject parentObjRecord = childRecord.getSObject(listOfRelationFields[0]);
                                    for(String relationField : listOfRelationFields){
                                        if(listOfRelationFields.size() == relationCount){
                                            String relationFieldToUse = relationField.endsWithIgnoreCase('Id') ? 
                                                relationField.subStringBefore('Id') : (relationField.endsWithIgnoreCase('__c')
                                                                                       ? relationField.replace('__c', '__r') : relationField);
                                            contact = (Contact)parentObjRecord.getSObject(relationFieldToUse);
                                            break;
                                        }
                                        parentObjRecord = relationCount != 1 ? parentObjRecord.getSObject(relationField) : parentObjRecord;
                                        relationCount++;
                                    }
                                }else if(childRecord.getSObject(contactRelationField) != null){
                                    contact = (Contact)childRecord.getSObject(contactRelationField);
                                }
                            }
                            if(contact != null){
                                inviteeDetails.recordId = contact.Id;
                                inviteeDetails.name = (String)contact.get('Name');
                                inviteeDetails.firstName = (String)contact.get('FirstName');
                                inviteeDetails.lastName = (String)contact.get('LastName');
                                inviteeDetails.email = (String)contact.get(contactEmailFieldAPIName);
                                inviteeDetails.type = 'Contact';
                            }                            
                        }
                        if(String.isNotBlank(leadLookupFieldAPINameOnChildObject)){
                            sObject lead;
                            if(childRelationshipName.equalsIgnoreCase('Leads')){
                                lead = (Lead)childRecord;
                            }else{
                                Integer relationCount = 1;
                                if(leadLookupFieldAPINameOnChildObject.contains('.') 
                                   && (leadLookupFieldAPINameOnChildObject.contains('__r') || 
                                       leadLookupFieldAPINameOnChildObject.endsWithIgnoreCase('Id'))){
                                    List<String> listOfRelationFields = leadLookupFieldAPINameOnChildObject.split('\\.');
                                    Sobject parentObjRecord = childRecord.getSObject(listOfRelationFields[0]);
                                    for(String relationField : listOfRelationFields){
                                        if(listOfRelationFields.size() == relationCount){
                                            String relationFieldToUse = relationField.endsWithIgnoreCase('Id') ? 
                                                relationField.subStringBefore('Id') : (relationField.endsWithIgnoreCase('__c')
                                                                                       ? relationField.replace('__c', '__r') : relationField);
                                            lead = (Lead)parentObjRecord.getSObject(relationFieldToUse);
                                            break;
                                        }
                                        parentObjRecord = relationCount != 1 ? parentObjRecord.getSObject(relationField) : parentObjRecord;
                                        relationCount++;
                                    }
                                }else{
                                    lead = (Lead)childRecord.getSObject(leadRelationField);
                                }
                            }
                            if(lead != null){
                                inviteeDetails.recordId = lead.Id;
                                inviteeDetails.firstName = (String)lead.get('FirstName');
                                inviteeDetails.lastName = (String)lead.get('LastName');
                                inviteeDetails.name = (String)lead.get('Name');
                                inviteeDetails.email = (String)lead.get(leadEmailFieldAPIName);
                                inviteeDetails.type = 'Lead';
                            }                            
                        }
                        if(String.isNotBlank(inviteeDetails.email) && String.isNotBlank(inviteeDetails.lastName)){
                            listOfInviteeDetailsToSend.add(inviteeDetails);
                        }
                    }
                }
            }
        }Catch(Exception ex){
            System.debug('SFZoom Meeting Handler Extension - Find List Of Contact Or Lead From Child Records - Exception: ' + ex.getMessage());
        }
        return listOfInviteeDetailsToSend;
    }
    
    /******************************************************************************************************************
        Method Name  : FindInvitationDetails
        Description  : It finds all the leads and contacts who are invited or who are not invited
        Date         : 24 Dec 2018.
        Parameter1   : parentRecordId - It contains parent/setup object record id
        Parameter2   : meetingID - It contains salesforce meeting record id
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static Map<String, Object> FindInvitationDetails(Id parentRecordId, Id meetingID){
        Map<String, Object> retMap = new Map<String, Object>();
        try{
            List<InviteeDetailsWrapper> listOfAllChildRecords = FindListOfContactOrLeadFromChildRecords(parentRecordId);
            Map<Id, InviteeDetailsWrapper> mapOfRecordIdWithInviteeDetails = new Map<Id, InviteeDetailsWrapper>();
            for(InviteeDetailsWrapper invitee : listOfAllChildRecords){
                mapOfRecordIdWithInviteeDetails.put(invitee.recordId, invitee);
            }
            List<String> listOfEventFields = new List<String>{'whoId', 'Zoom_Meeting_Attendance__c'};
                List<Event> listOfExistingEvents = new List<Event>();
            if(SFZoom_AccessUtil.hasReadAccess(meetingID) && SFZoom_AccessUtil.objectIsAccessible('Event') 
               && SFZoom_AccessUtil.objectIsQueryable('Event') 
               && SFZoom_AccessUtil.fieldsAreAccessible('Event', listOfEventFields)){
                   
                   listOfExistingEvents = [SELECT whoId, Zoom_Meeting_Attendance__c FROM Event 
                                           WHERE Zoom_Meeting__c = :String.escapeSingleQuotes(meetingID)];
               }
            List<InviteeDetailsWrapper> lstInviteeDetails = new List<InviteeDetailsWrapper>();
            List<InviteeDetailsWrapper> lstOfAttendedInviteeDetails = new List<InviteeDetailsWrapper>();
            for(Event existingEvent : listOfExistingEvents){
                if(mapOfRecordIdWithInviteeDetails.containsKey(existingEvent.whoId)){
                    lstInviteeDetails.add(mapOfRecordIdWithInviteeDetails.get(existingEvent.whoId));
                    if(Label.Meeting_Attended_Value.equalsIgnoreCase(existingEvent.Zoom_Meeting_Attendance__c)){
                        lstOfAttendedInviteeDetails.add(mapOfRecordIdWithInviteeDetails.get(existingEvent.whoId));
                    }
                    mapOfRecordIdWithInviteeDetails.remove(existingEvent.whoId);
                }
            }
            retMap.put('attendees', lstInviteeDetails);
            retMap.put('attended', lstOfAttendedInviteeDetails);
            retMap.put('newAttendees', mapOfRecordIdWithInviteeDetails.values());
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Handler Extension - Find Invitation Details - Exception: ' + ex.getMessage());
        }        
        return retMap;
    }
    
    /******************************************************************************************************************
        Class Name  : ParticipantRegistrationDetails
        Description : It is a wrapper class which holds attendee registration details.
        Date        : 20 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public with sharing Class ParticipantRegistrationDetails{
        public String email {get; set;}
        public String first_name {get; set;}
        public String last_name {get; set;}
    }

    /******************************************************************************************************************
        Class Name  : InviteeDetailsWrapper
        Description : It is a wrapper class which holds invitee details
        Date        : 31 Dec 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    global with sharing Class InviteeDetailsWrapper{
        @AuraEnabled global String setupObjectName {get; set;}
        @AuraEnabled global String childRecordId {get; set;}
        @AuraEnabled global String recordId {get; set;}
        @AuraEnabled global Boolean isSelected {get; set;}
        @AuraEnabled global String firstName {get; set;}
        @AuraEnabled global String lastName {get; set;}
        @AuraEnabled global String name {get; set;}
        @AuraEnabled global String email {get; set;}
        @AuraEnabled global String type {get; set;}

        global InviteeDetailsWrapper(){
            isSelected = true;
        }
    }
   
}