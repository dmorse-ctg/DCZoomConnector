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

@isTest(seeAllData = false)
public class ZoomUtils_Test {
    
    /******************************************************************************************************************
        Method Name  : testWebinarSave
        Description  : It verifies save operation of the inline VF page for webinar with Auto_Register__c as true.
        Date         : 31 May 2019
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void testWebinarSave(){
        InsertDefaultConfigSetting(); 
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Weebles Lead Test', Company ='Weebles Widgets', Email='testlead@mailinator.com');
        INSERT testLead;
        System.assertNotEquals(null, testLead.Id);
        Campaign campaignToTest = InsertCampaignWithCampaignMembers(testLead.Id);
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
        //For AutoRegister = true
        ZoomUtils.sendEmail(testLead.Id,true,campaignToTest.Id); 
        //For AutoRegister = false
        ZoomUtils.sendEmail(testLead.Id,false,campaignToTest.Id); 
        Test.stopTest();
        List<Zoom_Meeting__c> listOfCreatedZoomMeetings = [SELECT Duration__c FROM Zoom_Meeting__c];
        //System.assertEquals(1, listOfCreatedZoomMeetings.size());  
    }
    
    /******************************************************************************************************************
        Method Name  : createZoomMeeting
        Description  : It creates test zoom meeting record.
        Date         : 31 May 2019
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
        Date         : 31 May 2019
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
        Date         : 31 May 2019
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static Event CreateEvent(Id meetingId, Id whoId){
        Event eventToTest = new Event();
        eventToTest.StartDateTime = System.now();
        eventToTest.EndDateTime = eventToTest.StartDateTime.addMinutes(30);
        eventToTest.Subject = 'Test Meeting Topic';
        eventToTest.Zoom_Meeting__c = meetingId;
        eventToTest.WhoId = whoId;
        eventToTest.Description = 'https://zoom.us/j/182061822';
        INSERT eventToTest;
        system.assertNotEquals(null,eventToTest);
        return eventToTest;
    }
    
    /******************************************************************************************************************
        Method Name  : InsertCampaignWithCampaignMembers
        Description  : It creates test record for lead, campaign and campaign member.
        Date         : 31 May 2019
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static Campaign InsertCampaignWithCampaignMembers(Id leadId){
        //Create a campaign
        Campaign testCampaign = new Campaign(Name = 'Test Campaign 1', IsActive = True);
        INSERT testCampaign;
        System.assertNotEquals(null, testCampaign.Id);
        List<CampaignMember> listOfCmpMembers = new List<CampaignMember>();
        listOfCmpMembers.add(new CampaignMember(LeadId = leadId, CampaignId = testCampaign.Id, Status = 'Sent'));
        insert listOfCmpMembers;
        System.assertNotEquals(null, listOfCmpMembers[0].Id);
        return testCampaign;
    }
    
    /******************************************************************************************************************
        Method Name  : InsertCampaignWithCampaignMembersOfContact
        Description  : It creates test record for contact, campaign and campaign member.
        Date         : 31 May 2019
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
        Date         : 31 May 2019
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