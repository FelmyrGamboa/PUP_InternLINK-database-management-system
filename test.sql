-- ============================================================
-- TEST FILE for pup_ilink_db (ver5)
-- Run pup_ilink_db_completed_table_ver5.sql FIRST. Then run this file.
--
-- PART 1: adds fake test data (should work with NO errors)
-- PART 2: shows the results (look at the output)
-- PART 3: bad data. Each line is commented out. Try ONE at a time.
--         It should be REFUSED with an error. That means the rules work.
--
-- Run PART 1 only once on a fresh database. The test data uses fixed names,
-- so running it twice will give "Duplicate entry" errors.
-- ============================================================

USE pup_ilink_db;

-- ============================================================
-- PART 1: GOOD TEST DATA
-- ============================================================

-- People: a coordinator, an adviser, a company supervisor and an intern supervisor
INSERT INTO users (email, password_hash, first_name, last_name, user_role, account_status, must_change_password) VALUES
  ('coordinator@test.com', 'x', 'Cora', 'Dela Cruz', 'faculty',    'active', 0),
  ('adviser@test.com',     'x', 'Ben',  'Reyes',     'faculty',    'active', 0),
  ('company@test.com',     'x', 'Hana', 'Rivera',    'company',    'active', 0),
  ('internsup@test.com',   'x', 'Cy',   'Lim',       'supervisor', 'active', 0);

INSERT INTO faculties (faculty_no, user_id, department_code, is_coordinator) VALUES
  ('F001', (SELECT user_id FROM users WHERE email = 'coordinator@test.com'), 'CCIS-IT', 1),
  ('F002', (SELECT user_id FROM users WHERE email = 'adviser@test.com'),     'CCIS-IT', 0);

-- A company, with a MOA that ends in 20 days
INSERT INTO companies (company_name, address, contact_email, contact_no, moa_start, moa_end) VALUES
  ('Test Company', 'Makati City', 'info@testcompany.com', '028123456', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 20 DAY));

INSERT INTO company_supervisors (user_id, user_role, company_id, first_name, last_name, company_position, company_department) VALUES
  ((SELECT user_id FROM users WHERE email = 'company@test.com'),   'company',    (SELECT company_id FROM companies WHERE contact_email = 'info@testcompany.com'), 'Hana', 'Rivera', 'HR Officer', 'HR'),
  ((SELECT user_id FROM users WHERE email = 'internsup@test.com'), 'supervisor', (SELECT company_id FROM companies WHERE contact_email = 'info@testcompany.com'), 'Cy',   'Lim',    'IT Manager', 'IT');

-- Pre-registering a student: only email and student number. Status is 'pending'.
INSERT INTO users (email, password_hash) VALUES ('student@test.com', 'default-password-hash');
INSERT INTO students (student_no, user_id, adviser_id) VALUES
  ('2021-12345-MN-0', (SELECT user_id FROM users WHERE email = 'student@test.com'), 'F002');

-- The student sets up the account, so it becomes 'active'. Year level 4 is allowed.
UPDATE users SET first_name = 'Ana', last_name = 'Cruz', account_status = 'active', must_change_password = 0
 WHERE email = 'student@test.com';
UPDATE students SET program_code = 'BSIT', year_level = 4, section = '4-1', contact_no = '09171234567'
 WHERE student_no = '2021-12345-MN-0';

-- A posting goes through the approval steps
INSERT INTO internship_opportunities (company_id, supervisor_id, title, slots, required_hours, location, work_mode, target_programs) VALUES
  ((SELECT company_id FROM companies WHERE contact_email = 'info@testcompany.com'),
   (SELECT supervisor_id FROM company_supervisors WHERE user_role = 'supervisor' LIMIT 1),
   'Web Developer Intern', 1, 40, 'Makati', 'hybrid', '["BSIT","BSCS"]');
UPDATE internship_opportunities SET opp_status = 'pending_coordinator' WHERE title = 'Web Developer Intern';
UPDATE internship_opportunities SET opp_status = 'active', reviewed_by = 'F001', review_remarks = 'Approved'
 WHERE title = 'Web Developer Intern';

