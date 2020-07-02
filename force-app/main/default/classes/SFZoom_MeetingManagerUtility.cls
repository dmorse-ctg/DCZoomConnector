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
    Class Name  : SFZoom_MeetingManagerUtility
    Description : This class is responsible for managing all the operation for Salesforce and Zoom Integration.
    Date        : 01 Nov 2018.
    Author      : DataColada Pty Ltd

*******************************************************************************************************************/
public with sharing class SFZoom_MeetingManagerUtility{
    
    /******************************************************************************************************************
        Method Name  : CreateMeetingInZoomAccount
        Description  : It creates meeting in the Zoom Account based on the user input.
        Parameter1   : dataToSend - It holds meeting data which needs to pass to Zoom API to create the meeting.
        Date         : 01 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String CreateMeetingInZoomAccount(String dataToSend){
        HTTPResponse response = new HTTPResponse();
        try{
            String userId = FindUserIdFromCustomSetting();
            if(String.isNotBlank(userId)){
                String endPointURL = Label.Zoom_Base_EndPoint_URL+'users/'+userId+'/meetings'; 
                HttpRequest req = constructHttpRequestHeader('POST', endPointUrl); 
                req.setBody(dataToSend);
                Http http = new Http();
                response = http.send(req);
            }
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Manager Utility - Create Meeting In Zoom Account - Exception: ' + ex.getMessage());
        }
        return response.getBody();
    }

    /******************************************************************************************************************
        Method Name  : UpdateMeetingInZoomAccount
        Description  : It updates meeting in the Zoom Account based on the user input.
        Parameter1   : dataToSend - It holds meeting data which needs to pass to Zoom API to update the meeting.
        Parameter2   : updateMeetingId - It holds Zoom meeting Id which is used to update zoom meeting details.
        Date         : 01 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String UpdateMeetingInZoomAccount(String dataToSend, String updateMeetingId){
        HTTPResponse response = new HTTPResponse();
        try{
            String endPointURL = Label.Zoom_Base_EndPoint_URL+'sf/meetings/'+updateMeetingId;
            HttpRequest req = constructHttpRequestHeader('PUT', endPointUrl); 
            req.setBody(dataToSend);
            Http http = new Http();
            response = http.send(req);
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Manager Utility - Update Meeting In Zoom Account - Exception: ' + ex.getMessage());
        }
        return response.getBody();
    }
    
    /******************************************************************************************************************
        Method Name  : CancelMeetingInZoomAccount
        Description  : It cancels meeting from the Zoom Account.
        Parameter1   : meetingId - It holds meeting Id which needs to be cancelled
        Date         : 01 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static HTTPResponse CancelMeetingInZoomAccount(String meetingId){
        HTTPResponse response = new HTTPResponse();
        try{
            String endPointURL = Label.Zoom_Base_EndPoint_URL+'meetings/'+meetingId; 
            HttpRequest req = constructHttpRequestHeader('DELETE', endPointUrl);
            Http http = new Http();
            if(Test.isRunningTest()){
                response.setStatusCode(204);
            }else{
                response = http.send(req);
            }
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Manager Utility - Cancel Meeting In Zoom Account - Exception: ' + ex.getMessage());
        }
        return response;
    }
    
    /******************************************************************************************************************
        Method Name  : AddMeetingRegistrants
        Description  : It adds meeting registrants to the supplied meeting.
        Parameter1   : meetingId - It holds meeting Id for which participant/attendee details would be added
        Parameter2   : requestBody - It contains participant firstName, lastName and email address in the JSON format.
        Date         : 20 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static HTTPResponse AddMeetingRegistrants(String meetingId, String requestBody){
        HTTPResponse response = new HTTPResponse();
        try{
            String endPointURL = Label.Zoom_Base_EndPoint_URL+'meetings/'+meetingId+'/registrants'; 
            HttpRequest req = constructHttpRequestHeader('POST', endPointUrl);
            req.setBody(requestBody);
            Http http = new Http();
            response = http.send(req);
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Manager Utility - Add Meeting Registrants - Exception: ' + ex.getMessage());
        }
        return response;
    }
    
    /******************************************************************************************************************
        Method Name  : getMeetingRecordingDetails
        Description  : It gets the recording details from the Zoom 
        Date         : 06 Mar 2019.
        Parameter1   : List of event records
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static HTTPResponse getMeetingRecordingDetails(String meetingId){
        HTTPResponse response = new HTTPResponse();
        try{
            if(String.isNotBlank(meetingId)) {
                String endPointUrl = Label.Zoom_Base_EndPoint_URL + 'meetings/'+ meetingId + '/recordings';
                HttpRequest req = SFZoom_MeetingManagerUtility.constructHttpRequestHeader('GET', endPointUrl); 
                Http http = new Http();
                if(!Test.isRunningTest()){
                    response = http.send(req);
                }else{
                    response.setStatusCode(200);
                    String responseBody = '{"id":125886484,"recording_count":2,"recording_files":[{"play_url":"https://api.zoom.us/recording/play/v645MvmvNs1I7REwePJJskTpGNnGZHKRQ4uPDjuOtKrLRq7L_k54soj2SsahxusI"}]}';
                    response.setBody(responseBody);
                }              
            }
        }Catch(Exception ex){
            System.debug('SF Zoom Service To Update Participants Details - set Meeting Url For Attendees - Exception: ' + ex.getMessage() + ex.getStackTraceString());
        }        
        return response;
    }
    
    /******************************************************************************************************************
        Method Name  : FindRecordingPlayUrl
        Description  : It fetches the recorded url from zoom and the recent recorded url link.
        Date         : 08 Mar 2019.
        Parameter1   : responseBody - It contains the response Body which is received from the API
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String FindRecordingPlayUrl(String responseBody){
        String playURL;
        if(String.isNotBlank(responseBody)){
            Map<String,Object> mapOfResponseData = new Map<String, Object>();
            mapOfResponseData = (Map<String,Object>)JSON.deserializeUntyped(responseBody) ;
            if(!mapOfResponseData.isEmpty()){
                List<Object> listOfRecordings = (List<Object>) mapOfResponseData.get('recording_files');
                if(listOfRecordings != null && !listOfRecordings.isEmpty()){
                    playUrl = String.valueOf(((Map<String, Object>)listOfRecordings[listOfRecordings.size()-1]).get('play_url'));
                }
            }
        }
       return playURL;
    }
    
    /******************************************************************************************************************
        Method Name  : CreateWebinarInZoomAccount
        Description  : It creates webinar in the Zoom Account based on the user input.
        Parameter1   : dataToSend - It holds webinar data which needs to pass to Zoom API to create the meeting.
        Date         : 27 Dec 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String CreateWebinarInZoomAccount(String dataToSend){
        HTTPResponse response = new HTTPResponse();
        try{
            String userId = FindUserIdFromCustomSetting();
            if(String.isNotBlank(userId)){
                String endPointURL = Label.Zoom_Base_EndPoint_URL+'users/'+userId+'/webinars'; 
                HttpRequest req = constructHttpRequestHeader('POST', endPointUrl);
                req.setBody(dataToSend);
                Http http = new Http();
                response = http.send(req);
            }
        }Catch(Exception ex){
            System.debug('SFZoom Meeting Manager Utility - Create Webinar In ZoomAccount - Exception: ' + ex.getMessage());
        }
        return response.getBody();
    }

    /******************************************************************************************************************
        Method Name  : UpdateWebinarInZoomAccount
        Description  : It updates webinar in the Zoom Account based on the user input.
        Parameter1   : dataToSend - It holds webinar data which needs to pass to Zoom API to create the meeting.
        Parameter2   : updatedWebinarId - It holds zoom webinar id
        Date         : 31 Dec 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String UpdateWebinarInZoomAccount(String dataToSend, String updatedWebinarId){
        HTTPResponse response = new HTTPResponse();
        try{
            String endPointURL = Label.Zoom_Base_EndPoint_URL+'sf/webinars/'+updatedWebinarId;
            HttpRequest req = constructHttpRequestHeader('PUT', endPointUrl);
            req.setBody(dataToSend);
            Http http = new Http();
            response = http.send(req);
        }Catch(Exception ex){
            System.debug('SFZoom Meeting Manager Utility - Update Webinar In Zoom Account - Exception: ' + ex.getMessage());
        }
        return response.getBody();
    }
    
    /******************************************************************************************************************
        Method Name  : CancelWebinarInZoomAccount
        Description  : It cancels webinar from the Zoom Account.
        Parameter1   : webinarId - It holds meeting Id which needs to be cancelled
        Date         : 27 Dec 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static HTTPResponse CancelWebinarInZoomAccount(String webinarId){
        HTTPResponse response = new HTTPResponse();
        try{
            String endPointURL = Label.Zoom_Base_EndPoint_URL+'webinars/'+webinarId;
            HttpRequest req = constructHttpRequestHeader('DELETE', endPointUrl);
            Http http = new Http();
            if(Test.isRunningTest()){
                response.setStatusCode(204);
            }else{
                response = http.send(req);
            }
            
        }Catch(Exception ex){
            System.debug('SFZoom Meeting Manager Utility - Cancel Webinar In Zoom Account - Exception: ' + ex.getMessage());
        }
        return response;
    }

    /******************************************************************************************************************
        Method Name  : AddWebinarRegistrants
        Description  : It adds webinar registrants.
        Parameter1   : webinarId - It holds webinar Id for which participant/attendee details would be added
        Parameter2   : requestBody - It contains participant firstName, lastName and email address in the JSON format.
        Date         : 30 Dec 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static HTTPResponse AddWebinarRegistrants(String webinarId, String requestBody){
        HTTPResponse response = new HTTPResponse();
        try{
            String endPointURL = Label.Zoom_Base_EndPoint_URL+'webinars/'+webinarId+'/registrants';
            HttpRequest req = constructHttpRequestHeader('POST', endPointUrl);
            req.setBody(requestBody);
            Http http = new Http();
            response = http.send(req);
        }Catch(Exception ex){
            System.debug('SF Zoom Meeting Manager Utility - Add Webinar Registrants - Exception: ' + ex.getMessage());
        }
        return response;
    }
    
    /******************************************************************************************************************
        Method Name  : FindAuthorizationTokenFromCustomSetting
        Description  : It finds authorization token from the custom setting named 'Zoom Configuration Settings'.
        Date         : 01 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    private static String FindAuthorizationTokenFromCustomSetting(){
        String authToken;
        Zoom_Configuration_Settings__c zoomConfigurationDetails = Zoom_Configuration_Settings__c.getValues(Label.Config_Details_Custom_Setting_Name);
        If(zoomConfigurationDetails != null){
            authToken = zoomConfigurationDetails.Zoom_Authorization_Token__c;
        }
        return authToken;
    }
    
    /******************************************************************************************************************
        Method Name  : FindUserIdFromCustomSetting
        Description  : It finds User Id from the custom setting named 'Zoom Configuration Settings'.
        Date         : 01 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    private static String FindUserIdFromCustomSetting(){
        String zoomAccountUserId;
        Zoom_Configuration_Settings__c zoomConfigurationDetails = Zoom_Configuration_Settings__c.getValues(Label.Config_Details_Custom_Setting_Name);
        If(zoomConfigurationDetails != null){
            zoomAccountUserId = zoomConfigurationDetails.Zoom_Account_User_Id__c;
        }
        return zoomAccountUserId;
    }
    
    /******************************************************************************************************************
        Method Name  : FindZoomURLFromCustomSetting
        Description  : It finds zoom org URL from the custom setting named 'Zoom Configuration Settings'.
        Date         : 01 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String FindZoomURLFromCustomSetting(){
        String zoomURL;
        Zoom_Configuration_Settings__c zoomConfigurationDetails = Zoom_Configuration_Settings__c.getValues(Label.Config_Details_Custom_Setting_Name);
        If(zoomConfigurationDetails != null){
            zoomURL = zoomConfigurationDetails.Zoom_URL__c;
        }
        return zoomURL;
    }
    
    /******************************************************************************************************************
        Method Name  : sendEmail
        Description  : It sends email notification for the event invite.
        Parameter    : Email Address List, Mail body to send, Template id for email, Sender Display Name, ReplyTo Email Address, Email Subject
        Date         : 22 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String sendEmail(List<String> listOfToEmailAddress, List<String> listOfCCEmailAddress, String mailBody, String templateId, 
                                 String senderDisplayName, String ReplyToEmailAddress, String emailSubject, String targetObjectId,
                                 List<Messaging.Emailfileattachment> fileAttachments){
        try{
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            // Create a new Email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            if(listOfToEmailAddress != null && !listOfToEmailAddress.isEmpty()){
                //Set list of people who should get the email
                mail.setToAddresses(listOfToEmailAddress);
            }
            // Set who the email is sent from
            mail.setReplyTo(ReplyToEmailAddress);
            mail.setSenderDisplayName(senderDisplayName);
            // (Optional) Set list of people who should be CC'ed
            if(listOfCCEmailAddress != null && !listOfCCEmailAddress.isEmpty()){
                mail.setCcAddresses(listOfCCEmailAddress);
            }
            if(String.isNotBlank(templateId)){
                mail.setTemplateId(templateId);
            }
            // Set email contents - you can use variables!
            mail.setSubject(emailSubject);
            mail.setHtmlBody(mailBody);
            if(fileAttachments != null && !fileAttachments.isEmpty()){
                mail.setFileAttachments(fileAttachments);
            }
            mails.add(mail);
            if(!mails.isEmpty() && !Test.isRunningTest()){
                // Send all emails in the master list
                Messaging.sendEmail(mails);
            }
        }
        catch(Exception ex) {
            System.debug('SFZoom Meeting Manager Utility - send Email - Exception: ' + ex.getMessage());
            return ex.getMessage();
        }
        return null;
    }
    
    /******************************************************************************************************************
        Method Name : GenertePrivateCryptoKey
        Description : This method is used to generate private crypto Key.
        Date        : 23 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String GenerteEncryptedPrivateKeyText(){
        String randomCryptoKey;
        try{
            Blob cryptoKey = Crypto.generateAesKey(256);
            randomCryptoKey = EncodingUtil.base64Encode(cryptoKey);
        }catch(Exception ex) {
            System.debug('SFZoom Meeting Manager Utility - Generte Encrypted Private Key Text - Exception: ' + ex.getMessage());
        }
        return randomCryptoKey;
    }
    
    /******************************************************************************************************************
        Method Name : DecryptStringToBlob
        Description : This method is used to generate private crypto Key.
        Date        : 23 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    private static Blob DecryptStringToBlob(String dataToDecrypt){
        Blob cryptoKey = String.isNotBlank(dataToDecrypt) ? EncodingUtil.base64Decode(dataToDecrypt) : null;
        return cryptoKey;
    }
    

    /******************************************************************************************************************
        Method Name : EncryptData
        Description : This method is used to encrypt data using cryptoKey and AES256 Algorithm.
        Param1      : dataToEncrypt - Text Data which has to encrypt
        Param2      : cryptoKey - Private crypto Key generated using Crypto Class.
        Date        : 23 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static Blob EncryptData(String dataToEncrypt, Blob cryptoKey){
        // Generate the data to be encrypted.
        Blob data = String.isNotBlank(dataToEncrypt) ? Blob.valueOf(dataToEncrypt) : null;
        // Encrypt the data and have Salesforce.com generate the initialization vector
        Blob encryptedData = data != null && data.size() > 0 && cryptoKey != null && cryptoKey.size() > 0 ? Crypto.encryptWithManagedIV('AES256', cryptoKey, data) : null;
        return encryptedData;
    }
    
    /******************************************************************************************************************
        Method Name : DecryptData
        Description : This method is used to decrypt data using cryptoKey and AES256 Algorithm.
        Param1      : dataToEncrypt - Text Data which has to encrypt
        Param2      : cryptoKey - Private crypto Key generated using Crypto Class.
        Date        : 23 Nov 2018
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    private static String DecryptData(Blob encryptedData, Blob cryptoKey){
        // Decrypt the data - the first 16 bytes contain the initialization vector
        Blob decryptedData = encryptedData != null && encryptedData.size() > 0 && cryptoKey != null && cryptoKey.size() > 0 ? 
                                Crypto.decryptWithManagedIV('AES256', cryptoKey, encryptedData) : null;
        
        // Decode the decrypted data for subsequent use
        String decryptedDataString = decryptedData != null && decryptedData.size() > 0 ? decryptedData.toString() : null;
        return decryptedDataString;
    }
    
    /******************************************************************************************************************
        Method Name : DecryptData
        Description : This method is used to decrypt data using cryptoKey and AES256 Algorithm.
        Param1      : encryptedData - Encrypted data which we get from the URL parameters.
        Date        : 23 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String DecryptData(String encryptedData){
        String actualData;
        try{
            if(String.isNotBlank(encryptedData)){
                Blob decryptedCustomValue = DecryptStringToBlob(encryptedData);
                Zoom_Configuration_Settings__c zoomConfigurationDetails = Zoom_Configuration_Settings__c.getValues(Label.Config_Details_Custom_Setting_Name);
                String privateKeyValue = zoomConfigurationDetails != null && zoomConfigurationDetails.Crypto_Key__c != null ? 
                    zoomConfigurationDetails.Crypto_Key__c : Label.Default_Crypto_Key;
                Blob cryptoKey = DecryptStringToBlob(privateKeyValue); 
                actualData = DecryptData(decryptedCustomValue, cryptoKey);
            }
        }Catch(Exception ex) {
            System.debug('SFZoom Meeting Manager Utility - Decrypt Data - Exception: ' + ex.getMessage());
        }
        return actualData;
    }
    
    /******************************************************************************************************************
        Method Name : EncryptData
        Description : This method is used to encrypt data using cryptoKey and AES256 Algorithm.
        Param1      : dataToEncrypt - original data which needs to be encrypted before adding it in the URL parameters.
        Date        : 23 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String EncryptData(String dataToEncrypt){
        String encrypteddata;
        try{
            if(String.isNotBlank(dataToEncrypt)){
                Zoom_Configuration_Settings__c zoomConfigurationDetails = Zoom_Configuration_Settings__c.getValues(Label.Config_Details_Custom_Setting_Name);
                String privateKeyValue = zoomConfigurationDetails != null && zoomConfigurationDetails.Crypto_Key__c != null ? 
                    zoomConfigurationDetails.Crypto_Key__c : Label.Default_Crypto_Key;
                if(String.isNotBlank(privateKeyValue)){
                    Blob cryptoKey = DecryptStringToBlob(privateKeyValue);
                    Blob encryptedDataReturned = EncryptData(dataToEncrypt, cryptoKey);
                    encrypteddata = EncodingUtil.base64Encode(encryptedDataReturned);
                    encrypteddata = EncodingUtil.urlEncode(encrypteddata,'UTF-8');
                }
            }
        }Catch(Exception ex) {
            System.debug('SFZoom Meeting Manager Utility - Encrypt Data - Exception: ' + ex.getMessage());
        }
        return encrypteddata;
    }
    
    /******************************************************************************************************************
        Method Name : FindSetupObjectNameFromZoomMeeting
        Description : This method is used to find all the lookup fields on the Zoom Meeting object which is used to setup the zoom Meeting.
        Date        : 28 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String FindParentObjectRecordIdFromZoomMeeting(Id sfMeetingId){
        String parentObjectRecordId;
        try{
            List<Zoom_Meeting__c> listOfMeetings;
            if(sfMeetingId != null){
                List<String> listOfSetupObjectFields = FindListOfSetupObjectFeildNameFromZoomMeeting();
                String query = 'SELECT ';
                for(String meetingField : listOfSetupObjectFields){
                    if(meetingField.equalsIgnoreCase(listOfSetupObjectFields[0])){
                        query += meetingField;
                    }else{
                        query += ', '+meetingField;
                    }                
                }
                query += ' FROM Zoom_Meeting__c WHERE ID = \''+String.escapeSingleQuotes(SFMeetingId)+'\' LIMIT 1';
                if(SFZoom_AccessUtil.hasReadAccess(String.escapeSingleQuotes(sfMeetingId)) 
                   && SFZoom_AccessUtil.objectIsAccessible('Zoom_Meeting__c') 
                   && SFZoom_AccessUtil.objectIsQueryable('Zoom_Meeting__c') 
                   && SFZoom_AccessUtil.fieldsAreAccessible('Zoom_Meeting__c', listOfSetupObjectFields)){
                       
                       listOfMeetings = Database.query(query);
                       if(!listOfMeetings.isEmpty()){
                           for(String meetingField : listOfSetupObjectFields){
                               if(listOfMeetings[0].get(meetingField) != null){
                                   parentObjectRecordId = (String)listOfMeetings[0].get(meetingField);
                                   break;
                               }
                           }
                       }
                   }
            }
        } Catch(Exception ex){
            System.debug('SFZoom Meeting Manager Utility - Find Parent Object Record Id From Zoom Meeting - Exception: ' + ex.getMessage());
        }
        return parentObjectRecordId;
    }

    /******************************************************************************************************************
        Method Name : FindSetupObjectNameFromZoomMeeting
        Description : This method is used to find all the lookup fields on the Zoom Meeting object which is used to setup the zoom Meeting.
        Date        : 28 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static List<String> FindListOfSetupObjectFeildNameFromZoomMeeting(){
        List<String> listOfSetupOjbectName = new List<String>();
        try{
            Final String objName = 'Zoom_Meeting__c';
            Map<string, Map<String, Schema.SObjectField>> objectFieldsMap = new map<string, Map<String, Schema.SObjectField>>(); 
            Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
            for(Schema.SObjectField fld :objectFields.values()){
                schema.describeFieldResult dfield = fld.getDescribe();
                string fldType = string.valueOf(dfield.getType());   
                string fldName = string.valueOf(dfield.Name);
                if (fldType == 'REFERENCE' && fldName.endswith('__c')){ // Lookup field!
                    listOfSetupOjbectName.add(fldName);
                }
            }
        }Catch(Exception ex){
            System.debug('SFZoom Meeting Manager Utility - Find List Of Setup Object Field Name From Zoom Meeting - Exception: ' + ex.getMessage());
        }
        return listOfSetupOjbectName;
    }
    
    /******************************************************************************************************************
        Method Name : changeDateFormat
        Description : This method converts date format to DD-MMM-YYYY(Ex - 29-NOV-2018).
        Date        : 29 Nov 2018
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String changeDateFormat(Date dateToConvert){
        String convertedDate = '';
        if(dateToConvert != null){
            Integer day = dateToConvert.day();
            Integer month = dateToConvert.month();
            Integer year = dateToConvert.year();
            DateTime dt = DateTime.newInstance(year, month, day);
            String monthName= dt.format('MMM');
            convertedDate = day +'-'+monthName + '-'+year;
        }
        return convertedDate;
    }
    
    /******************************************************************************************************************
        Method Name : convertedTime
        Description : This method converts time format to MMM-DD-YYYY(Ex - Jul 27, 2017).
        Date        : 27 July 2017
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static String changeTimeFormat(Time timeToConvert){
        String convertedTime = '';
        if(timeToConvert != null){
            Datetime myDateTime = Datetime.newInstance(Date.today(), timeToConvert);
            convertedTime = myDateTime.format('h:mm a');
        }
        return convertedTime;
    }
    
    /******************************************************************************************************************
        Method Name : constructHttpRequestHeader
        Description : This method constructs HTTP Request header for making any http call.
        Date        : 27 July 2017
        Parameter1  : method - It contains the http method which needs to set (Ex- Get, Post etc.)
        Parameter1  : endPointUrl - It contains the end point URL which needs to set for the HTTP Call.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static HttpRequest constructHttpRequestHeader(String method, String endPointUrl){
        String accessToken = FindAuthorizationTokenFromCustomSetting();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setMethod(method);  
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');  
        req.setHeader('Authorization', AccessToken);
        return req;
    }
}