@IsTest
private class BatchSchooxCSVSyncTest {

    private static HttpResponse mockOkJson(String bodyJson) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setStatus('OK');
        res.setHeader('Content-Type', 'application/json');
        res.setBody(bodyJson);
        return res;
    }

    @IsTest
    static void testBatch_MergesAndChunks() {
        String csv =
            'sxUserId,courseId,completedAt\n' +
            '1363665,7373158,2024-11-23\n' +
            '1363665,"7373159;7373160",2024-11-24\n' +
            '2222222,8888888,\n' +
            '3333333,"1001;1002;1003;1004;1005;1006;1007;1008;1009;1010",2025-01-15\n' +
            '3333333,"1011;1012",2025-01-16\n';

        BatchSchooxCSVSync.TEST_CSV = csv;
        SchooxAPI.testResponse = mockOkJson('[]');

        BatchSchooxCSVSync b = new BatchSchooxCSVSync('SX_Courses_To_Sync');

        Test.startTest();
        Database.executeBatch(b, 200);
        Test.stopTest();

        // ✅ Assert static summaries set in finish()
        System.assertEquals(4,  BatchSchooxCSVSync.LAST_USERS_TOUCHED,
            'usersTouched should equal number of Jobs processed');
        System.assertEquals(4,  BatchSchooxCSVSync.LAST_ASSIGN_CALLS,
            'assignCourses called once per Job');
        System.assertEquals(16, BatchSchooxCSVSync.LAST_COMPLETE_CALLS,
            'total completions: 3 + 1 + 12 = 16');
        System.assertEquals(0,  BatchSchooxCSVSync.LAST_ERRORS,
            'no errors expected');

        BatchSchooxCSVSync.TEST_CSV = null; // cleanup
    }

    @IsTest
    static void testBatch_EmptyCsv_NoJobs() {
        BatchSchooxCSVSync.TEST_CSV = 'sxUserId,courseId,completedAt\n';
        SchooxAPI.testResponse = mockOkJson('[]');

        BatchSchooxCSVSync b = new BatchSchooxCSVSync('Anything');
        Test.startTest();
        Database.executeBatch(b, 200);
        Test.stopTest();

        // ✅ Assert static summaries (instance fields may be 0 in Dev Console)
        System.assertEquals(0, BatchSchooxCSVSync.LAST_USERS_TOUCHED);
        System.assertEquals(0, BatchSchooxCSVSync.LAST_ASSIGN_CALLS);
        System.assertEquals(0, BatchSchooxCSVSync.LAST_COMPLETE_CALLS);
        System.assertEquals(0, BatchSchooxCSVSync.LAST_ERRORS);

        BatchSchooxCSVSync.TEST_CSV = null;
    }
}