/**
 * TriggerX by Sebastian Wagner 2013
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted.
 *
 * Force.com Trigger API for advanced trigger execution
 * http://github.com/sebwagner/TriggerX
 */
public virtual class TriggerX {

    // for INSERT && UPDATE Trigger.new otherwise Trigger.old 
    public sObject[] records;

    public TriggerX(){}


    // used instead of constructor since handlers are instanciated with an emptry contructor
    public virtual TriggerX doConstruct(sObject[] records){

    	this.records = records;
        return this;
    }


    // Method executed to perform BEFORE_INSERT operations, overwrite if applicable
    public virtual void onBeforeInsert(){}


    // Method executed to perform AFTER_INSERT operations, overwrite if applicable
    public virtual void onAfterInsert(){}


    // Method executed to perform BEFORE_UPDATE operations, overwrite if applicable
    public virtual void onBeforeUpdate(Map<Id,sObject> triggerOldMap){}


    // Method executed to perform AFTER_UPDATE operations, overwrite if applicable
    public virtual void onAfterUpdate(Map<Id,sObject> triggerOldMap){}

    
    // Method executed to perform BEFORE_DELETE operations, overwrite if applicable
    public virtual void onBeforeDelete(){}

    
    // Method executed to perform AFTER_DELETE operations, overwrite if applicable
    public virtual void onAfterDelete(){}

    
    // Method executed to perform AFTER_UNDELETE operations, overwrite if applicable
    public virtual void onAfterUndelete(){}


    // returns a list that contains only records which ids are not returned by TriggerX.getUpdatedIds()
    // for improved performance use contains() directly on the set of updated ids
    // 
    // Set<Id> updatedIds = TriggerX.getUpdatedIds();
    // for (Account record:(Account)records){
    //     if (!updatedIds.contains(record.Id))
    // }
    protected sObject[] getNonRecursiveUpdates(){

        Set<Id> updatedIds = TriggerX.getUpdatedIds();

        // make a copy of records
        sObject[] tmp = records.clone();
        tmp.clear();
        // loop through records and make check if is tracked as updated
        for (sObject record:records)
        {
        	if (!updatedIds.contains((Id)record.get('Id')))
        	{
        		tmp.add(record);
        	}
        }

        return tmp;
    }


    //--------------------------------------------------------------
    // Handling
    //--------------------------------------------------------------
    // instanciates the applicable Trigger Handler object and passes it with Trigger context to handleTrigger  
    public static void handleTrigger(Type handlerType){

        handleTrigger(
              (TriggerX)handlerType.newInstance()
            , handlerType
            , Trigger.isBefore
            , Trigger.isInsert
            , Trigger.IsUpdate
            , Trigger.isDelete
            , Trigger.isUndelete
            , Trigger.new
            , Trigger.oldMap);
    }


    // executes the required methods based on the triggers context
    public static void handleTrigger(TriggerX handler, Type handlerType, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, sObject[] triggerNew, Map<Id,sObject> triggerOldMap){

        initControls(handlerType,false);

        //TriggerX handler = handlerClass.newInstance();
        Set<String> dsbld = getDisabledEvents(handlerType);

        // BEFORE events
        if (isBefore)
        {
            if (isInsert && !dsbld.contains(EventType.BEFORE_INSERT.name())) handler.doConstruct(triggerNew).onBeforeInsert();
            else if (isUpdate && !dsbld.contains(EventType.BEFORE_UPDATE.name())) handler.doConstruct(triggerNew).onBeforeUpdate(triggerOldMap);
            else if (isDelete && !dsbld.contains(EventType.BEFORE_DELETE.name())) handler.doConstruct(triggerOldMap.values()).onBeforeDelete();
        }
        // AFTER events
        else
        {
            if (isInsert && !dsbld.contains(EventType.AFTER_INSERT.name())) handler.doConstruct(triggerNew).onAfterInsert();
            else if (isUpdate && !dsbld.contains(EventType.AFTER_UPDATE.name())) handler.doConstruct(triggerNew).onAfterUpdate(triggerOldMap);
            else if (isDelete && !dsbld.contains(EventType.AFTER_DELETE.name())) handler.doConstruct(triggerOldMap.values()).onAfterDelete();
            else if (isUndelete && !dsbld.contains(EventType.AFTER_UNDELETE.name())) handler.doConstruct(triggerOldMap.values()).onAfterUndelete();
        }
    }


    //--------------------------------------------------------------
    // Change Tracking
    //--------------------------------------------------------------

    // returns true if a value of one of the specified fields has changed
    public static Boolean hasChangedFields(String[] fieldZ, sObject record, sObject recordOld){

        for (String field:fieldZ)
        {
            if (record.get(field) != recordOld.get(field)) return true;
        }

        return false;
    }


    // returns true if a value of one of the specified fields has changed
    public static Boolean hasChangedFields(sObjectField[] fieldZ, sObject record, sObject recordOld){

        for (sObjectField field:fieldZ)
        {
            if (record.get(field) != recordOld.get(field)) return true;
        }

        return false;
    }


    // returns a list of changed fields based on provided fieldZ list
    public static String[] getChangedFields(String[] fieldZ, sObject record, sObject recordOld){

        String[] changes = new String[]{};

        for (String field:fieldZ)
        {
            if (record.get(field) != recordOld.get(field)) changes.add(field);
        }

        return changes;
    }

    // returns a list of changed fields based on provided fieldZ list
    public static sObjectField[] getChangedFields(sObjectField[] fieldZ, sObject record, sObject recordOld){

        sObjectField[] changes = new sObjectField[]{};

        for (sObjectField field:fieldZ)
        {
            if (record.get(field) != recordOld.get(field)) changes.add(field);
        }

        return changes;
    }


    //--------------------------------------------------------------
    // EVENT Control
    //--------------------------------------------------------------
    // enum that represents all Trigger events
    public enum EventType {
          BEFORE_INSERT
        , AFTER_INSERT
        , BEFORE_UPDATE
        , AFTER_UPDATE
        , BEFORE_DELETE
        , AFTER_DELETE
        , AFTER_UNDELETE
    }

    // all disabled events by tyep 
    static Map<Type,Set<String>> disabledMap = new Map<Type,Set<String>>();

    // keep track for which TriggerX instances initControls has been executed  
    static Set<Type> ctrlInits = new Set<Type>(); 

    // keep track of the updated ids
    static Set<Id> ctrlUpdatedIds = new Set<Id>(); 

    // add set of ids to updatedIds 
    public static void addUpdatedIds(Set<Id> idSet){
        ctrlUpdatedIds.addAll(idSet);    
    }

    // return all updated ids
    public static Set<Id> getUpdatedIds(){
    	return ctrlUpdatedIds;
    }


    // init disabled events from TRIGGER_CONTROL__c settings
    public static void initControls(Type className, Boolean forceInit){

        // only init the list for the given set
        if (!ctrlInits.contains(className) || forceInit)
        {

            TRIGGER_CONTROL__c record = TRIGGER_CONTROL__c.getInstance(className.toString());
            Set<String> events = getDisabledEvents(className);

            if (record != null)
            {
                // reduce statements  
                events.addAll(
                  new Set<String>{
                      !record.AFTER_INSERT__c ? 'AFTER_INSERT' : null
                    , !record.AFTER_UPDATE__c ? 'AFTER_UPDATE' : null
                    , !record.AFTER_DELETE__c ? 'AFTER_DELETE' : null
                    , !record.AFTER_UNDELETE__c ? 'AFTER_UNDELETE' : null
                    , !record.BEFORE_INSERT__c ? 'BEFORE_INSERT' : null
                    , !record.BEFORE_UPDATE__c ? 'BEFORE_UPDATE' : null
                    , !record.BEFORE_DELETE__c ? 'BEFORE_DELETE' : null});

                events.remove(null);
            }

            // remember that the given key has been index already 
            ctrlInits.add(className);
        }

    }


    // returns set of disabled events
    public static Set<String> getDisabledEvents(Type className){

        if (!disabledMap.containsKey(className))
        {
            disabledMap.put(className,new Set<String>());
        }
        return disabledMap.get(className);
    }


    // returns true if the specified event is disabled
    public static Boolean isDisabled(Type className, EventType event){
        return getDisabledEvents(className).contains(event.name());
    }


    // all insert events
    public static EventType[] getInsertEvents(){
        return new EventType[]{
              EventType.BEFORE_INSERT
            , EventType.AFTER_INSERT};
    }


    // all update events
    public static EventType[] getUpdateEvents(){
        return new EventType[]{
              EventType.BEFORE_UPDATE
            , EventType.AFTER_UPDATE};
    }


    // all update events
    public static EventType[] getDeleteEvents(){
        return new EventType[]{
              EventType.BEFORE_DELETE
            , EventType.AFTER_DELETE};
    }

    // list of all BEFORE EventType enums
    public static EventType[] getBeforeEvents(){
        return new EventType[]{
        	  EventType.BEFORE_INSERT
        	, EventType.BEFORE_UPDATE
        	, EventType.BEFORE_DELETE};
    }


    // list of all AFTER EventType enums
    public static EventType[] getAfterEvents(){
        return new EventType[]{
              EventType.AFTER_INSERT
            , EventType.AFTER_UPDATE
            , EventType.AFTER_DELETE
            , EventType.AFTER_UNDELETE};
    }


    // disables all events for the type
    public static void disable(Type className){

        EventType[] allEvents = new EventType[]{};
        allEvents.addAll(getBeforeEvents());
        allEvents.addAll(getAfterEvents());

        disable(className,allEvents);//.addAll(toStringEvents(allEvents));
    }


    // removes all disabled events for the class
    public static void enable(Type className){

        getDisabledEvents(className).clear();
    }


    //  disable all specificed events for the type
    public static void disable(Type className, EventType[] events){
        getDisabledEvents(className).addAll(toStringEvents(events));
    }


    //  enable all specificed events for the type
    public static void enable(Type className, EventType[] events){
        getDisabledEvents(className).removeAll(toStringEvents(events));
    }


    // disable a single event
    public static void disable(Type className, EventType event){
        getDisabledEvents(className).add(event.name());
    }


    // enable a single event
    public static void enable(Type className, EventType event){
        getDisabledEvents(className).remove(event.name());
    }


    // converts a Set of Event enums into Strings 
    public static Set<String> toStringEvents(EventType[] events){

        Set<String> output = new Set<String>();
        for (EventType e:events)
        {
        	output.add(e.name());
        }
        return output;        
    }

}