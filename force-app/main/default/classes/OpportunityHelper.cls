public with sharing class OpportunityHelper {
    
    /* List of methods
        
        Refactored from AnotherOpportunityTrigger.Trigger
            setOppType()
            preventClosedOppDate() - deprecated
            createTaskFromNewOpportunities()
            appendStageNameToDescription()
            notifyOwnersOpportunityDeleted()
            assignPrimaryContact() - deprecated
            processUndeletedOpps()

        Reused from HW7
            validateOppAmount()
            preventDeleteClosedWonBanking() - deprecated
            setPrimaryContactOnUpdate() - deprecated

        New methods
            preventOppDelete() - Combines preventClosedOppDate() and preventDeleteClosedWonBanking()

    */

    // BEFORE_INSERT, BEFORE_UPDATE
    public static void setOppType (List<Opportunity> oppNew) {
        for (Opportunity opp : oppNew) {
            if (opp.Type == null) {
                opp.Type = 'New Customer';
            }
        }
    }
    
    // AFTER_INSERT 
    // TO DO - Candidate for @Future 
    public static void createTaskFromNewOpportunities(List<Opportunity> oppNew) {
        List<Task> newTasks = new List<Task>();  // Initialize collection to store new Task records; insert later.
        for (Opportunity opp : oppNew){
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            newTasks.add(tsk); // Add new record to collection
        }
        insert newTasks; // Moved outside for() loop to 'bulkify'
    }

    // BEFORE_UPDATE
    public static void appendStageNameToDescription(List<Opportunity> oppNew) {
        for (Opportunity opp : oppNew) {
            if (opp.StageName != null) {
                opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
            }
        }
    }
    
    // BEFORE_UPDATE
    public static void validateOppAmount(List<Opportunity> oppNew) {
        for (Opportunity opp : oppNew) {
            Double minOpp = 5000;
            if (opp.Amount <= minopp) {
                opp.Amount.addError('Opportunity amount must be greater than ' + string.valueOf(minOpp));
            }
        }
    }
    
    

    // BEFORE_UPDATE
    /*
    public static void setPrimaryContact(List<Opportunity> oppNew) {}

    */
   

    
    public static void assignPrimaryContact(List<Opportunity> oppTrigger) {        
        Set<Id> oppAccountIdSet = new Set<Id>();
        for (Opportunity opp : oppTrigger) { 
            if (opp.Primary_Contact__c == null && opp.AccountId != null) {
                oppAccountIdSet.add(opp.AccountId); 
            }
        }
        String contactTitle = 'VP Sales';
        List<Contact> ceoContacts = [SELECT Id, FirstName, LastName, Title, AccountId FROM Contact WHERE AccountId IN :oppAccountIdSet AND Title = :contactTitle];
        Map<String,String> acctIdToContactIdMap = new Map<String,String>();
        for (Contact cont : ceoContacts) {
            acctIdToContactIdMap.put(cont.AccountId, cont.Id);
        }
        for (Opportunity opp2 : oppTrigger) {
            opp2.Primary_Contact__c = acctIdToContactIdMap.get(opp2.AccountId);  
        }
    }

    public static void setPrimaryContactOnUpdate(List<Opportunity> oppTrigger) {
        Set<Id> oppAccountIdSet = new Set<Id>();
        for (Opportunity opp : oppTrigger) { 
            if (opp.AccountId != null) {
                oppAccountIdSet.add(opp.AccountId); 
            }
        }
        String contactTitle = 'CEO';
        List<Contact> ceoContacts = [SELECT Id, FirstName, LastName, Title, AccountId FROM Contact WHERE AccountId IN :oppAccountIdSet AND Title = :contactTitle];
        Map<String,String> acctIdToContactIdMap = new Map<String,String>();
        for (Contact cont : ceoContacts) {
            acctIdToContactIdMap.put(cont.AccountId, cont.Id);
        }
        for (Opportunity opp2 : oppTrigger) {
            opp2.Primary_Contact__c = acctIdToContactIdMap.get(opp2.AccountId);  
        }
    }

    // BEFORE_DELETE
    public static void preventOppDelete (List<Opportunity> oppOld) {
        List<Opportunity> oppList = [SELECT Id, Name, Amount, StageName, Account.Industry, IsClosed FROM Opportunity WHERE Id IN :oppOld];
        for (Opportunity opp : oppList) {
            if (opp.IsClosed) {
                // opp.addError('Cannot delete closed opportunity'); // Cannot throw exception outside of Trigger List     
                throw new Exception.DmlException('Cannot delete closed opportunity');
            } else if (opp.IsClosed && opp.Account.Industry == 'Banking') { 
                throw new Exception.DmlException('Cannot delete closed opportunity for a banking account that is won');
            } else {
                opp.Opp_Is_Deleted__c = true;  // New custom field
            }
        }
    }
        
    // // BEFORE_DELETE
    // public static void preventClosedOppDelete (List<Opportunity> oppOld) {
    //     Boolean oppTriggerWasDeleted = true;
    //     for (Opportunity opp : oppOld){
    //         if (opp.IsClosed) {
    //             oppTriggerWasDeleted = false;
    //             opp.addError('Cannot delete closed opportunity');
    //         } else {
    //             opp.Name += 'DELETED';
    //         }
    //     }  
    // }
    
    // // BEFORE_DELETE
    // public static void preventDeleteClosedWonBanking(List<Opportunity> oppOld) {
    //     Boolean oppTriggerWasDeleted = true;
    //     // Must run 'extra' query to find Account.Industry.
    //     List<Opportunity> oppList = [SELECT Id, Name, Amount, StageName, Account.Industry FROM Opportunity WHERE Id IN :oppOld];
    //     for (Opportunity opp : oppList) {
    //         if (opp.StageName == 'Closed Won' && opp.Account.Industry == 'Banking') {
    //             // opp.Id.addError('<message>') does not work.
    //             throw new Exception.DmlException('Cannot delete closed opportunity for a banking account that is won');
    //         } else {
    //             opp.Name += 'DELETED';
    //         }
    //     }
    // }

    // AFTER_DELETE
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> oppDel) {
        List<Messaging.SingleEmailMessage> emailsList = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : oppDel){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> emailSendToUsers = new List<String>();
            emailSendToUsers.add(opp.OwnerId);
            mail.setToAddresses(emailSendToUsers);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            emailsList.add(mail);
        }        
        try {
            Messaging.sendEmail(emailsList);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    // AFTER_UNDELETE
    public static void processUndeletedOpps(Map<Id, Opportunity> mapUndeletedOpps) {
        List<Opportunity> oppToProcess =[SELECT Id, Opp_Is_Deleted__c FROM Opportunity WHERE Id IN :mapUndeletedOpps.keySet()];
        for (Opportunity opp : oppToProcess) {
            opp.Opp_Is_Deleted__c = true; 
        }
        update oppToProcess;
    }

}