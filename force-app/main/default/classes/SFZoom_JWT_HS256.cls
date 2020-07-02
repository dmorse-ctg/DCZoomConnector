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
    Class Name  : SFZoom_JWT_HS256
    Description : This class is responsible to generate Authorization token which is used during Zoom API call.
    Date        : 01 Nov 2018.
    Author       : DataColada Pty Ltd
*******************************************************************************************************************/
public with sharing class SFZoom_JWT_HS256 {

    public String alg {get;set;}
    public String iss {get;set;}
    public String exp {get;set;}
    public Integer validForMilliSec {get;set;}
    public String privateKey {get;set;}
    // Constructor which accepts alogirthm name, API Key, API Secret and Milliseconds
    public SFZoom_JWT_HS256(String alg, String iss, String privateKey, Integer validForMilliSec) {
        this.alg = alg;
        this.iss = iss;
        this.privateKey = privateKey;
        this.validForMilliSec = validForMilliSec;
    }
    
	/******************************************************************************************************************
        Method Name  : generateAuthToken
        Description  : It generates authorization token which is used during API call.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public String generateAuthToken() {
        String jwt = '';
        try{
            JSONGenerator header = JSON.createGenerator(false);
            header.writeStartObject();
            header.writeStringField('alg', this.alg);
            header.writeEndObject();
            String encodedHeader = base64URLencode(Blob.valueOf(header.getAsString()));
            
            JSONGenerator body = JSON.createGenerator(false);
            
            body.writeStartObject();
            body.writeStringField('iss', this.iss);
            body.writeNumberField('exp', (DateTime.now().getTime() + validForMilliSec));
            body.writeEndObject();
            
            jwt = encodedHeader + '.' + base64URLencode(Blob.valueOf(body.getAsString()));        
            
            Blob key = Blob.valueOf(privateKey);
            Blob signature = Crypto.generateMac('hmacSHA256', Blob.valueof(jwt), key);
            jwt += '.' + base64URLencode(signature);
        }Catch(Exception ex){
            System.debug('SFZoom_JWT_HS256 - generateAuthToken - Exception: ' + ex.getMessage());
        }
        return Label.Zoom_Auth_Token_Prefix +' ' +jwt;
    }

    /******************************************************************************************************************
        Method Name  : base64URLencode
        Description  : It encodes input into base 64 URl format.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private String base64URLencode(Blob input) { 

        String output = EncodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');

        while ( output.endsWith('=')) {
            output = output.subString(0, output.length() - 1);
        }
        return output;
    }

}