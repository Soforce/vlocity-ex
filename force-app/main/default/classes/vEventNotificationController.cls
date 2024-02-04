/**
 * @description major controller and interface to manage Event Notifications
 */
public with sharing class vEventNotificationController {
    public class EventNotificationRetriableException extends Exception {}
    public class EventNotificationIgnorableException extends Exception {}
    public class EventNotificationFatalException extends Exception {}

    /**
     * 
     */
    public String getErrorMessage(Exception ex) {
        return ex.getMessage();
    }


    public vEventNotificationController() {

    }

    /**
     * 
     */
    public void processEvent(String eventId, String eventType, String eventEntity, Datetime eventTime, String eventJSON) {
        Event_Notification__c evt = new Event_Notification__c(
            Event_Id__c = eventId,
            Event_Type__c = eventType,
            Entity__c = eventEntity,
            Event_Time__c = eventTime,
            Retry_Count__c = 0,
            Event_Payload__c = eventJSON        
        );

        vEventNotificationBaseService evtService;

        Savepoint eventSP = Database.setSavepoint();
        Integer start = Datetime.now().millisecond();
        try {
            evtService = getEventServiceProvider(eventType, eventEntity);
            evtService.process(evt);

            evt.Status__c = 'Success';
            evt.Primary_Key__c = evtService.getPrimaryKey();
            evt.Rely_on_Key__c = evtService.getRelyOnKey();

        } catch (System.DmlException ex) {
            if (StatusCode.UNABLE_TO_LOCK_ROW == ex.getDmlType(0)) {
                evt.Status__c = 'Retriable Error';
            } else {
                evt.Status__c = 'Fatal Error';
                evt.Memory_Dump__c = evtService.getMemoryDump();
            }
            evt.Error_Message__c = getErrorMessage(ex);

        } catch (EventNotificationIgnorableException ex) {
            evt.Status__c = 'Ignored';
            evt.Error_Message__c = getErrorMessage(ex);
            evt.Memory_Dump__c = evtService.getMemoryDump();
        } catch (EventNotificationRetriableException ex) {
            Database.rollback(eventSP);
            
            evt.Status__c = 'Retriable Error';
            evt.Error_Message__c = getErrorMessage(ex);
            evt.Memory_Dump__c = evtService.getMemoryDump();
        } catch (Exception ex) {
            Database.rollback(eventSP);

            evt.Status__c = 'Fatal Error';
            evt.Error_Message__c = getErrorMessage(ex);
            evt.Memory_Dump__c = evtService.getMemoryDump();
        } finally {
            Integer stop = Datetime.now().millisecond();
            evt.Performance_Matrix__c = String.valueOf(stop - start) + ', ' + Limits.getCpuTime() + ', ' + Limits.getHeapSize() + ', ' + Limits.getQueries() + ', ' + Limits.getDmlStatements();
        
            if (evt.Id == null) Database.insert(evt);
            else Database.update(evt);
        }

        // Kick-off error-handling queueable process if needed.
        try {
            if (evtService?.getPrimaryKey() != null) {
                Event_Notification__c[] dependentEvts = [SELECT Id, Primary_Key__c, Rely_on_Key__c, Status__c FROM Event_Notification__c WHERE Rely_on_Key__c = :evtService.getPrimaryKey()];
            }
        } catch (Exception ex) {

        }
    }

    /**
     * 
     */
    public void retryEvent(Event_Notification__c evt, Boolean testMode) {
        evt.Retry_Count__c += 1;
        reprocessEvent(evt, false);
    }

    /**
     * 
     */
    public void reprocessEvent(Event_Notification__c evt, Boolean testMode) {
        vEventNotificationBaseService evtService;

        Savepoint eventSP = Database.setSavepoint();
        Integer start = Datetime.now().millisecond();
        try {
            evtService = getEventServiceProvider(evt.Event_Type__c, evt.Entity__c);
            evtService.process(evt);

            if (testMode) {
                Database.rollback(eventSP);

                vLogger.writeVar('Primary_Key__c', evtService.getPrimaryKey());
                vLogger.writeVar('Rely_on_Key__c', evtService.getRelyOnKey());
                vLogger.writeVar('Memory_Dump__c', evtService.getMemoryDump());
            } else {
                evt.Status__c = 'Success';
                evt.Primary_Key__c = evtService.getPrimaryKey();
                evt.Rely_on_Key__c = evtService.getRelyOnKey();
            }

        } catch (System.DmlException ex) {
            if (StatusCode.UNABLE_TO_LOCK_ROW == ex.getDmlType(0)) {
                evt.Status__c = 'Retriable Error';
            } else {
                evt.Status__c = 'Fatal Error';
                evt.Memory_Dump__c = evtService.getMemoryDump();
            }
            evt.Error_Message__c = getErrorMessage(ex);

        } catch (EventNotificationIgnorableException ex) {
            evt.Status__c = 'Ignored';
            evt.Error_Message__c = getErrorMessage(ex);
            evt.Memory_Dump__c = evtService.getMemoryDump();
        } catch (EventNotificationRetriableException ex) {
            Database.rollback(eventSP);
            
            evt.Status__c = 'Retriable Error';
            evt.Error_Message__c = getErrorMessage(ex);
            evt.Memory_Dump__c = evtService.getMemoryDump();
        } catch (Exception ex) {
            Database.rollback(eventSP);

            evt.Status__c = 'Fatal Error';
            evt.Error_Message__c = getErrorMessage(ex);
            evt.Memory_Dump__c = evtService.getMemoryDump();
        } finally {
            Integer stop = Datetime.now().millisecond();
            evt.Performance_Matrix__c = String.valueOf(stop - start) + ', ' + Limits.getCpuTime() + ', ' + Limits.getHeapSize() + ', ' + Limits.getQueries() + ', ' + Limits.getDmlStatements();
        
            if (!testMode) {
                if (evt.Id == null) Database.insert(evt);
                else Database.update(evt);
            }
        }

        if (evtService?.getPrimaryKey() != null) {
            Event_Notification__c[] dependentEvts = [
                SELECT Id, Primary_Key__c, Rely_on_Key__c, Status__c FROM Event_Notification__c 
                WHERE Rely_on_Key__c = :evtService.getPrimaryKey() AND Status__c = 'Pending'
            ];
        }
    }

    public vEventNotificationBaseService getEventServiceProvider(String eventType, String eventEntity) {
        throw new EventNotificationFatalException('Cannot instantiate the event notification controller for ' + eventType + ':' + eventEntity + '.');
    }

}