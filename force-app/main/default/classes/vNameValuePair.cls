/** 
 * @description generic Name Value pair data structure.
 */
public class vNameValuePair {
    @AuraEnabled
    public String name;

    @AuraEnabled
    public String value;

    public vNameValuePair(String name, String value) {
        this.name = name;
        this.value = value;
    }
    
}
