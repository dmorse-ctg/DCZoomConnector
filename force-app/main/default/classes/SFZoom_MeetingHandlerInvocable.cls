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

global with sharing class SFZoom_MeetingHandlerInvocable{
    
    /******************************************************************************************************************
        Method Name  : sendEmail
        Description  : It sends email to event registrant's of an Event
        Date         : 24 May 2019
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    @InvocableMethod(label='Send Zoom Invitation/Confirmation Email') 
    public static void sendEmailToRegistrant(List<SendEmailRequest> request) {
        if(request[0].whoId!=null  && request[0].parentRecordId!=null){
          ZoomUtils.sendEmail(request[0].whoId, request[0].autoRegisterFlag, request[0].parentRecordId);
        }
    }
    
    global class SendEmailRequest {
        @InvocableVariable
        global Id whoId; //Contact/Lead Id

        @InvocableVariable
        global Boolean autoRegisterFlag;//Auto-Register Flag value
        
        @InvocableVariable
        global Id parentRecordId; //Parent Object Id from metadata
        
        global SendEmailRequest() {
            
        }    
    }  
}