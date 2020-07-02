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
    Class Name  : SFZoom_ConfigDetailsController
    Description : This class is responsible for saving configuration details for Salesforce and Zoom Integration.
    Date        : 01 Nov 2018.
    Author       : DataColada Pty Ltd
*******************************************************************************************************************/
public with sharing class SFZoom_ConfigDetailsController {
    public Zoom_Configuration_Settings__c configEmailSettings{get;set;}
    public String zoomAPIKey {get; set;} 
    public String ZoomAPISecret {get; set;}
    public String ZoomUserEmail {get; set;}
    public String ZoomURL {get; set;}
    public String SiteURL {get; set;}
    public String EmailSenderName {get; set;}
    public Integer minimumMeetingDuration {get; set;}
    public Integer maximumMeetingDuration {get; set;}
    public Boolean joinBeforeHost {get; set;}
    public Boolean thankYouEmailNotification {get;set;}
    public Boolean startParticipantVideo {get; set;}
    public Boolean enforceLogin {get; set;}
    public Boolean isRecordExist {get; set;}
    public Boolean isUpdate {get; set;}
    public Boolean shareSurveyLink {get;set;}
    public Boolean shareRecordingURL {get;set;}
    //Webinar config
    public Boolean allowMultipleDevices {get; set; }
    public Boolean defaultsToHDVideo {get; set; } 
    public Boolean startVideoWhenHostJoin {get; set; }
    public Boolean startVideoWhenPanelistJoin {get; set; }
        
    private Id metaDataRecordId;
    
    // Constructor to load existing configuration if saved earlier
    public SFZoom_ConfigDetailsController(){
        configEmailSettings = new Zoom_Configuration_Settings__c();
        try{            
            isUpdate = false;
            isRecordExist = false;
            LoadConfigurationDetails();
        }Catch(Exception ex){
            System.debug('SFZoom_ConfigDetailsController - Constructor - Exception: ' + ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        }
    }
    
    /******************************************************************************************************************
        Method Name  : resetThankYouSetting
        Description  : It resets share survey link and share recording url checkboxes if thank you notification checkbox made unchecked
        Date         : 12 Mar 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference resetThankYouSetting(){
        if(!thankYouEmailNotification){
            shareRecordingURL = false;
            shareSurveyLink = false;
        }
        return null;
    }
    
    /******************************************************************************************************************
        Method Name  : SaveConfigurationDetails
        Description  : It saves all the configuration details in a custom setting.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference SaveConfigurationDetails(){
        try{
            if(validateConfigurationDetails()){
                Zoom_Configuration_Settings__c configToSave = new Zoom_Configuration_Settings__c();
                configToSave.Name = Label.Config_Details_Custom_Setting_Name;
                configToSave.Zoom_API_Key__c = zoomAPIKey;
                configToSave.Zoom_API_Secret__c = ZoomAPISecret;
                configToSave.Zoom_Integration_User_Email__c = ZoomUserEmail;
                SFZoom_JWT_HS256 myJWT = new SFZoom_JWT_HS256(Label.Zoom_Auth_Token_Algorithm_Name, zoomAPIKey, ZoomAPISecret, 
                                                              Integer.valueOf(Label.Zoom_Auth_Token_Valitidy_In_Miliseconds));
                configToSave.Zoom_Authorization_Token__c = myJWT.generateAuthToken();
                String zoomAccountUserId = VerifyAuthorizationTokenAndSaveUserId(configToSave.Zoom_Authorization_Token__c,configToSave.Zoom_Integration_User_Email__c);
                if(String.isNotBlank(zoomAccountUserId)){
                    configToSave.Zoom_Account_User_Id__c = zoomAccountUserId;
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Auth_Token_Error_Message));
                    return null;
                }
                
                configToSave.Zoom_URL__c = ZoomURL;
                configToSave.Site_URL__c = siteURL.endsWith('/') ? siteURL : siteURL + '/';
                configToSave.Email_Sender_Name__c = emailSenderName;
                configToSave.Minimum_Meeting_Duration__c = minimumMeetingDuration != null ? minimumMeetingDuration : Integer.valueOf(Label.Minimum_Meeting_Duration);
                configToSave.Maximum_Meeting_Duration__c = maximumMeetingDuration != null ? maximumMeetingDuration : Integer.valueOf(Label.Maximum_Meeting_Duration);
                configToSave.Join_Before_Host__c = joinBeforeHost;
                configToSave.Send_Thank_you_email_notification__c = thankYouEmailNotification;
                configToSave.Share_Recording_URL__c = shareRecordingURL;
                configToSave.Share_Survey_Link__c =  shareSurveyLink;
                configToSave.Start_Participant_Video_on_Join__c = startParticipantVideo;
                configToSave.Enforce_Login__c = enforceLogin;
                
                //Webinar config starts
                configToSave.Allow_Multiple_Devices__c = allowMultipleDevices;
                configToSave.HD_Video__c = defaultsToHDVideo;
                configToSave.Host_Video__c = startVideoWhenHostJoin;
                configToSave.Panelist_Video__c = startVideoWhenPanelistJoin;
                //Webinar config ends
                
                if(isRecordExist){
                    configToSave.Id = metaDataRecordId;
                }else{
                    configToSave.Crypto_Key__c = SFZoom_MeetingManagerUtility.GenerteEncryptedPrivateKeyText();
                }
                List<String> zoomConfigFields = new List<String>{
                    'Start_Participant_Video_on_Join__c', 'Site_URL__c',
                    'Host_Video__c','HD_Video__c','Allow_Multiple_Devices__c','Name', 
                    'Zoom_API_Key__c', 'Zoom_API_Secret__c', 'Zoom_URL__c', 
                    'Email_Sender_Name__c', 'Join_Before_Host__c', 'Crypto_Key__c',
                    'Enforce_Login__c','Send_Thank_you_email_notification__c',
                    'Share_Recording_URL__c','Share_Survey_Link__c',    
                    'Zoom_Authorization_Token__c', 'Zoom_Account_User_Id__c','Zoom_Integration_User_Email__c',
                    'Minimum_Meeting_Duration__c', 'Maximum_Meeting_Duration__c'};
                if(SFZoom_AccessUtil.objectIsCreatable('Zoom_Configuration_Settings__c') && 
                    SFZoom_AccessUtil.fieldsAreCreatable('Zoom_Configuration_Settings__c', zoomConfigFields) && 
                    SFZoom_AccessUtil.objectIsUpdateable('Zoom_Configuration_Settings__c') && 
                    SFZoom_AccessUtil.fieldsAreUpdateable('Zoom_Configuration_Settings__c', zoomConfigFields)){
                    UPSERT configToSave;
                    isRecordExist = true;
                    isUpdate = false;
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Insufficient_Error_Message));
                }       
            }            
        }Catch(Exception ex){
            System.debug('SFZoom_ConfigDetailsController - SaveConfigurationDetails - Exception: ' + ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Apex_Exception_Error_Message));
        }
        return null;
    }

    /******************************************************************************************************************
        Method Name  : validateConfigurationDetails
        Description  : It validates the field information for the required fields
        Date         : 10 Jan 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private Boolean validateConfigurationDetails(){
        
        if(String.isBlank(zoomAPIKey) || String.isBlank(ZoomAPISecret) || String.isBlank(ZoomURL) || 
            String.isBlank(SiteURL) || String.isBlank(emailSenderName) || 
            minimumMeetingDuration == null || maximumMeetingDuration == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Required_Field_Missing_Error_Message));
            return false;
        }else if(minimumMeetingDuration < 1 || maximumMeetingDuration < 1){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Meeting_Duration_Error_Message));
            return false;
        }else if(maximumMeetingDuration <= minimumMeetingDuration){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Maximum_and_Minimum_Meeting_Duration_Validation_Message));
            return false;
        }else if(String.isBlank(ZoomUserEmail)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.Zoom_User_Email_Validation_Message));
            return false;
        }return true;
    }
    
    /******************************************************************************************************************
        Method Name  : VerifyAuthorizationTokenAndSaveUserId
        Description  : It calls the Zoom List User API and fetch the Zoom Account user Id. It also verifies the token is working or not.
        Parameter1   : accessToken - It holds meeting data which needs to pass to Zoom API to create the meeting.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private static String VerifyAuthorizationTokenAndSaveUserId(String accessToken, String ZoomUserEmail){
        String zoomAccountUserId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Label.List_User_API + '/' + ZoomUserEmail);
        req.setMethod('GET');  
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');   
        req.setHeader('Authorization', AccessToken);
        Http http = new Http();
        HTTPResponse response = new HTTPResponse();
        response = http.send(req);
        
        Map<String,Object> mapOfResponse = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());        
        if(response.getStatusCode() == 200 && mapOfResponse.containsKey('id')){
             zoomAccountUserId = String.valueOf(mapOfResponse.get('id'));                    
        }
        return zoomAccountUserId;
    }
    
    /******************************************************************************************************************
        Method Name  : EditConfigurationDetails
        Description  : It enables the edit mode to update the saved configuration details on the VF Page.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public void EditConfigurationDetails(){
        isUpdate = true;
    }
    
    /******************************************************************************************************************
        Method Name  : CancelConfigurationDetails
        Description  : It cancels the edit mode which allows user to update the saved configuration details on the VF Page.
        Date         : 03 Dec 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public PageReference CancelConfigurationDetails(){
        isUpdate = false;
        try{
            LoadConfigurationDetails();
        }Catch(Exception ex){
            System.debug('SFZoom_ConfigDetailsController - SaveConfigurationDetails - Exception: ' + ex.getMessage());
        }
        return null;
    }
    
    /******************************************************************************************************************
        Method Name  : SaveConfigurationDetails
        Description  : It laods previoulsy saved configuration details from the custom setting.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private void LoadConfigurationDetails(){ 
        Zoom_Configuration_Settings__c zoomConfigurationDetails = Zoom_Configuration_Settings__c.getValues(Label.Config_Details_Custom_Setting_Name);
        If(zoomConfigurationDetails != null){
            zoomAPIKey = zoomConfigurationDetails.Zoom_API_Key__c;
            ZoomAPISecret = zoomConfigurationDetails.Zoom_API_Secret__c;
            ZoomURL = zoomConfigurationDetails.Zoom_URL__c;
            ZoomUserEmail = zoomConfigurationDetails.Zoom_Integration_User_Email__c;
            siteURL = zoomConfigurationDetails.Site_URL__c;
            emailSenderName = zoomConfigurationDetails.Email_Sender_Name__c;
            minimumMeetingDuration = Integer.valueOf(zoomConfigurationDetails.Minimum_Meeting_Duration__c);
            maximumMeetingDuration = Integer.valueOf(zoomConfigurationDetails.Maximum_Meeting_Duration__c);
            joinBeforeHost = zoomConfigurationDetails.Join_Before_Host__c;
            thankYouEmailNotification = zoomConfigurationDetails.Send_Thank_you_email_notification__c;
            startParticipantVideo = zoomConfigurationDetails.Start_Participant_Video_on_Join__c;
            enforceLogin = zoomConfigurationDetails.Enforce_Login__c;
            isRecordExist = true;
            metaDataRecordId = zoomConfigurationDetails.Id;
            allowMultipleDevices = zoomConfigurationDetails.Start_Participant_Video_on_Join__c;
            defaultsToHDVideo = zoomConfigurationDetails.Host_Video__c;
            startVideoWhenHostJoin = zoomConfigurationDetails.HD_Video__c;
            startVideoWhenPanelistJoin = zoomConfigurationDetails.Allow_Multiple_Devices__c;
            shareRecordingURL = zoomConfigurationDetails.Share_Recording_URL__c;
            shareSurveyLink = zoomConfigurationDetails.Share_Survey_Link__c;      
        }
    }
    
    
}