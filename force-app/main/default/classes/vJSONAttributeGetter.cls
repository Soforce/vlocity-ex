public with sharing class vJSONAttributeGetter {
    public class Response {
        @InvocableVariable(label='Attribute' description='The attribute retrieved by the given attributeCodoe')
        public vNameValuePair attribute;
        public Response(vNameValuePair attribute) {
            this.attribute = attribute;
        }
        
        @InvocableVariable(label='Attributes' description='The attributes retrieved for the itemId')
        public List<vNameValuePair> attributes;
        public Response(vNameValuePair[] attributes) {
            this.attributes = attributes;
        }

    }  
   
    public class Request {
        @InvocableVariable(label='ItemId' description='Id of the record with JSONAttribute')
        public Id itemId;
        @InvocableVariable(label='AttributeCode' description='JSONAttribute code')
        public String attributeCode;
        
        public Request() {}

        public Request(Id itemId) {
            this.itemId = itemId;
        }  
        
        public Request(Id itemId, String attributeCode) {
            this.itemId = itemId;
            this.attributeCode = attributeCode;
        }  
    }

    @InvocableMethod(label='Get JSONAttribute' category='Vlocity Extension')
    public static List<Response> getAttributes(List<Request> requests) {
        vLogger.writeInfo('Enter vJSONAttributeGetter.getAttributes');
        try {
            vLogger.writeVar('requests', requests);

            Response resp;
            Request req = requests[0];
            if (req.attributeCode != null)  {
                resp = new Response(readAttribute(req.itemId, req.attributeCode));
            } else {
                resp = new Response(readAttributes(req.itemId));
            }

            vLogger.writeVar('resp', resp);
            return new List<Response> { resp };
        } catch (Exception ex) {
            vLogger.write(ex);
            throw ex;
        } finally {
            vLogger.writeInfo('Exit vJSONAttributeGetter.getAttributes');
        }
    }

    static vNameValuePair readAttribute(Id itemId, String attributeCode) {
        String jsonStr = readJSONAttribute(itemId);
        if (jsonStr != null && jsonStr != '') {
            vNameValuePair[] nvps = new List<vNameValuePair>();
            Object val = vHelper.getJSONAttributeValue(jsonStr, attributeCode);
            String strVal = val == null ? null : String.valueOf(val);
            vNameValuePair nvp = new vNameValuePair(attributeCode, strVal);

            return nvp;
        } else {
            return null;
        }
    }

    static vNameValuePair[] readAttributes(Id itemId) {
        String jsonStr = readJSONAttribute(itemId);
        if (jsonStr != null && jsonStr != '') {
            vNameValuePair[] nvps = new List<vNameValuePair>();
            Map<String, Object> attribNameVals = vHelper.getJSONAttributeValues(jsonStr);
            for (String name : attribNameVals.keySet()) {
                Object val = attribNameVals.get(name);
                String strVal = val == null ? null : String.valueOf(val);

                vNameValuePair nvp = new vNameValuePair(name, strVal);
                nvps.add(nvp);
            }

            return nvps;
        } else {
            return null;
        }
    }

    static String readJSONAttribute(Id itemId) {
        String query = 'SELECT vlocity_cmt__JSONAttribute__c FROM ' + itemId.getSobjectType().getDescribe().getName() + ' WHERE Id=:itemId';
        SObject item = Database.query(query);
        if (item != null)
            return (String)item.get('vlocity_cmt__JSONAttribute__c');
        else 
            return null;
    }
}
