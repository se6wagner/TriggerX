/**
 * TriggerX by Sebastian Wagner 2013
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted.
 *
 * Unit Tests for TriggerX
 * http://github.com/sebwagner/TriggerX
 */
@isTest
public class TriggerXTest {

    //--------------------------------------------------------------
    // DataTypes
    //--------------------------------------------------------------
    public class ConcreteHandlerWithoutOverride extends TriggerX {}

    // Test hanlder that sets the TriggerX.EventType of the executed method
    public class ConcreteHandler extends TriggerX {
    
        public TriggerX.EventType eventX;

        // set eventX to null
        public void reset(){
        	eventX = null;
        }

	    public override void onBeforeInsert(){
	       eventX = TriggerX.EventType.BEFORE_INSERT;
	    }

	    public override void onAfterInsert(){
           eventX = TriggerX.EventType.AFTER_INSERT;
	    }

	    public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap){
           eventX = TriggerX.EventType.BEFORE_UPDATE;
	    }

	    public override void onAfterUpdate(Map<Id,sObject> triggerOldMap){
           eventX = TriggerX.EventType.AFTER_UPDATE;
	    }

	    public override void onBeforeDelete(){
           eventX = TriggerX.EventType.BEFORE_DELETE;
	    }

	    public override void onAfterDelete(){
           eventX = TriggerX.EventType.AFTER_DELETE;
	    }

	    public override void onAfterUndelete(){
           eventX = TriggerX.EventType.AFTER_UNDELETE;
	    }


        public sObject[] getNonRecursiveRecords(){

            return super.getNonRecursiveUpdates();
        }


        public Boolean hasChangedNameOrPhoneField(sObject record, sObject recordOld){        	
        	return TriggerX.hasChangedFields(new sObjectField[]{Account.Name,Account.Phone},record,recordOld);
        }


        public Boolean hasChangedNameOrPhoneString(sObject record, sObject recordOld){           
            return TriggerX.hasChangedFields(new String[]{'Name','Phone'},record,recordOld);
        }


        public sObjectField[] getNameAndPhoneChangesField(sObject record, sObject recordOld){
            return TriggerX.getChangedFields(new sObjectField[]{Account.Name,Account.Phone},record,recordOld);
        }

