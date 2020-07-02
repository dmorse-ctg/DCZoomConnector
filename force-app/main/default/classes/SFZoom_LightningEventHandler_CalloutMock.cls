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
Class Name  : SFZoom_LightningEventHandler_CalloutMock
Description : This class is responsible for providing JSON response to SFZoom_LightningEventHandler class
Date        : 03 Jan 2019
Author      : DataColada Pty Ltd
*******************************************************************************************************************/
@isTest
global with sharing class SFZoom_LightningEventHandler_CalloutMock implements HttpCalloutMock  {
    Boolean isWebinar;
    Boolean isAddMeetingParticipant;
    global SFZoom_LightningEventHandler_CalloutMock(Boolean isWebinar, Boolean isAddMeetingParticipant){
        this.isWebinar = isWebinar;
        this.isAddMeetingParticipant = isAddMeetingParticipant;
    }
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');         
        response.setHeader('Authorization', 'Basic YXBmFtaWx5');
        if(isWebinar){
            response.setBody('{"uuid":"fwwkgAPjSM6V5jNVXpCxfg==","id":182061822,"host_id":"Qi79NR8_TXqkvj4uV5GBzg","topic":"Test Topic","start_time":"2018-11-29T05:00:00Z","duration":30,"timezone":"Australia/Sydney","agenda":"Test Agenda","join_url":"https://zoom.us/j/182061822","settings":{ "participant_video":true,"join_before_host":true,"mute_upon_entry":true,"use_pmi":false,"enforce_login":true }}');
            System.assertEquals('{"uuid":"fwwkgAPjSM6V5jNVXpCxfg==","id":182061822,"host_id":"Qi79NR8_TXqkvj4uV5GBzg","topic":"Test Topic","start_time":"2018-11-29T05:00:00Z","duration":30,"timezone":"Australia/Sydney","agenda":"Test Agenda","join_url":"https://zoom.us/j/182061822","settings":{ "participant_video":true,"join_before_host":true,"mute_upon_entry":true,"use_pmi":false,"enforce_login":true }}', response.getBody());
            System.assertNotEquals('', response.getBody());
        }
        if(!isWebinar){
            response.setBody('{"uuid":"fwwkgAPjSM6V5jNVXpCxfg==","id":182061825,"host_id":"Qi79NR8_TXqkvj4uV5GBtr","topic":"Test Topic","start_time":"2018-11-29T05:00:00Z","duration":30,"timezone":"Australia/Sydney","agenda":"Test Agenda","join_url":"https://zoom.us/j/182061825","settings":{ "participant_video":true,"join_before_host":true,"mute_upon_entry":true,"use_pmi":false,"enforce_login":true }}');
            System.assertEquals('{"uuid":"fwwkgAPjSM6V5jNVXpCxfg==","id":182061825,"host_id":"Qi79NR8_TXqkvj4uV5GBtr","topic":"Test Topic","start_time":"2018-11-29T05:00:00Z","duration":30,"timezone":"Australia/Sydney","agenda":"Test Agenda","join_url":"https://zoom.us/j/182061825","settings":{ "participant_video":true,"join_before_host":true,"mute_upon_entry":true,"use_pmi":false,"enforce_login":true }}', response.getBody());
            System.assertNotEquals('', response.getBody());
        }
        if(isAddMeetingParticipant){
            response.setBody('{"registrant_id":"2rUUUTQvSayZ2IDCu5ewaw","id":775031389,"topic":"test meeting","start_time":"2018-11-28T01:00:00Z","join_url":"https://zoom.us/w/775031389?tk=BS6buYHGJG--RrRsBo0wfCadCBRIVsci76yz1M-BmLY.DQEAAAAALjIKXRYyclVVVVRRdlNheVoySURDdTVld2F3AA"}');
            System.assertEquals('{"registrant_id":"2rUUUTQvSayZ2IDCu5ewaw","id":775031389,"topic":"test meeting","start_time":"2018-11-28T01:00:00Z","join_url":"https://zoom.us/w/775031389?tk=BS6buYHGJG--RrRsBo0wfCadCBRIVsci76yz1M-BmLY.DQEAAAAALjIKXRYyclVVVVRRdlNheVoySURDdTVld2F3AA"}', response.getBody());
            System.assertNotEquals('', response.getBody());
        }
        response.setStatusCode(204);
        System.assertEquals(204, response.getStatusCode());
        return response; 
    }
}