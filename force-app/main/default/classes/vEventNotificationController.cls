/**
 * @description major controller and interface to manage Event Notifications
 */
public with sharing class vEventNotificationController {
    public static final Integer MAX_RETRY_COUNT = 3; 
    public class EventNotificationRetriableException extends Exception {}
    public class EventNotificationIgnorableException extends Exception {}
    public class EventNotificationPendingException extends Exception {}
    public class EventNotificationFatalException extends Exception {}
    
    /**
     * 
     */
    public class vRetriableEventQueue implements Queueable {
        private Id retriableEvId;
        
        public vRetriableEventQueue(Id retriableEvId) {
            this.retriableEvId = retriableEvId;
        } 

        public void execute(QueueableContext context) {
            try {
                vEventNotificationController ctrl = new vEventNotificationController();
                ctrl.retryEvent(retriableEvId);
            } catch (Exception ex) {
                vLogger.write(ex);
            } finally {

            }
        }        
    }

    /**
     * 
     */
    public class vRelyOnEventQueue implements Queueable {
        private List<Id> relyOnEvIds;
        private Integer index;
        
        public vRelyOnEventQueue(List<String> relyOnEvIds, Integer index) {
            this.relyOnEvIds = relyOnEvIds;
            this.index = index;
        }
        
        public void execute(QueueableContext context) {
            try {
                vEventNotificationController ctrl = new vEventNotificationController();
                Event_Notification__c myEvent;
                Id eventId = relyOnEvIds[index];
                myEvent = ctrl.getEvent(eventId);    
                myEvent = ctrl.reprocessEvent(myEvent, false);
            } catch (Exception ex) {
                vLogger.write(ex);
            } finally {
                // Continue to process the next dependent Event
                if (index + 1 < relyOnEvIds.size())
                    System.enqueueJob(new vRelyOnEventQueue(this.relyOnEvIds, index + 1));
            }
        }
    } 

    /**
     * 
     */
    public String getErrorMessage(Exception ex) {
        return ex.getMessage();
    }


    public vEventNotificationController() {

    }

    /**
     * @description Major interface to receive & process the event notifications from external message queue system
     */
    public Event_Notification__c processEvent(String eventId, String eventType, String eventEntity, Datetime eventTime, String eventJSON) {
        Event_Notification__c evt = new Event_Notification__c(
            Event_Id__c = eventId,
            Event_Type__c = eventType,
            Entity__c = eventEntity,
            Event_Time__c = eventTime,
            Retry_Count__c = 0,
            Event_Payload__c = eventJSON        
        );

        return reprocessEvent(evt, false);

        // return evt;
        // vEventNotificationBaseService evtService;

        // Savepoint eventSP = Database.setSavepoint();
        // Integer start = Datetime.now().millisecond();
        // try {
        //     evtService = getEventServiceProvider(eventType, eventEntity);
        //     evtService.process(evt);

        //     evt.Status__c = 'Success';
        //     evt.Primary_Key__c = evtService.getPrimaryKey();
        //     evt.Rely_on_Key__c = evtService.getRelyOnKey();

        // } catch (System.DmlException ex) {
        //     if (StatusCode.UNABLE_TO_LOCK_ROW == ex.getDmlType(0)) {
        //         evt.Status__c = 'Retriable Error';
        //     } else {
        //         evt.Status__c = 'Fatal Error';
        //         evt.Memory_Dump__c = evtService.getMemoryDump();
        //     }
        //     evt.Error_Message__c = getErrorMessage(ex);

        // } catch (EventNotificationIgnorableException ex) {
        //     evt.Status__c = 'Ignored';
        //     evt.Error_Message__c = getErrorMessage(ex);
        //     evt.Memory_Dump__c = evtService.getMemoryDump();
        // } catch (EventNotificationRetriableException ex) {
        //     Database.rollback(eventSP);
            
        //     evt.Status__c = 'Retriable Error';
        //     evt.Error_Message__c = getErrorMessage(ex);
        //     evt.Memory_Dump__c = evtService.getMemoryDump();
        // } catch (Exception ex) {
        //     Database.rollback(eventSP);

        //     evt.Status__c = 'Fatal Error';
        //     evt.Error_Message__c = getErrorMessage(ex);
        //     evt.Memory_Dump__c = evtService.getMemoryDump();
        // } finally {
        //     Integer stop = Datetime.now().millisecond();
        //     evt.Performance_Matrix__c = String.valueOf(stop - start) + ', ' + Limits.getCpuTime() + ', ' + Limits.getHeapSize() + ', ' + Limits.getQueries() + ', ' + Limits.getDmlStatements();
        
        //     if (evt.Id == null) Database.insert(evt);
        //     else Database.update(evt);
        // }

        // // Kick-off error-handling queueable process if needed.
        // try {
        //     if (evtService?.getPrimaryKey() != null) {
        //         Event_Notification__c[] dependentEvts = [SELECT Id, Primary_Key__c, Rely_on_Key__c, Status__c FROM Event_Notification__c WHERE Rely_on_Key__c = :evtService.getPrimaryKey()];
        //     }
        // } catch (Exception ex) {

        // }
    }

    /**
     * @description Reprocess the event
     */
    public Event_Notification__c retryEvent(Id eventId) {
        Event_Notification__c myEvent;
        try {
            myEvent = getEvent(eventId);
            myEvent.Retry_Count__c += 1;

            myEvent = reprocessEvent(myEvent, false);
        } catch (Exception ex) {
            vLogger.write(ex);
            throw ex;
        }

        return myEvent;
    } 

    /**
     * @description Process the event in the test mode, no data will be committed to the database
     */
    public Event_Notification__c testRunEvent(Id eventId) {
        Event_Notification__c myEvent;
        try {
            myEvent = getEvent(eventId);
            // myEvent.Retry_Count__c += 1;

            myEvent = reprocessEvent(myEvent, false);
        } catch (Exception ex) {
            vLogger.write(ex);
            throw ex;
        }

        return myEvent;
    } 
    
    /**
     * 
     */
    public Event_Notification__c reprocessEvent(Event_Notification__c myEvent, Boolean testMode) {
        vEventNotificationBaseService service;

        Exception myException = null;
        Boolean retriableEx = false;
        Savepoint eventSP = Database.setSavepoint();

        Integer start = Datetime.now().millisecond();
        try {
            service = getEventServiceProvider(myEvent.Event_Type__c, myEvent.Entity__c);
            service.process(myEvent);
            myEvent.Status__c = 'Success';
        } catch (EventNotificationIgnorableException ex) {
            myEvent.Status__c = 'Ignored';
            myException = ex;
        } catch (EventNotificationPendingException ex) {
            myEvent.Status__c = 'Pending';
            myException = ex;
        } catch (System.DmlException ex) {
            if (StatusCode.UNABLE_TO_LOCK_ROW == ex.getDmlType(0)) {
                myEvent.Status__c = 'Retriable Error';
            } else {
                myEvent.Status__c = 'Fatal Error';
            }
            myException = ex;
        } catch (EventNotificationRetriableException ex) {
            myEvent.Status__c = 'Retriable Error';
            myException = ex;
        } catch (Exception ex) {
            myEvent.Status__c = 'Fatal Error';
            myException = ex;
        } finally {
            Integer stop = Datetime.now().millisecond();
            myEvent.Performance_Matrix__c = String.valueOf(stop - start) + ', ' + Limits.getCpuTime() + ', ' + Limits.getHeapSize() + ', ' + Limits.getQueries() + ', ' + Limits.getDmlStatements();

            if (myException != null) {
                if (service != null) myEvent.Memory_Dump__c = service.getMemoryDump();
                myEvent.Error_Message__c = getErrorMessage(myException);
            }

            myEvent.Primary_Key__c = service?.getPrimaryKey();
            myEvent.Rely_on_Key__c = service?.getRelyOnKey();
        }

        if (myException != null || testMode) {
            Database.rollback(eventSP);

        } 

        // Upsert the Event_Notification__c record
        if (myEvent.Id == null) {
            // New event
            Database.insert(myEvent);

            // Kick-off queueable process for the events which rely on this event
            if (myEvent.Primary_Key__c != null && myEvent.Status__c == 'Success') {
                Event_Notification__c[] dependentEvents = [
                    SELECT Id FROM Event_Notification__c 
                    WHERE Rely_on_Key__c = :myEvent.Primary_Key__c AND Status__c = 'Pending'
                ];
                
                if (dependentEvents.size() > 0) {
                    List<Id> relyOnEvIds = new List<Id>((new Map<Id, Event_Notification__c>(dependentEvents)).keySet());

                    // New Queueable process for the dependent events
                    AsyncOptions options = new AsyncOptions();
                    options.DuplicateSignature = QueueableDuplicateSignature.Builder()
                                .addString('RelyOnQueue')
                                .addString(myEvent.Event_Type__c)
                                .addString(myEvent.Entity__c)
                                .addString(myEvent.Primary_Key__c)
                                .build();
                    try {
                        System.enqueueJob(new vRelyOnEventQueue(relyOnEvIds, 0), options);
                    } catch (DuplicateMessageException ex) {
                        vLogger.write('Queueable job is skipped because an existing job is running.');
                    } catch (Exception ex) {
                        vLogger.write(ex);
                    }
                }
            }
        } else {
            Database.update(myEvent);           
        }

        if (myEvent.Status__c == 'Retriable Error' && myEvent.Retry_Count__c < MAX_RETRY_COUNT) {
            System.enqueueJob(new vRetriableEventQueue(myEvent.Id));
        }

        // Event_Notification__c[] retriableEvents = [SELECT Id FROM Event_Notification__c WHERE Status__c='Retriable Error' AND Retry_Count__c <=3];
        // if (retriableEvents.size() > 0) {
        //     // New Batchable process for the retriable events
        // }

        return myEvent;
    }

    /**
     * @description Return the Event Notification Service class for the given event type and entity.
     */
    public vEventNotificationBaseService getEventServiceProvider(String eventType, String eventEntity) {
        Event_Notification_Service_Provider__mdt[] svsProviders = [SELECT Id,DeveloperName, Event_Entity__c, Event_Type__c, Service_Class__c FROM Event_Notification_Service_Provider__mdt WHERE Event_Type__c=:eventType AND Event_Entity__c=:eventEntity];
        if (svsProviders.size() == 0)
            throw new EventNotificationFatalException('There is NO service class registered for ' + eventType + ':' + eventEntity + ' event message.');
        
        String className = svsProviders[0].Service_Class__c;
        try {
            Type t = Type.forName(className);
            vEventNotificationBaseService service = (vEventNotificationBaseService)t.newInstance();

            return service;
        } catch (Exception ex) {
            throw new EventNotificationFatalException('Cannot instantiate ' + className + ' service class for ' + eventType + ':' + eventEntity + '.', ex);
        }
    }

    /**
     * @description 
     */
    private Event_Notification__c getEvent(Id eventId) {
        Event_Notification__c myEvent = [
            SELECT Id, Entity__c, Error_Message__c, Event_Id__c, Event_Payload__c, Event_Time__c, Event_Type__c, Memory_Dump__c, Name, Performance_Matrix__c, Primary_Key__c, Rely_on_Key__c, Retry_Count__c, Status__c 
            FROM Event_Notification__c WHERE Id=:eventId
        ];

        return myEvent;
    }

    
}