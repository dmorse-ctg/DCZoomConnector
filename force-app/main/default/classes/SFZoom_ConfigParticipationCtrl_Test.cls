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
    Class Name  : SFZoom_ConfigParticipationCtrl_Test
    Description : This class is responsible for testing all the operation of SFZoom_ConfigParticipationController Class.
    Date        : 26 Nov 2018.
    Author       : DataColada Pty Ltd
*******************************************************************************************************************/
@isTest(seeAllData = false)
public class SFZoom_ConfigParticipationCtrl_Test {
    
    /******************************************************************************************************************
        Method Name  : testDeclineInvitation
        Description  : It verifies event invitation decline operation of the site page.
        Date         : 26 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest 
    static void testDeclineInvitation(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        Campaign campaignInserted = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembers(testLead.Id);
        System.assertNotEquals(null, campaignInserted.Id);
        Zoom_Meeting__c zoomMeetingCreated = SFZoom_MeetingHandlerExtension_Test.createZoomMeeting();
        System.assertNotEquals(null, zoomMeetingCreated.Id);
        Event eventCreated = SFZoom_MeetingHandlerExtension_Test.CreateEvent(zoomMeetingCreated.Id, testLead.Id,null);
        System.assertNotEquals(null, eventCreated.Id);
        
        Test.startTest();
        
        List<CampaignMember> listOfCmpMembers = [SELECT leadId FROM CampaignMember 
                                                 WHERE campaignId = :campaignInserted.Id];
        System.assertEquals(1, listOfCmpMembers.size());        
        String encryptedId = SFZoom_MeetingManagerUtility.EncryptData(listOfCmpMembers[0].Id);
        String encryptedLeadId = SFZoom_MeetingManagerUtility.EncryptData(listOfCmpMembers[0].leadId);
        String encryptedMeetingId = SFZoom_MeetingManagerUtility.EncryptData(zoomMeetingCreated.Id);
        PageReference pageRefToTest = Page.SFZoom_ConfigParticipation;
        pageRefToTest.getParameters().put('id', EncodingUtil.urlDecode(encryptedId, 'UTF-8'));
        pageRefToTest.getParameters().put('leadid', EncodingUtil.urlDecode(encryptedLeadId, 'UTF-8'));
        pageRefToTest.getParameters().put('meetingid', EncodingUtil.urlDecode(encryptedMeetingId, 'UTF-8'));
        pageRefToTest.getParameters().put('setupobj', 'Campaign');
        Test.setCurrentPage(pageRefToTest);
        SFZoom_ConfigParticipationController configParticipationCtrlTest = new SFZoom_ConfigParticipationController();
        configParticipationCtrlTest.DeclineInvitation();
        Test.stopTest();
        List<Event> listOfEventsUpdated = [SELECT Zoom_Registration_Status__c FROM Event 
                                           WHERE Zoom_Meeting__c = :zoomMeetingCreated.Id
                                           AND Zoom_Registration_Status__c = 'Declined'];
        System.assertEquals(1, listOfEventsUpdated.size());
        System.assertEquals(true, configParticipationCtrlTest.isCancelled);
    }
    
    /******************************************************************************************************************
        Method Name  : testAcceptInvitation
        Description  : It verifies event invitation accept and add Registrant operation of the site page.
        Date         : 26 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest 
    static void testAcceptInvitation(){
        SFZoom_MeetingHandlerExtension_Test.InsertDefaultConfigSetting();
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Weebles Contact Test', Email='testcontact@mailinator.com');
        INSERT testContact;
        Campaign campaignInserted = SFZoom_MeetingHandlerExtension_Test.InsertCampaignWithCampaignMembersOfContact(testContact.id);
        System.assertNotEquals(null, campaignInserted.Id);
        Zoom_Meeting__c zoomMeetingCreated = SFZoom_MeetingHandlerExtension_Test.createZoomMeeting();
        System.assertNotEquals(null, zoomMeetingCreated.Id);
        Event eventCreated = SFZoom_MeetingHandlerExtension_Test.CreateEvent(zoomMeetingCreated.Id, testContact.Id,campaignInserted.Id);
        System.assertNotEquals(null, eventCreated.Id);
        
        Test.startTest();
        
        List<CampaignMember> listOfCmpMembers = [SELECT contactId FROM CampaignMember 
                                                 WHERE campaignId = :campaignInserted.Id];
        System.assertEquals(1, listOfCmpMembers.size());        
        String encryptedId = SFZoom_MeetingManagerUtility.EncryptData(listOfCmpMembers[0].Id);
        String encryptedContactId = SFZoom_MeetingManagerUtility.EncryptData(listOfCmpMembers[0].contactId);
        String encryptedMeetingId = SFZoom_MeetingManagerUtility.EncryptData(zoomMeetingCreated.Id);
        PageReference pageRefToTest = Page.SFZoom_ConfigParticipation;
        SFZoom_ConfigParticipationController configParticipationCtrlTest = new SFZoom_ConfigParticipationController();
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        pageRefToTest.getParameters().put('id', EncodingUtil.urlDecode(encryptedId, 'UTF-8'));
        pageRefToTest.getParameters().put('meetingid', EncodingUtil.urlDecode(encryptedMeetingId, 'UTF-8'));
        pageRefToTest.getParameters().put('setupobj', 'Campaign');
        pageRefToTest.getParameters().put('conid', EncodingUtil.urlDecode(encryptedContactId, 'UTF-8'));
        Test.setCurrentPage(pageRefToTest);
        
        configParticipationCtrlTest = new SFZoom_ConfigParticipationController();
        configParticipationCtrlTest.AddMeetingRegistrant();
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        configParticipationCtrlTest.registrationDetails.email = 'testemailnotification@gmail.com';
        configParticipationCtrlTest.registrationDetails.first_name = 'Test';
        configParticipationCtrlTest.registrationDetails.last_name = 'Email Notification';
        Test.setMock(HttpCalloutMock.class, new SFZoom_LightningEventHandler_CalloutMock(false,true));
        configParticipationCtrlTest.AddMeetingRegistrant();
        Test.stopTest();
        List<Event> listOfEventsUpdated = [SELECT Zoom_Registration_Status__c FROM Event 
                                           WHERE Zoom_Meeting__c = :zoomMeetingCreated.Id
                                           AND Zoom_Registration_Status__c = 'Registered'];
        System.assertEquals(1, listOfEventsUpdated.size());
        System.assertEquals(true, configParticipationCtrlTest.isRegistered);
        
        configParticipationCtrlTest = new SFZoom_ConfigParticipationController();
        pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
    }
    
}