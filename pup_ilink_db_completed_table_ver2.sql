-- ============================================================
-- PUP InternLINK Database (Version 5)
-- 15 tables. Needs MySQL 8.0.16 or newer.
--
-- Made to match the Interface Content documents
-- (student, OJT coordinator, adviser, company supervisor
--  and intern supervisor screens).
--
-- How to read the comments:
--   "NEW:"     = added in this version
--   "CHANGED:" = was different before
--
-- Two ideas used everywhere:
--   1) We never delete accounts or companies. We "soft delete" instead:
--      users.account_status = 'inactive' and companies.is_active = 0.
--      This keeps the history. MySQL also refuses to delete a row
--      that other rows still use.
--   2) Numbers like "hours rendered", "remaining hours" and "completion %"
--      are NOT stored. Your code calculates them with a query
--      (see the sample queries at the bottom).
-- ============================================================

-- Remove the "--" in front of the next line ONLY if you want to
-- DELETE the old database and start fresh. WARNING: all data will be erased!
-- DROP DATABASE IF EXISTS pup_ilink_db;

CREATE DATABASE IF NOT EXISTS pup_ilink_db
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE pup_ilink_db;


-- ============================================================
-- PART 1: SCHOOL STRUCTURE (colleges -> departments -> programs)
-- ============================================================

CREATE TABLE IF NOT EXISTS colleges (
  college_code CHAR(10) NOT NULL,
  college_name VARCHAR(150) DEFAULT NULL,
  PRIMARY KEY (college_code)
);

CREATE TABLE IF NOT EXISTS departments (
  department_code CHAR(10) NOT NULL,
  department_name VARCHAR(150) NOT NULL,
  college_code CHAR(10) NOT NULL,
  PRIMARY KEY (department_code),
  KEY fk_department_college (college_code),
  CONSTRAINT fk_department_college FOREIGN KEY (college_code) REFERENCES colleges (college_code)
);

CREATE TABLE IF NOT EXISTS programs (
  program_code CHAR(10) NOT NULL,
  program_name VARCHAR(150) NOT NULL,
  department_code CHAR(10) NOT NULL,
  PRIMARY KEY (program_code),
  KEY fk_department_code (department_code),
  CONSTRAINT fk_department_code FOREIGN KEY (department_code) REFERENCES departments (department_code)
);


-- ============================================================
-- PART 2: USERS (one login table, then one detail table per role)
-- ============================================================

-- CHANGED: user_role now has 4 roles:
--   student
--   faculty    = adviser or coordinator (faculties.is_coordinator tells which)
--   company    = the company supervisor (posts internships, decides on applications)
--   supervisor = the intern supervisor (watches interns, approves reports, evaluates)
-- CHANGED: account_status starts as 'pending'. The flow is:
--   pre-registered (pending) -> user sets up the account -> active.
--   'inactive' is the soft delete (deactivated, not erased).
-- CHANGED: first_name and last_name can be empty at first, because
--   pre-registration only has the student number and email.
--   An 'active' account must have a name.
-- NEW: must_change_password = 1 means the user still has the default password
--   and must set up the account first.
-- NEW: token_hash and token_expires_at are for the activation invitation and the
--   "forgot password" link. Save only a hash of the token, never the token itself.
CREATE TABLE IF NOT EXISTS users (
  user_id INT NOT NULL AUTO_INCREMENT,
  email VARCHAR(150) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) DEFAULT NULL,
  last_name VARCHAR(100) DEFAULT NULL,
  user_role ENUM('student','faculty','company','supervisor') NOT NULL DEFAULT 'student',
  account_status ENUM('pending','active','inactive','suspended') NOT NULL DEFAULT 'pending',
  must_change_password TINYINT(1) NOT NULL DEFAULT 1,
  token_hash VARCHAR(255) DEFAULT NULL,
  token_expires_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_users_email (email),
  -- this lets the other tables check the user's role
  UNIQUE KEY uq_users_id_role (user_id, user_role),
  CONSTRAINT chk_users_email CHECK (email LIKE '%_@_%._%'),
  CONSTRAINT chk_users_name CHECK (
    account_status <> 'active' OR (first_name IS NOT NULL AND last_name IS NOT NULL)
  )
);

-- Only users with the role 'faculty' can be added here.
CREATE TABLE IF NOT EXISTS faculties (
  faculty_no CHAR(12) NOT NULL,
  user_id INT NOT NULL,
  user_role ENUM('student','faculty','company','supervisor') NOT NULL DEFAULT 'faculty',
  department_code CHAR(10) NOT NULL,
  is_coordinator TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (faculty_no),
  UNIQUE KEY uq_faculty_user_id (user_id),
  KEY fk_faculty_departments (department_code),
  CONSTRAINT fk_faculty_users FOREIGN KEY (user_id, user_role) REFERENCES users (user_id, user_role),
  CONSTRAINT fk_faculty_departments FOREIGN KEY (department_code) REFERENCES departments (department_code),
  CONSTRAINT chk_faculty_role CHECK (user_role = 'faculty')
);

