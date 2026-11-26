# PUP InternLINK Database Overview

A short guide to what the database has, what it does, and how it connects to our system screens.

File: `pup_ilink_db_completed_table_ver5.sql` (MySQL 8, **15 tables**)

---

## 1. What the database is for

It is the place where the system saves everything about student internships:

- **Who** uses the system (students, faculty, company people)
- **What** internships are offered, and by which company
- **Who applied**, who was accepted, and who supervises them
- **How the internship went**: requirements, progress reports, hours, evaluations and certificate

The Python system reads from and writes to these tables. The database also protects the data with rules, so wrong data (like a duplicate application) is refused.

---

## 2. The 15 tables in 5 groups

| Group | Tables | In simple words |
| --- | --- | --- |
| School structure | `colleges`, `departments`, `programs` | The list of PUP colleges, departments and degree programs. Comes with starter data. |
| People | `users`, `students`, `faculties`, `company_supervisors` | `users` is the login for everyone. The other three add details for each role. |
| Companies and postings | `companies`, `internship_opportunities` | Partner companies (with MOA dates) and the internships they post. |
| The internship process | `applications`, `internship_placements`, `progress_reports`, `evaluations` | Apply, get accepted, work and report hours, then get evaluated. |
| Requirements | `requirements`, `student_submissions` | The documents students must submit, and the files they uploaded. |

### How the tables connect

```
colleges -> departments -> programs -> students
users -> students / faculties / company_supervisors

companies -> company_supervisors
companies -> internship_opportunities -> applications -> internship_placements
                                                         |-> progress_reports
                                                         |-> evaluations
requirements -> student_submissions <- students
```

Each arrow means "one row points to another row". For example, an application points to one student and one posting. This is how the database knows who applied to what.

### The 4 user roles (`users.user_role`)

| Role | Who | Saved in |
| --- | --- | --- |
| `student` | Intern | `students` |
| `faculty` | OJT coordinator (`is_coordinator = 1`) or adviser (`is_coordinator = 0`) | `faculties` |
| `company` | Company supervisor (like HR) | `company_supervisors` |
| `supervisor` | Intern supervisor | `company_supervisors` |

---

## 3. How it connects to our system screens

| Screen in the interface document | Tables it uses |
| --- | --- |
| **Login and account management** (pre-registration, activation, forgot password, account settings) | `users`, `students` |
| **Student: Internship Opportunities** | `internship_opportunities`, `companies` |
| **Student: My Profile** | `students`, `users`, `faculties` (adviser) |
| **Student: Internship Requirements** | `requirements`, `student_submissions` |
| **Student: My Applications** | `applications` |
| **Student: My Placement, Progress, Evaluation** | `internship_placements`, `progress_reports`, `evaluations` |
| **OJT Coordinator: approve postings, manage companies, assign advisers** | `internship_opportunities`, `companies`, `faculties`, `students.adviser_id` |
| **Adviser: assigned students, review requirements, monitor progress, confirm completion** | `students`, `student_submissions`, `progress_reports`, `internship_placements` |
| **Company Supervisor: company profile, postings, decide on applications, create intern supervisors, assign interns** | `companies`, `internship_opportunities`, `applications`, `users`, `company_supervisors`, `internship_placements` |
| **Intern Supervisor: monitor interns, approve reports, evaluate** | `internship_placements`, `progress_reports`, `evaluations` |

---

## 4. How it satisfies our system requirements

| Requirement | How the database handles it |
| --- | --- |
| Pre-register a student with only student number and email | Name, program, year and section can be empty at first. Account status starts as `pending`. |
| Default password, and the user must set up the account first | `must_change_password` flag. Account becomes `active` after setup. |
| Deactivate accounts without losing history | `account_status = 'inactive'` and `companies.is_active = 0` (soft delete). Rows that are still used cannot be deleted. |
| Company supervisor and intern supervisor are different | Two roles: `company` and `supervisor`. |
| Coordinator assigns students to advisers | `students.adviser_id`. |
| Postings with location, modality, required hours, qualifications, skills, responsibilities | Columns on `internship_opportunities`. |
| Filter postings by program | `target_programs` list on each posting. |
| Posting approval steps (company, then coordinator, with remarks) | `opp_status`, `reviewed_by`, `review_remarks`. |
| Student sees only open postings with slots left, and not ones already applied to | Sample query 1 in the SQL file. |
| Cannot apply twice to the same posting | Unique rule on `applications`. |
| Company decides on applications | `decided_by`, `decision_remarks` on `applications`. |
| Requirements: before / during / after, mandatory or optional | `phase` and `is_mandatory` on `requirements`. |
| Resubmit a rejected document | Update the same `student_submissions` row and set it back to `pending`. |
| Progress reports with approval and remarks | `report_status`, `supervisor_remarks`, `reviewed_by`. |
| Daily attendance records and weekly reports | `report_type` is `daily` or `weekly`. A daily record holds the hours (above 0, up to 24). A weekly report is a summary dated on a Monday and has no hours, so hours are never counted twice. One of each per date. |
| Year level 1 to 4 only | A rule on `students.year_level`. |
| Hours rendered, approved, remaining, completion % | Calculated by a query (sample query 2) from the daily records, so they are never out of date. |
| "Ready for completion", then confirmation | Sample query 5 finds them. `confirmed_by` is required before a placement is `completed`. |
| Evaluation by supervisor (and optionally adviser) | `evaluations.evaluation_type`. One of each type per placement. |
| MOA "expiring soon" | Sample query 3 (`moa_end` within 30 days). |
| List of students with no application yet | Sample query 4. |

---

## 5. What the database does NOT do (the Python code must)

Some rules are actions or checks that a database cannot do alone:

- Block applying until all mandatory "before" requirements are accepted
- Accept reports only while the placement is active and the date is within the placement dates, never for future dates
- Lock approved or rejected reports, and lock evaluations after submitting
- Show grades to the student only after the placement is completed
- Send email reminders (students without a weekly report this week, supervisors with pending reports)
- Warn before deactivating an intern supervisor who still has active interns
- Check that the intern supervisor belongs to the same company as the posting
- Hash passwords and tokens (never save plain text)

The full list is in the `README.md`.

---

## 6. Open questions for the team

1. **Hours come only from daily records.** Weekly reports are summaries and have no hours. If your team wants the hours inside the weekly report instead, tell me and the rule can be changed.
2. **Does the adviser also evaluate students?** The database supports it (`adviser` type). If not, use only the `company` type.
3. **Program targeting:** it is a list column to keep 15 tables. A separate table would be cleaner, but makes 16.
