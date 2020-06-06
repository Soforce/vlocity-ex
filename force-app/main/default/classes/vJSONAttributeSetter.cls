public with sharing class vJSONAttributeSetter {
    public class Request {
        @InvocableVariable(label='ItemId' description='Id of the record to set JSON Attribute')
        public Id itemId;

        @InvocableVariable(label='attribute' description='The attribute to update')
        public vNameValuePair attribute;
        
        @InvocableVariable(label='attributes' description='The attributes to update')
        public vNameValuePair[] attributes;

        public Request() {}

        public Request(Id itemId, vNameValuePair attribute) {
            this.itemId = itemId;
            this.attribute = attribute;
        }  
        
        public Request(Id itemId, vNameValuePair[] attributes) {
            this.itemId = itemId;
            this.attributes = attributes;
        }  
    }

    @InvocableMethod(label='Set JSONAttribute' category='Vlocity Extension')
    public static void setAttributes(List<Request> requests) {
        Request req = requests[0];
        vNameValuePair[] attrVals;
        if (req.attribute != null)  {
            attrVals = new List<vNameValuePair> { req.attribute };
        } else {
            attrVals = req.attributes;
        }

        setAttributes(req.itemId, attrVals);
    }

    static void setAttributes(Id itemId, vNameValuePair[] attribValues) {
        vLogger.writeInfo('Enter vJSONAttributeSetter.setAttributes');
        try {
            String query = 'SELECT Id, vlocity_cmt__JSONAttribute__c FROM ' + itemId.getSobjectType().getDescribe().getName() + ' WHERE Id=:itemId';
            SObject item = Database.query(query);
            if (item != null && item.get('vlocity_cmt__JSONAttribute__c') != null) {
                Map<String, Object> attribValMap = new Map<String, Object>();
                for (vNameValuePair attribValue : attribValues) {
                    attribValMap.put(attribValue.name, attribValue.value);
                }
    
                String modifiedJSON = vHelper.setJSONAttributes((String)item.get('vlocity_cmt__JSONAttribute__c'), '{}', attribValMap);
                item.put('vlocity_cmt__JSONAttribute__c', modifiedJSON);

                vLogger.writeVar('modifiedJSON', modifiedJSON);
                update item;
            }
        } catch (Exception ex) {
            vLogger.write(ex);
            throw ex;
        } finally {
            vLogger.writeInfo('Exit vJSONAttributeSetter.setAttributes');
        }
    }

}