-- Only users with the role 'student' can be added here.
-- CHANGED: program_code, year_level, section and contact_no can be empty at first.
--   Pre-registration only needs the student number and email.
--   The student fills in the rest when setting up the account.
-- NEW: adviser_id = the faculty adviser assigned to this student
--   (the coordinator assigns students to advisers).
CREATE TABLE IF NOT EXISTS students (
  student_no VARCHAR(15) NOT NULL,
  user_id INT NOT NULL,
  user_role ENUM('student','faculty','company','supervisor') NOT NULL DEFAULT 'student',
  adviser_id CHAR(12) DEFAULT NULL,
  program_code CHAR(10) DEFAULT NULL,
  year_level INT DEFAULT NULL,
  section VARCHAR(10) DEFAULT NULL,
  contact_no CHAR(11) DEFAULT NULL,
  PRIMARY KEY (student_no),
  UNIQUE KEY uq_students_user_id (user_id),
  KEY fk_students_programs (program_code),
  KEY fk_students_adviser (adviser_id),
  CONSTRAINT fk_students_users FOREIGN KEY (user_id, user_role) REFERENCES users (user_id, user_role),
  CONSTRAINT fk_students_programs FOREIGN KEY (program_code) REFERENCES programs (program_code),
  CONSTRAINT fk_students_adviser FOREIGN KEY (adviser_id) REFERENCES faculties (faculty_no),
  CONSTRAINT chk_students_role CHECK (user_role = 'student'),
  -- CHANGED: year level is 1 to 4 only (was 1 to 6)
  CONSTRAINT chk_students_year CHECK (year_level BETWEEN 1 AND 4),
  CONSTRAINT chk_students_contact CHECK (contact_no REGEXP '^[0-9]{11}$')
);


-- ============================================================
-- PART 3: COMPANIES AND INTERNSHIP POSTINGS
-- ============================================================

-- NEW: contact_no (phone number of the company).
-- NEW: is_active = 0 means the partnership is archived (soft delete).
-- "Expiring soon" MOAs are found with moa_end (see sample query 3).
CREATE TABLE IF NOT EXISTS companies (
  company_id INT NOT NULL AUTO_INCREMENT,
  company_name VARCHAR(150) NOT NULL,
  address VARCHAR(200) NOT NULL,
  contact_email VARCHAR(100) NOT NULL,
  contact_no VARCHAR(20) DEFAULT NULL,
  moa_start DATE NOT NULL,
  moa_end DATE NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (company_id),
  UNIQUE KEY uq_companies_email (contact_email),
  CONSTRAINT chk_companies_moa_dates CHECK (moa_end > moa_start)
);

-- This table holds BOTH kinds of company-side people.
-- The kind is set by user_role: 'company' (company supervisor) or 'supervisor' (intern supervisor).
-- CHANGED: the role check now allows both roles (before, only 'supervisor').
-- is_active = 0 means deactivated. Before deactivating an intern supervisor,
-- your code should warn if he or she still has active interns.
CREATE TABLE IF NOT EXISTS company_supervisors (
  supervisor_id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  user_role ENUM('student','faculty','company','supervisor') NOT NULL DEFAULT 'supervisor',
  company_id INT NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  company_position VARCHAR(100) NOT NULL,
  company_department VARCHAR(100) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (supervisor_id),
  UNIQUE KEY uq_company_supervisors_user_id (user_id),
  KEY fk_supervisors_companies (company_id),
  CONSTRAINT fk_company_supervisors_users FOREIGN KEY (user_id, user_role) REFERENCES users (user_id, user_role),
  CONSTRAINT fk_supervisors_companies FOREIGN KEY (company_id) REFERENCES companies (company_id),
  CONSTRAINT chk_supervisors_role CHECK (user_role IN ('company','supervisor'))
);

