public with sharing class OpportunityHelper {
    
    /* List of methods
        
        Refactored from AnotherOpportunityTrigger.Trigger
            setOppType()
            preventClosedOppDate()
            createTaskFromNewOpportunities()
            appendStageNameToDescription()
            notifyOwnersOpportunityDeleted()
            assignPrimaryContact()
            processUndeletedOpps()

        Reused from HW7
            validateOppAmount()
            preventDeleteClosedWonBanking()
            setPrimaryContactOnUpdate()

    */

    public static void setOppType (List<Opportunity> opp1New) {
        for (Opportunity opp : opp1New) {
            if (opp.Type == null) {
                opp.Type = 'New Customer';
            }
        }
    }
    
    public static void preventClosedOppDelete (List<Opportunity> opp2Old) {
        Boolean oppTriggerWasDeleted = true;
        for (Opportunity opp : opp2Old){
            if (opp.IsClosed) {
                oppTriggerWasDeleted = false;
                opp.addError('Cannot delete closed opportunity');
            }
        }  
    }

    public static void createTaskFromNewOpportunities(List<Opportunity> opp3New) {
        List<Task> newTasks = new List<Task>();  // Initialize collection to store new Task records; insert later.
        for (Opportunity opp : opp3New){
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
    
    public static void appendStageNameToDescription(List<Opportunity> opp4New) {
        for (Opportunity opp : opp4New) {
            if (opp.StageName != null) {
                opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
            }
        }
    }

    public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        List<Messaging.SingleEmailMessage> emailsList = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : opps){
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
    
    public static void assignPrimaryContact(List<Opportunity> oppTrigger) {        
        //List<Opportunity> privOppList = new List<Opportunity>(oppTrigger); 
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
    
    public static void processUndeletedOpps(Map<Id, Opportunity> mapUndeletedOpps) {
        List<Opportunity> oppToProcess =[SELECT Id, Name FROM Opportunity WHERE Id IN :mapUndeletedOpps.keySet()];
        
        for (Opportunity opp : oppToProcess) {
            String nameString = opp.Name;
            opp.Name = nameString;
        }
        update oppToProcess;
    }
    
    public static void validateOppAmount(List<Opportunity> oppTriggerNew) {
        for (Opportunity opp : oppTriggerNew) {
            Double minOpp = 5000;
            if (opp.Amount <= minopp) {
                opp.Amount.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    public static void preventDeleteClosedWonBanking(List<Opportunity> oppTriggerOld) {
        // Must run 'extra' query to find Account.Industry.
        List<Opportunity> oppList = [SELECT Id, Name, Amount, StageName, Account.Industry FROM Opportunity WHERE Id IN :oppTriggerOld];
        System.debug('***** oppList size: ' + String.valueOf(oppList.size()));
        for (Opportunity opp : oppList) {
            if (opp.StageName == 'Closed Won' && opp.Account.Industry == 'Banking') {
                // opp.Id.addError('<message>') does not work.
                throw new Exception.DmlException('Cannot delete closed opportunity for a banking account that is won');
            }
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
}