-- The student applies and the company supervisor accepts
INSERT INTO applications (student_no, opportunity_id) VALUES
  ('2021-12345-MN-0', (SELECT opportunity_id FROM internship_opportunities WHERE title = 'Web Developer Intern'));
UPDATE applications
   SET application_status = 'accepted', decision_remarks = 'Welcome!', decided_at = NOW(),
       decided_by = (SELECT supervisor_id FROM company_supervisors WHERE user_role = 'company' LIMIT 1)
 WHERE student_no = '2021-12345-MN-0';

-- The placement (40 required hours)
INSERT INTO internship_placements (application_id, adviser_id, supervisor_id, start_date, end_date, required_hours) VALUES
  ((SELECT application_id FROM applications WHERE student_no = '2021-12345-MN-0'),
   'F002',
   (SELECT supervisor_id FROM company_supervisors WHERE user_role = 'supervisor' LIMIT 1),
   '2026-02-02', '2026-12-31', 40);

-- DAILY records: 8 hours a day for 6 days (hours are required)
INSERT INTO progress_reports (placement_id, report_type, report_date, hours_rendered, activities) VALUES
  ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-02-02', 8, 'Setup and training'),
  ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-02-03', 8, 'Learned the codebase'),
  ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-02-04', 8, 'Built the login page'),
  ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-02-05', 8, 'Built the home page'),
  ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-02-06', 8, 'Bug fixing'),
  ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-02-09', 8, 'Testing');

-- WEEKLY reports: dated on the Monday, hours are left empty
-- (a weekly report may have the same date as a daily record. That is allowed.)
INSERT INTO progress_reports (placement_id, report_type, report_date, activities) VALUES
  ((SELECT MIN(placement_id) FROM internship_placements), 'weekly', '2026-02-02', 'Week 1: training, login page, home page and bug fixing'),
  ((SELECT MIN(placement_id) FROM internship_placements), 'weekly', '2026-02-09', 'Week 2: testing');

-- The intern supervisor approves 4 daily records and the weekly report of week 1,
-- rejects one daily record, and approves the last daily record.
UPDATE progress_reports
   SET report_status = 'approved', reviewed_at = NOW(),
       reviewed_by = (SELECT supervisor_id FROM company_supervisors WHERE user_role = 'supervisor' LIMIT 1)
 WHERE (report_type = 'daily' AND report_date IN ('2026-02-02', '2026-02-03', '2026-02-04', '2026-02-05', '2026-02-09'))
    OR (report_type = 'weekly' AND report_date = '2026-02-02');
UPDATE progress_reports
   SET report_status = 'rejected', supervisor_remarks = 'Please add more details', reviewed_at = NOW(),
       reviewed_by = (SELECT supervisor_id FROM company_supervisors WHERE user_role = 'supervisor' LIMIT 1)
 WHERE report_type = 'daily' AND report_date = '2026-02-06';

-- Two evaluations: one by the intern supervisor, one by the adviser
INSERT INTO evaluations (placement_id, evaluator_id, evaluation_type, score, comments) VALUES
  ((SELECT MIN(placement_id) FROM internship_placements), (SELECT user_id FROM users WHERE email = 'internsup@test.com'), 'company', 95, 'Very good intern'),
  ((SELECT MIN(placement_id) FROM internship_placements), (SELECT user_id FROM users WHERE email = 'adviser@test.com'),   'adviser', 90, 'Good work');


-- ============================================================
-- PART 2: CHECK THE RESULTS
-- ============================================================

-- 2a) How many rows are in each important table?
-- Expected: users 5, students 1, faculties 2, company_supervisors 2, companies 1,
--           internship_opportunities 1, applications 1, internship_placements 1,
--           progress_reports 8 (6 daily + 2 weekly), evaluations 2
SELECT 'users' AS table_name, COUNT(*) AS total_rows FROM users
UNION ALL SELECT 'students', COUNT(*) FROM students
UNION ALL SELECT 'faculties', COUNT(*) FROM faculties
UNION ALL SELECT 'company_supervisors', COUNT(*) FROM company_supervisors
UNION ALL SELECT 'companies', COUNT(*) FROM companies
UNION ALL SELECT 'internship_opportunities', COUNT(*) FROM internship_opportunities
UNION ALL SELECT 'applications', COUNT(*) FROM applications
UNION ALL SELECT 'internship_placements', COUNT(*) FROM internship_placements
UNION ALL SELECT 'progress_reports', COUNT(*) FROM progress_reports
UNION ALL SELECT 'evaluations', COUNT(*) FROM evaluations;

