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
    Class Name  : SFZoom_WebinarInformation
    Description : This class is a wrapper class which is used to bind webinar details or information for Salesforce and Zoom Integration.
    Date        : 17 Nov 2018.
    Author      : DataColada Pty Ltd
*******************************************************************************************************************/
public with sharing class SFZoom_WebinarInformation {
    public String topic {get;set;} 
    public String type {get;set;}
    public String start_time {get;set;} 
    public String duration {get;set;} 
    public String timezone {get;set;} 
    public String password {get;set;} 
    public String agenda {get;set;} 
    public SFZoom_WebinarSettings settings {get;set;} 
    
    /******************************************************************************************************************
        Class Name  : SFZoom_Settings
        Description : This class is a wrapper class which is used to bind webinar settings for Salesforce and Zoom Integration.
        Date        : 17 Nov 2018.
        Author      : DataColada Pty Ltd
    *******************************************************************************************************************/
    public with sharing class SFZoom_WebinarSettings {
        public String host_video {get;set;} 
        public String panelists_video {get; set;}
        public String practice_session {get; set;}
        public String hd_video {get; set;}
        public String approval_type {get;set;} 
        public String registration_type {get; set;}
        public String audio {get;set;} 
        public String auto_recording {get;set;} 
        public String enforce_login {get;set;} 
        public String enforce_login_domains {get;set;} 
        public String alternative_hosts {get;set;} 
        public String close_registration {get;set;} 
        public String show_share_button {get;set;} 
        public String allow_multiple_devices {get;set;} 
        public String on_demand {get; set;}
    }
}