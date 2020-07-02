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
    Class Name  : SFZoom_ConfigParticipationController
    Description : This class is responsible for managing event invitaion accepetance and declination.
    Date        : 20 Nov 2018.
    Author       : DataColada Pty Ltd
*******************************************************************************************************************/
public with sharing class SFZoom_ConfigParticipationController {
    public Boolean isRegistered {get; set;}
    public Boolean isCancelled {get; set;}
    public ParticipantRegistrationDetails registrationDetails {get; set;}
    
    private String meetingId;
    private String recordId;
    private String childObjectName;
    private String contactEmailFieldAPIName;
    private String leadEmailFieldAPIName;
    private String emailValue;
    private String whoId;
    private String salesforceZoomMeetingId;
    private String eventType;
    private List<Event> listOfEvents;
        
    // Constructor code
    public SFZoom_ConfigParticipationController(){
        try{
            String encryptedRecordId = Apexpages.currentpage().getparameters().get('id');
            String salesforceEncryptedZoomMeetingId = Apexpages.currentpage().getparameters().get('meetingid');
            String parentObjectName = Apexpages.currentpage().getparameters().get('setupobj');
            String encryptedLeadId = Apexpages.currentpage().getparameters().get('leadid');
            String encryptedContactId = Apexpages.currentpage().getparameters().get('conid');
                        
            if(String.isNotBlank(encryptedRecordId) && String.isNotBlank(salesforceEncryptedZoomMeetingId) && String.isNotBlank(parentObjectName)){
                registrationDetails = new ParticipantRegistrationDetails();
                recordId = SFZoom_MeetingManagerUtility.DecryptData(encryptedRecordId);
                salesforceZoomMeetingId = SFZoom_MeetingManagerUtility.DecryptData(salesforceEncryptedZoomMeetingId);
                List<String> listOfZoomMeetingFields = new List<String>{'Name', 'Event_Type__c'};
                List<Zoom_Meeting__c> listOfZoomMeeting;
                String query = 'SELECT Name, Event_Type__c FROM Zoom_Meeting__c WHERE ID = \'' + String.escapeSingleQuotes(salesforceZoomMeetingId) +'\'';
                // False Positive - We have to query meeting details regardless of user's permission.
                listOfZoomMeeting = (List<Zoom_Meeting__c>)SFZoom_HandleEventOperation.FetchRecordsWithoutAccessCheck(query);
                
                If(listOfZoomMeeting != null && !listOfZoomMeeting.isEmpty()){
                    meetingId = listOfZoomMeeting[0].Name;
                    eventType = listOfZoomMeeting[0].Event_Type__c;
                }
                childObjectName = String.valueOf(Id.valueOf(recordId).getSObjectType());
                List<Zoom_Metadata__mdt> listOfMetaData = SFZoom_MeetingHandlerExtension.getMetadataDetails(parentObjectName);
                if(listOfMetaData == null || listOfMetaData.isEmpty()){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Event_Invitation_Apex_Error_Message));
                }
                else{
                    contactEmailFieldAPIName = listOfMetaData[0].Email_Field_API_Name_of_Contact__c;
                    leadEmailFieldAPIName = listOfMetaData[0].Email_Field_API_Name_of_Lead__c;
                    String registrationStatus;
                    String contactId;
                    String leadId;
                    if(String.isNotBlank(encryptedContactId)){
                        whoId = contactId = SFZoom_MeetingManagerUtility.DecryptData(encryptedContactId);
                    }
                    if(String.isNotBlank(encryptedLeadId)){
                        whoId = leadId = SFZoom_MeetingManagerUtility.DecryptData(encryptedLeadId);
                    }
                    List<String> listOfFields = new List<String>{'Zoom_Registration_Status__c', 'Joining_URL__c',
                                'Zoom_Registration_Id__c', 'WhoId', 'Zoom_Meeting__c' };
                    if(String.isNotBlank(whoId) && String.isNotBlank(salesforceZoomMeetingId)){
                        if(SFZoom_AccessUtil.objectIsAccessible('Event') && SFZoom_AccessUtil.objectIsQueryable('Event') 
                            && SFZoom_AccessUtil.fieldsAreAccessible('Event', listOfFields)){
                            String eventQuery = 'SELECT Zoom_Registration_Status__c, Joining_URL__c,'+
                                    'Zoom_Registration_Id__c FROM Event '+
                                    'WHERE WhoId = \'' + String.escapeSingleQuotes(whoId) + 
                                    '\' AND Zoom_Meeting__c = \'' + String.escapeSingleQuotes(salesforceZoomMeetingId) +'\'';
                            // False Positive - We have to access the contact record irrespective of the site user access to the record
                            listOfEvents = (List<Event>)SFZoom_HandleEventOperation.FetchRecordsWithoutAccessCheck(eventQuery);
                            if(listOfEvents != null && !listOfEvents.isEmpty()){
                                registrationStatus = listOfEvents[0].Zoom_Registration_Status__c;
                            }
                        }
                    }
                    
                    if(String.isNotBlank(registrationStatus) && registrationStatus.equalsIgnoreCase(Label.Registered_Meeting_Status)){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Event_Invitation_Already_Registered_Message));
                        isRegistered = true;
                    }else{
                        List<String> listOfConOrLeadFields = new List<String>{'FirstName', 'LastName', contactEmailFieldAPIName};
                        if(String.isNotBlank(encryptedContactId)){
                            if(SFZoom_AccessUtil.objectIsAccessible('Contact') && SFZoom_AccessUtil.objectIsQueryable('Contact') 
                                && SFZoom_AccessUtil.fieldsAreAccessible('Contact', listOfConOrLeadFields)){
                                String contactQuery = 'SELECT FirstName, LastName, '+
                                    String.escapeSingleQuotes(contactEmailFieldAPIName)+ ' FROM Contact WHERE ID = \'' +
                                    String.escapeSingleQuotes(contactId) +'\' LIMIT 1';
                                // False Positive - We have to access the contact record irrespective of the site user access to the record
                                List<sObject> listOfContact = SFZoom_HandleEventOperation.FetchRecordsWithoutAccessCheck(contactQuery);
                                if(!listOfContact.isEmpty()){
                                    registrationDetails.first_name = listOfContact[0].get('FirstName') != null ? String.valueOf(listOfContact[0].get('FirstName')) : '';
                                    registrationDetails.last_name = listOfContact[0].get('LastName') != null ? String.valueOf(listOfContact[0].get('LastName')) : '';
                                    emailValue = registrationDetails.email = listOfContact[0].get(contactEmailFieldAPIName) != null 
                                                                ? String.valueOf(listOfContact[0].get(contactEmailFieldAPIName)) : '';
                                }
                            }
                        }else if(String.isNotBlank(encryptedLeadId)){
                            if(SFZoom_AccessUtil.objectIsAccessible('Lead') && SFZoom_AccessUtil.objectIsQueryable('Lead') 
                                && SFZoom_AccessUtil.fieldsAreAccessible('Lead', listOfConOrLeadFields)){
                                String leadQuery = 'SELECT FirstName, LastName, '+
                                    String.escapeSingleQuotes(leadEmailFieldAPIName)+ ' FROM Lead WHERE ID = \'' +
                                    String.escapeSingleQuotes(leadId) +'\' LIMIT 1';
                                    
                                List<sObject> listOfLead = SFZoom_HandleEventOperation.FetchRecordsWithoutAccessCheck(leadQuery);
                                    
                                if(!listOfLead.isEmpty()){
                                    registrationDetails.first_name = listOfLead[0].get('FirstName') != null ? String.valueOf(listOfLead[0].get('FirstName')) : '';
                                    registrationDetails.last_name = listOfLead[0].get('LastName') != null ? String.valueOf(listOfLead[0].get('LastName')) : '';
                                    registrationDetails.email = listOfLead[0].get(leadEmailFieldAPIName) != null ? 
                                            String.valueOf(listOfLead[0].get(leadEmailFieldAPIName)) : '';
                                }
                            }
                        }
                    }
                }
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Missing_Parameter_Error_Message));
            }
            
        }Catch(Exception ex){
            System.debug('SFZoom_ConfigParticipationController - Constructor - Exception: ' + ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Event_Invitation_Apex_Error_Message));
        }       
    }
    
    /******************************************************************************************************************
        Method Name  : AddMeetingRegistrant
        Description  : It adds that invitee as a meeting registrants in that Zoom Meeting and updates the status, 
                       registration id and joining URL of the relevant event record
        Date         : 07 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference AddMeetingRegistrant(){
        try{
            String requestBody = JSON.serialize(registrationDetails);
            if(String.isNotBlank(whoId) && String.isNotBlank(salesforceZoomMeetingId)){
                if(!listOfEvents.isEmpty()){
                    SFZoom_HandleEventOperation.AddRegistrantsAndUpdateEvent(whoId, salesforceZoomMeetingId, 
                                                                             requestBody, meetingId, eventType);                       
                    isRegistered = true;
                } 
            }

        }Catch(Exception ex){
            System.debug('SFZoom_ConfigParticipationController - AddMeetingRegistrant - Exception: ' + ex.getMessage());       
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Event_Invitation_Apex_Error_Message));
        }
        return null;
    }
    
    /******************************************************************************************************************
        Method Name  : AddMeetingRegistrantManually
        Description  : It adds that invitee as a meeting registrants in that Zoom Meeting and updates the status, 
                       registration id and joining URL of the relevant event record
        Date         : 07 Dec 2018.
        Author       : DataColada Pty Ltd
    ******************************************************************************************************************
    public PageReference AddMeetingRegistrantManually(){
        try{
        Campaign campaignID =  new Campaign (Id=ID.valueOf('7017F000000EeeU'));
            Contact contactID = new Contact (Id = ID.valueOf('0037F00000wuLrR'));
            
        ID campaignIdv=ID.valueOf('7017F000000EeeU');
          ID contactIdv = ID.valueOf('0037F00000wuLrR');  
        CampaignMember test = new CampaignMember();
        test.Status = 'Responded';
        test.CampaignId = campaignIdv;
        test.ContactId = contactIdv;               
        insert test;
       }catch(Exception exe){
           System.debug('Zoom Utils sendEmailToInvitees - Exception: ' + exe.getMessage());
       }
        return null;
    }*/
    
    /******************************************************************************************************************
        Method Name  : DeclineInvitation
        Description  : It changes event status value if meeting is declined by the user and updates the event record
        Date         : 20 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference DeclineInvitation(){
        try{
            if(string.isNotBlank(recordId)){
                if(String.isNotBlank(whoId) && String.isNotBlank(salesforceZoomMeetingId)){
                    if(!listOfEvents.isEmpty()){
                        SFZoom_HandleEventOperation.UpdateEventForDeclinedInvitation(whoId,salesforceZoomMeetingId);  
                        isCancelled = true;
                    } 
                }
            }  
        }Catch(Exception ex){
            System.debug('SFZoom_ConfigParticipationController - DeclineInvitation - Exception: ' + ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Event_Invitation_Apex_Error_Message));
        }
        return null;
    }
    
    /******************************************************************************************************************
        Class Name  : ParticipantRegistrationDetails
        Description : It is a wrapper class which holds attendee registration details.
        Date        : 20 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public without sharing Class ParticipantRegistrationDetails{
        public String email {get; set;}
        public String first_name {get; set;}
        public String last_name {get; set;}
    }
}