-- 2b) How many daily and weekly reports? Expected: daily 6, weekly 2
SELECT report_type, COUNT(*) AS total FROM progress_reports GROUP BY report_type;

-- 2c) Hours of the placement. Only DAILY records count as hours.
-- Expected: required 40, rendered 40.00 (the rejected day is not counted),
--           approved 40.00, remaining 0.00, completion 100.0
-- (If the weekly reports were counted too, you would see wrong numbers.)
SELECT p.placement_id,
       p.required_hours,
       COALESCE(SUM(CASE WHEN r.report_status <> 'rejected' THEN r.hours_rendered END), 0) AS hours_rendered,
       COALESCE(SUM(CASE WHEN r.report_status = 'approved' THEN r.hours_rendered END), 0) AS approved_hours,
       p.required_hours - COALESCE(SUM(CASE WHEN r.report_status = 'approved' THEN r.hours_rendered END), 0) AS remaining_hours,
       ROUND(COALESCE(SUM(CASE WHEN r.report_status = 'approved' THEN r.hours_rendered END), 0) / p.required_hours * 100, 1) AS completion_percent
FROM internship_placements p
LEFT JOIN progress_reports r ON r.placement_id = p.placement_id AND r.report_type = 'daily'
GROUP BY p.placement_id, p.required_hours;

-- 2d) Hours per week (adding up the daily records of each week).
-- Expected: week of 2026-02-02 = 40.00 total, 32.00 approved (the rejected day is not approved)
--           week of 2026-02-09 = 8.00 total, 8.00 approved
SELECT DATE_SUB(report_date, INTERVAL WEEKDAY(report_date) DAY) AS week_start,
       SUM(hours_rendered) AS total_hours,
       SUM(CASE WHEN report_status = 'approved' THEN hours_rendered END) AS approved_hours
FROM progress_reports
WHERE report_type = 'daily'
GROUP BY week_start
ORDER BY week_start;

-- 2e) Is the placement "ready for completion"? Expected: 1 row (approved hours reached 40).
SELECT p.placement_id
FROM internship_placements p
JOIN progress_reports r ON r.placement_id = p.placement_id AND r.report_type = 'daily' AND r.report_status = 'approved'
WHERE p.placement_status = 'active'
GROUP BY p.placement_id, p.required_hours
HAVING SUM(r.hours_rendered) >= p.required_hours;

-- 2f) Active placements with NO weekly report for the current week (for the email reminder).
-- Expected: 1 row (the test reports are from February, not this week)
SELECT p.placement_id
FROM internship_placements p
WHERE p.placement_status = 'active'
  AND NOT EXISTS (SELECT 1 FROM progress_reports r
                  WHERE r.placement_id = p.placement_id
                    AND r.report_type = 'weekly'
                    AND r.report_date = DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY));

-- 2g) Confirm the completion (the adviser confirms). This should WORK.
UPDATE internship_placements
   SET placement_status = 'completed', confirmed_by = 'F002', confirmed_at = NOW()
 WHERE placement_id > 0;


-- ============================================================
-- PART 3: BAD DATA (each one should be REFUSED)
-- Remove the "-- " in front of ONE line, run it, and read the error.
-- If it is NOT refused, a rule is missing.
-- ============================================================

-- TEST 1: a year level of 5 (only 1 to 4 is allowed)
--   Expected: Check constraint 'chk_students_year' is violated
-- UPDATE students SET year_level = 5 WHERE student_no = '2021-12345-MN-0';

-- TEST 2: a year level of 0
--   Expected: Check constraint 'chk_students_year' is violated
-- UPDATE students SET year_level = 0 WHERE student_no = '2021-12345-MN-0';

-- TEST 3: a daily record with 25 hours
--   Expected: Check constraint 'chk_reports_hours' is violated
-- INSERT INTO progress_reports (placement_id, report_type, report_date, hours_rendered, activities) VALUES ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-03-02', 25, 'test');

