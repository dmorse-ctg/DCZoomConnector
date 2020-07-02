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
    Class Name  : SFZoom_MeetingHandlerExtension_Test
    Description : This class is responsible for testing all the operation of SFZoom_MeetingHandlerExtension Class.
    Date        : 01 Nov 2018.
    Author      : DataColada Pty Ltd
*******************************************************************************************************************/
@isTest(seeAllData = false)
public class SFZoom_MeetingHandlerExtension_Test {
    /******************************************************************************************************************
        Method Name  : testMeetingSave
        Description  : It verifies save operation of the inline VF page for meeting.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testMeetingSave(){
        InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id); 
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Test.startTest();
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id); 
        
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(new ApexPages.StandardController(campaignToTest));               
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(-1);
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);
        meetinghandlerExtensionTest.eventType='Meeting';
        meetinghandlerExtensionTest.CreateMeetingClassic();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 15;
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(12);
        
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 30;
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Join_before_Host__c = false;
        meetinghandlerExtensionTest.zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Enforce_Login__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Auto_Register__c = false;
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(false,true));
        PageReference meetingRef = meetinghandlerExtensionTest.CreateMeetingClassic();
        system.assertEquals(null,meetingRef);
        meetinghandlerExtensionTest.SelectAllInvitees();
        for (SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper inviteeDetails : meetinghandlerExtensionTest.listOfNotInvitedRecordDetails) {
            System.assertEquals(true, inviteeDetails.isSelected);   
        }       
        PageReference meetinfInviteCl = meetinghandlerExtensionTest.SendEmailInviteClassic();
        
        System.assertEquals(meetinfInviteCl.getURL(),ApexPages.currentPage().getParameters().get('retURL'));
        PageReference cancelOpPageReference = meetinghandlerExtensionTest.CancelOperation();
        Test.stopTest();
        System.assertEquals(cancelOpPageReference.getURL(),ApexPages.currentPage().getParameters().get('retURL'));
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(1, listOfCreatedZoomMeetings.size()); 
    }
    
    /******************************************************************************************************************
        Method Name  : testWebinarSave
        Description  : It verifies save operation of the inline VF page for webinar with Auto_Register__c as true.
        Date         : 07 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testWebinarSave(){
        InsertDefaultConfigSetting(); 
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id); 
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(false,true));   
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(new ApexPages.StandardController(campaignToTest));
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today(); 
        meetinghandlerExtensionTest.meetingStartTime = null;
        meetinghandlerExtensionTest.eventType='Webinar';     
        meetinghandlerExtensionTest.CreateWebinar(); 
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 1;
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 30;
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 30; 
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Join_before_Host__c = false;
        meetinghandlerExtensionTest.zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Enforce_Login__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(12);
        meetinghandlerExtensionTest.zoomMeeting.Auto_Register__c = true;
        PageReference meetingRef = meetinghandlerExtensionTest.CreateWebinar(); 
        System.assertEquals(null,meetingRef);
        meetinghandlerExtensionTest.SelectAllInvitees();        
        PageReference meetingInviteCl = meetinghandlerExtensionTest.SendEmailInviteClassic();
        Test.stopTest();
        System.assertEquals(meetingInviteCl.getURL(), ApexPages.currentPage().getParameters().get('retURL'));
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(1, listOfCreatedZoomMeetings.size());  
    }
    
    /******************************************************************************************************************
        Method Name  : testWebinarSaveAutoRegFalse
        Description  : It verifies save operation of the inline VF page for webinar with Auto_Register__c as false.
        Date         : 09 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testWebinarSaveAutoRegFalse(){
        InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        
        Contact testContact = new Contact(LastName = 'Test Weebles Contact', Email='Test@test.com');
        INSERT testContact;
        System.assertNotEquals(null, testContact.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testContact.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Test.startTest();
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);

        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(new ApexPages.StandardController(campaignToTest));
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(12);
        meetinghandlerExtensionTest.meetingStartTime = null;
        meetinghandlerExtensionTest.eventType='Webinar';        
        meetinghandlerExtensionTest.CreateWebinar(); 
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 1;
        
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 30;
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Join_before_Host__c = false;
        meetinghandlerExtensionTest.zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Enforce_Login__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(12);
        meetinghandlerExtensionTest.zoomMeeting.Auto_Register__c = FALSE;
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        PageReference meetingRef = meetinghandlerExtensionTest.CreateWebinar();
        system.assertEquals(null,meetingRef); 
        for (SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper inviteeDetails : meetinghandlerExtensionTest.listOfNotInvitedRecordDetails) {
            inviteeDetails.isSelected = false;   
        }        
        meetinghandlerExtensionTest.SendEmailInviteClassic();
        System.assertNotEquals(0, ApexPages.getMessages().size());
        meetinghandlerExtensionTest.SelectAllInvitees();
        for (SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper inviteeDetails : meetinghandlerExtensionTest.listOfNotInvitedRecordDetails) {
            System.assertEquals(true, inviteeDetails.isSelected);            
        }        
        meetinghandlerExtensionTest.SelectAllInvitees();        
        PageReference meetinfInviteCl = meetinghandlerExtensionTest.SendEmailInviteClassic();
        Test.stopTest();
        System.assertEquals(meetinfInviteCl.getURL(), ApexPages.currentPage().getParameters().get('retURL'));
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(1, listOfCreatedZoomMeetings.size());
        System.assertEquals(30, listOfCreatedZoomMeetings[0].Duration__c);
    }
    
    
    /******************************************************************************************************************
        Method Name  : testMeetingLightningSave
        Description  : It verifies save operation on the lightning  for meeting.
        Date         : 07 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testMeetingLightningSave(){
        InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Test.startTest();
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(false,false));
        
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(null,campaignToTest.Id, false);
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(12);              
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);        
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 30;        
        meetinghandlerExtensionTest.zoomMeeting.Join_before_Host__c = false;
        meetinghandlerExtensionTest.zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Enforce_Login__c = true;
        meetinghandlerExtensionTest.eventType= Label.Meeting_Record_Type_Name;
        String createLigMeetig = meetinghandlerExtensionTest.CreateMeetingLightning(false);
        system.assertEquals(meetinghandlerExtensionTest.zoomMeeting.id, createLigMeetig); 
        String sendEmailLighting = meetinghandlerExtensionTest.SendEmailInviteLightning(false);       
        Test.stopTest();
        System.assertEquals(null, sendEmailLighting);      
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(1, listOfCreatedZoomMeetings.size());
        System.assertEquals(30, listOfCreatedZoomMeetings[0].Duration__c);
    }
    
    
    /******************************************************************************************************************
        Method Name  : testWebinarLightningSave
        Description  : It verifies save operation on the lightning  for webinar.
        Date         : 07 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testWebinarLightningSave(){
        InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Test.startTest();
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(null,campaignToTest.Id, false);
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today()+12;
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 30;
        meetinghandlerExtensionTest.zoomMeeting.Join_before_Host__c = false;
        meetinghandlerExtensionTest.zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Enforce_Login__c = true;
        meetinghandlerExtensionTest.eventType= Label.Webinar_Record_Type_Name;
        String createLigMeeting = meetinghandlerExtensionTest.CreateMeetingLightning(true);        
        System.assertEquals(meetinghandlerExtensionTest.zoomMeeting.id, createLigMeeting);
        String sendEmailLighting = meetinghandlerExtensionTest.SendEmailInviteLightning(false);        
        Test.stopTest();
        System.assertEquals(null, sendEmailLighting);        
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(1, listOfCreatedZoomMeetings.size());
        System.assertEquals(30, listOfCreatedZoomMeetings[0].Duration__c); 
    }
    
     /******************************************************************************************************************
        Method Name  : testMeetingLightningUpdate
        Description  : It verifies update operation on the lightning  for meeting.
        Date         : 07 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testMeetingLightningUpdate(){
        InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = createZoomMeeting();
        System.assertNotEquals(null, testMeeting.Id);
        Event eventCreated = CreateEvent(testMeeting.Id, testLead.id, null);
        System.assertNotEquals(null, eventCreated.Id);
        Test.startTest();
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);        
        
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(testMeeting.Id,campaignToTest.Id, false);
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(12);
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);        
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 15; 
        meetinghandlerExtensionTest.zoomMeeting.Join_before_Host__c = false;
        meetinghandlerExtensionTest.zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Enforce_Login__c = true;
        meetinghandlerExtensionTest.eventType= Label.Meeting_Record_Type_Name;
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(false,false));
        String updateMeetingLig = meetinghandlerExtensionTest.UpdateMeetingDetailsLightning();
        System.assertEquals(testMeeting.Id, updateMeetingLig);
        String sendEmailLighting = meetinghandlerExtensionTest.SendEmailInviteLightning(true);
        Test.stopTest();
        System.assertEquals(null, sendEmailLighting);   
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(1, listOfCreatedZoomMeetings.size());        
        System.assertEquals(15, listOfCreatedZoomMeetings[0].Duration__c);
    }
    
    /******************************************************************************************************************
        Method Name  : testWebinarLightningUpdate
        Description  : It verifies update operation on the lightning  for webinar.
        Date         : 07 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testWebinarLightningUpdate(){
        InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = createZoomWebinar();
        System.assertNotEquals(null, testMeeting.Id);
        Event eventCreated = CreateEvent(testMeeting.Id, testLead.id,null);
        System.assertNotEquals(null, eventCreated.Id);
        Test.startTest();
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(testMeeting.Id,campaignToTest.Id, false);
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(12);
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);        
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 15;        
        meetinghandlerExtensionTest.zoomMeeting.Join_before_Host__c = false;
        meetinghandlerExtensionTest.zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Enforce_Login__c = true;
        meetinghandlerExtensionTest.eventType= Label.Webinar_Record_Type_Name;
        String updateMeetingLig = meetinghandlerExtensionTest.UpdateMeetingDetailsLightning();
        System.assertEquals(testMeeting.Id, updateMeetingLig);
        String sendEmailLighting = meetinghandlerExtensionTest.SendEmailInviteLightning(true);
        System.assertEquals(null, sendEmailLighting);
        meetinghandlerExtensionTest.UpdateMeetingDetailsLightning();
        Test.stopTest();
        System.assertNotEquals(null, meetinghandlerExtensionTest); 
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(1, listOfCreatedZoomMeetings.size());
        System.assertEquals(15, listOfCreatedZoomMeetings[0].Duration__c);
    }
    
    /******************************************************************************************************************
        Method Name  : testMeetingClassicUpdate
        Description  : It verifies update operation on the classic  for meeting.
        Date         : 07 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testMeetingClassicUpdate(){
        InsertDefaultConfigSetting(); 
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = createZoomMeeting();        
        System.assertNotEquals(null, testMeeting.Id);
        testMeeting.Campaign__c = campaignToTest.Id;
        UPDATE testMeeting;
        Test.startTest(); 
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(false,false));
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
                                                                    new ApexPages.StandardController(new Zoom_Meeting__c(Id=testMeeting.Id, 
                                                                    Campaign__c = testMeeting.Campaign__c, 
                                                                    RecordTypeId = testMeeting.RecordTypeId)));
        
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(-12);
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);
        meetinghandlerExtensionTest.eventType=Label.Meeting_Record_Type_Name;        
        meetinghandlerExtensionTest.UpdateMeetingDetailsClassic();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages(); 
        System.assertNotEquals(0, pageMessages.size());
        
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 15;
        
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(12);
        meetinghandlerExtensionTest.zoomMeeting.Join_before_Host__c = false;
        meetinghandlerExtensionTest.zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Enforce_Login__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Auto_Register__c = false;
        meetinghandlerExtensionTest.eventType= Label.Meeting_Record_Type_Name;
        PageReference updateMeetingRef = meetinghandlerExtensionTest.UpdateMeetingDetailsClassic();              
        System.assertEquals(updateMeetingRef.getURL(), ApexPages.currentPage().getParameters().get('retURL'));
        
        for (SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper inviteeDetails : meetinghandlerExtensionTest.listOfNotInvitedRecordDetails) {
            inviteeDetails.isSelected = false;   
        }
        meetinghandlerExtensionTest.SendEmailInviteClassic();
        System.assertNotEquals(0, ApexPages.getMessages().size());
        meetinghandlerExtensionTest.SelectAllInvitees();
        for (SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper inviteeDetails : meetinghandlerExtensionTest.listOfNotInvitedRecordDetails) {
            System.assertEquals(true, inviteeDetails.isSelected);            
        }
        PageReference sendMailRef = meetinghandlerExtensionTest.SendEmailInviteClassic();
        Test.stopTest();        
        System.assertEquals(sendMailRef.getURL(), ApexPages.currentPage().getParameters().get('retURL'));
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(1, listOfCreatedZoomMeetings.size());
        System.assertEquals(15, listOfCreatedZoomMeetings[0].Duration__c);
    }
    
    /******************************************************************************************************************
        Method Name  : testSendThankYouEmailNotification
        Description  : It inserts default custom setting for the zoom account configuration
        Date         : 20 Mar 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testSendThankYouEmailNotification(){
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = createZoomWebinar();
        System.assertNotEquals(null, testMeeting.Id);
        testMeeting.Campaign__c = campaignToTest.Id;
        UPDATE testMeeting;        
        
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
            new ApexPages.StandardController(new Zoom_Meeting__c(Id=testMeeting.Id, 
                                                                         Campaign__c = testMeeting.Campaign__c, 
                                                                         RecordTypeId = testMeeting.RecordTypeId)));
        ApexPages.Message[] pageMessages = ApexPages.getMessages(); 
        System.assertNotEquals(0, pageMessages.size());
        
        InsertDefaultConfigSetting();
        Test.startTest();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
            new ApexPages.StandardController(new Zoom_Meeting__c(Id=testMeeting.Id, 
                                                                         Campaign__c = testMeeting.Campaign__c, 
                                                                         RecordTypeId = testMeeting.RecordTypeId)));
        meetinghandlerExtensionTest.SelectAllInvitees();
        for (SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper inviteeDetails : meetinghandlerExtensionTest.listOfNotInvitedRecordDetails) {
            System.assertEquals(true, inviteeDetails.isSelected);            
        }
        PageReference sendMailRef = meetinghandlerExtensionTest.SendEmailInviteClassic();
        meetinghandlerExtensionTest.SendEmailInviteClassic();
        List<Event> lisOfEvents = [SELECT ID, Zoom_Meeting_Attendance__c FROM Event where Zoom_Meeting__c = :testMeeting.Id];
        for(Event eventVar : lisOfEvents){
            eventVar.Zoom_Meeting_Attendance__c = Label.Meeting_Attended_Value;
        }
        UPDATE lisOfEvents;
        meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
            new ApexPages.StandardController(new Zoom_Meeting__c(Id=testMeeting.Id, 
                                                                         Campaign__c = testMeeting.Campaign__c, 
                                                                         RecordTypeId = testMeeting.RecordTypeId)));
        
        meetinghandlerExtensionTest.zoomMeeting.Thank_you_notification__c = false;
        PageReference sendThankYouEmailPageRef = meetinghandlerExtensionTest.sendThankYouEmail();
        System.assertNotEquals(0, ApexPages.getMessages().size());
        meetinghandlerExtensionTest.zoomMeeting.Thank_you_notification__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Share_Survey_Link__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Survey_Link_URL__c = 'https://testsurverylink.com';
        meetinghandlerExtensionTest.zoomMeeting.Share_Recording_URL__c = true;
        UPDATE meetinghandlerExtensionTest.zoomMeeting;
        meetinghandlerExtensionTest.isFromLightning = true;        
        
        sendThankYouEmailPageRef = meetinghandlerExtensionTest.sendThankYouEmail();
        Test.stopTest();
        System.assertNotEquals(null, sendThankYouEmailPageRef);        
    }
    
    /******************************************************************************************************************
        Method Name  : testResetThankYouSettings
        Description  : It inserts default custom setting for the zoom account configuration
        Date         : 20 Mar 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testResetThankYouSettings(){
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = createZoomWebinar();
        System.assertNotEquals(null, testMeeting.Id);
        testMeeting.Campaign__c = campaignToTest.Id;
        UPDATE testMeeting;        
        
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
                                                            new ApexPages.StandardController(new Zoom_Meeting__c(Id=testMeeting.Id, 
                                                                         Campaign__c = testMeeting.Campaign__c, 
                                                                         RecordTypeId = testMeeting.RecordTypeId)));
        ApexPages.Message[] pageMessages = ApexPages.getMessages(); 
        System.assertNotEquals(0, pageMessages.size());
        
        InsertDefaultConfigSetting();
        Test.startTest();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
            new ApexPages.StandardController(new Zoom_Meeting__c(Id=testMeeting.Id, 
                                                                         Campaign__c = testMeeting.Campaign__c, 
                                                                         RecordTypeId = testMeeting.RecordTypeId)));
        meetinghandlerExtensionTest.zoomMeeting.Thank_you_notification__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Share_Survey_Link__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Share_Recording_URL__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Thank_you_notification__c = false;
        meetinghandlerExtensionTest.resetThankYouSetting();
        Test.stopTest();
        System.assertEquals(false, meetinghandlerExtensionTest.zoomMeeting.Share_Survey_Link__c);
        System.assertEquals(false, meetinghandlerExtensionTest.zoomMeeting.Share_Recording_URL__c);        
    }
    
    /******************************************************************************************************************
        Method Name  : testWebinarClassicUpdate
        Description  : It verifies update operation on the classic  for meeting.
        Date         : 07 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testWebinarClassicUpdate(){        
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = createZoomWebinar();
        System.assertNotEquals(null, testMeeting.Id);
        testMeeting.Campaign__c = campaignToTest.Id;
        UPDATE testMeeting;        
        
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
                                                            new ApexPages.StandardController(new Zoom_Meeting__c(Id=testMeeting.Id, 
                                                                         Campaign__c = testMeeting.Campaign__c, 
                                                                         RecordTypeId = testMeeting.RecordTypeId)));
        ApexPages.Message[] pageMessages = ApexPages.getMessages(); 
        System.assertNotEquals(0, pageMessages.size());
        
        InsertDefaultConfigSetting();
        Test.startTest();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
                                                            new ApexPages.StandardController(new Zoom_Meeting__c(Id=testMeeting.Id, 
                                                              Campaign__c = testMeeting.Campaign__c, 
                                                              RecordTypeId = testMeeting.RecordTypeId)));
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(12);
        meetinghandlerExtensionTest.meetingStartTime = null;
        meetinghandlerExtensionTest.UpdateWebinarDetailsClassic();
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size()); 
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);
        
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 15;
        meetinghandlerExtensionTest.zoomMeeting.Join_before_Host__c = false;
        meetinghandlerExtensionTest.zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Enforce_Login__c = true;
        meetinghandlerExtensionTest.eventType= Label.Webinar_Record_Type_Name;  
        PageReference updateWebinarRef = meetinghandlerExtensionTest.UpdateWebinarDetailsClassic();
        Test.stopTest();
        System.assertEquals(updateWebinarRef.getURL(), ApexPages.currentPage().getParameters().get('retURL'));
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(1, listOfCreatedZoomMeetings.size());
        System.assertEquals(15, listOfCreatedZoomMeetings[0].Duration__c);
    }
    
 
    /******************************************************************************************************************
        Method Name  : testMeetingVerifyDelete
        Description  : It verifies Delete operation of the inline VF page for meeting.
        Date         : 07 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testMeetingVerifyDelete(){
        InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = createZoomMeeting();
        System.assertNotEquals(null, testMeeting.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(false,false));
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        ApexPages.currentPage().getParameters().put('delID',testMeeting.Id);
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
            new ApexPages.StandardController(new Zoom_Meeting__c(Id=testMeeting.Id, 
                                                                         Campaign__c = testMeeting.Campaign__c, 
                                                                         RecordTypeId = testMeeting.RecordTypeId)));
        PageReference verifyDelPageReference = meetinghandlerExtensionTest.VerifyDeleteOperation();
        Test.stopTest();
        System.assertEquals(verifyDelPageReference.getUrl(), ApexPages.currentPage().getParameters().get('retURL'));
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(0, listOfCreatedZoomMeetings.size());        
    }
    
    /******************************************************************************************************************
        Method Name  : testWebinarVerifyDelete
        Description  : It verifies Delete operation of the inline VF page for Webinar.
        Date         : 07 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testWebinarVerifyDelete(){
        InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testWebinar = createZoomWebinar();
        System.assertNotEquals(null, testWebinar.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(true,false));
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        ApexPages.currentPage().getParameters().put('delID',testWebinar.Id);
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
            new ApexPages.StandardController(new Zoom_Meeting__c(Id=testWebinar.Id, 
                                                                         Campaign__c = testWebinar.Campaign__c, 
                                                                         RecordTypeId = testWebinar.RecordTypeId)));        
        PageReference verifyDelPageReference = meetinghandlerExtensionTest.VerifyDeleteOperation();
        Test.stopTest();
        System.assertEquals(verifyDelPageReference.getUrl(), ApexPages.currentPage().getParameters().get('retURL'));
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertEquals(0, listOfCreatedZoomMeetings.size());        
    }
    
    /******************************************************************************************************************
        Method Name  : testMeetingSaveWithAutoRegister
        Description  : It verifies save operation of the inline VF page with auto register option checked.
        Date         : 12 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testMeetingSaveWithAutoRegister(){
        InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(false,false));
        ApexPages.currentPage().getParameters().put('retURL','/'+campaignToTest.Id);
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(new ApexPages.StandardController(campaignToTest));
        meetinghandlerExtensionTest.zoomMeeting.Topic__c = 'Test Meeting Topic';
        meetinghandlerExtensionTest.zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(-1);
        meetinghandlerExtensionTest.meetingStartTime = null;        
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 1;       
        
        meetinghandlerExtensionTest.CreateMeetingClassic();
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 30;
        meetinghandlerExtensionTest.zoomMeeting.Join_before_Host__c = false;
        meetinghandlerExtensionTest.zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Enforce_Login__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Auto_Register__c = true;
        meetinghandlerExtensionTest.zoomMeeting.Start_Date__c = System.today().addDays(6);
        meetinghandlerExtensionTest.eventType= Label.Meeting_Record_Type_Name;
             
        PageReference createdMeetingRef = meetinghandlerExtensionTest.CreateMeetingClassic();
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Name FROM Zoom_Meeting__c];             
        System.assertEquals(1, listOfCreatedZoomMeetings.size());

        for (SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper inviteeDetails : meetinghandlerExtensionTest.listOfNotInvitedRecordDetails) {
            inviteeDetails.isSelected = false;   
        }
        meetinghandlerExtensionTest.SendEmailInviteClassic();
        System.assertNotEquals(0, ApexPages.getMessages().size());
        meetinghandlerExtensionTest.SelectAllInvitees();
        for (SFZoom_MeetingHandlerExtension.InviteeDetailsWrapper inviteeDetails : meetinghandlerExtensionTest.listOfNotInvitedRecordDetails) {
            System.assertEquals(true, inviteeDetails.isSelected);   
        }
        PageReference pageToRedirect = meetinghandlerExtensionTest.SendEmailInviteClassic();
        Test.stopTest();
        System.assertEquals(ApexPages.currentPage().getParameters().get('retURL'), pageToRedirect.getUrl());
    }
    
    
    
    /******************************************************************************************************************
        Method Name  : testExistingMeetingUpdateAndCancel
        Description  : It verifies update and cancel operation of the inline VF page.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testExistingMeetingUpdateAndCancel(){
        InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testLead = new Contact(FirstName = 'Test', LastName = 'Weebles Lead Test',  Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembersOfContact(testLead.Id);
        System.assertNotEquals(null, campaignToTest.Id);
        Zoom_Meeting__c testMeeting = createZoomMeeting();
        System.assertNotEquals(null, testMeeting.Id);
        Test.startTest();
        System.assertNotEquals(null, testMeeting.Id);
        Event eventCreated = CreateEvent(testMeeting.Id, testLead.id,null);
        System.assertNotEquals(null, eventCreated.Id);
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(false,false));
        SFZoom_MeetingHandlerExtension meetinghandlerExtensionTest = new SFZoom_MeetingHandlerExtension(
            new ApexPages.StandardController(new Zoom_Meeting__c(Id=testMeeting.Id, 
                                                                         Campaign__c = testMeeting.Campaign__c, 
                                                                         RecordTypeId = testMeeting.RecordTypeId)));  
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
       
        meetinghandlerExtensionTest.eventType= Label.Meeting_Record_Type_Name;
        pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size());
        meetinghandlerExtensionTest.meetingStartTime = Time.newInstance(18, 30, 2, 20);
        meetinghandlerExtensionTest.zoomMeeting.Duration__c = 60;
        ApexPages.currentPage().getParameters().put('meetingIdSF','/'+testMeeting.Id);
        ApexPages.currentPage().getParameters().put('delID',testMeeting.Id);
        
        List<Zoom_Meeting__c> listOfUpdatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        System.assertNotEquals(null, listOfUpdatedZoomMeetings);
        
        System.assertEquals(true, meetinghandlerExtensionTest.isEditEnabled);
        PageReference cancelOpPageReference = meetinghandlerExtensionTest.CancelOperation();
        Test.stopTest();
        System.assertEquals(cancelOpPageReference.getURL(), ApexPages.currentPage().getParameters().get('meetingIdSF'));
        List<Zoom_Meeting__c> listOfZoomMeetings = [SELECT Name FROM Zoom_Meeting__c];
        System.assertEquals(1, listOfZoomMeetings.size());         
    } 
    
    /******************************************************************************************************************
        Method Name  : createZoomMeeting
        Description  : It creates test zoom meeting record.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static Zoom_Meeting__c createZoomMeeting(){
        Zoom_Meeting__c zoomMeeting = new Zoom_Meeting__c();
        List<RecordType> listOfRecordTypes = [SELECT Name FROM RecordType WHERE sObjectType = 'Zoom_Meeting__c' 
                            AND DeveloperName = :Label.Meeting_Record_Type_Name LIMIT 1];
        zoomMeeting.Name = '661257541';
        zoomMeeting.Agenda__c = 'Test Meeting Agenda';
        zoomMeeting.Start_Date__c = System.today();
        zoomMeeting.Start_Time__c = Time.newInstance(18, 30, 2, 20);
        zoomMeeting.Duration__c = 30;
        zoomMeeting.Topic__c = 'Test Meeting Topic';
        zoomMeeting.Join_before_Host__c = false;
        zoomMeeting.Start_Participant_Video_on_Meeting_Join__c = true;
        zoomMeeting.Enforce_Login__c = true;
        if(!listOfRecordTypes.isEmpty()){
            zoomMeeting.RecordTypeId =  listOfRecordTypes[0].Id;
        }        
        INSERT zoomMeeting;
        System.assertNotEquals(null, zoomMeeting.Id);
        return zoomMeeting;
    }

    /******************************************************************************************************************
        Method Name  : createZoomWebinar
        Description  : It creates test zoom webinar record.
        Date         : 08 Jan 2019
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static Zoom_Meeting__c createZoomWebinar(){
        Zoom_Meeting__c zoomWebinar = new Zoom_Meeting__c();
        List<RecordType> listOfRecordTypes = [SELECT Name FROM RecordType WHERE sObjectType = 'Zoom_Meeting__c' 
                            AND DeveloperName = :Label.Webinar_Record_Type_Name LIMIT 1];
        zoomWebinar.Name = '661257541';
        zoomWebinar.Agenda__c = 'Test Meeting Agenda';
        zoomWebinar.Start_Date__c = System.today().addDays(2);
        zoomWebinar.Start_Time__c = Time.newInstance(18, 30, 2, 20);
        zoomWebinar.Duration__c = 30;
        zoomWebinar.Topic__c = 'Test Meeting Topic';
        zoomWebinar.HD_Video__c = false;
        zoomWebinar.Allow_Multiple_Devices__c = true;
        zoomWebinar.Host_Video__c = true;
        zoomWebinar.Panelist_Video__c = true;
        if(!listOfRecordTypes.isEmpty()){
            zoomWebinar.RecordTypeId =  listOfRecordTypes[0].Id;
        }        
        INSERT zoomWebinar;
        System.assertNotEquals(null, zoomWebinar.Id);
        return zoomWebinar;
    }
    
    /******************************************************************************************************************
        Method Name  : CreateEvent
        Description  : It creates test record for event.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static Event CreateEvent(Id meetingId, Id whoId, Id WhatId){
        Event eventToTest = new Event();
        eventToTest.StartDateTime = System.now();
        eventToTest.EndDateTime = eventToTest.StartDateTime.addMinutes(30);
        eventToTest.Subject = 'Test Meeting Topic';
        eventToTest.Zoom_Meeting__c = meetingId;
        eventToTest.WhoId = whoId;
        //eventToTest.WhatId = WhatId;
        eventToTest.Description = 'https://zoom.us/j/182061822';
        eventToTest.Zoom_Registration_Id__c = 'Qi79NR8_TXqkvj4uV5GBzg';
        INSERT eventToTest;
        system.assertNotEquals(null,eventToTest);
        return eventToTest;
    }
    
    /******************************************************************************************************************
        Method Name  : InsertCampaignWithCampaignMembers
        Description  : It creates test record for lead, campaign and campaign member.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static Campaign InsertCampaignWithCampaignMembers(Id leadId){
        //Create a campaign
        Campaign testCampaign = new Campaign(Name = 'Test Campaign 1', IsActive = True);
        INSERT testCampaign;
        System.assertNotEquals(null, testCampaign.Id);
        List<CampaignMember> listOfCmpMembers = new List<CampaignMember>();
        listOfCmpMembers.add(new CampaignMember(LeadId = leadId, CampaignId = testCampaign.Id,Status = 'Sent'));
        insert listOfCmpMembers;
        System.assertNotEquals(null, listOfCmpMembers[0].Id);
        return testCampaign;
    }
    
    /******************************************************************************************************************
        Method Name  : InsertCampaignWithCampaignMembersOfContact
        Description  : It creates test record for contact, campaign and campaign member.
        Date         : 05 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static Campaign InsertCampaignWithCampaignMembersOfContact(Id contactId){
        //Create a campaign
        Campaign testCampaign = new Campaign(Name = 'Test Campaign 1', IsActive = True);
        INSERT testCampaign;
        System.assertNotEquals(null, testCampaign.Id);
        List<CampaignMember> listOfCmpMembers = new List<CampaignMember>();
        listOfCmpMembers.add(new CampaignMember(ContactId = contactId, CampaignId = testCampaign.Id, Status = 'Sent'));
        INSERT listOfCmpMembers;
        System.assertNotEquals(null, listOfCmpMembers[0].Id);
        return testCampaign;
    }
    
    /******************************************************************************************************************
        Method Name  : InsertDefaultConfigSetting
        Description  : It inserts default custom setting for the zoom account configuration
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static void InsertDefaultConfigSetting(){
        Zoom_Configuration_Settings__c zoomConfigurationDetails = new Zoom_Configuration_Settings__c();
        zoomConfigurationDetails.Name = 'Zoom Settings';
        zoomConfigurationDetails.Zoom_API_Key__c = 'Test_API_Key';
        zoomConfigurationDetails.Zoom_API_Secret__c = 'Test_API_Secret';
        zoomConfigurationDetails.Zoom_URL__c = 'https://zoom.us/j/';
        zoomConfigurationDetails.Site_URL__c = 'https://datacoladasfzoom-developer-edition.ap5.force.com/';
        zoomConfigurationDetails.Email_Sender_Name__c = 'DataColada';
        zoomConfigurationDetails.Zoom_Authorization_Token__c = 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJxdk5YRzJmMVJXU1';
        zoomConfigurationDetails.Zoom_Account_User_Id__c = 'Qi79NR8_TXrqVJ2sK3uiyt';
        zoomConfigurationDetails.Enforce_Login__c = true;
        zoomConfigurationDetails.Join_Before_Host__c = true;
        zoomConfigurationDetails.Start_Participant_Video_on_Join__c = true;  
        zoomConfigurationDetails.Send_Thank_you_email_notification__c = true;    
        zoomConfigurationDetails.Share_Recording_URL__c = true;    
        zoomConfigurationDetails.Share_Survey_Link__c = true;    
        
        INSERT zoomConfigurationDetails;
        system.assertNotEquals(null, zoomConfigurationDetails);
    }
    
}