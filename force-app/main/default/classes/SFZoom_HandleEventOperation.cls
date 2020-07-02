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
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHERq
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
 */

/******************************************************************************************************************
    Class Name  : SFZoom_HandleEventOperation
    Description : This class is responsible for managing event invitaion accepetance and declination in a separte call.
                  Site user doesn't have permission to edit the event object. So, We have this class as without sharing
                  to update the event details
    Date        : 18 Jan 2019
    Author       : DataColada Pty Ltd
*******************************************************************************************************************/
global without sharing class SFZoom_HandleEventOperation {
    
    /******************************************************************************************************************
        Method Name : AddRegistrantsAndUpdateEvent
        Description : It updates event status if invitee decline the invitation
        Date        : 18 Jan 2019.
        Parameter1  : whoId - It contains the contact/lead id of the event
        Parameter2  : salesforceZoomMeetingId - It contains salesforce Zoom Meeting record id
        Parameter3  : requestBody - It contains request body for the Http call
        Parameter4  : meetingId - It contains the Zoom Meeting id
        Parameter5  : eventType - It contains the event type (Webinar/Meeting)
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/  
    @future(callout=true)
    public static void AddRegistrantsAndUpdateEvent(String whoId, String salesforceZoomMeetingId, String requestBody, 
                                                    String meetingId, String eventType){
        try{
            HTTPResponse response;
            if(eventType.equalsIgnoreCase(Label.Meeting_Record_Type_Name)){
                response = SFZoom_MeetingManagerUtility.AddMeetingRegistrants(meetingId, requestBody);
            }
            else{
                response = SFZoom_MeetingManagerUtility.AddWebinarRegistrants(meetingId, requestBody);
            }
            Map<String,Object> mapOfResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            List<String> listOfEventFields = new List<String>{'Zoom_Registration_Status__c', 
                'Joining_URL__c', 'Zoom_Registration_Id__c', 'WhoId', 'Zoom_Meeting__c' };
            List<Event> listOfEventsToUpdate;
            if(SFZoom_AccessUtil.objectIsAccessible('Event') && SFZoom_AccessUtil.objectIsQueryable('Event') 
                    && SFZoom_AccessUtil.fieldsAreAccessible('Event', listOfEventFields)){                    
                listOfEventsToUpdate = [SELECT Zoom_Registration_Status__c, Joining_URL__c,
                                        Zoom_Registration_Id__c FROM Event 
                                        WHERE WhoId = :String.escapeSingleQuotes(whoId)
                                        AND Zoom_Meeting__c = :String.escapeSingleQuotes(salesforceZoomMeetingId)];
                if(listOfEventsToUpdate != null && !listOfEventsToUpdate.isEmpty()){
                    listOfEventsToUpdate[0].Zoom_Registration_Status__c = Label.Registered_Meeting_Status;
                    listOfEventsToUpdate[0].Zoom_Registration_Id__c = (String)mapOfResponse.get('registrant_id'); 
                    listOfEventsToUpdate[0].Joining_URL__c = (String)mapOfResponse.get('join_url');
                    //False Positive - The site user license doesn't allow to have the permission: Edit Events
                    //INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, insufficient access rights on object
                    UPDATE listOfEventsToUpdate;
                }
            }
        }Catch(Exception ex){
            System.debug('SFZoom_HandleEventOperation - AddRegistrantsAndUpdateEvent - Exception: ' + ex.getMessage());
        }
    }
    
   /******************************************************************************************************************
        Method Name : UpdateEventForDeclinedInvitation
        Description : It updates event status if invitee decline the invitation
        Date        : 17 Jan 2019
        Parameter1  : whoId - It contains the contact/lead id of the event
        Parameter2  : salesforceZoomMeetingId - It contains salesforce Zoom Meeting record id
        Author       : DataColada Pty Ltd
        *******************************************************************************************************************/  
    @future
    public static void UpdateEventForDeclinedInvitation(String whoId, String salesforceZoomMeetingId ){
        try{
            List<Event> listOfEventsToUpdate;
            List<String> listOfEventFields = new List<String>{'Zoom_Registration_Status__c','WhoId', 'Zoom_Meeting__c'};
            if(SFZoom_AccessUtil.objectIsAccessible('Event') && SFZoom_AccessUtil.objectIsQueryable('Event') 
               && SFZoom_AccessUtil.fieldsAreAccessible('Event', listOfEventFields)){
                listOfEventsToUpdate = [SELECT Zoom_Registration_Status__c, Joining_URL__c,
                                        Zoom_Registration_Id__c FROM Event 
                                        WHERE WhoId = :String.escapeSingleQuotes(whoId)
                                        AND Zoom_Meeting__c = :String.escapeSingleQuotes(salesforceZoomMeetingId)];
                
                listOfEventsToUpdate[0].Zoom_Registration_Status__c = Label.Declined_Meeting_Status;
                //False Positive - The site user license doesn't allow to have the permission: Edit Events
                //INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, insufficient access rights on object
                UPDATE listOfEventsToUpdate;
            }
        }Catch(Exception ex){
            System.debug('SFZoom_HandleEventOperation - UpdateEventForDeclinedInvitation - Exception: ' + ex.getMessage());
        }        
    } 
    
    /******************************************************************************************************************
        Method Name : FetchRecordsWithoutAccessCheck
        Description : It fetches records from salesforce wihthout checking the access.
        Date        : 05 Feb 2019
        Parameter1  : queryToExecute - It contains the query to execute
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/ 
    public static List<sObject> FetchRecordsWithoutAccessCheck(String queryToExecute){
        // False Positive - We have to access the lead/contact records on the site irrespective of the user permission.
        List<sObject> listOfRecords;
        try{
            listOfRecords = Database.query(queryToExecute);
        }Catch(Exception ex){
            System.debug('SFZoom_HandleEventOperation - FetchRecordsWithoutAccessCheck - Exception: ' + ex.getMessage());
        }
        return listOfRecords;
    }
    
    /***********************************************************************`*******************************************
        Method Name : UpdateEventAttendeeStatus
        Description : It updates status of the event attendee to 'Attended' based on the response.
        Date        : 05 Feb 2019
        Parameter1  : listOfEventsToUpdate - It contains list of events which has to update
        Author       : DataColada Pty Ltd
        *******************************************************************************************************************/ 
    public static void UpdateEventAttendeeStatus(List<Event> listOfEventsToUpdate){
        try{
            // False Positive - We have to update the event records in the web service irrespective of the user permission.
            UPDATE listOfEventsToUpdate;
        }Catch(Exception ex){
            System.debug('SFZoom_HandleEventOperation - UpdateEventAttendeeStatus - Exception: ' + ex.getMessage());
        }        
    }
}