        public String[] getNameAndPhoneChangesString(sObject record, sObject recordOld){
            return TriggerX.getChangedFields(new String[]{'Name','Phone'},record,recordOld);
        }

    }


    // Holds context variables for #handleTriggerTest
    private class TestContext {

        public TriggerX.EventType eventX;
        public Boolean isBefore;
        public Boolean isInsert;
        public Boolean isUpdate;
        public Boolean isDelete;
        public Boolean isUndelete;

        public sObject[] records = new sObject[]{};
        public Map<Id,sObject> triggerOldMap = new Map<Id,sObject>();

        public TestContext(){}

        // sets context variables based on the EventType
        public void setEvent(TriggerX.EventType eventX){

            this.eventX = eventX;
            String name = eventX.name();
            this.isBefore = eventX.name().contains('BEFORE');
            this.isInsert = name.contains('INSERT');
            this.isUpdate = name.contains('UPDATE');
            this.isDelete = name.contains('_DELETE');
            this.isUndelete = name.contains('UNDELETE');
        }
    }


    //--------------------------------------------------------------
    // Handler Features
    //--------------------------------------------------------------
    // test #hasChangedFields and #getChangedFields for TriggerX
    private static testMethod void fieldChangesTest(){

        String name = 'SAME_NAME';
        Account record = new Account(Name = name, Phone = '123456');
        Account recordOld = new Account(Name = name, Phone = record.Phone); 

        Test.startTest();

        ConcreteHandler hndl = new ConcreteHandler();

        system.assertEquals(false,hndl.hasChangedNameOrPhoneField(record, recordOld),'should be not true because nothing has changed');
        system.assertEquals(false,hndl.hasChangedNameOrPhoneString(record, recordOld),'should be not true because nothing has changed');
        recordOld.Phone += '1';
        system.assertEquals(true,hndl.hasChangedNameOrPhoneField(record, recordOld),'should be true because Phone has changed');
        system.assertEquals(true,hndl.hasChangedNameOrPhoneString(record, recordOld),'should be true because Phone has changed');

        system.assertEquals(Account.Phone,hndl.getNameAndPhoneChangesField(record, recordOld).get(0),'should return changed sObjectField Account.Phone');
        system.assertEquals('Phone',hndl.getNameAndPhoneChangesString(record, recordOld).get(0),'should return changed Fieldname Phone');
        
        Test.stopTest();
    }


    // test for recusion control while updating
    private static testMethod void recursionControlTest(){

        Test.startTest();

        ConcreteHandler hndl = new ConcreteHandler();
        sObject[] records = new sObject[]{
              new User(Id = UserInfo.getUserId())
            , new User(Id = null)};

        hndl.doConstruct(records);
        TriggerX.addUpdatedIds(new Set<Id>{UserInfo.getUserId()});

        system.assertEquals(true,TriggerX.getUpdatedIds().contains(UserInfo.getUserId()));
        system.assertEquals(null,hndl.getNonRecursiveRecords().get(0).Id,'should not return any record which id is returned by TriggerX.getUpdatedIds()');

        Test.stopTest();
    }

    //--------------------------------------------------------------
    // Event Control
    //--------------------------------------------------------------

    // test support with trigger control
    private static testMethod void fromControlTest(){

        Type typ = ConcreteHandler.class;

        // list of Event strings to disable
        TriggerX.EventType[] dsbld = new TriggerX.EventType[]{
              TriggerX.EventType.AFTER_INSERT
            , TriggerX.EventType.AFTER_DELETE
            , TriggerX.EventType.AFTER_UNDELETE
            , TriggerX.EventType.BEFORE_UPDATE
            , TriggerX.EventType.BEFORE_DELETE};

        // create the CONTROL record
        TRIGGER_CONTROL__c record = new TRIGGER_CONTROL__c(
                Name = typ.toString());

        // set flags on corresponding fields 
        for (TriggerX.EventType eventX:dsbld)
        {
            record.put(eventX.name() + '__c',false);
        }

        upsert record;


        Test.startTest();
 
        // load Controls
        TriggerX.initControls(typ,true);

        // make sure all events are disabled
        for (TriggerX.EventType eventX:dsbld)
        {
        	system.assert(TriggerX.isDisabled(typ, eventX),eventX.name() + ' should be disabled via TRIGGER_CONTROL__c');
        }

        Test.stopTest();
    }


    // Test for TriggerX.handleTrigger methods, with event control
    private static testMethod void handleTriggerTest(){

        Test.startTest();

        ConcreteHandler hndl = new ConcreteHandler();
        Type typ = ConcreteHandler.class;
        TestContext tx = new TestContext();

        // run test for each EventType
        for (TriggerX.EventType eventX:TriggerX.EventType.values())
        {

            // update the context
            tx.setEvent(eventX);
            hndl.reset();

            // disabled event
            TriggerX.disable(typ,tx.eventX);
            TriggerX.handleTrigger(hndl, typ, tx.isBefore, tx.isInsert, tx.isUpdate, tx.isDelete, tx.isUndelete, tx.records, tx.triggerOldMap);
            system.assertEquals(null,hndl.eventX,tx.eventX.name() + ' should be disabled for ' + typ.toString());

            // enabled event
            TriggerX.enable(typ,tx.eventX);
            TriggerX.handleTrigger(hndl, typ, tx.isBefore, tx.isInsert, tx.isUpdate, tx.isDelete, tx.isUndelete, tx.records, tx.triggerOldMap);
            system.assertEquals(tx.eventX,hndl.eventX,tx.eventX.name() + ' should be enabled for ' + typ.toString());

        }

        Test.stopTest();
    } 


    // controls all events via TriggerX.disable(Type) and TriggerX.enable(Type)
    public static testMethod void dynamicControlAllTest(){

        Test.startTest();
        Type typ = ConcreteHandler.class;

        // disable all events
        TriggerX.disable(typ);

        // make sure all events are disabled
        for (TriggerX.EventType eventX:TriggerX.EventType.values())
        {
            system.assert(TriggerX.isDisabled(typ, eventX),eventX.name() + ' shoud be disabled for ' + typ.toString());
        }

        // enable em all
        TriggerX.enable(typ);

        for (TriggerX.EventType eventX:TriggerX.EventType.values())
        {
            system.assert(!TriggerX.isDisabled(typ, eventX),eventX.name() + ' shoud be enabled for ' + typ.toString());
        }

        Test.stopTest();
    }


    // enables all events via TriggerX.enable(Type, EventType[])
    public static testMethod void dynamicControlTest(){

        Test.startTest();
        Type typ = ConcreteHandler.class;

        // disable all events
        TriggerX.disable(typ);

        // make sure all events are disabled
        for (TriggerX.EventType eventX:TriggerX.EventType.values())
        {
            system.assert(TriggerX.isDisabled(typ, eventX),eventX.name() + ' shoud be disabled for ' + typ.toString());
        }


        // an enable all 
        TriggerX.enable(typ, TriggerX.EventType.values());

        for (TriggerX.EventType eventX:TriggerX.EventType.values())
        {
            system.assert(!TriggerX.isDisabled(typ, eventX),eventX.name() + ' shoud be enabled for ' + typ.toString());
        }

        Test.stopTest();
    }


    // tests TriggerX.handleTrigger(Type) without Trigger context, coverage only
    private static testMethod void nonTriggerContextTest(){

        Boolean success = true;
        try
        {
            TriggerX.handleTrigger(ConcreteHandler.class);
        }
        catch(Exception ex)
        {
            success = false;
        }
        system.assert(!success, 'TriggerX.handleTrigger(Type) should fail in Non-Trigger mode');
    }


    // calls virtual TriggerX methods, just for TestCoverage 
    private static testMethod void nonOverrideTest(){

        Test.startTest();

        ConcreteHandlerWithoutOverride hndl = new ConcreteHandlerWithoutOverride();
        hndl.onBeforeInsert();
        hndl.onAfterInsert();
        hndl.onBeforeUpdate(null);
        hndl.onAfterUpdate(null);
        hndl.onBeforeDelete();
        hndl.onAfterDelete();
        hndl.onAfterUndelete();

        Test.stopTest();
    }

    // calls getInsertEvents, getUpdateEvents and getDeleteEvents()    
    private static testMethod void getTypesTest(){

        Test.startTest();
        
        for (TriggerX.EventType eventX:TriggerX.getDeleteEvents())
        {
            system.assert(eventX.name().contains('DELETE'),'DELETE events should contain DELETE');
        }
        for (TriggerX.EventType eventX:TriggerX.getInsertEvents())
        {
            system.assert(eventX.name().contains('INSERT'),'INSERT events should contain INSERT');
        }
        for (TriggerX.EventType eventX:TriggerX.getUpdateEvents())
        {
            system.assert(eventX.name().contains('UPDATE'),'UPDATE events should contain UPDATE');
        }
        Test.stopTest();
    }
}