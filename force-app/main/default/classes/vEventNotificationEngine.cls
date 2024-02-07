/**
 * 
 */
public without sharing class vEventNotificationEngine {
    public static final Integer MAX_RETRY_COUNT = 3; 
    
    public class EventNotificationInvalidEventException extends Exception {}
    public class EventNotificationRetriableException extends Exception {}
    public class EventNotificationIgnorableException extends Exception {}
    public class EventNotificationPendingException extends Exception {}
    public class EventNotificationFatalException extends Exception {}
    

    /**
     * @description Interface to be implemented by the event service provider class
     */
    public interface IEventService {
        /**
         * @description convert event payload to the JSON object, validate the JSON and generate the event object
         */
        Event initialize(String eventId, String eventType, Datetime eventTime, String eventPayload); 
        void preprocess(Event event);
        void process(Event event);
        void postprocess(Event event);

        String getPrimaryKey();
        String getRelyOnKey();
        String getEventTag();
    }

    public without sharing class vCharacteristic {
        public String id;
        public String name;
        public Object value;
        public String valueType;
    }

    /**
     * @description Event Notification entity (data) structure
     */
    public without sharing class Event {
        public String eventId { get; }
        public String eventType { get; }
        public Datetime eventTime { get; }
        public Object event;
        public List<vCharacteristic> analyticCharacteristic;
        public Integer retryCount { get; set; }
    }

    
    /**
     * @description Retriable queue processor to retry the events with "Retriable Error"
     */
    public class vRetriableQueueProcessor implements Queueable {
        private Id retriableEventId;
        
        public vRetriableQueueProcessor(Id retriableEventId) {
            this.retriableEventId = retriableEventId;
        } 

        public void execute(QueueableContext context) {
            try {
                vEventNotificationEngine engine = new vEventNotificationEngine();
                // engine.retryEvent(retriableEventId);
            } catch (Exception ex) {
                vLogger.write(ex);
            } finally {

            }
        }        
    }

    /**
     * @description Rely-on Queue Processor to process events whose dependency has been resolved.  
     */
    public class vRelyOnQueueProcessor implements Queueable {
        private List<Id> relyOnEventIds;
        private Integer index;
        
        public vRelyOnQueueProcessor(List<String> relyOnEventIds, Integer index) {
            this.relyOnEventIds = relyOnEventIds;
            this.index = index;
        }
        
        public void execute(QueueableContext context) {
            try {
                vEventNotificationEngine engine = new vEventNotificationEngine();
                Event_Notification__c myEvent;
                Id eventId = relyOnEventIds[index];
                // myEvent = engine.getEvent(eventId);    
                // myEvent = engine.reprocessEvent(myEvent, false);
            } catch (Exception ex) {
                vLogger.write(ex);
            } finally {
                // Continue to process the next dependent Event
                if (index + 1 < relyOnEventIds.size())
                    System.enqueueJob(new vRelyOnQueueProcessor(this.relyOnEventIds, index + 1));
            }
        }
    } 
    
    
    /**
     * @description helper method to return the detail error message of the exception
     */
    public String getErrorMessage(Exception ex) {
        return ex.getMessage() + '\n' + ex.getStackTraceString();
    }


    public vEventNotificationEngine() {

    }

    /**
     * @description instantiate the service provider by the event type
     */
    public IEventService getEventServiceProvider(String eventType) {
        Event_Notification_Service_Provider__mdt[] svsProviders = [SELECT Id,DeveloperName, Event_Type__c, Service_Class__c FROM Event_Notification_Service_Provider__mdt WHERE Event_Type__c=:eventType];
        if (svsProviders.size() == 0)
            throw new EventNotificationFatalException('There is NO event service provider class registered for ' + eventType + ' event.');
        
        String className = svsProviders[0].Service_Class__c;
        try {
            Type t = Type.forName(className);
            IEventService service = (IEventService)t.newInstance();

            return service;
        } catch (Exception ex) {
            throw new EventNotificationFatalException('Cannot instantiate ' + className + ' service provider class for ' + eventType + '.', ex);
        }
    }

    /**
     * 
     */
    public void process(String eventId, String eventType, Datetime eventTime, String eventPayload) {
        IEventService service = null;
        Event event = null;

        try {
            // get the service provider class for the given eventType
            service = getEventServiceProvider(eventType);
            // initialize - JSON.deseriablize & validate
            Event event = service.initialize(eventId, eventType, eventTime, eventPayload);
            // preprocess the event JSON object. 
            service.preprocess(event, ctx);

            // check if the current event needs to be ignored.
            if (isEventIgnorable(eventType, eventTime, serivce.getPrimaryKey())) {
                throw new EventNotificationIgnorableException('The event is ignored because a later event for the same record and type has already been received.');
            }

            // Prepare the context variable
            Map<String, Object> ctx = new Map<String, Object>();
            //
            service.process(event, ctx);
            //
            service.postprocess(event, ctx);

        } catch (EventNotificationRetriableException ex) {

        } catch (Exception ex) {

        }

    }

    /**
     * @description the current event should be ignored if a later event for the same record was received already. 
     */
    public Boolean isEventIgnorable(String eventType, String eventTime, String primaryKey) {
        if (primaryKey == null || eventTime == null) return false;

        Event_Notification__c[] evts = [SELECT Id FROM Event_Notification__c WHERE Primary_Key__c=:primaryKey AND Event_Time__c>:eventTime];
        return evts.size() > 0;
    }
}