/*
AnotherOpportunityTrigger Overview

This trigger was initially created for handling various events on the Opportunity object. It was developed by a prior developer and has since been noted to cause some issues in our org.

IMPORTANT:
- This trigger does not adhere to Salesforce best practices.
- It is essential to review, understand, and refactor this trigger to ensure maintainability, performance, and prevent any inadvertent issues.

ISSUES:
Avoid nested for loop - 1 instance
Avoid DML inside for loop - 1 instance
Bulkify Your Code - 1 instance
Avoid SOQL Query inside for loop - 2 instances
Stop recursion - 1 instance

RESOURCES: 
https://www.salesforceben.com/12-salesforce-apex-best-practices/
https://developer.salesforce.com/blogs/developer-relations/2015/01/apex-best-practices-15-apex-commandments
*/
trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            OpportunityHelper.setOppType(Trigger.new);
        }
        if (Trigger.isAfter) {
            OpportunityHelper.createTaskFromNewOpportunities(Trigger.new);
        }
    }
    
    if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            OpportunityHelper.setOppType(Trigger.new);
            OpportunityHelper.appendStageNameToDescription(Trigger.new);
            // OpportunityHelper.assignPrimaryContact(Trigger.new);
            OpportunityHelper.setPrimaryContact(Trigger.new);
        }
    }

    if (Trigger.isDelete) {
        if (Trigger.isBefore) {
            // OpportunityHelper.preventClosedOppDelete(Trigger.old);
            OpportunityHelper.preventOppDelete(Trigger.old);
        }
        if (Trigger.isAfter) {
            OpportunityHelper.notifyOwnersOpportunityDeleted(Trigger.old);
        }
    }


    if (Trigger.isUndelete) {
        if (Trigger.isAfter) {      
            OpportunityHelper.processUndeletedOpps(Trigger.newMap);
        }
    }

}