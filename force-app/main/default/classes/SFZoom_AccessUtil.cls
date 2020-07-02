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
    Class Name  : SFZoom_AccessUtil
    Description : This class is responsible verify all the type of permission like FLS, object permission and record permission.
    Date        : 01 Nov 2018.
    Author       : DataColada Pty Ltd
*******************************************************************************************************************/
public class SFZoom_AccessUtil {
    private static Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    
    /******************************************************************************************************************
        Method Name  : objectIsUpdateable
        Description  : It checks if an Object is updateable.
        Parameter1   : ObjectName - It holds the object name which is being checked for the access permission.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean objectIsUpdateable(String ObjectName) {
        try {
            List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(new String[]{ObjectName});

            if(describes.size() == 0) {
                return false;
            } else {
                Schema.DescribeSObjectResult describe = describes.get(0);
                if(describe.isUpdateable()) {
                    return true;
                } else {
                    return false;
                }
            }
        } catch(Exception ex) {
            System.debug('Access Check - object Is Updateable - Exception: ' + ex.getMessage());
            return false;
        }
    }

    /******************************************************************************************************************
        Method Name  : objectIsCreatable
        Description  : It checks if an Object is creatable.
        Parameter1   : ObjectName - It holds the object name which is being checked for the access permission.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean objectIsCreatable(String ObjectName) {
        try {
            List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(new String[]{ObjectName});
            if(describes.size() == 0) {
                return false;
            } else {                
                Schema.DescribeSObjectResult describe = describes.get(0);               
                if(describe.isCreateable()) {
                    return true;
                } else {
                    return false;
                }
            }
        } catch(Exception ex) {
            System.debug('Access Check - object Is Creatable - Exception: ' + ex.getMessage());
            return false;
        }
    }

    /******************************************************************************************************************
        Method Name  : objectIsAccessible
        Description  : It checks if an Object is being used for query is accessible.
        Parameter1   : ObjectName - It holds the object name which is being checked for the access permission.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean objectIsAccessible(String ObjectName ) {
        try {
            List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(new String[]{ObjectName});

            if(describes.size() == 0) {
                return false;
            } else {                
                Schema.DescribeSObjectResult describe = describes.get(0); 
                if(describe.isAccessible()) {
                    return true;
                } else {
                    return false;
                }
            }
        } catch(Exception ex) {
            System.debug('Access Check - object Is Accessible - Exception: ' + ex.getMessage());
            return false;
        }
    }    
    
    /******************************************************************************************************************
        Method Name  : objectIsQueryable
        Description  : It checks if the object being used is queryable
        Parameter1   : ObjectName - It holds the object name which is being checked for the access permission.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean objectIsQueryable(String ObjectName ) {
        try {
            List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(new String[]{ObjectName});
            if(describes.size() == 0) {
                return false;
            } else {                
                Schema.DescribeSObjectResult describe = describes.get(0); 
                if(describe.isQueryable()) {
                    return true;
                } else {
                    return false;
                }
            }
        } catch(Exception ex) {
            System.debug('Access Check - object Is Queryable - Exception: ' + ex.getMessage());
            return false;
        }
    }    
    
    /******************************************************************************************************************
        Method Name  : deleteRecordsWithAccessCheck
        Description  : It checks if the object being used is deletable
        Parameter1   : listToDelete - It holds the list of records which needs to be deleted.
        Parameter2   : allOrNone - It specify whether we allow partial delete or not.
        Date         : 11 Feb 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static List<Sobject> deleteRecordsWithAccessCheck(List<Sobject> listToDelete, Boolean allOrNone) {
        if(listToDelete != null && listToDelete.size() > 0){
            try{
                if((listToDelete[0].getSobjectType()).getDescribe().isAccessible() && (listToDelete[0].getSobjectType()).getDescribe().isDeletable()){
                    Database.Delete(listToDelete, allOrNone);
                    return listToDelete;
                }
                else{
                    return null;
                }
            }catch(Exception e) {
                system.debug('Access Check - delete Records With Access Check - Exception ==>'+e.getMessage());
            }
        }
        return null;
    }
    
    /******************************************************************************************************************
        Method Name  : fieldsAreUpdateable
        Description  : It checks if the field that the user is attempting to update is updateable
        Parameter1   : ObjectName - It holds the object name which is being checked for the access permission.
        Parameter2   : FieldNames - It holds the list of field name which is being checked for the access permission.
        Date         : 11 Feb 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean fieldsAreUpdateable(String objectName, List<string> FieldsToUpdate) {
        Boolean permission = true;
        try {
            if(String.isNotBlank(objectName) && getObjectUpdateAccessCheck(objectName)){
                Map<String,Schema.SObjectField> m = schemaMap.get( objectName ).getDescribe().fields.getMap();
                for (String fieldToCheck : FieldsToUpdate) {
                    if (!m.get(fieldToCheck).getDescribe().isAccessible() || !m.get(fieldToCheck).getDescribe().isUpdateable()){
                        permission  = false;
                        break;
                     }
                }
            }
        }
        catch(Exception e) {
            system.debug('Access Check - fields Are Updateable - Exception: '+e.getMessage());
            return false;
        }
        return permission;
    }
    /******************************************************************************************************************
        Method Name  : getObjectUpdateAccessCheck
        Description  : It checks if an Object is updateable.
        Parameter1   : ObjectName - It holds the object name which is being checked for the access permission.
        Date         : 11 Feb 2019.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    private static boolean getObjectUpdateAccessCheck(String objectName){
        try {
            Schema.DescribeSobjectResult drSObj = schemaMap.get(objectName) != null ? schemaMap.get(objectName).getDescribe() : null;
            if(drSObj != null && drSObj.isAccessible() && drSObj.isUpdateable()){
                return true;
            }else{
                return false;
            }
        }catch(Exception ex) {
            System.debug('Access Check - get Object Update Access Check - Exception: '+ex.getMessage());
            return false;
        }
        
    }
    
    /******************************************************************************************************************
        Method Name  : fieldsAreAccessible
        Description  : It checks the fields that the user is attempting to query are accessible
        Parameter1   : ObjectName - It holds the object name which is being checked for the access permission.
        Parameter2   : FieldNames - It holds the list of field name which is being checked for the access permission.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean fieldsAreAccessible(String ObjectName, List<String> FieldNames) {        
        try {
            List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(new String[]{ObjectName});
            if(describes.size() == 0) {
                return false;
            } else {
                Schema.DescribeSObjectResult describe = describes.get(0);
                boolean status;
                for(String currentField : fieldNames) {
                    Schema.SObjectField result = describe.fields.getMap().get(currentField);
                    if(result == null) {
                        status = false;
                        return status;
                    }

                    Schema.DescribeFieldResult fr = result.getDescribe();
                    if(fr.isAccessible()) {
                        status = true;
                    } else {
                        status = false;
                        return status;
                    }
                }
                return status;
            }
        } catch(Exception ex) {
            System.debug('Access Check - fields Are Accessible - Exception: ' + ex.getMessage());
            return false;
        }
    }
    
    /******************************************************************************************************************
        Method Name  : fieldsAreCreatable
        Description  : It checks the fields that the user is attempting to query are creatable
        Parameter1   : ObjectName - It holds the object name which is being checked for the access permission.
        Parameter2   : FieldNames - It holds the list of field name which is being checked for the access permission.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean fieldsAreCreatable(String ObjectName, List<String> FieldNames) {        
        try {
            List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(new String[]{ObjectName});
            if(describes.size() == 0) {
                return false;
            } else {
                Schema.DescribeSObjectResult describe = describes.get(0);
                boolean status;
                for(String currentField : fieldNames) {
                    Schema.SObjectField result = describe.fields.getMap().get(currentField);
                    if(result == null) {
                        status = false;
                        return status;
                    }

                    Schema.DescribeFieldResult fr = result.getDescribe();
                    if(fr.isAccessible() && fr.isCreateable()) {
                        status = true;
                    } else {
                        status = false;
                        return status;
                    }
                }
                return status;
            }
        } catch(Exception ex) {
            System.debug('Access Check - fields Are Accessible - Exception: ' + ex.getMessage());
            return false;
        }
    }

    /******************************************************************************************************************
        Method Name  : hasReadAccess
        Description  : It checks that the user has read access for that particular record which he/she is going to access.
        Parameter1   : Id - It holds the record Id for which read access would be checked.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean hasReadAccess(String Id) {
        try {
            UserRecordAccess uAccess = [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId=:UserInfo.getUserId() AND RecordId =: Id];
            return uAccess.HasReadAccess;
        } catch(Exception ex) {
            System.debug('Access Check - has Read Access - Exception: ' + ex.getMessage());
            return false;
        }
    }
    
    /******************************************************************************************************************
        Method Name  : hasEditAccess
        Description  : It checks that the user has edit access for that particular record which he/she is going to edit/update.
        Parameter1   : Id - It holds the record Id for which edit access would be checked.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean hasEditAccess(String Id) {
        try {
            UserRecordAccess uAccess = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId=:UserInfo.getUserId() AND RecordId =: Id];
            return uAccess.HasEditAccess;
        } catch(Exception ex) {
            System.debug('Access Check - has Edit Access - Exception: ' + ex.getMessage());
            return false;
        } 
    }
    
    /******************************************************************************************************************
        Method Name  : hasDeleteAccess
        Description  : It checks that the user has delete access for that particular record which he/she is going to delete.
        Parameter1   : Id - It holds the record Id for which delete access would be checked.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean hasDeleteAccess(String Id) {
        try {
            UserRecordAccess uAccess = [SELECT RecordId, HasDeleteAccess FROM UserRecordAccess WHERE UserId=:UserInfo.getUserId() AND RecordId =: Id];
            return uAccess.HasDeleteAccess;
        } catch(Exception ex) {
            System.debug('Access check - has Delete Access - Exception: ' + ex.getMessage());
            return false;
        }      
    }

    /******************************************************************************************************************
        Method Name  : hasDeleteAccessMulti
        Description  : It checks that the user has delete access for that particular record which he/she is going to delete.
        Parameter1   : Id - It holds the record Id for which delete access would be checked.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean hasDeleteAccessMulti(Set<Id> setOfRecordIds) {
        try {
            UserRecordAccess uAccess = [SELECT RecordId, HasDeleteAccess FROM UserRecordAccess WHERE UserId=:UserInfo.getUserId() AND RecordId IN: setOfRecordIds];
            return uAccess.HasDeleteAccess;
        } catch(Exception ex) {
            System.debug('Access Check - has Delete Access - Exception: ' + ex.getMessage());
            return false;
        }
    }
    
    /******************************************************************************************************************
        Method Name  : hasEditAccessMulti
        Description  : It checks that the user has edit access for all those records which he/she is going to edit/update.
        Parameter1   : setOfRecordIds - It holds all the record Ids for which edit access would be checked.
        Date         : 01 Nov 2018.
        Author       : DataColada Pty Ltd
    *******************************************************************************************************************/
    public static boolean hasEditAccessMulti(Set<Id> setOfRecordIds) {
        try {
            
            Boolean hasEditAccess = false;

            UserRecordAccess[] uAccess = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId=:UserInfo.getUserId() AND RecordId IN: setOfRecordIds];
            if(uAccess != null && uAccess.size() > 0) {
                hasEditAccess = uAccess[0].HasEditAccess;
            }

            return hasEditAccess;

        } catch(Exception ex) {
            System.debug('Access Check - has Edit Access - Exception: ' + ex.getMessage());
            return false;
        }      
    }
}