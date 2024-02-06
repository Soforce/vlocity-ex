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
        vEvent initialize(String eventId, String eventType, Datetime eventTime, String eventPayload); 
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
    public without sharing class vEvent {
        public String eventId { get; }
        public String eventType { get; }
        public Datetime eventTime { get; }
        public Object event;
        public List<vCharacteristic> analyticCharacteristic;
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

    }

    /**
     * 
     */
    public void process(String eventId, String eventType, Datetime eventTime, String eventPayload) {
        IEventService service = null;

        vEvent event = service.initialize(eventId, eventType, eventTime, eventPayload);
    }
}