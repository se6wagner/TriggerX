**Table of Contents**  
[Features](#features)  
_[One-Line Trigger Code](#one_line)  
_[Evaluate Field Value Changes](#field_eval)  
_[Dynamic Event Control](#event_control)  
_[Recursion Control](#recursion)

[How To Use](#how_to)

# <a id="features">Features</a>#


## <a id="one_line">One-Line Trigger Code</a> ##

Execute Triggers with a single line of code

```java
TriggerX.handleTrigger(AccountSampleHandler.class)
```

## <a id="field_eval">Evaluate Field Value Changes</a> ##
Often triggers contain conditional logic that checks for changed field values

```java
if (record.CloseDate != recordOld.CloseDate
	|| record.OwnerId != recordOld.CloseDate
	|| record.StageName != recordOld.StageName
	|| record.Type != recordOld.Type){

	// logic executed when condition is true
}
```
. Using the TriggerX.hasChangedFields methods and TriggerX.getChangedFields methods you can you provide a list of fields (String or sObjectField) for which changes should be evaluated

```java
String[] fieldZ = new String[]{'StageName','CloseDate','OwnerId','Type'};

if (TriggerX.hasChangedFields(fieldZ,record,recordOld)){
	// logic executed when condition is true
}
```

## <a id="event_control">Dynamic Event Control</a> ##

Turn execution of events within the runtime context on and off. Use for instance when you perform operations that cause updates on multiple hierachy levels of the same ObjectType see also *Recursion Control*

**control single events**

```java
TriggerX.disable(AccountSampleHandler.class,TriggerX.EventType.AFTER_UPDATE)
TriggerX.enable(AccountSampleHandler.class,TriggerX.EventType.AFTER_UPDATE)
```

**control multiple events**

```java
TriggerX.disable(AccountSampleHandler.class
		,new TriggerX.EventType[]{
			  TriggerX.EventType.AFTER_INSERT
			, TriggerX.EventType.BEFORE_UPDATE
			, TriggerX.EventType.AFTER_UPDATE})

TriggerX.enable(AccountSampleHandler.class
		,new TriggerX.EventType[]{
			  TriggerX.EventType.BEFORE_UPDATE
			, TriggerX.EventType.AFTER_UPDATE})

```
**control entire trigger via code**

```java
TriggerX.disable(AccountSampleHandler.class)
TriggerX.enable(AccountSampleHandler.class)
```
**control trigger via custom setting**

With the custom setting TRIGGER_CONTROL you can control the execution of your trigger via configuration, which is especially usefull when performing data migration and massive batchjobs. The following custom setting for the AccountSampleHandler class 

```java
TRIGGER_CONTROL__c {
	  Name = 'AccountSampleHandler'
	, AFTER__c = false
	, AFTER_INSERT__c = true
	, AFTER_UPDATE__c = true
	, AFTER_DELETE__c = false
	, AFTER_UNDELETE__c = false
	, BEFORE__c = true
	, BEFORE_INSERT__c = false
	, BEFORE_UPDATE__c = false
	, BEFORE_DELETE__c = false}
```

will prevent the exuection of AFTER INSERT, AFTER UPDATE as well as all BEFORE events for AccountSampleHandler.class.


## <a id="recursion">Recursion Control</a> ##
The built-in recursion control allows you to keep track of updated records within the current runtime context and filter on those records which have already been processed. Use for instance for updates on multiple hierachy levels of the same ObjectType or for recursive updates.

```java
// add all records in the current update context to the updatedIds and 
TriggerX.addUpdatedIds(triggerOldMap.keySet());

// and use this to return only records which havent been processed before
#getNonRecursiveUpdates()
```

# <a id="how_to">How To Use</a> #

**Handler class**  
Create a Handler class that extends TriggerX, per Custom Object. Overwrite those methods you actually want to handle. Keep in mind, that you have to cast the record variables to the concrete sObjectType

```java
public class AccountSampleHandler extends TriggerX {
 
    // handle after update
    public override void onBeforeInsert(){
        for (Account record:(Account[])records){
            // BEFORE INSERT LOGIC
        }
    }
    // handle after update
    public override void onAfterUpdate(Map<Id,sObject> triggerOldMap){
        // just process Account records that haven't been updated in the same context
        for (Account record:(Account[])getNonRecursiveUpdates()){
            // AFTER UPDATE LOGIC
        }
        // prevent recursion
        TriggerX.addUpdatedIds(triggerOldMap.keySet());
    }
}
```

Create then a Trigger for your Custom Object and call TriggerX.handleTrigger with the Type of the handler class you just created

	trigger AccountSample on Account (before insert, after update){
    	TriggerX.handleTrigger(AccountSampleHandler.class)
	}

# License #
BSD