-- Internship postings.
-- CHANGED: opp_status now follows the approval steps:
--   pending_company     = the company is still preparing / reviewing the posting
--   pending_coordinator = submitted, waiting for the OJT coordinator
--   approved            = the coordinator approved it
--   active              = open for students to apply
--   filled              = no slots left
--   deactivated         = closed by the company
--   rejected            = the coordinator rejected it (see review_remarks)
-- CHANGED: approved_by is now reviewed_by (the coordinator who approved OR rejected it).
--   It can be empty until the coordinator reviews the posting.
-- NEW: review_remarks = the coordinator's reason for approving or rejecting.
-- NEW: supervisor_id = the intern supervisor this posting is assigned to.
-- NEW: qualifications, skills, responsibilities, location, required_hours, work_mode
--   (work_mode is the "modality"). Students can filter by location, modality and hours.
-- NEW: target_programs = the programs the company wants, saved as a list like
--   '["BSIT","BSCS"]'. Leave it empty if any program can apply.
--   (A separate table would be the textbook way, but that would make 16 tables.
--    Your code must check that the program codes are real. See sample query 1.)
CREATE TABLE IF NOT EXISTS internship_opportunities (
  opportunity_id INT NOT NULL AUTO_INCREMENT,
  company_id INT NOT NULL,
  supervisor_id INT DEFAULT NULL,
  reviewed_by CHAR(12) DEFAULT NULL,
  review_remarks TEXT,
  title VARCHAR(100) NOT NULL,
  opp_description TEXT,
  qualifications TEXT,
  skills TEXT,
  responsibilities TEXT,
  slots INT NOT NULL,
  required_hours INT DEFAULT NULL,
  location VARCHAR(150) DEFAULT NULL,
  work_mode ENUM('onsite','remote','hybrid') NOT NULL DEFAULT 'onsite',
  target_programs JSON DEFAULT NULL,
  application_deadline DATE DEFAULT NULL,
  opp_status ENUM('pending_company','pending_coordinator','approved','active','filled','deactivated','rejected')
    NOT NULL DEFAULT 'pending_company',
  created_at TIMESTAMP NOT NULL DEFAULT (NOW()),
  updated_at TIMESTAMP NOT NULL DEFAULT (NOW()) ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (opportunity_id),
  KEY fk_opportunities_company (company_id),
  KEY fk_opportunities_supervisor (supervisor_id),
  KEY fk_opportunities_reviewer (reviewed_by),
  KEY idx_opportunities_status (opp_status),
  CONSTRAINT fk_opportunities_company FOREIGN KEY (company_id) REFERENCES companies (company_id),
  CONSTRAINT fk_opportunities_supervisor FOREIGN KEY (supervisor_id) REFERENCES company_supervisors (supervisor_id),
  CONSTRAINT fk_opportunities_reviewer FOREIGN KEY (reviewed_by) REFERENCES faculties (faculty_no),
  CONSTRAINT chk_opportunities_slots CHECK (slots > 0),
  CONSTRAINT chk_opportunities_hours CHECK (required_hours > 0),
  -- a posting that was approved, opened, filled or rejected must have a reviewer
  CONSTRAINT chk_opportunities_reviewed CHECK (
    opp_status IN ('pending_company','pending_coordinator','deactivated') OR reviewed_by IS NOT NULL
  )
);


-- ============================================================
-- PART 4: THE INTERNSHIP PROCESS
-- applications -> placements -> progress reports + evaluations
-- ============================================================

-- A student can apply to the same posting only once.
-- (A rejected or withdrawn student can still apply to OTHER postings.
--  The company slot comes back automatically, because slots left =
--  slots minus the number of 'accepted' applications.)
-- NEW: decided_by, decision_remarks, decided_at = the company supervisor's decision.
--   "Company decision" and "status" are the same thing: application_status.
-- An 'accepted' or 'rejected' application must say who decided.
CREATE TABLE IF NOT EXISTS applications (
  application_id INT NOT NULL AUTO_INCREMENT,
  student_no VARCHAR(15) NOT NULL,
  opportunity_id INT NOT NULL,
  date_applied DATE NOT NULL DEFAULT (CURDATE()),
  application_status ENUM('accepted','pending','rejected','withdrawn') NOT NULL DEFAULT 'pending',
  decided_by INT DEFAULT NULL,
  decision_remarks TEXT,
  decided_at DATETIME DEFAULT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (application_id),
  UNIQUE KEY uq_applications_student_opp (student_no, opportunity_id),
  KEY fk_applications_opp (opportunity_id),
  KEY fk_applications_decider (decided_by),
  KEY idx_applications_status (application_status),
  CONSTRAINT fk_applications_student FOREIGN KEY (student_no) REFERENCES students (student_no),
  CONSTRAINT fk_applications_opp FOREIGN KEY (opportunity_id) REFERENCES internship_opportunities (opportunity_id),
  CONSTRAINT fk_applications_decider FOREIGN KEY (decided_by) REFERENCES company_supervisors (supervisor_id),
  CONSTRAINT chk_applications_decided CHECK (
    application_status NOT IN ('accepted','rejected') OR decided_by IS NOT NULL
  )
);

