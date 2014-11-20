<a href="https://githubsfdeploy.herokuapp.com?owner=sebwagner&repo=TriggerX">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

**Table of Contents**  
[Features](#features)  
_[One-Line Trigger Code](#one-line-trigger-code)  
_[Evaluate Field Value Changes](#evaluate-field-value-changes)  
_[Dynamic Event Control](#dynamic-event-control)  
_[Recursion Control](#recursion-control)

[How To Use](#how-to-use)  
[Test Coverage](#test-coverage)  
[License](#license)

# <a name="features">Features</a>#


## <a name="one-line-trigger-code">One-Line Trigger Code</a> ##

Execute Triggers with a single line of code

```java
TriggerX.handleTrigger(AccountSampleHandler.class)
```

## <a name="evaluate-field-value-changes">Evaluate Field Value Changes</a> ##
Often triggers contain conditional logic that checks for changed field values

```java
if (record.CloseDate != recordOld.CloseDate
	|| record.OwnerId != recordOld.CloseDate
	|| record.StageName != recordOld.StageName
	|| record.Type != recordOld.Type){

	// logic executed when condition is true
}
```
. Using the hasChangedFields and getChangedFields methods you just pass in a list of fields (String or sObjectField) for which changes should be evaluated

```java
// use string field names
String[] stringFieldZ = new String[]{'StageName','CloseDate','OwnerId','Type'};

if (TriggerX.hasChangedFields(stringFieldZ,record,recordOld)){
	// logic executed when condition is true
}

// or sObjectFields
sObjectField[] fieldZ = new sObjectField[]{Opportunity.StageName, Opportunity.CloseDate, Opportunity.OwnerId, Opportunity.Type};

for (sObjectField field:TriggerX.getChangedFields(fieldZ,record,recordOld)){
	// process field
}
```

## <a name="dynamic-event-control">Dynamic Event Control</a> ##

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

With the custom setting TRIGGER_CONTROL you can control the execution of your trigger via configuration, which is especially usefull when performing data migration and massive batchjobs. The following custom setting for the AccountSampleHandler.class 

```java
TRIGGER_CONTROL__c {
	  Name = 'AccountSampleHandler'
	, AFTER_INSERT__c = true
	, AFTER_UPDATE__c = false
	, AFTER_DELETE__c = false
	, AFTER_UNDELETE__c = true
	, BEFORE_INSERT__c = false
	, BEFORE_UPDATE__c = false
	, BEFORE_DELETE__c = false}
```

will prevent the execution of all BEFORE events as well as AFTER UPDATE and AFTER DELETE events for AccountSampleHandler.class. If no TRIGGER_CONTROL__c record exists, all events are considered as enabled!


## <a name="recursion-control">Recursion Control</a> ##
The built-in recursion control allows you to keep track of updated records within the current runtime context and filter on those records which have already been processed. Use for instance for updates on multiple hierachy levels of the same ObjectType or for recursive updates.

```java
// add all records in the current update context to the updatedIds and 
TriggerX.addUpdatedIds(triggerOldMap.keySet());

// and use this to return only records which havent been processed before
#getNonRecursiveUpdates()
```

# <a name="how-to-use">How To Use</a> #

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


# <a name="test-coverage">Test Coverage</a> #
TriggerX.cls has a 100% test coverage.
AccountSampleHandler.cls and AccountSample.trigger might have a lower coverage, depending on required fields and validation rules on Account and Contact.

# <a name="license">License</a> #
Redistribution and use in source and binary forms, with or without modification, are permitted.
