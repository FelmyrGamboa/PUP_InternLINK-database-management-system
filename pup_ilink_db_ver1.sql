
-- ============================================================
-- POLYTECHNIC UNIVERSITY OF THE PHILIPPINES
-- ACADEMIC REFERENCE DATABASE
-- Tables: colleges, departments, programs
-- Database: pup_academic_db
-- ============================================================

CREATE DATABASE IF NOT EXISTS pup_academic_db;

USE pup_academic_db;

-- ============================================================
-- 1. DROP TABLES (FOR CLEAN RECREATION)
-- ============================================================

DROP TABLE IF EXISTS programs;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS colleges;

-- ============================================================
-- 2. CREATE COLLEGES TABLE
-- ============================================================

CREATE TABLE colleges (
    college_code VARCHAR(20) PRIMARY KEY,
    college_name VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

-- ============================================================
-- 3. CREATE DEPARTMENTS TABLE
-- ============================================================

CREATE TABLE departments (
    department_code VARCHAR(30) PRIMARY KEY,
    department_name VARCHAR(150) NOT NULL,
    college_code VARCHAR(20) NOT NULL,

    CONSTRAINT fk_department_college
        FOREIGN KEY (college_code)
        REFERENCES colleges(college_code)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 4. CREATE PROGRAMS TABLE
-- ============================================================

CREATE TABLE programs (
    program_code VARCHAR(30) PRIMARY KEY,
    program_name VARCHAR(200) NOT NULL,
    department_code VARCHAR(30) NOT NULL,

    CONSTRAINT fk_program_department
        FOREIGN KEY (department_code)
        REFERENCES departments(department_code)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 5. INSERT COLLEGES
-- ============================================================

INSERT INTO colleges (college_code, college_name)
VALUES
('CAF', 'College of Accountancy and Finance'),
('CADBE', 'College of Architecture, Design and the Built Environment'),
('CAL', 'College of Arts and Letters'),
('CBA', 'College of Business Administration'),
('COC', 'College of Communication'),
('CCIS', 'College of Computer and Information Sciences'),
('COED', 'College of Education'),
('CE', 'College of Engineering'),
('CHK', 'College of Human Kinetics'),
('CL', 'College of Law'),
('CPSPA', 'College of Political Science and Public Administration'),
('CSSD', 'College of Social Sciences and Development'),
('CS', 'College of Science'),
('CTHTM', 'College of Tourism, Hospitality and Transportation Management'),

-- Additional academic unit for diploma programs
('ITECH', 'Institute of Technology');

-- ============================================================
-- 6. INSERT DEPARTMENTS
-- ============================================================

INSERT INTO departments
    (department_code, department_name, college_code)
VALUES

-- CAF
('CAF-ACC', 'Department of Accountancy', 'CAF'),
('CAF-BAMA', 'Department of Basic Accounting / Management Accounting', 'CAF'),

-- CADBE
('CADBE-ARCH', 'Department of Architecture', 'CADBE'),
('CADBE-ID', 'Department of Interior Design', 'CADBE'),
('CADBE-EP', 'Department of Environmental Planning', 'CADBE'),

-- CAL
('CAL-HP', 'Department of Humanities and Philosophy', 'CAL'),
('CAL-EFL', 'Department of English, Foreign Languages and Linguistics', 'CAL'),
('CAL-FIL', 'Department of Filipinology', 'CAL'),
('CAL-PA', 'Department of Performing Arts', 'CAL'),

-- CBA
('CBA-ENT', 'Department of Entrepreneurship', 'CBA'),
('CBA-FM', 'Department of Financial Management', 'CBA'),
('CBA-HRM', 'Department of Human Resource Management', 'CBA'),
('CBA-MM', 'Department of Marketing Management', 'CBA'),
('CBA-OA', 'Department of Office Administration', 'CBA'),
('CBA-REM', 'Department of Real Estate Management', 'CBA'),
('CBA-CSD', 'Department of Cooperatives and Social Development', 'CBA'),

-- COC
('COC-APR', 'Department of Advertising and Public Relations', 'COC'),
('COC-BC', 'Department of Broadcast Communication', 'COC'),
('COC-CR', 'Department of Communication Research', 'COC'),
('COC-JOUR', 'Department of Journalism', 'COC'),

-- CCIS
('CCIS-CS', 'Department of Computer Science', 'CCIS'),
('CCIS-IT', 'Department of Information Technology', 'CCIS'),

-- COED
('COED-BTLE', 'Department of Business Technology and Livelihood Education', 'COED'),
('COED-ESE', 'Department of Elementary and Secondary Education', 'COED'),
('COED-LIS', 'Department of Library and Information Science', 'COED'),
('COED-ECEE', 'Department of Early Childhood and Elementary Education', 'COED'),

-- CE
('CE-CIV', 'Department of Civil Engineering', 'CE'),
('CE-CPE', 'Department of Computer Engineering', 'CE'),
('CE-EE', 'Department of Electrical Engineering', 'CE'),
('CE-ECE', 'Department of Electronics Engineering', 'CE'),
('CE-IE', 'Department of Industrial Engineering', 'CE'),
('CE-ME', 'Department of Mechanical Engineering', 'CE'),
('CE-RE', 'Department of Railway Engineering', 'CE'),
('CE-ES', 'Department of Engineering Sciences', 'CE'),

-- CHK
('CHK-PP', 'Department of Professional Programs', 'CHK'),
('CHK-SPE', 'Department of Service Physical Education', 'CHK'),
('CHK-SS', 'Department of Sports Science', 'CHK'),

-- CL
('CL-LAW', 'Department of Law', 'CL'),

-- CPSPA
('CPSPA-PAG', 'Department of Public Administration and Governance', 'CPSPA'),
('CPSPA-PE', 'Department of Political Economy', 'CPSPA'),
('CPSPA-PS', 'Department of Political Science', 'CPSPA'),

-- CS
('CS-BIO', 'Department of Biology', 'CS'),
('CS-CHEM', 'Department of Chemistry', 'CS'),
('CS-FT', 'Department of Food Technology', 'CS'),
('CS-MS', 'Department of Mathematics and Statistics', 'CS'),
('CS-ND', 'Department of Nutrition and Dietetics', 'CS'),
('CS-PS', 'Department of Physical Science', 'CS'),

-- CSSD
('CSSD-ECON', 'Department of Economics', 'CSSD'),
('CSSD-HPS', 'Department of History and Philippine Studies', 'CSSD'),
('CSSD-PSY', 'Department of Psychology', 'CSSD'),
('CSSD-SA', 'Department of Sociology and Anthropology', 'CSSD'),

-- CTHTM
('CTHTM-HM', 'Department of Hospitality Management', 'CTHTM'),
('CTHTM-TTM', 'Department of Tourism and Transportation Management', 'CTHTM'),

-- ITECH
('ITECH-PROG', 'Institute of Technology Programs', 'ITECH');

-- ============================================================
-- 7. INSERT PROGRAMS
-- ============================================================

INSERT INTO programs
    (program_code, program_name, department_code)
VALUES

-- CAF
('BSA', 'Bachelor of Science in Accountancy', 'CAF-ACC'),
('BSMA', 'Bachelor of Science in Management Accounting', 'CAF-BAMA'),

-- CADBE
('BSARCH', 'Bachelor of Science in Architecture', 'CADBE-ARCH'),
('BSID', 'Bachelor of Science in Interior Design', 'CADBE-ID'),
('BSEP', 'Bachelor of Science in Environmental Planning', 'CADBE-EP'),

-- CAL
('ABELS', 'Bachelor of Arts in English Language Studies', 'CAL-EFL'),
('ABF', 'Bachelor of Arts in Filipinology', 'CAL-FIL'),
('ABLCS', 'Bachelor of Arts in Literary and Cultural Studies', 'CAL-HP'),
('ABPHILO', 'Bachelor of Arts in Philosophy', 'CAL-HP'),
('BPEA', 'Bachelor of Performing Arts major in Theater Arts', 'CAL-PA'),

-- CBA
('BSBAFM', 'Bachelor of Science in Business Administration major in Financial Management', 'CBA-FM'),
('BSBAHRM', 'Bachelor of Science in Business Administration major in Human Resource Management', 'CBA-HRM'),
('BSBAMM', 'Bachelor of Science in Business Administration major in Marketing Management', 'CBA-MM'),
('BSENTREP', 'Bachelor of Science in Entrepreneurship', 'CBA-ENT'),
('BSOA', 'Bachelor of Science in Office Administration', 'CBA-OA'),

-- COC
('BADPR', 'Bachelor in Advertising and Public Relations', 'COC-APR'),
('BABR', 'Bachelor of Arts in Broadcasting', 'COC-BC'),
('BACR', 'Bachelor of Arts in Communication Research', 'COC-CR'),
('BAJ', 'Bachelor of Arts in Journalism', 'COC-JOUR'),

-- CCIS
('BSCS', 'Bachelor of Science in Computer Science', 'CCIS-CS'),
('BSIT', 'Bachelor of Science in Information Technology', 'CCIS-IT'),

-- COED
('BTLEd', 'Bachelor of Technology and Livelihood Education', 'COED-BTLE'),
('BLIS', 'Bachelor of Library and Information Science', 'COED-LIS'),
('BSEd', 'Bachelor of Secondary Education', 'COED-ESE'),
('BEEd', 'Bachelor of Elementary Education', 'COED-ESE'),
('BECEd', 'Bachelor of Early Childhood Education', 'COED-ECEE'),

-- CE
('BSCE', 'Bachelor of Science in Civil Engineering', 'CE-CIV'),
('BSCpE', 'Bachelor of Science in Computer Engineering', 'CE-CPE'),
('BSEE', 'Bachelor of Science in Electrical Engineering', 'CE-EE'),
('BSECE', 'Bachelor of Science in Electronics Engineering', 'CE-ECE'),
('BSIE', 'Bachelor of Science in Industrial Engineering', 'CE-IE'),
('BSME', 'Bachelor of Science in Mechanical Engineering', 'CE-ME'),
('BSRE', 'Bachelor of Science in Railway Engineering', 'CE-RE'),

-- CHK
('BPE', 'Bachelor of Physical Education', 'CHK-PP'),
('BSESS', 'Bachelor of Science in Exercise and Sports Sciences', 'CHK-SS'),

-- CPSPA
('BAPS', 'Bachelor of Arts in Political Science', 'CPSPA-PS'),
('BAPE', 'Bachelor of Arts in Political Economy', 'CPSPA-PE'),
('BAIS', 'Bachelor of Arts in International Studies', 'CPSPA-PS'),
('BPA', 'Bachelor of Public Administration', 'CPSPA-PAG'),

-- CSSD
('ABS', 'Bachelor of Arts in Sociology', 'CSSD-SA'),
('BSE', 'Bachelor of Science in Economics', 'CSSD-ECON'),
('BAH', 'Bachelor of Arts in History', 'CSSD-HPS'),
('BAPHS', 'Bachelor of Arts in Philippine Studies', 'CSSD-HPS'),
('BSPSY', 'Bachelor of Science in Psychology', 'CSSD-PSY'),
('BHS', 'Bachelor in Human Services', 'CSSD-SA'),
('BSSW', 'Bachelor of Science in Social Work', 'CSSD-SA'),

-- CS
('BSFT', 'Bachelor of Science in Food Technology', 'CS-FT'),
('BSAPMATH', 'Bachelor of Science in Applied Mathematics', 'CS-MS'),
('BSBIO', 'Bachelor of Science in Biology', 'CS-BIO'),
('BSCHEM', 'Bachelor of Science in Chemistry', 'CS-CHEM'),
('BSMATH', 'Bachelor of Science in Mathematics', 'CS-MS'),
('BSND', 'Bachelor of Science in Nutrition and Dietetics', 'CS-ND'),
('BSPHY', 'Bachelor of Science in Physics', 'CS-PS'),
('BSSTAT', 'Bachelor of Science in Statistics', 'CS-MS'),

-- CTHTM
('BSHM', 'Bachelor of Science in Hospitality Management', 'CTHTM-HM'),
('BSTM', 'Bachelor of Science in Tourism Management', 'CTHTM-TTM'),
('BSTRM', 'Bachelor of Science in Transportation Management', 'CTHTM-TTM'),

-- ITECH DIPLOMA PROGRAMS
('DCET', 'Diploma in Computer Engineering Technology', 'ITECH-PROG'),
('DECET', 'Diploma in Electronics Communications Engineering Technology', 'ITECH-PROG'),
('DEET', 'Diploma in Electrical Engineering Technology', 'ITECH-PROG'),
('DICT', 'Diploma in Information Communication Technology', 'ITECH-PROG'),
('DMET', 'Diploma in Mechanical Engineering Technology', 'ITECH-PROG'),
('DOMT', 'Diploma in Office Management Technology', 'ITECH-PROG'),
('DRET', 'Diploma in Railway Engineering Technology', 'ITECH-PROG');

-- ============================================================
-- 8. VERIFICATION QUERIES
-- ============================================================

-- Count colleges
SELECT COUNT(*) AS total_colleges
FROM colleges;

-- Count departments
SELECT COUNT(*) AS total_departments
FROM departments;

-- Count programs
SELECT COUNT(*) AS total_programs
FROM programs;

-- Display complete academic hierarchy
SELECT
    c.college_code,
    c.college_name,
    d.department_code,
    d.department_name,
    p.program_code,
    p.program_name
FROM colleges c
LEFT JOIN departments d
    ON c.college_code = d.college_code
LEFT JOIN programs p
    ON d.department_code = p.department_code
ORDER BY
    c.college_name,
    d.department_name,
    p.program_name;

-- ============================================================
-- END OF SCRIPT
-- ============================================================


CREATE TABLE users (
    user_id INT AUTO_INCREMENT,
    email VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    user_role ENUM('student', 'faculty', 'supervisor')
        NOT NULL DEFAULT 'student',
    account_status ENUM('active', 'inactive', 'suspended')
        NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uq_users_email UNIQUE (email)
);

CREATE TABLE students (
    student_no CHAR(12) NOT NULL,
    user_id INT NOT NULL,
    program_code CHAR(10) NOT NULL,
    year_level INT NOT NULL,
    section VARCHAR(10) NOT NULL,
    contact_no CHAR(11) NOT NULL,

    CONSTRAINT pk_students PRIMARY KEY (student_no),
    CONSTRAINT uq_students_user_id UNIQUE (user_id),
    CONSTRAINT fk_students_programs
        FOREIGN KEY (program_code) REFERENCES programs(program_code),
    CONSTRAINT fk_students_users
        FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE faculties (
    faculty_no CHAR(12) NOT NULL,
    user_id INT NOT NULL,
    department_code CHAR(10) NOT NULL,
    is_coordinator BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_faculty PRIMARY KEY (faculty_no),
    CONSTRAINT uq_faculty_user_id UNIQUE (user_id),
    CONSTRAINT fk_faculty_users
        FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_faculty_departments
        FOREIGN KEY (department_code) REFERENCES departments(department_code)
);

CREATE TABLE company_supervisors (
    supervisor_id INT AUTO_INCREMENT,
    user_id INT NOT NULL,
    company_id INT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    company_position VARCHAR(100) NOT NULL,
    company_department VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_company_supervisors PRIMARY KEY (supervisor_id),
    CONSTRAINT uq_company_supervisors_user_id UNIQUE (user_id),
    CONSTRAINT fk_company_supervisors_users
        FOREIGN KEY (user_id) REFERENCES users(user_id)
    CONSTRAINT fk_supervisors_companies 
		FOREIGN KEY (company_id) REFERENCES companies(company_id);
);  

CREATE TABLE companies (
	company_id INT AUTO_INCREMENT, 
	conpany_name VARCHAR(100) NOT NULL, 
	address VARCHAR(255) NOT NULL, 
	industry VARCHAR(100) NOT NULL, 
	contact_email VARCHAR(100) NOT NULL, 
	moa_start DATETIME NOT NULL, 
	moa_end DATETIME NOT NULL, 
	
	CONSTRAINT pk_companies PRIMARY KEY (company_id), 
	CONSTRAINT uq_contact_emails UNIQUE (contact_email),
	CONSTRAINT chk_companies_moa_dates CHECK (moa_end > moa_start)
);

CREATE TABLE companies (
	company_id INT AUTO_INCREMENT, 
	company_name VARCHAR(150) NOT NULL, 
	address VARCHAR(200) NOT NULL, 
	contact_email VARCHAR(100) NOT NULL, 
	moa_start DATE NOT NULL, 
	moa_end DATE NOT NULL, 
	
	CONSTRAINT PRIMARY KEY (company_id)
	CONSTRAINT uq_companies_email UNIQUE (contact_email), 
	CONSTRAINT chk_companies_moa_dates CHECK (moa_end > moa_start)
);

CREATE TABLE requirements (
	requirement_id INT AUTO_INCREMENT, 
	requirement_name VARCHAR(150) NOT NULL, 
	req_description TEXT, 
	is_mandatory BOOLEAN NOT NULL DEFAULT FALSE, 
	
	CONSTRAINT PRIMARY KEY (requirement_id),
	CONSTRAINT uq_requirements_name UNIQUE (requirement_name)
);

CREATE TABLE progress_report (
	report_id INT, 
	placement_id INT NOT NULL, 
	report_date DATE DEFAULT (CURRENT_DATE), 
	hours_rendered DECIMAL NOT NULL, 
	activities TEXT NOT NULL, 
	
	CONSTRAINT PRIMARY KEY (report_id),
	CONSTRAINT chk_progress_report_hours CHECK (hours_rendered >= 0)
);