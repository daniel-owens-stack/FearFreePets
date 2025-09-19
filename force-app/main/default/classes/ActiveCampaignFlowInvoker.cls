public with sharing class ActiveCampaignFlowInvoker {

//     public class ContactInput {
//         @InvocableVariable(required=true)
//         public Id contactId;
//     }

//     @InvocableMethod(label='Send Contact to ActiveCampaign' description='Sends a Person Account Contact to ActiveCampaign')
// public static void sendToActiveCampaign(List<ContactInput> inputs) {
//     List<Id> contactIds = new List<Id>();
//     for (ContactInput input : inputs) {
//         contactIds.add(input.contactId);
//     }

//     List<Contact> contacts = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id IN :contactIds];

//     for (Contact con : contacts) {
//         ActiveCampaignService.sendContactToActiveCampaign(con);
//     }
// }

 }