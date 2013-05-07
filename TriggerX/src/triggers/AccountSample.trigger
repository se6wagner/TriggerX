/**
 * TriggerX by Sebastian Wagner 2013
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted.
 *
 * Sample Trigger for TriggerX implementation
 * http://github.com/sebwagner/TriggerX
 */
trigger AccountSample on Account (after update, before update) {

    TriggerX.handleTrigger(AccountSampleHandler.class);

}