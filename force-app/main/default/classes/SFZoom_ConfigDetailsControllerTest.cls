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
    Class Name  : SFZoom_ConfigDetailsControllerTest
    Description : This class is responsible for testing all the operation of SFZoom_ConfigDetailsController Class.
    Date        : 01 Nov 2018.
    Author       : DataColada Pty Ltd
*******************************************************************************************************************/
@isTest(seeAllData = false)
public class SFZoom_ConfigDetailsControllerTest {
    
    /******************************************************************************************************************
        Method Name  : TestConfigDetailsControllerSaveAndEdit
        Description  : It verifies save and edit operation of the Zoom Configuration page.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void TestConfigDetailsControllerSaveAndEdit(){
        Test.startTest();
        
        SFZoom_ConfigDetailsController controllerVar = new SFZoom_ConfigDetailsController();
        Test.setMock(HttpCalloutMock.class, new VerifyAuthAndSave_CalloutMock());


        System.assertEquals(false, controllerVar.isUpdate);
        System.assertEquals(false, controllerVar.isRecordExist);
        
        controllerVar.zoomAPIKey = 'Test_API_Key';
        controllerVar.ZoomAPISecret = 'Test_API_Secret';
        controllerVar.ZoomUserEmail = 'admin@datacolada.com';
        controllerVar.ZoomURL = 'https://zoom.us/j/';
        controllerVar.siteURL = 'https://datacoladasfzoom-developer-edition.ap5.force.com/';
        controllerVar.EmailSenderName = 'DataColada';
        controllerVar.joinBeforeHost = true;
        controllerVar.startParticipantVideo = true;
        controllerVar.enforceLogin = true;
        controllerVar.thankYouEmailNotification = true;
        controllerVar.shareSurveyLink = true;
        controllerVar.shareRecordingURL = true;
            
        
        controllerVar.minimumMeetingDuration = 0;
        controllerVar.maximumMeetingDuration = 0;
        controllerVar.joinBeforeHost = true;
        controllerVar.startParticipantVideo = true;
        controllerVar.allowMultipleDevices = true;
        controllerVar.defaultsToHDVideo = true;
        controllerVar.startVideoWhenHostJoin = true;
        controllerVar.startVideoWhenPanelistJoin = true;
        controllerVar.SaveConfigurationDetails();


        controllerVar.minimumMeetingDuration = 10;
        controllerVar.maximumMeetingDuration = 100;
        controllerVar.SaveConfigurationDetails();

        Zoom_Configuration_Settings__c zoomConfigurationDetails = Zoom_Configuration_Settings__c.getValues(Label.Config_Details_Custom_Setting_Name);
        system.debug('zoomConfigurationDetails'+zoomConfigurationDetails);
        System.assertEquals('Test_API_Key', zoomConfigurationDetails.Zoom_API_Key__c);
        System.assertEquals('Test_API_Secret', zoomConfigurationDetails.Zoom_API_Secret__c);
        System.assertEquals('https://zoom.us/j/', zoomConfigurationDetails.Zoom_URL__c);
        System.assertEquals(true, zoomConfigurationDetails.Enforce_Login__c);
        System.assertNotEquals(0, zoomConfigurationDetails.Maximum_Meeting_Duration__c);
        System.assertNotEquals(0, zoomConfigurationDetails.Minimum_Meeting_Duration__c);
        System.assertEquals(100, zoomConfigurationDetails.Maximum_Meeting_Duration__c);
        System.assertEquals(10, zoomConfigurationDetails.Minimum_Meeting_Duration__c);
        System.assertNotEquals(false, zoomConfigurationDetails.Join_Before_Host__c);
        
        controllerVar.EditConfigurationDetails();
        System.assertEquals(true, controllerVar.isUpdate);
        controllerVar.CancelConfigurationDetails();
        Test.stopTest();
        System.assertEquals(false, controllerVar.isUpdate);
    }
    
    /******************************************************************************************************************
        Method Name  : TestConfigDetailsControllerLoadConfigEditAndSave
        Description  : It verifies load existing configuration, edit and save operation of the Zoom Configuration page.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @isTest
    static void TestConfigDetailsControllerLoadConfigEditAndSave(){
        Test.startTest();
        
        Zoom_Configuration_Settings__c zoomConfigurationDetails = new Zoom_Configuration_Settings__c();
        zoomConfigurationDetails.Name = 'Zoom Settings'; 
       
        zoomConfigurationDetails.Zoom_API_Key__c = 'Test_API_Key';
        zoomConfigurationDetails.Zoom_API_Secret__c = 'Test_API_Secret';
        zoomConfigurationDetails.Zoom_Integration_User_Email__c = 'admin@datacolada.com';
        zoomConfigurationDetails.Zoom_URL__c = 'https://zoom.us/j/';
        zoomConfigurationDetails.Site_URL__c = 'https://datacoladasfzoom-developer-edition.ap5.force.com/';
        zoomConfigurationDetails.Email_Sender_Name__c = 'DataColada';
        zoomConfigurationDetails.Enforce_Login__c = true;
        zoomConfigurationDetails.Join_Before_Host__c = true;
        zoomConfigurationDetails.Start_Participant_Video_on_Join__c = true;

        zoomConfigurationDetails.Maximum_Meeting_Duration__c = 30;
        zoomConfigurationDetails.Minimum_Meeting_Duration__c = 20;
        
        zoomConfigurationDetails.Allow_Multiple_Devices__c = true;
        zoomConfigurationDetails.Crypto_Key__c = 'test1234';
        zoomConfigurationDetails.Zoom_Account_User_Id__c = 'testUserId';
		zoomConfigurationDetails.HD_Video__c = true;
        zoomConfigurationDetails.Host_Video__c = true;
        zoomConfigurationDetails.Panelist_Video__c = true;
        zoomConfigurationDetails.Zoom_Authorization_Token__c = 'test_authorization_token';
        zoomConfigurationDetails.Allow_Multiple_Devices__c = true;
        zoomConfigurationDetails.Send_Thank_you_email_notification__c = true;    
        zoomConfigurationDetails.Share_Recording_URL__c = true;    
        zoomConfigurationDetails.Share_Survey_Link__c = true;  
        
        INSERT zoomConfigurationDetails;
        
        Zoom_Configuration_Settings__c zoomConfigurationDetailsInserted = Zoom_Configuration_Settings__c.getValues('Zoom Settings');
        System.assertNotEquals(null, zoomConfigurationDetailsInserted);
        
        SFZoom_ConfigDetailsController controllerVar = new SFZoom_ConfigDetailsController();
        System.assertEquals('Test_API_Key', controllerVar.zoomAPIKey);
        System.assertEquals('Test_API_Secret', controllerVar.ZoomAPISecret);
        System.assertNotEquals('https://zoom.us', controllerVar.ZoomURL);
        System.assertEquals(true, controllerVar.joinBeforeHost);
        System.assertEquals(true, controllerVar.startParticipantVideo);
        System.assertEquals(true, controllerVar.enforceLogin);
        System.assertEquals(true, controllerVar.thankYouEmailNotification);
        System.assertEquals(true, controllerVar.shareSurveyLink);
        System.assertEquals(true, controllerVar.shareRecordingURL);
        
        
        controllerVar.EditConfigurationDetails();
        System.assertEquals(true, controllerVar.isUpdate);
        
        controllerVar.ZoomURL = 'https://zoom.us/j/';
        controllerVar.SaveConfigurationDetails();
        Test.stopTest();
        System.assertEquals('https://zoom.us/j/', zoomConfigurationDetails.Zoom_URL__c);
    }
}