-- An accepted student gets a placement.
-- adviser_id = the adviser at the time of the placement (copy it from students.adviser_id).
-- supervisor_id = the intern supervisor of this student.
-- NEW: confirmed_by, confirmed_at = the coordinator or adviser who confirmed the
--   completion. When the approved hours reach required_hours, your code shows
--   "ready for completion". The placement becomes 'completed' only after someone confirms.
-- Reminder: the database cannot check that the supervisor works for the SAME company
-- as the posting. Please check that in your code.
CREATE TABLE IF NOT EXISTS internship_placements (
  placement_id INT NOT NULL AUTO_INCREMENT,
  application_id INT NOT NULL,
  adviser_id CHAR(12) NOT NULL,
  supervisor_id INT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  required_hours INT NOT NULL,
  placement_status ENUM('completed','active','terminated') NOT NULL DEFAULT 'active',
  confirmed_by CHAR(12) DEFAULT NULL,
  confirmed_at DATETIME DEFAULT NULL,
  certificate_no VARCHAR(50) DEFAULT NULL,
  date_issued DATE DEFAULT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (placement_id),
  UNIQUE KEY uq_placements_application (application_id),
  UNIQUE KEY uq_placements_certificate (certificate_no),
  KEY fk_placements_adviser (adviser_id),
  KEY fk_placements_supervisor (supervisor_id),
  KEY fk_placements_confirmer (confirmed_by),
  KEY idx_placements_status (placement_status),
  CONSTRAINT fk_placements_application FOREIGN KEY (application_id) REFERENCES applications (application_id),
  CONSTRAINT fk_placements_adviser FOREIGN KEY (adviser_id) REFERENCES faculties (faculty_no),
  CONSTRAINT fk_placements_supervisor FOREIGN KEY (supervisor_id) REFERENCES company_supervisors (supervisor_id),
  CONSTRAINT fk_placements_confirmer FOREIGN KEY (confirmed_by) REFERENCES faculties (faculty_no),
  CONSTRAINT chk_placement_dates CHECK (end_date >= start_date),
  CONSTRAINT chk_req_hours CHECK (required_hours > 0),
  -- a completed placement must have a confirmer
  CONSTRAINT chk_placement_confirmed CHECK (placement_status <> 'completed' OR confirmed_by IS NOT NULL),
  -- certificate number and date must be filled in together, or both left empty
  CONSTRAINT chk_certificate_pair CHECK (
    (certificate_no IS NULL AND date_issued IS NULL)
    OR (certificate_no IS NOT NULL AND date_issued IS NOT NULL)
  )
);

