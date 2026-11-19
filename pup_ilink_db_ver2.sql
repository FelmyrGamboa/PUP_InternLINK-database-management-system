-- --------------------------------------------------------
-- Host:                         localhost
-- Server version:               8.0.46 - MySQL Community Server - GPL
-- Server OS:                    Win64
-- HeidiSQL Version:             12.20.0.7320
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Dumping database structure for pup_ilink_db
CREATE DATABASE IF NOT EXISTS `pup_ilink_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `pup_ilink_db`;

-- Dumping structure for table pup_ilink_db.colleges
CREATE TABLE IF NOT EXISTS `colleges` (
  `college_code` char(10) COLLATE utf8mb4_general_ci NOT NULL,
  `college_name` varchar(150) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`college_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table pup_ilink_db.colleges: ~14 rows (approximately)
INSERT INTO `colleges` (`college_code`, `college_name`) VALUES
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

-- Dumping structure for table pup_ilink_db.companies
CREATE TABLE IF NOT EXISTS `companies` (
  `company_id` int NOT NULL AUTO_INCREMENT,
  `company_name` varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  `address` varchar(200) COLLATE utf8mb4_general_ci NOT NULL,
  `contact_email` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `moa_start` date NOT NULL,
  `moa_end` date NOT NULL,
  PRIMARY KEY (`company_id`),
  UNIQUE KEY `uq_companies_email` (`contact_email`),
  CONSTRAINT `chk_companies_moa_dates` CHECK ((`moa_end` > `moa_start`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table pup_ilink_db.companies: ~0 rows (approximately)

-- Dumping structure for table pup_ilink_db.company_supervisors
CREATE TABLE IF NOT EXISTS `company_supervisors` (
  `supervisor_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `company_id` int NOT NULL,
  `first_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `company_position` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `company_department` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`supervisor_id`),
  UNIQUE KEY `uq_company_supervisors_user_id` (`user_id`),
  KEY `fk_supervisors_companies` (`company_id`),
  CONSTRAINT `fk_company_supervisors_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `fk_supervisors_companies` FOREIGN KEY (`company_id`) REFERENCES `companies` (`company_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table pup_ilink_db.company_supervisors: ~0 rows (approximately)

-- Dumping structure for table pup_ilink_db.departments
CREATE TABLE IF NOT EXISTS `departments` (
  `department_code` char(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `department_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `college_code` char(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`department_code`),
  KEY `fk_department_college` (`college_code`) USING BTREE,
  CONSTRAINT `fk_department_college` FOREIGN KEY (`college_code`) REFERENCES `colleges` (`college_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table pup_ilink_db.departments: ~54 rows (approximately)
INSERT INTO `departments` (`department_code`, `department_name`, `college_code`) VALUES
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

-- Dumping structure for table pup_ilink_db.faculties
CREATE TABLE IF NOT EXISTS `faculties` (
  `faculty_no` char(12) COLLATE utf8mb4_general_ci NOT NULL,
  `user_id` int NOT NULL,
  `department_code` char(10) COLLATE utf8mb4_general_ci NOT NULL,
  `is_coordinator` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`faculty_no`),
  UNIQUE KEY `uq_faculty_user_id` (`user_id`),
  KEY `fk_faculty_departments` (`department_code`),
  CONSTRAINT `fk_faculty_departments` FOREIGN KEY (`department_code`) REFERENCES `departments` (`department_code`),
  CONSTRAINT `fk_faculty_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table pup_ilink_db.faculties: ~0 rows (approximately)

-- Dumping structure for table pup_ilink_db.programs
CREATE TABLE IF NOT EXISTS `programs` (
  `program_code` char(10) COLLATE utf8mb4_general_ci NOT NULL,
  `program_name` varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  `department_code` char(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`program_code`),
  KEY `fk_department_code` (`department_code`),
  CONSTRAINT `fk_department_code` FOREIGN KEY (`department_code`) REFERENCES `departments` (`department_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table pup_ilink_db.programs: ~57 rows (approximately)
INSERT INTO `programs` (`program_code`, `program_name`, `department_code`) VALUES
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

-- Dumping structure for table pup_ilink_db.progress_report
CREATE TABLE IF NOT EXISTS `progress_report` (
  `report_id` int NOT NULL,
  `placement_id` int NOT NULL,
  `report_date` date DEFAULT (curdate()),
  `hours_rendered` decimal(10,0) NOT NULL,
  `activities` text COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`report_id`),
  CONSTRAINT `chk_progress_report_hours` CHECK ((`hours_rendered` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table pup_ilink_db.progress_report: ~0 rows (approximately)

-- Dumping structure for table pup_ilink_db.requirements
CREATE TABLE IF NOT EXISTS `requirements` (
  `requirement_id` int NOT NULL AUTO_INCREMENT,
  `requirement_name` varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  `req_description` text COLLATE utf8mb4_general_ci,
  `is_mandatory` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`requirement_id`),
  UNIQUE KEY `uq_requirements_name` (`requirement_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table pup_ilink_db.requirements: ~0 rows (approximately)

-- Dumping structure for table pup_ilink_db.students
CREATE TABLE IF NOT EXISTS `students` (
  `student_no` char(12) COLLATE utf8mb4_general_ci NOT NULL,
  `user_id` int NOT NULL,
  `program_code` char(10) COLLATE utf8mb4_general_ci NOT NULL,
  `year_level` int NOT NULL,
  `section` varchar(10) COLLATE utf8mb4_general_ci NOT NULL,
  `contact_no` char(11) COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`student_no`),
  UNIQUE KEY `uq_students_user_id` (`user_id`),
  KEY `fk_students_programs` (`program_code`),
  CONSTRAINT `fk_students_programs` FOREIGN KEY (`program_code`) REFERENCES `programs` (`program_code`),
  CONSTRAINT `fk_students_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table pup_ilink_db.students: ~0 rows (approximately)

-- Dumping structure for table pup_ilink_db.users
CREATE TABLE IF NOT EXISTS `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `first_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `user_role` enum('student','faculty','supervisor') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'student',
  `account_status` enum('active','inactive','suspended') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uq_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table pup_ilink_db.users: ~0 rows (approximately)

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
