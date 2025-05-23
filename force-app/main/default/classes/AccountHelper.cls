/*
AccountHelper Overview

The `AccountHelper` class is designed to provide helper methods that assist in performing specific operations on Account records. 
This class is intended to modularize the logic used in the `AccountTrigger` to ensure separation of concerns, improve readability, and ease maintenance. 

This class is currently stubbed out. As part of this exercise, you are expected to:
1. Implement the method bodies to carry out the specified operations on Account records.
2. Refactor the `AccountTrigger` to utilize the methods provided in this `AccountHelper` class.

Methods:
- `setTypeProspect(SObject objects)`: 
    - Purpose: Update the 'Type' field of the given Account record to 'Prospect' if it's not already set.
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `addressCopy()`: 
    - Purpose: Copy the shipping address of the Account to its billing address. 
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `setRating`: 
    - Purpose: Evaluate certain conditions on the Account and assign a rating based on that evaluation. You'll need to define the method's signature and implement its logic.

- `defaultContact`: 
    - Purpose: Create a default contact related to the Account after the Account is inserted. You'll need to define the method's signature and implement its logic.

Remember:
Always ensure that your helper methods are bulk-safe to handle multiple records efficiently. 
*/

public with sharing class AccountHelper {
    
   public static void setTypeProspect(List<Account> acc1TriggerNew) {
        String accType = 'Prospect';
        for (Account acct : acc1TriggerNew) {
            if (acct.Type == null) {
                acct.Type = accType;   
            }
        }
    }

    public static void addressCopy(List<Account> acc2TriggerNew) {
        for (Account acct : acc2TriggerNew) {
            acct.BillingStreet = acct.ShippingStreet;
            acct.BillingCity = acct.ShippingCity;
            acct.BillingState = acct.ShippingState;
            acct.BillingPostalCode = acct.ShippingPostalCode;
            acct.BillingCountry = acct.ShippingCountry;            
        }
    }
    
    public static void setRating(List<Account> acc3TriggerNew) {
        String accRating = 'Hot';
        for (Account acct : acc3TriggerNew) {
            if (acct.Phone != null && acct.Website != null && acct.Fax != null) {
                acct.Rating = accRating;   
            }                    
        }
    }
    
    public static void defaultContact(List<Account> acc4TriggerNew) {
        
        List<Contact> newContact = new List<Contact>();
        for (Account acct : acc4TriggerNew) {
            Contact newCont = new Contact();
            newCont.LastName = 'DefaultContact';
            newCont.Email = 'default@email.com';
            newCont.AccountId = acct.Id;    
            newContact.add(newCont);
        }

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.insert(newContact, dml);
        
    }

}