-- Progress reports. There are TWO kinds, set by report_type:
--   'daily'  = the daily attendance record. One row per day, with the hours worked
--              that day (more than 0, up to 24) and a short note of what was done.
--   'weekly' = the weekly report. One row per week with the summary of the week.
--              Use the MONDAY of the week as report_date. Leave hours empty (NULL).
-- Hours come ONLY from the daily records, so hours are never counted twice.
-- (To show the hours of a week, add up that week's daily hours. See sample query 2.)
-- NEW: report_type.
-- CHANGED: hours_rendered can be empty, but only for weekly reports.
-- CHANGED: a placement can have only one report of each kind per date.
-- CHANGED: removed ON DELETE CASCADE, because we do not delete data (soft delete).
-- NEW: report_status = pending / approved / rejected. Only 'approved' DAILY hours count
--   as approved hours. The intern supervisor decides. (Your code can approve a whole
--   week of daily records with one click.)
-- NEW: supervisor_remarks, reviewed_by, reviewed_at = the supervisor's review.
-- Your code must also check: the placement is 'active', the date is between the
-- start and end date, the date is not in the future, and approved or rejected
-- reports are locked (a student can edit only a rejected report).
CREATE TABLE IF NOT EXISTS progress_reports (
  report_id INT NOT NULL AUTO_INCREMENT,
  placement_id INT NOT NULL,
  report_type ENUM('daily','weekly') NOT NULL DEFAULT 'daily',
  report_date DATE NOT NULL DEFAULT (CURDATE()),
  hours_rendered DECIMAL(5,2) DEFAULT NULL,
  activities TEXT NOT NULL,
  report_status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  supervisor_remarks TEXT,
  reviewed_by INT DEFAULT NULL,
  reviewed_at DATETIME DEFAULT NULL,
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (report_id),
  UNIQUE KEY uq_reports_placement_type_date (placement_id, report_type, report_date),
  KEY fk_reports_reviewer (reviewed_by),
  KEY idx_reports_status (report_status),
  CONSTRAINT fk_reports_placement FOREIGN KEY (placement_id) REFERENCES internship_placements (placement_id),
  CONSTRAINT fk_reports_reviewer FOREIGN KEY (reviewed_by) REFERENCES company_supervisors (supervisor_id),
  -- daily: hours are required (more than 0 and not more than 24)
  -- weekly: hours must be empty
  CONSTRAINT chk_reports_hours CHECK (
    (report_type = 'daily' AND hours_rendered IS NOT NULL AND hours_rendered > 0 AND hours_rendered <= 24)
    OR (report_type = 'weekly' AND hours_rendered IS NULL)
  ),
  -- a weekly report must be dated on a Monday
  CONSTRAINT chk_reports_monday CHECK (report_type = 'daily' OR WEEKDAY(report_date) = 0),
  -- an approved or rejected report must say who reviewed it
  CONSTRAINT chk_reports_reviewed CHECK (report_status = 'pending' OR reviewed_by IS NOT NULL)
);

-- CHANGED: evaluator_id is now a user_id (a number), so BOTH an intern supervisor
--   and a faculty adviser can evaluate. Before, only faculty could.
-- NEW: evaluation_type = 'company' (by the intern supervisor) or
--   'adviser' (by the faculty adviser). If your team decides that advisers do not
--   evaluate, just use 'company' only.
-- NEW: one evaluation of each type per placement (no duplicates).
-- There is no updated_at on purpose: once submitted, an evaluation should not change.
--   Your code should block edits, and show the grade to the student only after the
--   placement is 'completed'.
CREATE TABLE IF NOT EXISTS evaluations (
  evaluation_id INT NOT NULL AUTO_INCREMENT,
  placement_id INT NOT NULL,
  evaluator_id INT NOT NULL,
  evaluation_type ENUM('company','adviser') NOT NULL DEFAULT 'company',
  score INT NOT NULL,
  comments TEXT,
  date_evaluated DATE NOT NULL DEFAULT (CURDATE()),
  PRIMARY KEY (evaluation_id),
  UNIQUE KEY uq_evals_placement_type (placement_id, evaluation_type),
  KEY fk_evals_evaluator (evaluator_id),
  CONSTRAINT fk_evals_placement FOREIGN KEY (placement_id) REFERENCES internship_placements (placement_id),
  CONSTRAINT fk_evals_evaluator FOREIGN KEY (evaluator_id) REFERENCES users (user_id),
  CONSTRAINT chk_eval_score CHECK (score BETWEEN 1 AND 100)
);


-- ============================================================
-- PART 5: REQUIREMENTS AND STUDENT FILE SUBMISSIONS
-- ============================================================

-- NEW: phase = which tab the requirement belongs to:
--   'before' internship, 'during' internship or 'after' internship.
-- is_mandatory = 1 means mandatory, 0 means optional.
-- A student should not be allowed to apply until all mandatory 'before'
-- requirements are 'accepted' (your code checks this).
CREATE TABLE IF NOT EXISTS requirements (
  requirement_id INT NOT NULL AUTO_INCREMENT,
  requirement_name VARCHAR(150) NOT NULL,
  req_description TEXT,
  is_mandatory TINYINT(1) NOT NULL DEFAULT 0,
  phase ENUM('before','during','after') NOT NULL DEFAULT 'before',
  PRIMARY KEY (requirement_id),
  UNIQUE KEY uq_requirements_name (requirement_name)
);

-- A student has one row per requirement. To resubmit a rejected file,
-- update the same row and set the status back to 'pending'.
-- The reviewer's reason for rejecting goes in remarks.
CREATE TABLE IF NOT EXISTS student_submissions (
  submission_id INT NOT NULL AUTO_INCREMENT,
  student_no VARCHAR(15) NOT NULL,
  requirement_id INT NOT NULL,
  file_path VARCHAR(255) NOT NULL,
  date_submitted DATE NOT NULL DEFAULT (CURDATE()),
  submission_status ENUM('pending','accepted','rejected') NOT NULL DEFAULT 'pending',
  remarks TEXT,
  reviewed_by CHAR(12) DEFAULT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (submission_id),
  UNIQUE KEY uq_submissions_student_req (student_no, requirement_id),
  KEY fk_submissions_requirement (requirement_id),
  KEY fk_submissions_reviewer (reviewed_by),
  KEY idx_submissions_status (submission_status),
  CONSTRAINT fk_submissions_student FOREIGN KEY (student_no) REFERENCES students (student_no),
  CONSTRAINT fk_submissions_requirement FOREIGN KEY (requirement_id) REFERENCES requirements (requirement_id),
  CONSTRAINT fk_submissions_reviewer FOREIGN KEY (reviewed_by) REFERENCES faculties (faculty_no)
);


-- ============================================================
-- STARTER DATA
-- INSERT IGNORE = if a row already exists, skip it (so you can run this script again safely).
-- ============================================================

INSERT IGNORE INTO colleges (college_code, college_name) VALUES
	('CADBE', 'College of Architecture, Design and the Built Environment'),
	('CAF', 'College of Accountancy and Finance'),
	('CAL', 'College of Arts and Letters'),
	('CBA', 'College of Business Administration'),
	('CCIS', 'College of Computer and Information Sciences'),
	('CE', 'College of Engineering'),
	('CHK', 'College of Human Kinetics'),
	('CL', 'College of Law'),
	('COC', 'College of Communication'),
	('COED', 'College of Education'),
	('CPSPA', 'College of Political Science and Public Administration'),
	('CS', 'College of Science'),
	('CSSD', 'College of Social Sciences and Development'),
	('CTHTM', 'College of Tourism, Hospitality and Transportation Management'),
	('ITECH', 'Institute of Technology');

INSERT IGNORE INTO departments (department_code, department_name, college_code) VALUES
	('CADBE-ARCH', 'Department of Architecture', 'CADBE'),
	('CADBE-EP', 'Department of Environmental Planning', 'CADBE'),
	('CADBE-ID', 'Department of Interior Design', 'CADBE'),
	('CAF-ACC', 'Department of Accountancy', 'CAF'),
	('CAF-BAMA', 'Department of Basic Accounting / Management Accounting', 'CAF'),
	('CAL-EFL', 'Department of English, Foreign Languages and Linguistics', 'CAL'),
	('CAL-FIL', 'Department of Filipinology', 'CAL'),
	('CAL-HP', 'Department of Humanities and Philosophy', 'CAL'),
	('CAL-PA', 'Department of Performing Arts', 'CAL'),
	('CBA-CSD', 'Department of Cooperatives and Social Development', 'CBA'),
	('CBA-ENT', 'Department of Entrepreneurship', 'CBA'),
	('CBA-FM', 'Department of Financial Management', 'CBA'),
	('CBA-HRM', 'Department of Human Resource Management', 'CBA'),
	('CBA-MM', 'Department of Marketing Management', 'CBA'),
	('CBA-OA', 'Department of Office Administration', 'CBA'),
	('CBA-REM', 'Department of Real Estate Management', 'CBA'),
	('CCIS-CS', 'Department of Computer Science', 'CCIS'),
	('CCIS-IT', 'Department of Information Technology', 'CCIS'),
	('CE-CIV', 'Department of Civil Engineering', 'CE'),
	('CE-CPE', 'Department of Computer Engineering', 'CE'),
	('CE-ECE', 'Department of Electronics Engineering', 'CE'),
	('CE-EE', 'Department of Electrical Engineering', 'CE'),
	('CE-ES', 'Department of Engineering Sciences', 'CE'),
	('CE-IE', 'Department of Industrial Engineering', 'CE'),
	('CE-ME', 'Department of Mechanical Engineering', 'CE'),
	('CE-RE', 'Department of Railway Engineering', 'CE'),
	('CHK-PP', 'Department of Professional Programs', 'CHK'),
	('CHK-SPE', 'Department of Service Physical Education', 'CHK'),
	('CHK-SS', 'Department of Sports Science', 'CHK'),
	('CL-LAW', 'Department of Law', 'CL'),
	('COC-APR', 'Department of Advertising and Public Relations', 'COC'),
	('COC-BC', 'Department of Broadcast Communication', 'COC'),
	('COC-CR', 'Department of Communication Research', 'COC'),
	('COC-JOUR', 'Department of Journalism', 'COC'),
	('COED-BTLE', 'Department of Business Technology and Livelihood Education', 'COED'),
	('COED-ECEE', 'Department of Early Childhood and Elementary Education', 'COED'),
	('COED-ESE', 'Department of Elementary and Secondary Education', 'COED'),
	('COED-LIS', 'Department of Library and Information Science', 'COED'),
	('CPSPA-PAG', 'Department of Public Administration and Governance', 'CPSPA'),
	('CPSPA-PE', 'Department of Political Economy', 'CPSPA'),
	('CPSPA-PS', 'Department of Political Science', 'CPSPA'),
	('CS-BIO', 'Department of Biology', 'CS'),
	('CS-CHEM', 'Department of Chemistry', 'CS'),
	('CS-FT', 'Department of Food Technology', 'CS'),
	('CS-MS', 'Department of Mathematics and Statistics', 'CS'),
	('CS-ND', 'Department of Nutrition and Dietetics', 'CS'),
	('CS-PS', 'Department of Physical Science', 'CS'),
	('CSSD-ECON', 'Department of Economics', 'CSSD'),
	('CSSD-HPS', 'Department of History and Philippine Studies', 'CSSD'),
	('CSSD-PSY', 'Department of Psychology', 'CSSD'),
	('CSSD-SA', 'Department of Sociology and Anthropology', 'CSSD'),
	('CTHTM-HM', 'Department of Hospitality Management', 'CTHTM'),
	('CTHTM-TTM', 'Department of Tourism and Transportation Management', 'CTHTM'),
	('ITECH-PROG', 'Institute of Technology Programs', 'ITECH');

INSERT IGNORE INTO programs (program_code, program_name, department_code) VALUES
	('ABELS', 'Bachelor of Arts in English Language Studies', 'CAL-EFL'),
	('ABF', 'Bachelor of Arts in Filipinology', 'CAL-FIL'),
	('ABLCS', 'Bachelor of Arts in Literary and Cultural Studies', 'CAL-HP'),
	('ABPHILO', 'Bachelor of Arts in Philosophy', 'CAL-HP'),
	('ABS', 'Bachelor of Arts in Sociology', 'CSSD-SA'),
	('BABR', 'Bachelor of Arts in Broadcasting', 'COC-BC'),
	('BACR', 'Bachelor of Arts in Communication Research', 'COC-CR'),
	('BADPR', 'Bachelor in Advertising and Public Relations', 'COC-APR'),
	('BAH', 'Bachelor of Arts in History', 'CSSD-HPS'),
	('BAIS', 'Bachelor of Arts in International Studies', 'CPSPA-PS'),
	('BAJ', 'Bachelor of Arts in Journalism', 'COC-JOUR'),
	('BAPE', 'Bachelor of Arts in Political Economy', 'CPSPA-PE'),
	('BAPHS', 'Bachelor of Arts in Philippine Studies', 'CSSD-HPS'),
	('BAPS', 'Bachelor of Arts in Political Science', 'CPSPA-PS'),
	('BECEd', 'Bachelor of Early Childhood Education', 'COED-ECEE'),
	('BEEd', 'Bachelor of Elementary Education', 'COED-ESE'),
	('BHS', 'Bachelor in Human Services', 'CSSD-SA'),
	('BLIS', 'Bachelor of Library and Information Science', 'COED-LIS'),
	('BPA', 'Bachelor of Public Administration', 'CPSPA-PAG'),
	('BPE', 'Bachelor of Physical Education', 'CHK-PP'),
	('BPEA', 'Bachelor of Performing Arts major in Theater Arts', 'CAL-PA'),
	('BSA', 'Bachelor of Science in Accountancy', 'CAF-ACC'),
	('BSAPMATH', 'Bachelor of Science in Applied Mathematics', 'CS-MS'),
	('BSARCH', 'Bachelor of Science in Architecture', 'CADBE-ARCH'),
	('BSBAFM', 'Bachelor of Science in Business Administration major in Financial Management', 'CBA-FM'),
	('BSBAHRM', 'Bachelor of Science in Business Administration major in Human Resource Management', 'CBA-HRM'),
	('BSBAMM', 'Bachelor of Science in Business Administration major in Marketing Management', 'CBA-MM'),
	('BSBIO', 'Bachelor of Science in Biology', 'CS-BIO'),
	('BSCE', 'Bachelor of Science in Civil Engineering', 'CE-CIV'),
	('BSCHEM', 'Bachelor of Science in Chemistry', 'CS-CHEM'),
	('BSCpE', 'Bachelor of Science in Computer Engineering', 'CE-CPE'),
	('BSCS', 'Bachelor of Science in Computer Science', 'CCIS-CS'),
	('BSE', 'Bachelor of Science in Economics', 'CSSD-ECON'),
	('BSECE', 'Bachelor of Science in Electronics Engineering', 'CE-ECE'),
	('BSEd', 'Bachelor of Secondary Education (English, Mathematics, Science, Filipino, and Social Studies)', 'COED-ESE'),
	('BSEE', 'Bachelor of Science in Electrical Engineering', 'CE-EE'),
	('BSENTREP', 'Bachelor of Science in Entrepreneurship', 'CBA-ENT'),
	('BSEP', 'Bachelor of Science in Environmental Planning', 'CADBE-EP'),
	('BSESS', 'Bachelor of Science in Exercises and Sports', 'CHK-SS'),
	('BSFT', 'Bachelor of Science in Food Technology', 'CS-FT'),
	('BSHM', 'Bachelor of Science in Hospitality Management', 'CTHTM-HM'),
	('BSID', 'Bachelor of Science in Interior Design', 'CADBE-ID'),
	('BSIE', 'Bachelor of Science in Industrial Engineering', 'CE-IE'),
	('BSIT', 'Bachelor of Science in Information Technology', 'CCIS-IT'),
	('BSMA', 'Bachelor of Science in Management Accounting', 'CAF-BAMA'),
	('BSMATH', 'Bachelor of Science in Mathematics', 'CS-MS'),
	('BSME', 'Bachelor of Science in Mechanical Engineering', 'CE-ME'),
	('BSND', 'Bachelor of Science in Nutrition and Dietetics', 'CS-ND'),
	('BSOA', 'Bachelor of Science in Office Administration', 'CBA-OA'),
	('BSPHY', 'Bachelor of Science in Physics', 'CS-PS'),
	('BSPSY', 'Bachelor of Science in Psychology', 'CSSD-PSY'),
	('BSRE', 'Bachelor of Science in Railway Engineering', 'CE-RE'),
	('BSSTAT', 'Bachelor of Science in Statistics', 'CS-MS'),
	('BSSW', 'Bachelor of Science in Social Work', 'CSSD-SA'),
	('BSTM', 'Bachelor of Science in Tourism Management', 'CTHTM-TTM'),
	('BSTRM', 'Bachelor of Science in Transportation Management', 'CTHTM-TTM'),
	('BTLEd', 'Bachelor of Technology and Livelihood Education (Home Economics, Industrial Arts, and ICT)', 'COED-BTLE'),
	('DCET', 'Diploma in Computer Engineering Technology', 'ITECH-PROG'),
	('DECET', 'Diploma in Electronics Communications Engineering Technology', 'ITECH-PROG'),
	('DEET', 'Diploma in Electrical Engineering Technology', 'ITECH-PROG'),
	('DICT', 'Diploma in Information Communication Technology', 'ITECH-PROG'),
	('DMET', 'Diploma in Mechanical Engineering Technology', 'ITECH-PROG'),
	('DOMT', 'Diploma in Office Management Technology', 'ITECH-PROG'),
	('DRET', 'Diploma in Railway Engineering Technology', 'ITECH-PROG');

-- NEW: sample requirements, now with a phase (before / during / after).
-- These are only examples. Change them to match your school's real list.
INSERT IGNORE INTO requirements (requirement_name, req_description, is_mandatory, phase) VALUES
	('Resume', 'Updated resume or CV of the student', 1, 'before'),
	('Parent/Guardian Waiver', 'Signed waiver from the parent or guardian', 1, 'before'),
	('Endorsement Letter', 'Letter from the college endorsing the student to the company', 1, 'before'),
	('Company Acceptance Letter', 'Letter from the company accepting the student', 1, 'before'),
	('Medical Certificate', 'Proof that the student is fit for the internship', 0, 'before'),
	('Daily Time Record (DTR)', 'Signed record of the hours rendered', 1, 'during'),
	('Narrative Report', 'Final report about what the student learned', 1, 'after'),
	('Certificate of Completion', 'Certificate given by the company', 0, 'after');


-- ============================================================
-- SAMPLE QUERIES (just examples, they are commented out)
-- Remove the "-- " in front of a query to try it.
-- ============================================================

-- 1) Postings a student can see: active, still has slots, matches the student's
--    program, and the student has not applied yet.
--    (Change the student number to a real one.)
-- SELECT o.opportunity_id, o.title, c.company_name, o.work_mode, o.location, o.required_hours
-- FROM internship_opportunities o
-- JOIN companies c ON c.company_id = o.company_id
-- JOIN students s ON s.student_no = '2021-12345-MN-0'
-- WHERE o.opp_status = 'active'
--   AND c.is_active = 1
--   AND (o.target_programs IS NULL OR JSON_CONTAINS(o.target_programs, JSON_QUOTE(s.program_code)))
--   AND o.slots > (SELECT COUNT(*) FROM applications a
--                  WHERE a.opportunity_id = o.opportunity_id AND a.application_status = 'accepted')
--   AND NOT EXISTS (SELECT 1 FROM applications a
--                   WHERE a.opportunity_id = o.opportunity_id AND a.student_no = s.student_no);

