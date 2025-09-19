public without sharing class FFHandleLMSUserFlowAction implements Queueable, Database.AllowsCallouts {
    private Id contactId;
    private List<Integer> courseIds;

    public FFHandleLMSUserFlowAction(Id contactId, List<Integer> courseIds) {
        this.contactId = contactId;
        this.courseIds = courseIds;
    }

    public void execute(QueueableContext context) {
        try {
            // Call the existing method exactly as is — no changes to it
            SchooxAPI.handleLMSUser(contactId, courseIds);
        } catch (Exception e) {
            System.debug('Queueable error: ' + e.getMessage());
            // Optionally log error
        }
    }

    public class LMSUserInput {
        @InvocableVariable(required=true)
        public Id contactId;

        // Accept as List<Decimal> to allow Flow to pass values without rounding first
        @InvocableVariable(required=true)
        public List<Decimal> courseIdsRaw;
    }

    public class LMSUserOutput {
        @InvocableVariable
        public String resultMessage;
    }

    @InvocableMethod(label='Handle LMS User (Queued)' description='Queues LMS user update to avoid callout errors')
    public static List<LMSUserOutput> handleLMSUser(List<LMSUserInput> inputs) {
        List<LMSUserOutput> outputs = new List<LMSUserOutput>();

        for (LMSUserInput input : inputs) {
            LMSUserOutput output = new LMSUserOutput();
            try {
                // Convert decimal courseIds to integer courseIds
                List<Integer> roundedIds = new List<Integer>();
                for (Decimal d : input.courseIdsRaw) {
                    // Round and cast to Integer safely
                    roundedIds.add(Integer.valueOf(Math.round(d)));
                }

                System.enqueueJob(new FFHandleLMSUserFlowAction(input.contactId, roundedIds));
                output.resultMessage = 'Queued successfully';
            } catch (Exception e) {
                output.resultMessage = 'Error: ' + e.getMessage();
            }
            outputs.add(output);
        }

        return outputs;
    }
}