public class OpportunityTriggerHandler extends TriggerHandler {
    
    private List<Opportunity> handlerTriggerNew;
    private List<Opportunity> handlerTriggerOld;
    private Map<Id,Opportunity> handlerNewOppMap;
    private Map<Id,Opportunity> handlerOldOppMap;
    
    public OpportunityTriggerHandler() {
        this.handlerTriggerNew = (List<Opportunity>) Trigger.new;
        this.handlerTriggerOld = (List<Opportunity>) Trigger.old;
        this.handlerNewOppMap = (Map<Id,Opportunity>) Trigger.newMap;
        this.handlerOldOppMap = (Map<Id,Opportunity>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        OpportunityHelper.setOppType(handlerTriggerNew);
    }

    public override void afterInsert() {
        OpportunityHelper.createTaskFromNewOpportunities(handlerTriggerNew);
    }

    public override void beforeUpdate() {
        OpportunityHelper.setOppType(handlerTriggerNew);
        OpportunityHelper.appendStageNameToDescription(handlerTriggerNew);
        OpportunityHelper.assignPrimaryContact(handlerTriggerNew);
        OpportunityHelper.validateOppAmount(handlerTriggerNew);
        OpportunityHelper.setPrimaryContactOnUpdate(handlerTriggerNew);
    }

    public override void beforeDelete() {
        OpportunityHelper.preventOppDelete(handlerTriggerOld);
        //OpportunityHelper.preventClosedOppDelete(handlerTriggerOld);
        //OpportunityHelper.preventDeleteClosedWonBanking(handlerTriggerOld);
        
    }

    public override void afterDelete() {
        OpportunityHelper.notifyOwnersOpportunityDeleted(handlerTriggerOld);
    }

    public override void afterUndelete() {
        OpportunityHelper.processUndeletedOpps(handlerNewOppMap);
    }

}