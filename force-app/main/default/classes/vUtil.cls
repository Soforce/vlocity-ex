/**
 * @descripition Utility class
 */
public class vUtil {
    public static Object compareSObjs(Id fromId, Id toId) {
        return compareSObjs(fromId, toId, true);
    }

    public static Object compareSObjs(Id fromId, Id toId, Boolean excludeSystemFields) {
        Set<String> systemFNames = new Set<String> {
            'lastreferenceddate',
            'lastvieweddate',
            'systemmodstamp',
            'createddate',
            'lastmodifieddate'
        };

        SObjectType objType = fromId.getSObjectType();
        Map<String, SObjectField> fldMap = objType.getDescribe().fields.getMap();
        List<String> fnames = new List<String>(fldMap.keySet());
        String query = 'SELECT ' + String.join(fnames, ',') + ' FROM ' + objType.getDescribe().getName() + ' WHERE Id=:fromId OR Id=:toId';
        Map<Id, SObject> resultMap = new Map<Id, SObject>(Database.query(query));
        SObject fromObj = resultMap.get(fromId);
        SObject toObj = resultMap.get(toId);

        Map<String, List<Object>> diffMap = new Map<String, List<Object>>();
        for (String fname : fnames) {
            if (excludeSystemFields && systemFNames.contains(fname)) {
                continue;
            }

            Object fromVal = fromObj.get(fname);
            Object toVal = toObj.get(fname);
            if (fromVal != toVal) {
                System.debug(fname + ': ' + fromVal + ' - ' + toVal);
                diffMap.put(fname, new List<Object> { fromVal, toVal });
            } 

        }

        return diffMap;
    }

    // public static SObject getSObject(Id objId) {
    //     SObjectType objType = objId.getSObjectType();
    //     Map<String, SObjectField> fldMap = objType.getDescribe().fields.getMap();
    //     List<String> fnames = new List<String>(fldMap.keySet());
    //     String query = 'SELECT ' + String.join(fnames, ',') + ' FROM ' + objType.getDescribe().getName() + ' WHERE Id=:objId';
    //     SObject resultObj = Database.query(query);

    //     // System.debug(JSON.serialize(resultObj));
    //     for (String fname : fnames) {
    //         System.debug(fname + ': ' + resultObj.get(fname));
    //     }
    //     return resultObj;
    // }

    // public static List<String> getSObjectFieldNames(SObjectType objectType) {
    //     Map<String, SObjectField> fldMap = objectType.getDescribe().fields.getMap();
    //     List<String> fnames = new List<String>(fldMap.keySet());
    //     return fnames;
    // }

    // public static Id cloneWithProducts(Id srcId) {
    //     SObjectType headerObjType = srcId.getSObjectType();
    //     // Clone parent SObject
    //     String query = 'SELECT ' + String.join(getSObjectFieldNames(headerObjType), ',') + ' FROM ' + headerObjType.getDescribe().getName() + ' WHERE Id=:srcId';
    //     System.debug(query);
    //     SObject headerObj = Database.query(query);
    //     SObject cloneObj = headerObj.clone(false, false, false, false);
    //     insert cloneObj;

    //     SObjectType childObjType;
    //     String parentIdFieldName;
    //     // Clone child SObject
    //     if (headerObjType == Opportunity.SObjectType) {
    //         childObjType = OpportunityLineItem.SObjectType;
    //         parentIdFieldName = 'OpportunityId';
    //     } else if (headerObjType == Quote.SObjectType) {
    //         childObjType = QuoteLineItem.SObjectType;
    //         parentIdFieldName = 'QuoteId';
    //     } else if (headerObjType == Order.SObjectType) {
    //         childObjType = OrderItem.SObjectType;
    //         parentIdFieldName = 'OrderId';
    //     }
    //     query = 'SELECT ' + String.join(getSObjectFieldNames(childObjType), ',') + ' FROM ' + childObjType.getDescribe().getName() + ' WHERE ' + parentIdFieldName + '=:srcId';
    //     SObject[] productObjs = Database.query(query);
    //     SObject[] cloneProducts = new List<SObject>();
    //     for (SObject productObj : productObjs) {
    //         SObject cloneProduct = productObj.clone(false, false, false, false);
    //         cloneProduct.put(parentIdFieldName, cloneObj.Id);
    //         cloneProducts.add(cloneProduct);
    //     }
    //     insert cloneProducts;
        
    //     System.debug('Header Id: ' + JSON.serialize(cloneObj.Id));
    //     System.debug('Product Item Ids: ' + JSON.serialize(new Map<Id, SObject>(cloneProducts).keySet()));

    //     return headerObj.Id;
    // }
}