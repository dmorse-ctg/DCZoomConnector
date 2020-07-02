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
    Class Name  : SFZoomServiceToUpdatePrcipntsDetail_Test
    Description : This class is responsible for testing the webhook response and the meeting attandance Tracking.
    Date        : 05 Dec 2018.
    Author       : DataColada Pty Ltd
*******************************************************************************************************************/
@isTest(seeAllData = false)
public class SFZoomServiceToUpdatePrcipntsDetail_Test {
/*******************************************************************************************************************
        Method Name  : testUpdateMeetingParticipantDetails
        Description  : It verifies update meeting participants detail operation after receiving the webhook response.
        Date         : 05 Dec 2018.
        Author       : DataColada Pty Ltd    
********************************************************************************************************************/
    @isTest
    static void testUpdateMeetingParticipantDetails(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test', Email='testlead@mailinator.com');
        insert testContact;
        Campaign campaignInserted = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembers(testLead.Id);
        System.assertNotEquals(null, campaignInserted.Id);
        Zoom_Meeting__c zoomMeetingCreated = SFZoom_MeetingHandlerExtension_Test.createZoomMeeting();
        System.assertNotEquals(null, zoomMeetingCreated.Id);
        zoomMeetingCreated.Campaign__c = campaignInserted.Id;
        zoomMeetingCreated.Thank_you_notification__c = true;
        zoomMeetingCreated.Share_Survey_Link__c = true;
        zoomMeetingCreated.Share_Recording_URL__c = true;
        zoomMeetingCreated.Survey_Link_URL__c = 'https://www.testsurvey.com';
        zoomMeetingCreated.Meeting_Recording_URL__c = 'https://www.myrecording.com';
        UPDATE zoomMeetingCreated;   
        
        Event eventCreated = SFZoom_MeetingHandlerExtension_Test.CreateEvent(zoomMeetingCreated.Id, testContact.Id,campaignInserted.Id);
        System.assertNotEquals(null, eventCreated.Id);
       	ApexPages.currentPage().getParameters().put('retURL','/'+campaignInserted.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
        new ApexPages.StandardController(new Zoom_Meeting__c(Id=zoomMeetingCreated.Id, 
                                                                         Campaign__c = zoomMeetingCreated.Campaign__c, 
                                                                         RecordTypeId = zoomMeetingCreated.RecordTypeId)));
        String testResponse = '{"uuid":"sojydbtWQSuPOOA/VEcDGA==","id":998995105,"account_id":"0o9aggZHT02Bxxb2h1MW4Q","host_id":"Qi79NR8_TXqkvj4uV5GBzg","topic":"zoom meeting wed","type":2,"start_time":"2019-03-11T11:45:29Z","timezone":"Australia/Sydney","duration":1,"total_size":285719,"recording_count":2,"share_url":"https://api.test.com"}';
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UpdateMeetingParticipantsDetail';
        req.httpMethod = 'POST';
        String contentToParse = '{"payload":{"account_id":"0o9aggZHT02Bxxb2h1MW4Q","meeting":{"duration":60,"status":"ENDED","start_time":"2018-09-06T14:11:02Z","timezone":"Asia/Calcutta","end_time":"","topic":"Meeting","id":"661257541","uuid":"QY/MSvURSiGOjrfRs/hEBg==","host_id":"Qi79NR8_TXqkvj4uV5GBzg"}},"event":"meeting_ended"}';        
        req.requestBody = Blob.valueof(contentToParse);
        RestContext.request = req;
        RestContext.response= res;
        
         List<Event> lisOfEvents = [SELECT ID, Zoom_Meeting_Attendance__c FROM Event where Zoom_Meeting__c = :zoomMeetingCreated.Id];
            for(Event eventVar : lisOfEvents){
                eventVar.Zoom_Meeting_Attendance__c = Label.Meeting_Attended_Value;                
            }
        UPDATE lisOfEvents;
        
        SFZoomServiceToUpdateParticipantsDetails.UpdateMeetingParticipantDetails();
        SFZoomServiceToUpdateParticipantsDetails.FindRecordingPlayUrl(testResponse);
        Test.stopTest();
        List<Zoom_Meeting__c> listOfZoomMeeting = [SELECT Webhook_Response__c FROM Zoom_Meeting__c
                                                           WHERE Name = '661257541' LIMIT 1];
        System.assertEquals(contentToParse, listOfZoomMeeting[0].Webhook_Response__c);    
    }
    
