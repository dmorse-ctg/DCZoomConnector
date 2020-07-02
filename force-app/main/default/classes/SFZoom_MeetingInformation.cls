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
    Class Name  : SFZoom_ZoomMeetingInformation
    Description : This class is a wrapper class which is used to bind meeting details or information for Salesforce and Zoom Integration.
    Date        : 01 Nov 2018.
    Author      : DataColada Pty Ltd
*******************************************************************************************************************/
public with sharing class SFZoom_MeetingInformation {
    public String topic {get;set;} 
	public String type {get;set;}
	public String start_time {get;set;} 
	public String duration {get;set;} 
	public String timezone {get;set;} 
	public String password {get;set;} 
	public String agenda {get;set;} 
	public SFZoom_MeetingSettings settings {get;set;} 
    
    /******************************************************************************************************************
        Class Name  : SFZoom_Settings
        Description : This class is a wrapper class which is used to bind meeting settings for Salesforce and Zoom Integration.
        Date        : 01 Nov 2018.
        Author      : DataColada Pty Ltd
	*******************************************************************************************************************/
	public with sharing class SFZoom_MeetingSettings {
		// Start video when host joins meeting
		public String host_video {get;set;}
		// Start video when participants join meeting
		public String participant_video {get;set;}
		// Host meeting in China
		public String cn_meeting {get;set;}
		// Host meeting in India
		public String in_meeting {get;set;}
		// Allow participants to join the meeting before the host starts the meeting. 
		// Only used for scheduled or recurring meetings.
		public String join_before_host {get;set;}
		// Mute participants upon entry
		public String mute_upon_entry {get;set;}
		// Add watermark when viewing shared screen
		public String watermark {get;set;}
		// Use Personal Meeting ID. 
		// Only used for scheduled meetings and recurring meetings with no fixed time.
		public String use_pmi {get;set;}
		// approval_type - 0-Automatically Approve, 1-Manually Approve, 2-No Registration Required
		public String approval_type {get;set;} 
		//registration_type - Registration type. Used for recurring webinar with fixed time only.
        // (1-Attendees register once and can attend any of the occurrences, 2-Attendees need to register for each occurrence to attend,
        // 3- Attendees register once and can choose one or more occurrences to attend)
        public String registration_type {get; set;}
        // audio - Determine how participants can join the audio portion of the meeting. (both-Both Telephony and VoIP, 
        // telephony-Telephony only, voip-VoIP only)
		public String audio {get;set;} 
		// auto_recording - local-Record to local device, cloud-Record to cloud, none-No Recording
		public String auto_recording {get;set;}
		// enforce_login - Only signed-in users can join this meeting 
		public String enforce_login {get;set;}
		//enforce_login_domains - Only signed-in users with specified domains can join meetings
		public String enforce_login_domains {get;set;}
		// alternative_hosts - Alternative hosts emails or IDs. Multiple values separated by comma
		public String alternative_hosts {get;set;} 
    }
}