-- TEST 4: a daily record with negative hours
--   Expected: Check constraint 'chk_reports_hours' is violated
-- INSERT INTO progress_reports (placement_id, report_type, report_date, hours_rendered, activities) VALUES ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-03-02', -3, 'test');

-- TEST 5: a daily record with NO hours
--   Expected: Check constraint 'chk_reports_hours' is violated
-- INSERT INTO progress_reports (placement_id, report_type, report_date, activities) VALUES ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-03-02', 'test');

-- TEST 6: a weekly report WITH hours (hours must be empty, so they are never counted twice)
--   Expected: Check constraint 'chk_reports_hours' is violated
-- INSERT INTO progress_reports (placement_id, report_type, report_date, hours_rendered, activities) VALUES ((SELECT MIN(placement_id) FROM internship_placements), 'weekly', '2026-03-02', 40, 'test');

-- TEST 7: a weekly report dated on a Wednesday (it must be a Monday)
--   Expected: Check constraint 'chk_reports_monday' is violated
-- INSERT INTO progress_reports (placement_id, report_type, report_date, activities) VALUES ((SELECT MIN(placement_id) FROM internship_placements), 'weekly', '2026-03-04', 'test');

-- TEST 8: a second daily record for the same day
--   Expected: Duplicate entry ... for key 'uq_reports_placement_type_date'
-- INSERT INTO progress_reports (placement_id, report_type, report_date, hours_rendered, activities) VALUES ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-02-02', 4, 'test');

-- TEST 9: a second weekly report for the same week
--   Expected: Duplicate entry ... for key 'uq_reports_placement_type_date'
-- INSERT INTO progress_reports (placement_id, report_type, report_date, activities) VALUES ((SELECT MIN(placement_id) FROM internship_placements), 'weekly', '2026-02-02', 'test');

-- TEST 10: an approved report with no reviewer
--   Expected: Check constraint 'chk_reports_reviewed' is violated
-- INSERT INTO progress_reports (placement_id, report_type, report_date, hours_rendered, activities, report_status) VALUES ((SELECT MIN(placement_id) FROM internship_placements), 'daily', '2026-03-03', 8, 'test', 'approved');

-- TEST 11: the same student applies to the same posting twice
--   Expected: Duplicate entry ... for key 'uq_applications_student_opp'
-- INSERT INTO applications (student_no, opportunity_id) VALUES ('2021-12345-MN-0', (SELECT opportunity_id FROM internship_opportunities WHERE title = 'Web Developer Intern'));

-- TEST 12: a faculty user added as a student
--   Expected: Check constraint 'chk_students_role' is violated
-- INSERT INTO students (student_no, user_id, user_role) VALUES ('2099-00001-MN-0', (SELECT user_id FROM users WHERE email = 'adviser@test.com'), 'faculty');

-- TEST 13: a posting that is 'approved' but has no reviewer
--   Expected: Check constraint 'chk_opportunities_reviewed' is violated
-- INSERT INTO internship_opportunities (company_id, title, slots, opp_status) VALUES ((SELECT company_id FROM companies WHERE contact_email = 'info@testcompany.com'), 'Bad Posting', 1, 'approved');

-- TEST 14: a placement set to 'completed' with no one who confirmed it
--   Expected: Check constraint 'chk_placement_confirmed' is violated
-- UPDATE internship_placements SET confirmed_by = NULL WHERE placement_id > 0;

-- TEST 15: a second company evaluation for the same placement
--   Expected: Duplicate entry ... for key 'uq_evals_placement_type'
-- INSERT INTO evaluations (placement_id, evaluator_id, evaluation_type, score) VALUES ((SELECT MIN(placement_id) FROM internship_placements), (SELECT user_id FROM users WHERE email = 'internsup@test.com'), 'company', 50);

-- TEST 16: delete a company that still has postings (we use soft delete instead)
--   Expected: Cannot delete or update a parent row: a foreign key constraint fails
-- DELETE FROM companies WHERE contact_email = 'info@testcompany.com';


-- ============================================================
-- CLEAN UP
-- To remove all test data, open pup_ilink_db_completed_table_ver5.sql,
-- remove the "--" in front of the DROP DATABASE line, and run it again.
-- ============================================================
