public virtual with sharing class vEventNotificationBaseService {
    public vEventNotificationBaseService() {

    }

    public virtual void process(Event_Notification__c evt) {

    } 


    public virtual String getPrimaryKey() {
        return '';
    }

    public virtual String getRelyOnKey() {
        return '';
    }

    public virtual String getMemoryDump() {
        return '';
    }   
    
    /**
     * @description Sample Service Provider Class
     */
    public class SampleService extends vEventNotificationBaseService {

    }
}