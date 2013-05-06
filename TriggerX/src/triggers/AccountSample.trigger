trigger AccountSample on Account (after update, before update) {

    TriggerX.handleTrigger(AccountSampleHandler.class);

}