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
        void initialize(Event event, Map<String, Object> contextVariables); 
        // void preprocess(Event event, Map<String, Object> contextVariables);
        void process(Event event, Map<String, Object> contextVariables);
        // void postprocess(Event event, Map<String, Object> contextVariables);

        String getPrimaryKey(Event event, Map<String, Object> contextVariables);
        // String getRelyOnKey();
        // String getEventTag();
    }

    /**
     * @description Describes a given characteristic of an object or entity through a name/value pair.
     */
    public without sharing class Characteristic {
        public String id;
        public String name;
        public Object value;
        public String valueType;
    }

    /**
     * @description Event Notification entity (data) structure
     */
    public without sharing virtual class Event {
        // unique identifier.
        public String id; 
        // The correlation id for this event.
        public String correlationId;
        // The identifier of the notification.
        public String eventId;
        // The type of the notification.
        public String eventType;
        // Time of the event occurrence.
        public Datetime eventTime;
        // An any (Any). The event linked to the involved resource object.
        public Object event;
        // Describes a given characteristic of an object or entity through a name/value pair.
        public List<Characteristic> analyticCharacteristic;
        // The JSON payload String
        protected String jsonPayload;
        // public transient String status;
        // public transient String errorMessage; 
        // public transient Integer retryCount { get; set; }
        // public transient String primaryKey;
        // public transient String relyOnKey;
        // public transient String tag;

        // private transient String payload; 
        // public Event_Notification__c toSObject() {
        //     return new Event_Notification__c(
        //         Id = this.id,
        //         Event_Id__c = eventId,
        //         Event_Type__c = eventType,
        //         Event_Time__c = eventTime
        //     );
        // }

        // public void init(Event_Notification__c eventObj, IEventService service) {
        //     this.id = eventObj.Id;
        //     this.eventId = eventObj.Event_Id__c;
        //     this.eventType = eventObj.Event_Type__c;
        //     this.eventTime = eventObj.Event_Time__c;

        //     this.event = service.descrializeJSON(eventObj);
        // }
    }

    
    /**
     * @description Retriable queue processor to retry the events with "Retriable Error"
     */
    public class RetriableQueueProcessor implements Queueable {
        private Id retriableEventId;
        
        public RetriableQueueProcessor(Id retriableEventId) {
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
    public class RelyOnQueueProcessor implements Queueable {
        private List<Id> relyOnEventIds;
        private Integer index;
        
        public RelyOnQueueProcessor(List<String> relyOnEventIds, Integer index) {
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
                    System.enqueueJob(new RelyOnQueueProcessor(this.relyOnEventIds, index + 1));
            }
        }
    } 
    
    
    /**
     * @description Data access class for event staging object
     */
    public class StagingObjectAccess {
        private String getSafeString(String value, Integer maxLength) {
            if (value == null) return null;
            else if (value.length() < maxLength) return value;
            else return value.left(maxLength);
        }
        
        private String getSafeString(Map<String, Object> contextVariables, String name, Integer maxLength) {
            String value = (String)contextVariables.get('name');
            return getSafeString(value, maxLength);
        }

        public void upsertRecord(Event event, Map<String, Object> contextVariables) {
            try {
                Event_Notification__c eventStagingRec = new Event_Notification__c(
                    Primary_Key__c = getSafeString(contextVariables, 'primaryKey', 128),
                    Rely_on_Key__c = getSafeString(contextVariables, 'relyOnKey', 255),
                    Event_Tag__c = getSafeString(contextVariables, 'eventTag', 255),
                    Retry_Count__c = contextVariables.get('Retry_Count__c') == null ? 0 : (Integer)contextVariables.get('Retry_Count__c'),
                    Status__c = getSafeString(contextVariables, 'status', 128),
                    Error_Message__c = getSafeString(contextVariables, 'errorMessage', 131072),
                    Memory_Dump__c = getSafeString(contextVariables, 'memoryDump', 131072),
                    Performance_Matrix__c = getSafeString(contextVariables, 'performance', 255)
                );

                if (event.id == null) {
                    // brand new record
                    eventStagingRec.Event_Id__c = getSafeString(event.eventId, 64);
                    eventStagingRec.Event_Time__c = event.eventTime;
                    eventStagingRec.Event_Type__c = getSafeString(event.eventType, 32);
                    eventStagingRec.Event_Payload__c = getSafeString(event.jsonPayload, 131072);

                    insert eventStagingRec;
                } else {
                    update eventStagingRec;
                }
            } catch (Exception ex) {
                vLogger.write(ex);
            }
        }

        /**
         * @description the current event should be ignored if a later event for the same record was received already. 
         */
        public Boolean isEventIgnorable(Event event, Map<String, Object> contextVariables, IEventService service) {
            String primaryKey = service.getPrimaryKey(event, contextVariables);
            if (event.eventTime == null || primaryKey == null) return false;
    
            Event_Notification__c[] evts = [SELECT Id FROM Event_Notification__c WHERE Primary_Key__c=:primaryKey AND Event_Time__c>:event.eventTime];
            return evts.size() > 0;
        }        

        public List<Id> getDependentEventRecordIds(Event event, Map<String, Object> contextVariables, IEventService service) {
            String primaryKey = service.getPrimaryKey(event, contextVariables);

            if (String.isNotEmpty(primaryKey)) {
                Event_Notification__c[] dependentEvents = [
                    SELECT Id FROM Event_Notification__c 
                    WHERE Rely_on_Key__c = :primaryKey AND Status__c = 'Pending'
                ];

                return new List<Id>((new Map<Id, Event_Notification__c>(dependentEvents)).keySet());
            } else {
                return new List<Id>(); // Empty list
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
    public void process(String eventRecordId) {
        try {
            Event_Notification__c myEvent = [
                SELECT Id, Entity__c, Error_Message__c, Event_Id__c, Event_Payload__c, Event_Time__c, Event_Type__c, Memory_Dump__c, Name, Performance_Matrix__c, Primary_Key__c, Rely_on_Key__c, Retry_Count__c, Status__c 
                FROM Event_Notification__c WHERE Id=:eventRecordId
            ];
        
        } catch (Exception ex) {

        }
    }

    /**
     * 
     */
    public void process(String eventId, String eventType, Datetime eventTime, String eventPayload) {
        // try {
        //     IEventService service = getEventServiceProvider(eventType);
        //     Event event = serivce.initialize(eventId, eventType, eventTime, eventPayload);

        //     process(event, service);
        // } catch (Exception ex) {

        // }

        // Event event = new Event(eventId, eventType, eventTime, eventPayload);

        // process(event);

    }

    /**
     * @description 
     */
    public void process(Event event, Boolean testRun) {
        Map<String, Object> ctx = new Map<String, Object> {
            'testRun' => testRun,
            'status' => 'In Progress',
            'errorMessage' => null
        };



    }

    /**
     * @description event processing context object
     */
    private void process(Event event, Map<String, Object> ctx) {
        Boolean testRun = (Boolean)ctx.get('testRun');
        IEventService service = null;
        StagingObjectAccess eventDataAccess = new StagingObjectAccess();


        // Savepoint for roll-back in case of error or test mode
        Savepoint eventSP = Database.setSavepoint();
        // transaction starting time, used for capturing performance data
        Integer start = Datetime.now().millisecond();

        try {
            // get the service provider class for the given eventType
            service = getEventServiceProvider(event.eventType);
            // initialize - JSON.deseriablize & validate
            service.initialize(event, ctx);

            // check if the current event needs to be ignored.
            if (eventDataAccess.isEventIgnorable(event, ctx, service)) {
                throw new EventNotificationIgnorableException('The event is ignored because a later event for the same record and type has already been received.');
            }

            //
            service.process(event, ctx);
            
            // process dependent events
            if (!testRun) {
                // Skip if in test run mode
                List<Id> depIds = eventDataAccess.getDependentEventRecordIds(event, ctx, service);
                if (depIds != null && depIds.size() >0) {
                    processDependentEvents(depIds, event, ctx, service);
                }
            }

            if (testRun) {
                // Roll back all DMLs on test run
                Database.rollback(eventSP);
            }

        } catch (EventNotificationRetriableException ex) {
            // Rollback any previous DMLs for data integrity
            Database.rollback(eventSP);
            // Retry the event async by the queue
            if (!testRun) {
                // Skip if in test run mode
                System.enqueueJob(new RetriableQueueProcessor(event.Id));
            }

            ctx.put('status', 'Retriable Error');
            ctx.put('errorMessage', getErrorMessage(ex));

            vLogger.write(ex);
        } catch (Exception ex) {
            // Rollback any previous DMLs for data integrity
            Database.rollback(eventSP);

            if (ex instanceOf EventNotificationIgnorableException) {
                ctx.put('status', 'Ignored');
            } else if (ex instanceOf EventNotificationPendingException) {
                ctx.put('status', 'Pending');
            } else {
                ctx.put('status', 'Fatal Error');
            }
            ctx.put('errorMessage', getErrorMessage(ex));

            vLogger.write(ex);
        } finally {
            Integer stop = Datetime.now().millisecond();
            Integer xactTime = stop - start; // ms used to execute this transaction

            if (!testRun) {
                // Upsert Event Staging Object
                eventDataAccess.upsertRecord(event, ctx);
            }
        }
    }


    // protected virtual void upsertEventStagingObject

    /**
     * @description the current event should be ignored if a later event for the same record was received already. 
     */
    // // protected virtual Boolean isEventIgnorable(String eventType, String eventTime, String primaryKey) {
    // protected virtual Boolean isEventIgnorable(Event event, Map<String, Object> ctx, IEventService service) {
    //     String primaryKey = service.getPrimary(event, ctx);
    //     if (event.eventTime == null || primaryKey == null) return false;

    //     Event_Notification__c[] evts = [SELECT Id FROM Event_Notification__c WHERE Primary_Key__c=:primaryKey AND Event_Time__c>:eventTime];
    //     return evts.size() > 0;
    // }

    /**
     * 
     */
    private void processDependentEvents(List<Id> relyOnEvIds, Event masterEvent, Map<String, Object> ctx, IEventService service) { // Event event, Map<String, Object> ctx, IEventService service) {
        String primaryKey = service.getPrimaryKey(masterEvent, ctx);
        if (String.isEmpty(primaryKey) || String.isEmpty(masterEvent.eventType)) return;

        AsyncOptions options = new AsyncOptions();
        options.DuplicateSignature = QueueableDuplicateSignature.Builder()
                    .addString('RelyOnQueueProcessor')
                    .addString(masterEvent.eventType)
                    .addString(primaryKey)
                    .build();
        try {
            System.enqueueJob(new RelyOnQueueProcessor(relyOnEvIds, 0), options);
        } catch (DuplicateMessageException ex) {
            vLogger.write('RelyOnQueueProcessor job was skipped due to an existing job currently running.');
        } catch (Exception ex) {
            vLogger.write(ex);
        }

        // // Kick-off queueable process for the events which rely on this event
        // if (String.isNotEmpty(event.primaryKey)) {
        //     Event_Notification__c[] dependentEvents = [
        //         SELECT Id FROM Event_Notification__c 
        //         WHERE Rely_on_Key__c = :event.primaryKey AND Status__c = 'Pending'
        //     ];
            
        //     if (dependentEvents.size() > 0) {
        //         List<Id> relyOnEvIds = new List<Id>((new Map<Id, Event_Notification__c>(dependentEvents)).keySet());

        //         // New Queueable process for the dependent events
        //         AsyncOptions options = new AsyncOptions();
        //         options.DuplicateSignature = QueueableDuplicateSignature.Builder()
        //                     .addString('RelyOnQueueProcessor')
        //                     .addString(myEvent.Event_Type__c)
        //                     .addString(myEvent.Primary_Key__c)
        //                     .build();
        //         try {
        //             System.enqueueJob(new RelyOnQueueProcessor(relyOnEvIds, 0), options);
        //         } catch (DuplicateMessageException ex) {
        //             vLogger.write('RelyOnQueueProcessor job was skipped due to an existing job currently running.');
        //         } catch (Exception ex) {
        //             vLogger.write(ex);
        //         }
        //     }
        // }
    }
}