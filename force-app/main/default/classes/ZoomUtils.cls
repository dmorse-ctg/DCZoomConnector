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

global without sharing class ZoomUtils {
    
    /******************************************************************************************************************
    Method Name  : sendEmail
    Description  : It sends email invite to all the members
    Date         : 24 May 2018
    Parameter1   : listOfInvitees - It holds the list of contacts/leads associated with parent object
    Parameter2   : whoId - It holds the contact/lead Id
    Parameter3   : autoRegisterFlag - value from flow/process builder
    Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    global static void sendEmail(Id whoId,Boolean autoRegister,Id parentRecordId) {

    try{
        String errorMessage;
        Zoom_Meeting__c zoomMeeting ;
        List<Zoom_Meeting__c> listOfMeeting = new List<Zoom_Meeting__c>();
        
        String parentObjectName = String.valueOf(parentRecordId.getSObjectType());
        List<Zoom_Metadata__mdt> listOfMetaData = SFZoom_MeetingHandlerExtension.getMetadataDetails(parentObjectName);
        String lookUpFieldAPIName = listOfMetaData[0].Lookup_Field_API_Name__c;
        //string lookupApiName = getlookupApiName(parentObjectName,listOfMetaData[0].Child_Relationship_Name__c);        
        String query = 'SELECT Name, Agenda__c, Duration__c,Event_Type__c,Meeting_Recording_URL__c,  ';
       query += 'Enforce_Login__c, Join_before_Host__c, Host_Video__c,Thank_you_notification__c,';
       query += 'Start_Date__c, Start_Time__c, Time_Zone__c, Topic__c,Share_Survey_Link__c, ';
       query += 'RecordTypeId, HD_Video__c, Panelist_Video__c, Allow_Multiple_Devices__c,Share_Recording_URL__c,Survey_Link_URL__c, ';
       query += 'Start_Participant_Video_on_Meeting_Join__c, Meeting_URL__c, Auto_Register__c ';
       query += ' FROM Zoom_Meeting__c WHERE ' + String.escapeSingleQuotes(lookUpFieldAPIName) + ' = \''+String.escapeSingleQuotes(parentRecordId)+'\'  LIMIT 1';
       
       listOfMeeting = Database.query(query);      
        
        if(!listOfMeeting.isEmpty() && listOfMeeting.size()>0){
			zoomMeeting = listOfMeeting[0];
            DateTime startDateTime = DateTime.newInstance(zoomMeeting.Start_Date__c, zoomMeeting.Start_Time__c);
            List<Event> listOfEventsToCreate = new List<Event>();
            String strInviteType;
            if(whoId != null && zoomMeeting!=null){
                //Query on event record to check if there is existing event for same contact/lead and meeting
                List<Event> existingEventList = [SELECT Id from Event WHERE WhoId =: whoId AND Zoom_Meeting__c =:zoomMeeting.Id LIMIT 1];
                strInviteType = String.valueOf(whoId.getSObjectType());  
                Event eventToCreateForInvitee = new Event();
				if(!existingEventList.isEmpty()){  //If we found event record then update the Id
					eventToCreateForInvitee.Id = existingEventList[0].Id;
				}
                eventToCreateForInvitee.StartDateTime = startDateTime;
                eventToCreateForInvitee.EndDateTime = startDateTime.addMinutes(Integer.valueOf(zoomMeeting.Duration__c));
                eventToCreateForInvitee.Subject = zoomMeeting.Topic__c;
                eventToCreateForInvitee.Zoom_Meeting__c = zoomMeeting.Id;              
                eventToCreateForInvitee.WhoId = whoId;
                if(strInviteType == 'Contact'){
                    eventToCreateForInvitee.WhatId = parentRecordId; // getWhatId(parentRecordId,whoId, listOfMetaData[0],lookupApiName);
                }
                eventToCreateForInvitee.Description = zoomMeeting.Meeting_URL__c;
                eventToCreateForInvitee.Zoom_Registration_Status__c = Label.Invitee_Event_Status_Initiated;
                listOfEventsToCreate.add(eventToCreateForInvitee);
            }
            if(!listOfEventsToCreate.isEmpty() && listOfEventsToCreate.size() <= 50){
                upsert listOfEventsToCreate; //changed from insert to upsert
            
               List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper> listOfInvitees = SFZoom_MeetingHandlerExtension.FindListOfContactOrLeadFromChildRecords(parentRecordId);

               //Send Email Call
               errorMessage = SendEmailToInvitees(zoomMeeting, whoId, autoRegister, listOfInvitees);
            }else if(!listOfEventsToCreate.isEmpty() && listOfEventsToCreate.size() > 50){
                errorMessage = Label.Maximum_Number_of_Invitee_Selection_To_Send_Email_Msg;
            }
        }
    }catch(Exception exe){
          System.debug('Zoom Utils sendEmail - Exception: ' + exe.getMessage());
    }
}

 /******************************************************************************************************************
    Method Name  : extractChildEntries
    Description  : It sends email invite to all the members
    Date         : 07 May 2020
    Parameter1   : zoomMettingIdentity - It holds the zoomMeeting Salesforce identity.
    Parameter2   : whoId - It holds the contact/lead Id
    Parameter3   : active Metadata record  
    Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static List<SObject> extractChildEntries(Id parentRecordId, Zoom_Metadata__mdt zoomSetting )
    {
        
        List<SObject> lstChildRecords = new List<SObject> ();
        try
        {
            string parentLookupApiName = getlookupApiName(parentRecordId, zoomSetting.Child_Relationship_Name__c);	
           
            if(parentRecordId != null){
                
                    lstChildRecords = Database.query('SELECT Id,' + zoomSetting.Contact_Lookup_Field__c +' FROM '+ zoomSetting.Child_Object_API_Name__c + ' WHERE '
                                                    + parentLookupApiName +'=: parentRecordId' );
                }
                
        }
        catch(Exception exe){
           System.debug('Zoom Utils extractChildEntries - Exception: ' + exe.getMessage());
       }
        
        return lstChildRecords;
    }
    
    /******************************************************************************************************************
    Method Name  : getlookupApiName
    Description  : It sends email invite to all the members
    Date         : 07 May 2020
    Parameter1   : zoomMettingIdentity - It holds the zoomMeeting Salesforce identity.
    Parameter2   : whoId - It holds the contact/lead Id
    Parameter3   : active Metadata record  
    Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static string getlookupApiName(Id parentObjectId,string zoomSettingChildRelationshipName)
    {
        String lookupApiName;
        List<SObject> lstChildRecords = new List<SObject> ();
        try
        {
            if(parentObjectId != null && string.isNotBlank(zoomSettingChildRelationshipName)){
                //String parentObjectName = String.valueOf(parentRecordId.getSObjectType());
                String parentObjectName = String.valueOf(parentObjectId.getSObjectType());
                SObjectType objObjectType = Schema.getGlobalDescribe().get(parentObjectName);
                Schema.DescribeSObjectResult   describeresult = objObjectType.getDescribe();
                List<Schema.ChildRelationship>   lstchildrelationships =describeresult.getChildRelationships();
                for (Schema.ChildRelationship relation : lstchildrelationships ){
                    String relationshipName = relation.getRelationshipName();
                    
                    if(relationshipName != null && relationshipName.contains(zoomSettingChildRelationshipName)){
                        lookupApiName = string.valueof(relation.getField());
                        break;
                    }
                }
                
            }
        }
        catch(Exception exe){
           System.debug('Zoom Utils getlookupApiName - Exception: ' + exe.getMessage());
       }
        return  lookupApiName;
    }
  
   
    /******************************************************************************************************************
    Method Name  : SendEmailToInvitees
    Description  : It sends email invite to all the members
    Date         : 24 May 2018
    Parameter1   : listOfInvitees - It holds the list of contacts/leads associated with parent object
    Parameter2   : whoId - It holds the contact/lead Id
    Parameter3   : autoRegisterFlag - value from flow/process builder
    Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private static String SendEmailToInvitees(Zoom_Meeting__c zoomMeeting, Id whoId, Boolean autoRegisterFlag,
                                              List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper> listOfInvitees){
        String errorMessage;
        String siteURL;
        String mailBody;
        String emailSenderName;
        Boolean isWebinar;
        String mailSentVerificationMsg;
        List<EmailTemplate> emailTemplateToSendEventNotification;

    try{
        String dateToSend = SFZoom_MeetingManagerUtility.changeDateFormat(zoomMeeting.Start_Date__c);
        String timeToSend = SFZoom_MeetingManagerUtility.changeTimeFormat(zoomMeeting.Start_Time__c);
        String emailContent = Label.Event_Invitation_Email_Line1;
        /*String userName = UserInfo.getUserName();
        User activeUser = [SELECT Email FROM User WHERE Username = : userName LIMIT 1];
        String userEmail = activeUser.Email;*/
        String userEmail = UserInfo.getUserEmail();
        if(zoomMeeting.Event_Type__c == Label.Meeting_Record_Type_Name){
            isWebinar = false;
        }else isWebinar = true;
        
        emailTemplateToSendEventNotification = [SELECT htmlValue FROM EmailTemplate 
                                                WHERE developername = :Label.Event_Invitation_Email_Template_Name LIMIT 1];
           		
        If(!emailTemplateToSendEventNotification.isEmpty()){
            mailBody = emailTemplateToSendEventNotification[0].htmlValue;
        }

        //Fetch the custom setting
        Zoom_Configuration_Settings__c zoomConfigurationDetails = Zoom_Configuration_Settings__c.getValues(Label.Config_Details_Custom_Setting_Name);
            If(zoomConfigurationDetails != null){
                if(String.isNotBlank(zoomConfigurationDetails.Site_URL__c)){
                    siteURL =  zoomConfigurationDetails.Site_URL__c.endsWith('/') ? zoomConfigurationDetails.Site_URL__c
                        : zoomConfigurationDetails.Site_URL__c + '/';
                }
                emailSenderName = zoomConfigurationDetails.Email_Sender_Name__c;
            }
        
        //For Auto Register Flag = False
        for(SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper invitee : listOfInvitees){
          String meetingDetails;
            if(invitee.recordId == whoId){
                mailBody = emailTemplateToSendEventNotification[0].htmlValue;
                
                if(!autoRegisterFlag){
                    meetingDetails = ' Type: '+ Label.Webinar_Record_Type_Name + 
                        ' Topic: '+ zoomMeeting.Topic__c + '<br/> Start Date: '+dateToSend + 
                        '<br/> Start Time: '+timeToSend +'<br/> Duration: '+zoomMeeting.Duration__c + ' Minutes' +
                        '<br/> Agenda: '+(String.isNotBlank(zoomMeeting.Agenda__c) ? zoomMeeting.Agenda__c : '' );
                    
                    if(String.isBlank(mailBody)){
                        mailBody = 'Hello '+ invitee.FirstName + emailContent + meetingDetails;
                    }
                    else{
                        if(String.isNotBlank(mailBody) && mailBody.containsIgnoreCase(Label.Invitee_Name)){
                            mailBody = mailBody.replace(Label.Invitee_Name, invitee.LastName);
                        }
                        if(String.isNotBlank(mailBody) && mailBody.containsIgnoreCase(Label.Meeting_or_Webinar_Details)){
                            mailBody = mailBody.replace(Label.Meeting_or_Webinar_Details, meetingDetails);
                        }    
                    }
               
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
                    
                    //Send Invitation Email To Registrant
                    mailSentVerificationMsg = SFZoom_MeetingManagerUtility.sendEmail(new List<String>{invitee.email}, null,
                                                                                     mailBody, null, emailSenderName, userEmail, 
                                                                                     Label.Event_Invitation_Subject_Label, invitee.RecordId, 
                                                                                     null);
                }
                
                //For Auto Register Flag = True
                if(autoRegisterFlag){
                    SFZoom_MeetingHandlerExtension.AddMeetingOrWebinarRegistrantForAutoRegistration(invitee.firstName, invitee.lastName, invitee.email, 
                                                                                                    zoomMeeting.Name, invitee.RecordId, null, zoomMeeting.Id, isWebinar);
                }
            }
        }
       }catch(Exception exe){
           System.debug('Zoom Utils sendEmailToInvitees - Exception: ' + exe.getMessage());
       }
     return errorMessage;
    }
}