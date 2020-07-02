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
    Class Name  : SFZoom_LightningEventHandler_Test
    Description : This class is responsible for testing all the operation of SFZoom_LightningEventHandler Class.
    Date        : 03 Jan 2019.
    Author      : DataColada Pty Ltd
*******************************************************************************************************************/
@isTest(seeAllData = false)
public class SFZoom_LightningEventHandler_Test {
    
    /******************************************************************************************************************
        Method Name  : testGetZoomEvent 
        Description : This method checks meeting record are fetched, its record id is also fetched and config setting is loaded
        Date        : 03 Jan 2019.
        Author      : DataColada Pty Ltd
	*******************************************************************************************************************/    
    @isTest
    static void testGetZoomEvent(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembers(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = SFZoom_MeetingHandlerExtension_Test.createZoomMeeting();
        System.assertNotEquals(null, testMeeting.Id);
        
        Test.startTest();
        Map<String, Object> zoomEventDetail = SFZoom_LightningEventHandler.getZoomEventDetails(testMeeting.Id);
        Map<String, String> recTypeDetail = SFZoom_LightningEventHandler.getRecordTypeDetails();
        Zoom_Meeting__c existingConfig = SFZoom_LightningEventHandler.loadExistingConfiguration();
        Test.stopTest();
        System.assertNotEquals(null, zoomEventDetail.keyset());
        System.assertNotEquals(null, recTypeDetail.keyset());
        System.assertNotEquals(null, existingConfig);
    }   
        
    /******************************************************************************************************************
        Method Name  : testInsertMeetingZoomEvent
        Description : This method checks meeting record is getting Inserted in database
        Date        : 03 Jan 2019.
        Author      : DataColada Pty Ltd
	*******************************************************************************************************************/ 
    @isTest
    static void testInsertMeetingZoomEvent(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembers(testLead.Id); 
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = SFZoom_MeetingHandlerExtension_Test.createZoomMeeting();        
        System.assertNotEquals(null, testMeeting.Id);        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        Zoom_Meeting__c zoomMeeting = new Zoom_Meeting__c();
        zoomMeeting.Agenda__c = 'Test Meeting Agenda2';
        zoomMeeting.Start_Date__c = System.today();
        zoomMeeting.Start_Time__c = Time.newInstance(18, 30, 2, 20);
        zoomMeeting.Duration__c = 35;
        zoomMeeting.Topic__c = 'Test Meeting Topic2';
        zoomMeeting.Join_before_Host__c = true;
        zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        zoomMeeting.Enforce_Login__c = false;
        zoomMeeting.Campaign__c = campaignToTest.Id;
        
        String zoomEventJson = JSON.serialize(zoomMeeting);
        zoomEventJson = zoomEventJson.replace('"Start_Time__c":"18:30:02.020Z"', '"Start_Time__c":1545322');
        Map<String, Object> insertMeeting = SFZoom_LightningEventHandler.upsertZoomEvent(zoomEventJson , campaignToTest.id, Label.Meeting_Record_Type_Name);        
        System.assertNotEquals(null, insertMeeting.get('attendees'));
        SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper newInviteWrapper = new SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper();
        newInviteWrapper.lastName = 'Test LastName';
        newInviteWrapper.email = 'email@testmethod.com';
        newInviteWrapper.isSelected = true;
        newInviteWrapper.type = 'Lead';
        newInviteWrapper.recordId = (String) testLead.Id;
		Map<Boolean, String> result = SFZoom_LightningEventHandler.sendInviteEmail(testMeeting.Id,null, false, 
                                                                                   JSON.serialize(new List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper>{newInviteWrapper}));        
        Test.stopTest();
        System.assertEquals(Label.Email_Successfully_Sent_Message, result.get(true));
    }
    
    /******************************************************************************************************************
        Method Name  : testSendThankYouEmail
        Description : This method checks thank you email sent.
        Date        : 26 Mar 2019.
        Author      : DataColada Pty Ltd
	*******************************************************************************************************************/ 
    @isTest
    static void testSendThankYouEmail(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembers(testLead.Id); 
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = SFZoom_MeetingHandlerExtension_Test.createZoomMeeting();        
        System.assertNotEquals(null, testMeeting.Id);     
        
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        Zoom_Meeting__c zoomMeeting = new Zoom_Meeting__c();
        zoomMeeting.Agenda__c = 'Test Meeting Agenda2';
        zoomMeeting.Start_Date__c = System.today();
        zoomMeeting.Start_Time__c = Time.newInstance(18, 30, 2, 20);
        zoomMeeting.Duration__c = 35;
        zoomMeeting.Topic__c = 'Test Meeting Topic2';
        zoomMeeting.Join_before_Host__c = true;
        zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        zoomMeeting.Enforce_Login__c = false;
        zoomMeeting.Campaign__c = campaignToTest.Id;
        zoomMeeting.Thank_you_notification__c = true;
        zoomMeeting.Share_Survey_Link__c = true;
        zoomMeeting.Survey_Link_URL__c = 'https://testsurverylink.com';
        zoomMeeting.Share_Recording_URL__c = true;
        
        String zoomEventJson = JSON.serialize(zoomMeeting);
        zoomEventJson = zoomEventJson.replace('"Start_Time__c":"18:30:02.020Z"', '"Start_Time__c":1545322');
        Map<String, Object> insertMeeting = SFZoom_LightningEventHandler.upsertZoomEvent(zoomEventJson , campaignToTest.id, Label.Meeting_Record_Type_Name);        
                
        SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper newInviteWrapper = new SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper();
        newInviteWrapper.lastName = 'Test LastName';
        newInviteWrapper.email = 'email@testmethod.com';
        newInviteWrapper.isSelected = true;
        newInviteWrapper.type = 'Lead';
        newInviteWrapper.recordId = (String) testLead.Id;
		Map<Boolean, String> result = SFZoom_LightningEventHandler.sendInviteEmail(testMeeting.Id,null, false, 
                                                                                   JSON.serialize(new List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper>{newInviteWrapper}));        
        List<Event> lisOfEvents = [SELECT ID, Zoom_Meeting_Attendance__c FROM Event where Zoom_Meeting__c = :testMeeting.Id];
        for(Event eventVar : lisOfEvents){
            eventVar.Zoom_Meeting_Attendance__c = Label.Meeting_Attended_Value;
        }
        UPDATE lisOfEvents;
        
        Test.startTest();
        Map<Boolean, String> result1 = SFZoom_LightningEventHandler.sendThankyouEmail(testMeeting.Id,  
                                      JSON.serialize(new List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper>{newInviteWrapper}));        
        
        Test.stopTest();
        System.assertEquals(Label.Email_Successfully_Sent_Message, result.get(true));
    }
    
    /******************************************************************************************************************
        Method Name  : testInsertWebinarZoomEvent
        Description : This method checks webinar record is getting Inserted in database
        Date        : 03 Jan 2019.
        Author      : DataColada Pty Ltd
	*******************************************************************************************************************/ 
    @isTest 
    static void testInsertWebinarZoomEvent(){
       SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembers(testLead.Id); 
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = SFZoom_MeetingHandlerExtension_Test.createZoomWebinar();        
        System.assertNotEquals(null, testMeeting.Id);        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        Zoom_Meeting__c zoomMeeting = new Zoom_Meeting__c();
        zoomMeeting.Agenda__c = 'Test Meeting Agenda2';
        zoomMeeting.Start_Date__c = System.today();
        zoomMeeting.Start_Time__c = Time.newInstance(18, 30, 2, 20);
        zoomMeeting.Duration__c = 35;
        zoomMeeting.Topic__c = 'Test Meeting Topic2';
        zoomMeeting.Join_before_Host__c = true;
        zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        zoomMeeting.Enforce_Login__c = false;
        zoomMeeting.Campaign__c = campaignToTest.Id;
        
        String zoomEventJson = JSON.serialize(zoomMeeting);
        Map<String, Object> insertWebinar = SFZoom_LightningEventHandler.upsertZoomEvent(zoomEventJson, campaignToTest.id, Label.Webinar_Record_Type_Name);
                       
        SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper newInviteWrapper = new SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper();
        newInviteWrapper.lastName = 'Test LastName';
        newInviteWrapper.email = 'email@testmethod.com';
        newInviteWrapper.isSelected = true;
        newInviteWrapper.type = 'Lead';
        newInviteWrapper.recordId = (String) testLead.Id;
		Map<Boolean, String> result = SFZoom_LightningEventHandler.sendInviteEmail(testMeeting.Id, null,false, 
                                     JSON.serialize(new List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper>{newInviteWrapper}));        
        Test.stopTest();
        System.assertEquals(Label.Email_Successfully_Sent_Message, result.get(true));
    }
    
    
    /******************************************************************************************************************
        Method Name  : testUpdateMeetingZoomEvent
        Description : This method checks meeting record is getting update in database
        Date        : 03 Jan 2019.
        Author      : DataColada Pty Ltd
	*******************************************************************************************************************/ 
    @isTest
    static void testUpdateMeetingZoomEvent(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembers(testLead.Id); 
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c zoomMeeting = SFZoom_MeetingHandlerExtension_Test.createZoomMeeting();        
        System.assertNotEquals(null, zoomMeeting.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        Zoom_Meeting__c zoomMeetingToUpdate = new Zoom_Meeting__c(id=zoomMeeting.Id);
        zoomMeetingToUpdate.Agenda__c = 'Test Updated Meeting Agenda';
        zoomMeetingToUpdate.Start_Date__c = System.today();
        zoomMeetingToUpdate.Duration__c = 45;
        zoomMeetingToUpdate.Topic__c = 'Test Updated Meeting Topic';
        zoomMeetingToUpdate.Join_before_Host__c = true;
        zoomMeetingToUpdate.Start_Participant_Video_on_Meeting_Join__c = true;
        zoomMeetingToUpdate.Enforce_Login__c = false;
        
        String jsonToUpdateZoomEvent = JSON.serialize(zoomMeetingToUpdate);
        Map<String, Object> updateMeeting = SFZoom_LightningEventHandler.upsertZoomEvent(jsonToUpdateZoomEvent, campaignToTest.id, Label.Meeting_Record_Type_Name);
        
        System.assertEquals(Label.Event_updated_successfully, updateMeeting.get('success'));               
        SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper newInviteWrapper = new SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper();
        newInviteWrapper.lastName = 'Test LastName';
        newInviteWrapper.email = 'email@testmethod.com';
        newInviteWrapper.isSelected = true;
        newInviteWrapper.type = 'Lead';
        newInviteWrapper.recordId = (String) testLead.Id;
		Map<Boolean, String> result = SFZoom_LightningEventHandler.sendInviteEmail(zoomMeetingToUpdate.Id, null,false, 
                                     JSON.serialize(new List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper>{newInviteWrapper}));        
        Test.stopTest();
        System.assertEquals(Label.Email_Successfully_Sent_Message, result.get(true));
    }
    
    /******************************************************************************************************************
        Method Name  : testNegativeScenarioMeeting
        Description : This method checks for error message thrown while creating meeting and sending invite email
        Date        : 11 Jan 2019.
        Author      : DataColada Pty Ltd
	*******************************************************************************************************************/ 
    @isTest
    static void testNegativeScenarioMeeting(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembers(testLead.Id); 
        System.assertNotEquals(null, campaignToTest.Id);        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false)); 
        Map<String, Object> insertMeeting = SFZoom_LightningEventHandler.upsertZoomEvent('{}' , campaignToTest.id, Label.Meeting_Record_Type_Name);        
        System.assertEquals('Review the errors on this page.', insertMeeting.get('error'));      
        SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper newInviteWrapper = new SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper();
        newInviteWrapper.lastName = 'Test LastName';
        newInviteWrapper.email = 'email@testmethod.com';
        newInviteWrapper.isSelected = true;
        newInviteWrapper.type = 'Lead';
        newInviteWrapper.recordId = (String) testLead.Id;
		Map<Boolean, String> result = SFZoom_LightningEventHandler.sendInviteEmail(null,null, false, 
                                      JSON.serialize(new List<SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper>{newInviteWrapper}));
        Test.stopTest();
        System.assertEquals(Label.Missing_meeting_detail, result.get(false));  
    }
    
    
    /******************************************************************************************************************
        Method Name  : testNegativeScenarioWOEventType
        Description : This method checks for error message thrown while creating meeting - Wrong event type
        Date        : 11 Jan 2019.
        Author      : DataColada Pty Ltd
	*******************************************************************************************************************/ 
    @isTest
    static void testNegativeScenarioWOEventType(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembers(testLead.Id); 
        System.assertNotEquals(null, campaignToTest.Id);        
                
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        Zoom_Meeting__c zoomMeeting = new Zoom_Meeting__c();
        zoomMeeting.Agenda__c = 'Test Meeting Agenda2';
        zoomMeeting.Start_Date__c = System.today();
        zoomMeeting.Duration__c = 35;
        zoomMeeting.Topic__c = 'Test Meeting Topic2';
        zoomMeeting.Join_before_Host__c = true;
        zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        zoomMeeting.Enforce_Login__c = false;
        
        String jsonToSend = JSON.serialize(zoomMeeting);
        jsonToSend = jsonToSend.replace('"Start_Time__c":"18:30:02.020Z"', '"Start_Time__c":1545322');
        Map<String, Object> upsertEvent = SFZoom_LightningEventHandler.upsertZoomEvent(jsonToSend, campaignToTest.id, null);
    	Test.stopTest();
        System.assertEquals(Label.Wrong_event_type, upsertEvent.get('error'));
    }
    
    /******************************************************************************************************************
        Method Name  : testNegativeScenarioWOParentId
        Description : This method checks for error message thrown while creating meeting - Invalid/Missing set up object detail
        Date        : 11 Jan 2019.
        Author      : DataColada Pty Ltd
	*******************************************************************************************************************/ 
    @isTest
    static void testNegativeScenarioWOParentId(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
                
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false)); 
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        Zoom_Meeting__c zoomMeeting = new Zoom_Meeting__c();
        zoomMeeting.Agenda__c = 'Test Meeting Agenda2';
        zoomMeeting.Start_Date__c = System.today();
        zoomMeeting.Duration__c = 35;
        zoomMeeting.Topic__c = 'Test Meeting Topic2';
        zoomMeeting.Join_before_Host__c = true;
        zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        zoomMeeting.Enforce_Login__c = false;
        String jsonToSend = JSON.serialize(zoomMeeting);
        
        Map<String, Object> upsertEvent = SFZoom_LightningEventHandler.upsertZoomEvent(jsonToSend, null, Label.Meeting_Record_Type_Name);
    	Test.stopTest();
        System.assertEquals('Invalid/Missing set up object detail', upsertEvent.get('error'));
    }
    
}