    /*******************************************************************************************************************
        Method Name  : testUpdateMeetingParticipantDetails
        Description  : It verifies update meeting participants detail operation after receiving the webhook response.
        Date         : 30 Apr 2019.
        Author       : DataColada Pty Ltd    
********************************************************************************************************************/
    @isTest
    static void testUpdateMeetingParticipantDetails_Cancellation(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        Campaign campaignInserted = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembers(testLead.Id);
        System.assertNotEquals(null, campaignInserted.Id);
        Zoom_Meeting__c zoomMeetingCreated = SFZoom_MeetingHandlerExtension_Test.createZoomMeeting();
        System.assertNotEquals(null, zoomMeetingCreated.Id);
        zoomMeetingCreated.Campaign__c = campaignInserted.Id;
        zoomMeetingCreated.Thank_you_notification__c = true;
        zoomMeetingCreated.Share_Survey_Link__c = true;
        zoomMeetingCreated.Share_Recording_URL__c = true;
        zoomMeetingCreated.Survey_Link_URL__c = 'https://www.testsurvey.com';
        zoomMeetingCreated.Meeting_Recording_URL__c = 'https://www.myrecording.com';
        UPDATE zoomMeetingCreated;   
        
        Event eventCreated = SFZoom_MeetingHandlerExtension_Test.CreateEvent(zoomMeetingCreated.Id, testLead.Id,null);
        System.assertNotEquals(null, eventCreated.Id);
        eventCreated.Zoom_Registration_Id__c = 'zBEzSk_NQgi3go7jsPm-fw';
        UPDATE eventCreated; 
       	ApexPages.currentPage().getParameters().put('retURL','/'+campaignInserted.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
        new ApexPages.StandardController(new Zoom_Meeting__c(Id=zoomMeetingCreated.Id, 
                                                                         Campaign__c = zoomMeetingCreated.Campaign__c, 
                                                                         RecordTypeId = zoomMeetingCreated.RecordTypeId)));
        String testResponse = '{"uuid":"sojydbtWQSuPOOA/VEcDGA==","id":998995105,"account_id":"0o9aggZHT02Bxxb2h1MW4Q","host_id":"Qi79NR8_TXqkvj4uV5GBzg","topic":"zoom meeting wed","type":2,"start_time":"2019-03-11T11:45:29Z","timezone":"Australia/Sydney","duration":1,"total_size":285719,"recording_count":2,"share_url":"https://api.test.com"}';
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/UpdateMeetingParticipantsDetail';
        req.httpMethod = 'POST';
        
        String contentToParse = '{"event": "meeting.registration_cancelled","payload":{"account_id": "0o9aggZHT02Bxxb2h1MW4Q","operator": "apurva.ghatge7@gmail.com","object":{"uuid": "UGv3SZYXSxO2AfkmJozgsA==","id": 607248205,"host_id": "Qi79NR8_TXqkvj4uV5GBzg","topic": "test 1","type": 2,"start_time": "2019-04-24T15:30:00Z","duration": 35,"timezone": "Australia/Sydney","registrant":{"id": "zBEzSk_NQgi3go7jsPm-fw","first_name": "Test Demo","last_name": "Lead","email": "apurva.ghatge7@gmail.com"}}}}';
        req.requestBody = Blob.valueof(contentToParse);
        RestContext.request = req;
        RestContext.response= res;
        
         List<Event> lisOfEvents = [SELECT ID, Zoom_Meeting_Attendance__c FROM Event where Zoom_Meeting__c = :zoomMeetingCreated.Id];
            for(Event eventVar : lisOfEvents){
                //eventVar.Zoom_Meeting_Attendance__c = Label.Meeting_Attended_Value;
                eventVar.Zoom_Meeting_Attendance__c = Label.Meeting_Cancelled_Value;
            }
        UPDATE lisOfEvents;        
        SFZoomServiceToUpdateParticipantsDetails.UpdateMeetingParticipantDetails();
        
        Test.stopTest();          
    }
}