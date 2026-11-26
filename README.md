# PUP InternLINK Database Management System

A database and Python project that keeps track of student internships at PUP: who the students, faculty and company people are, which internships are offered, who applied, and how each internship went.

---

## What you need before starting

| Tool | Version | Why |
| --- | --- | --- |
| Python | 3.10 or newer | Runs the project code |
| MySQL Server | **8.0.16 or newer** | Stores the data (older versions ignore some of the rules in the SQL file) |
| HeidiSQL or MySQL Workbench | Any | Optional. Makes it easier to run the SQL file and look at tables |

---

## Step 1: Set up Python

Open a terminal inside the project folder, then follow these steps.

**1. Create a virtual environment** (a private box for this project's packages):

```
python -m venv .venv
```

**2. Turn it on:**

- Windows (Command Prompt): `.venv\Scripts\activate`
- Windows (PowerShell): `.venv\Scripts\Activate.ps1`
- Linux / macOS: `source .venv/bin/activate`

When it works, you will see `(.venv)` at the start of your terminal line.

**3. Install the packages:**

```
pip install -r requirements.txt
```

> Tip: Every time you open a new terminal, do step 2 again before running the project.

---

## Step 2: Set up the database

The file `pup_ilink_db_completed_table_ver5.sql` creates the whole database (`pup_ilink_db`), all 15 tables, and some starter data (colleges, departments, programs, and sample requirements).

Choose **one** way to run it:

**Option A: HeidiSQL**
1. Connect to your MySQL server.
2. Go to **File → Load SQL file** and pick `pup_ilink_db_completed_table_ver5.sql`.
3. Click the blue **Run** (play) button.

**Option B: MySQL Workbench**
1. Connect to your server.
2. Go to **File → Open SQL Script** and pick the file.
3. Click the lightning bolt button to run it.

**Option C: Command line**

```
mysql -u root -p < pup_ilink_db_completed_table_ver5.sql
```

### Check that it worked

Run this in your SQL tool:

```sql
USE pup_ilink_db;
SHOW TABLES;
```

You should see **15 tables**.

### Test it

Open `test_ver5.sql` and run it. It adds fake test data, shows results to compare with the expected values, and has 16 bad-data tests that should each be refused. The steps are at the top of that file.

### Already have an older version (ver1 to ver4)?

The new file will **not** change tables that already exist (it only creates what is missing). Start fresh:

1. Open the SQL file.
2. Remove the `--` in front of the `DROP DATABASE` line near the top.
3. Run the file.

**Warning: this deletes all data in `pup_ilink_db`.**

If your Python code was written for an older version, update these names and columns:

| Old | New |
| --- | --- |
| table `student_submissons` | `student_submissions` |
| table `progress_report` | `progress_reports` |
| `internship_opportunities.approved_by` | `reviewed_by` |
| `evaluations.evaluator_id` (faculty number) | now a `user_id` (a number) |
| `student_no` (12 characters) | now up to 15 characters |
| `progress_reports` (no type) | now has `report_type` (`daily` or `weekly`). `hours_rendered` is empty for weekly reports |

---

## Step 3: Tell the code how to connect to the database

Create a file named `.env` in the project folder. Use `.env.example` below as a guide:

```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password_here
DB_NAME=pup_ilink_db
```

Important:
- Do **not** upload `.env` to GitHub. It has your password. Add `.env` to your `.gitignore` file.
- Instead, upload a copy named `.env.example` with a fake password, so teammates know what to fill in.
- The variable names must match the ones your Python code reads. Change them here if your code uses different names.

---

## Step 4: Run the project

With the virtual environment on and MySQL running:

```
python your_main_file.py
```

Replace `your_main_file.py` with the real name of your main Python file. (Add the exact file name here once you decide it, so everyone knows what to run.)

---

## Who uses the system (the 4 roles in `users.user_role`)

| Role | Who | Main jobs |
| --- | --- | --- |
| `student` | Intern | Set up account, upload requirements, apply, send progress reports |
| `faculty` | OJT coordinator (`is_coordinator = 1`) or adviser (`is_coordinator = 0`) | Coordinator: approves postings and companies, assigns advisers. Adviser: pre-registers students, checks requirements, confirms completion |
| `company` | Company supervisor (like HR) | Edits company profile, creates postings, accepts or rejects applications, creates intern supervisor accounts, assigns interns |
| `supervisor` | Intern supervisor | Watches assigned interns, approves progress reports, evaluates interns |

Both `company` and `supervisor` people are saved in the `company_supervisors` table. The `user_role` tells which kind they are.

---

## What is inside the database (15 tables)

### School structure
| Table | What it stores |
| --- | --- |
| `colleges` | PUP colleges (e.g. CCIS, CE) |
| `departments` | Departments inside each college |
| `programs` | Degree programs inside each department (e.g. BSIT) |

### People
| Table | What it stores |
| --- | --- |
| `users` | Login info for everyone (email, password hash, role, account status) |
| `students` | Student number, adviser, program, year level, section, contact number |
| `faculties` | Faculty number, department, coordinator or not |
| `company_supervisors` | Company supervisors and intern supervisors (company, position, department) |

### Companies and postings
| Table | What it stores |
| --- | --- |
| `companies` | Partner companies, contact info, MOA dates, active or archived |
| `internship_opportunities` | Postings: details, slots, hours, location, modality, target programs, approval status |

### The internship process
| Table | What it stores |
| --- | --- |
| `applications` | A student applying to a posting, and the company's decision |
| `internship_placements` | An accepted student: adviser, intern supervisor, dates, hours, confirmation, certificate |
| `progress_reports` | Daily attendance records (with hours) and weekly reports (a summary), with the supervisor's approval |
| `evaluations` | Scores and comments (by the intern supervisor, and optionally the adviser) |

### Requirements
| Table | What it stores |
| --- | --- |
| `requirements` | Documents students must submit (before, during or after the internship; mandatory or optional) |
| `student_submissions` | The files students uploaded, and whether they were accepted |

---

## How things flow

**Account setup**
1. The adviser pre-registers a student with only the **student number and email**. The system gives a default password. The account is `pending`.
2. The student logs in and must set up the account first (new password, name, program, year level, section, contact number). Then the account becomes `active` and `must_change_password` becomes `0`.
3. We never delete accounts. A deactivated account becomes `inactive`.

**Posting steps** (`opp_status`)

`pending_company` → `pending_coordinator` → `approved` → `active` → `filled` or `deactivated`

The coordinator can also set `rejected` (with `review_remarks`).

**Internship steps**
1. The student finishes the mandatory "before" requirements.
2. The student applies to an active posting.
3. The company supervisor accepts or rejects the application.
4. A placement is created with an adviser and an intern supervisor.
5. The student sends daily records (hours worked) and a weekly report. The intern supervisor approves or rejects them.
6. When the approved hours reach the required hours, the screen shows "ready for completion". The coordinator or adviser confirms, and the placement becomes `completed`.
7. The evaluation is saved and the certificate is issued.

---

## Rules the database checks for you

- Emails must be unique and look like real emails.
- Only users with the matching role can go into `students`, `faculties` and `company_supervisors` (`company_supervisors` accepts `company` and `supervisor`).
- An `active` account must have a first name and last name.
- Year level is 1 to 4. Contact number is exactly 11 digits.
- A student can apply to the same posting only once.
- An `accepted` or `rejected` application must say who decided.
- A posting that is `approved`, `active`, `filled` or `rejected` must have a reviewer.
- A company's MOA end date must be after its start date.
- A placement's end date is not before its start date, and required hours are more than 0.
- A `completed` placement must have someone who confirmed it.
- A certificate number is unique, and the number and date are filled together.
- A report is either `daily` or `weekly` (`report_type`).
  - A **daily** record must have hours (more than 0, at most 24).
  - A **weekly** report has no hours (it is a summary) and must be dated on a Monday.
  - A placement can have only one daily record per day and one weekly report per week.
  - Hours come only from daily records, so they are never counted twice.
- An `approved` or `rejected` report must say who reviewed it.
- A placement gets at most one `company` evaluation and one `adviser` evaluation. Scores are 1 to 100.
- A student has one submission per requirement.
- Rows that other rows still use cannot be deleted (so we use soft delete).

## Rules your Python code must handle

The database cannot check these. Your code must:

**Students and postings**
- Do not let a student apply until all mandatory `before` requirements are `accepted`.
- Show only postings that are `active`, have slots left, match the student's program (`target_programs`), and that the student has not applied to. (Sample query 1 in the SQL file does this.)
- Slots left = `slots` minus the number of `accepted` applications. A rejected or withdrawn application gives the slot back automatically. The student can apply to other postings, but not to the same posting again.
- Check that the program codes saved in `target_programs` are real.

**Progress reports**
- Accept a report only if the placement is `active`, the date is between the start and end date, and the date is not in the future.
- Lock a report after it is approved or rejected. A student can edit only a rejected report (then set it back to `pending`).
- Work out hours rendered, approved hours, remaining hours and completion percent with a query (sample query 2). Only daily records count as hours, and only `approved` daily records count as approved hours.
- Let the supervisor approve a whole week of daily records at once.
- Send email reminders: students with no weekly report this week (sample query 6), and supervisors with pending reports.

**Placements and evaluations**
- The intern supervisor of a placement must work for the same company as the posting.
- Show "ready for completion" when approved hours reach the required hours (sample query 5).
- Lock an evaluation after it is submitted, and show the grade to the student only after the placement is `completed`.
- Warn before deactivating an intern supervisor who still has active interns.

**Dashboards**
- "Expiring soon" MOAs (sample query 3) and students with no application yet (sample query 4).

**Accounts**
- Never save plain passwords. Save only a hash (for example with `bcrypt`).
- Save only a hash of invitation and reset tokens, and check `token_expires_at`.

---

## Try some queries

At the bottom of the SQL file there are six sample queries (commented out). Remove the `-- ` in front of one to try it.

---

## Common problems

| Problem | What to try |
| --- | --- |
| `Can't connect to MySQL server` | Make sure MySQL is running and the host, port, user and password in `.env` are correct. |
| `Unknown database 'pup_ilink_db'` | Run the SQL file first (Step 2). |
| `Cannot add or update a child row: a foreign key constraint fails` | You are adding a row that points to something that does not exist yet. Add the parent row first (for example, the user before the student). |
| `Check constraint ... is violated` | A value breaks a rule listed above (for example, 25 hours in one report). |
| `Duplicate entry` | The row already exists (for example, the student already applied to that posting). |
| `ModuleNotFoundError` in Python | Turn on the virtual environment (Step 1) and run `pip install -r requirements.txt` again. |
| `activate` is not recognized on Windows | Use `.venv\Scripts\activate` (it is `Scripts` with an **s**, with backslashes). |

---

## Ideas for later

- A table that links postings to the programs allowed to apply (this would make 16 tables, but gives a proper list instead of the `target_programs` list).
- A history table that records who approved or rejected something, and when.
- An ER diagram of the database (HeidiSQL and MySQL Workbench can create one from the SQL file).
