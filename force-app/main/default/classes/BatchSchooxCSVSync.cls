global with sharing class BatchSchooxCSVSync
implements Database.Batchable<BatchSchooxCSVSync.Job>, Database.Stateful, Database.AllowsCallouts {
    
    // Each batch "Job" handles up to 10 courses for a single user (API limit).
    global class Job {
        public Integer userId;
        public List<Integer> courseIds;                  // size ≤ 10
        public Map<Integer, String> completedByCourse;   // courseId -> completedAt (string)
        public Job(Integer u, List<Integer> ids, Map<Integer,String> dateMapParam) {
            userId = u;
            courseIds = ids;
            completedByCourse = dateMapParam;
        }
    }
    
    private final String resourceName;
    private Set<Integer> alreadyReactivated = new Set<Integer>();
    
    // Instance counters (tracked with Database.Stateful)
    @TestVisible global Integer usersTouched = 0;
    @TestVisible global Integer assignCalls = 0;
    @TestVisible global Integer completeCalls = 0;
    @TestVisible global Integer errors = 0;
    
    // Stable, test-visible summaries populated in finish()
    @TestVisible static Integer LAST_USERS_TOUCHED  = 0;
    @TestVisible static Integer LAST_ASSIGN_CALLS   = 0;
    @TestVisible static Integer LAST_COMPLETE_CALLS = 0;
    @TestVisible static Integer LAST_ERRORS         = 0;
    
    // (Optional) breadcrumb: number of jobs produced in start()
    @TestVisible static Integer LAST_JOB_COUNT = 0;
    
    // Test-only CSV injection (so we don't DML StaticResource in tests)
    @TestVisible static String TEST_CSV;
    
    public BatchSchooxCSVSync(String staticResourceName) {
        this.resourceName = staticResourceName;
    }
    
    // START
    global Iterable<Job> start(Database.BatchableContext bc) {
        // Reset static summaries in tests to avoid bleed-over
        if (Test.isRunningTest()) {
            LAST_USERS_TOUCHED  = 0;
            LAST_ASSIGN_CALLS   = 0;
            LAST_COMPLETE_CALLS = 0;
            LAST_ERRORS         = 0;
            LAST_JOB_COUNT      = 0;
        }
        
        // Load CSV (from Static Resource normally; from TEST_CSV in tests)
        String csv;
        if (Test.isRunningTest() && TEST_CSV != null) {
            csv = TEST_CSV;
        } else {
            StaticResource sr = [
                SELECT Body
                FROM StaticResource
                WHERE Name = :resourceName
                LIMIT 1
            ];
            csv = sr.Body.toString();
        }
        
        // Parse rows → aggregate per user (no regex)
        Map<Integer, Set<Integer>> userToCourses = new Map<Integer, Set<Integer>>();
        Map<Integer, Map<Integer, String>> userCourseToDate = new Map<Integer, Map<Integer, String>>();
        
        List<String> lines = splitLinesNoRegex(csv);
        if (lines.isEmpty()) return new List<Job>();
        
        // Skip leading empty lines
        Integer startIdx = 0;
        while (startIdx < lines.size() && String.isBlank(lines[startIdx])) startIdx++;
        if (startIdx >= lines.size()) return new List<Job>();
        
        // Header (case-insensitive)
        List<String> header = splitCsvLine(lines[startIdx]);
        Map<String, Integer> col = new Map<String, Integer>();
        for (Integer i = 0; i < header.size(); i++) {
            col.put(header[i].trim().toLowerCase(), i);
        }
        Integer idxUser   = col.containsKey('sxuserid')     ? col.get('sxuserid')
            : col.containsKey('sx_user_id')    ? col.get('sx_user_id') : null;
        Integer idxCourse = col.containsKey('courseid')     ? col.get('courseid')
            : col.containsKey('course_id')     ? col.get('course_id')  : null;
        Integer idxDate   = col.containsKey('completedat')  ? col.get('completedat')
            : col.containsKey('completed_at')  ? col.get('completed_at') : null;
        
        if (idxUser == null || idxCourse == null) {
            return new List<Job>(); // required columns missing
        }
        
        for (Integer r = startIdx + 1; r < lines.size(); r++) {
            if (String.isBlank(lines[r])) continue;
            List<String> cells = splitCsvLine(lines[r]);
            
            String userStr = safeCell(cells, idxUser);
            if (String.isBlank(userStr)) continue;
            
            Integer userId;
            try { userId = Integer.valueOf(userStr.trim()); }
            catch (Exception e) { continue; } // skip bad user id
            
            String rawCourses = safeCell(cells, idxCourse);
            if (String.isBlank(rawCourses)) continue;
            
            // Support either one course per row or semicolon-separated in one cell (e.g., "123;456")
            List<String> coursePieces = splitSemicolonsNoRegex(rawCourses);
            String dateStr = (idxDate != null && idxDate < cells.size()) ? safeCell(cells, idxDate) : null;
            
            if (!userToCourses.containsKey(userId)) {
                userToCourses.put(userId, new Set<Integer>());
                userCourseToDate.put(userId, new Map<Integer,String>());
            }
            
            for (String c : coursePieces) {
                if (String.isBlank(c)) continue;
                Integer cid;
                try { cid = Integer.valueOf(c.trim()); }
                catch (Exception e) { continue; } // skip bad course id
                
                userToCourses.get(userId).add(cid);
                if (!String.isBlank(dateStr)) {
                    userCourseToDate.get(userId).put(cid, dateStr.trim());
                }
            }
        }
        
        // Build Jobs in chunks of ≤10 courses per user
        List<Job> jobs = new List<Job>();
        for (Integer uid : userToCourses.keySet()) {
            List<Integer> courses = new List<Integer>(userToCourses.get(uid));
            Integer i = 0;
            while (i < courses.size()) {
                // manual chunk (Apex has no List.subList)
                List<Integer> sub = new List<Integer>();
                Integer picked = 0;
                while (i < courses.size() && picked < 10) {
                    sub.add(courses[i]);
                    i++;
                    picked++;
                }
                
                // subset the date map for this chunk
                Map<Integer,String> dateSubset = new Map<Integer,String>();
                Map<Integer,String> fullDates = userCourseToDate.get(uid);
                if (fullDates != null) {
                    for (Integer cId : sub) {
                        if (fullDates.containsKey(cId)) {
                            dateSubset.put(cId, fullDates.get(cId));
                        }
                    }
                }
                jobs.add(new Job(uid, sub, dateSubset));
            }
        }
        
        LAST_JOB_COUNT = jobs.size();
        return jobs;
    }
    
    // EXECUTE
    global void execute(Database.BatchableContext bc, List<Job> scope) {
        // Track users processed in this execute() so we can flag them for a follow-up sync
        Set<String> processedSxIds = new Set<String>();
        
        for (Job j : scope) {
            try {
                String sxIdStr = String.valueOf(j.userId);
                
                // --- Snapshot enrollments (no DML) ---
                // Uses your existing no-upsert method; returns Student_Course_Id__c like "<userId>#<courseId>"
                List<SX_Enrollment__c> enrolls = SchooxAPI.getUserCourseWithoutUpsert(sxIdStr);
                
                // Build maps keyed by Schoox courseId (Integer)
                Map<Integer, Decimal> progressByCourse   = new Map<Integer, Decimal>();
                Map<Integer, Date>    completedByCourse  = new Map<Integer, Date>();
                for (SX_Enrollment__c e : enrolls) {
                    if (String.isBlank(e.Student_Course_Id__c)) continue;
                    List<String> parts = e.Student_Course_Id__c.split('#');
                    if (parts.size() != 2) continue;
                    Integer cId;
                    try { cId = Integer.valueOf(parts[1]); } catch (Exception ignore) { continue; }
                    if (e.SX_percent_Completed__c != null) progressByCourse.put(cId, e.SX_percent_Completed__c);
                    if (e.SX_Completed_Date__c  != null)  completedByCourse.put(cId, e.SX_Completed_Date__c);
                }
                
                // Reactivate once per user
                if (!alreadyReactivated.contains(j.userId)) {
                    SchooxAPI.reActivateLMSUser(sxIdStr);
                    alreadyReactivated.add(j.userId);
                }
                
                // Decide actions
                List<String>  toAssign              = new List<String>();  // assign API expects strings
                List<Integer> toComplete            = new List<Integer>();
                List<Integer> retakeThenComplete    = new List<Integer>(); // 100% but wrong date
                
                for (Integer cid : j.courseIds) {
                    Decimal prog = progressByCourse.containsKey(cid) ? progressByCourse.get(cid) : null;
                    
                    // CSV completed date (expects YYYY-MM-DD). Compare as Date to avoid TZ/time issues.
                    String ds = (j.completedByCourse != null) ? j.completedByCourse.get(cid) : null;
                    Date csvDate = null;
                    if (!String.isBlank(ds)) {
                        String t = ds.trim();
                        if (t.length() == 10) {
                            try { csvDate = Date.valueOf(t); } catch (Exception ignore) {}
                        }
                    }
                    
                    if (prog == null) {
                        // Not assigned → assign then complete
                        toAssign.add(String.valueOf(cid));
                        toComplete.add(cid);
                        
                    } else if (prog < 100) {
                        // Assigned but not complete → complete
                        toComplete.add(cid);
                        
                    } else {
                        // Already 100% — ensure the certified date matches (if CSV provided one)
                        if (csvDate != null) {
                            Date apiDate = completedByCourse.get(cid); // may be null
                            if (apiDate == null || apiDate != csvDate) {
                                // Force retake so we can re-apply the correct completion date
                                retakeThenComplete.add(cid);
                            }
                        }
                    }
                }
                
                // Assign once (if needed)
                if (!toAssign.isEmpty()) {
                    SchooxAPI.assignCourses(sxIdStr, toAssign);
                    assignCalls++;
                }
                
                // Complete missing/incomplete
                for (Integer cid : toComplete) {
                    String ds = (j.completedByCourse != null) ? j.completedByCourse.get(cid) : null;
                    SchooxAPI.markCourseComplete(j.userId, cid, ds);
                    completeCalls++;
                }
                
                // For mismatched certified date: oblige → complete with the CSV date
                for (Integer cid : retakeThenComplete) {
                    String ds = (j.completedByCourse != null) ? j.completedByCourse.get(cid) : null;
                    if (!String.isBlank(ds)) {
                        SchooxAPI.obligeToRetake(j.userId, cid);
                        SchooxAPI.markCourseComplete(j.userId, cid, ds);
                        completeCalls++;
                    }
                }
                
                processedSxIds.add(sxIdStr);
                
            } catch (Exception e) {
                errors++;
                System.debug('❌ Error for user ' + j.userId + ': ' + e.getMessage());
            } finally {
                // Count each Job processed regardless of success/failure
                usersTouched++;
            }
        }
        
        // Post-processing: flag these users for an enrollment sync in ~1 hour
        if (!processedSxIds.isEmpty()) {
            Datetime dueAt = Datetime.now().addHours(1);
            List<SX_LMS_User__c> toUpdate = [
            SELECT Id
            FROM SX_LMS_User__c
            WHERE SX_User_ID__c IN :processedSxIds
        ];
            for (SX_LMS_User__c u : toUpdate) {
                u.SX_Process_Pending__c = true;
                u.Enrollments_Due_At__c = dueAt;
            }
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        }
    }
    
    
    // FINISH
    global void finish(Database.BatchableContext bc) {
        // Publish stable test-visible summary
        LAST_USERS_TOUCHED  = usersTouched;
        LAST_ASSIGN_CALLS   = assignCalls;
        LAST_COMPLETE_CALLS = completeCalls;
        LAST_ERRORS         = errors;
        
        System.debug('✅ BatchSchooxCSVSync finished.'
            + ' Users touched=' + usersTouched
            + ', Assign calls=' + assignCalls
            + ', Complete calls=' + completeCalls
            + ', Errors=' + errors
            + ', JobId=' + bc.getJobId());
    }
    
    // ---------- helpers (no-regex splitters + CSV row splitter) ----------
    
    // Splits text into lines handling \n, \r, and \r\n without regex
    private static List<String> splitLinesNoRegex(String text) {
        List<String> out = new List<String>();
        if (text == null) return out;
        
        String cur = '';
        Integer i = 0;
        while (i < text.length()) {
            String ch = text.substring(i, i+1);
            if (ch == '\r') {
                out.add(cur); cur = '';
                // swallow the following \n if present (CRLF)
                if (i + 1 < text.length() && text.substring(i+1, i+2) == '\n') i++;
            } else if (ch == '\n') {
                out.add(cur); cur = '';
            } else {
                cur += ch;
            }
            i++;
        }
        // last line (even if empty)
        out.add(cur);
        return out;
    }
    
    // Splits on ';' and trims pieces, without regex
    private static List<String> splitSemicolonsNoRegex(String s) {
        List<String> out = new List<String>();
        if (s == null) return out;
        
        String cur = '';
        for (Integer i = 0; i < s.length(); i++) {
            String ch = s.substring(i, i+1);
            if (ch == ';') {
                String piece = cur.trim();
                if (piece.length() > 0) out.add(piece);
                cur = '';
            } else {
                cur += ch;
            }
        }
        String last = cur.trim();
        if (last.length() > 0) out.add(last);
        return out;
    }
    
    // CSV line splitter that handles simple quoted fields (no escaped-quote support)
    private static List<String> splitCsvLine(String line) {
        List<String> out = new List<String>();
        if (line == null) return out;
        String cur = '';
        Boolean inQ = false;
        for (Integer i = 0; i < line.length(); i++) {
            String ch = line.substring(i, i+1);
            if (ch == '"') {
                inQ = !inQ;
                continue;
            }
            if (!inQ && ch == ',') {
                out.add(cur);
                cur = '';
            } else {
                cur += ch;
            }
        }
        out.add(cur);
        return out;
    }
    
    private static String safeCell(List<String> cells, Integer idx) {
        return (idx != null && idx < cells.size()) ? cells[idx] : null;
    }
}