-- 2) Hours of each placement: rendered, approved, remaining and completion %.
--    (Only daily records count as hours.)
-- SELECT p.placement_id,
--        p.required_hours,
--        COALESCE(SUM(CASE WHEN r.report_status <> 'rejected' THEN r.hours_rendered END), 0) AS hours_rendered,
--        COALESCE(SUM(CASE WHEN r.report_status = 'approved' THEN r.hours_rendered END), 0) AS approved_hours,
--        p.required_hours - COALESCE(SUM(CASE WHEN r.report_status = 'approved' THEN r.hours_rendered END), 0) AS remaining_hours,
--        ROUND(COALESCE(SUM(CASE WHEN r.report_status = 'approved' THEN r.hours_rendered END), 0) / p.required_hours * 100, 1) AS completion_percent
-- FROM internship_placements p
-- LEFT JOIN progress_reports r ON r.placement_id = p.placement_id AND r.report_type = 'daily'
-- GROUP BY p.placement_id, p.required_hours;

-- 3) Companies whose MOA ends within 30 days ("Expiring soon"):
-- SELECT company_id, company_name, moa_end
-- FROM companies
-- WHERE is_active = 1
--   AND moa_end BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);

-- 4) Students of one adviser who have no application yet (to follow up):
-- SELECT s.student_no, u.email
-- FROM students s
-- JOIN users u ON u.user_id = s.user_id
-- WHERE s.adviser_id = 'F001'
--   AND NOT EXISTS (SELECT 1 FROM applications a WHERE a.student_no = s.student_no);

-- 5) Placements that are "ready for completion" (approved hours reached the required hours,
--    but nobody has confirmed yet):
-- SELECT p.placement_id
-- FROM internship_placements p
-- JOIN progress_reports r ON r.placement_id = p.placement_id AND r.report_type = 'daily' AND r.report_status = 'approved'
-- WHERE p.placement_status = 'active'
-- GROUP BY p.placement_id, p.required_hours
-- HAVING SUM(r.hours_rendered) >= p.required_hours;

-- 6) Active placements that have NO weekly report yet for the current week
--    (for the weekly email reminder):
-- SELECT p.placement_id, p.application_id
-- FROM internship_placements p
-- WHERE p.placement_status = 'active'
--   AND NOT EXISTS (SELECT 1 FROM progress_reports r
--                   WHERE r.placement_id = p.placement_id
--                     AND r.report_type = 'weekly'
--                     AND r.report_date = DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY));
