# 💼 Job Tracker

<h1 align="center">📊 JOB TRACKER</h1>

<h3 align="center">One Database. Every Application. Complete Control.</h3>

<p align="center">
  A structured SQLite database to manage your internship applications, full-time opportunities, and postgraduate applications — from the first application to the final outcome.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/SQL-Database-4479A1?style=for-the-badge&logo=mysql&logoColor=white">
  <img src="https://img.shields.io/badge/SQLite-Powered-003B57?style=for-the-badge&logo=sqlite&logoColor=white">
  <img src="https://img.shields.io/badge/CS50-Final%20Project-9B1C1C?style=for-the-badge">
  <img src="https://img.shields.io/badge/Status-Completed-2EA44F?style=for-the-badge">
</p>

---

## ✨ About the Project

Searching for internships, full-time roles, or postgraduate programmes involves keeping track of multiple applications, deadlines, contacts, interviews, and outcomes.

**Job Tracker** brings all of this information into one organized relational database.

Built using **SQLite** as the final project for **CS50's Introduction to Databases with SQL**, this project focuses on structured data management, relational database design, automation through triggers, and meaningful SQL queries.

The database is tailored to a final-year ECE student applying to jobs and postgraduate programmes in Ireland, but its normalized design works for any personal application search.

<p align="center">
  <img src="images/application-lifecycle.png" alt="Application Lifecycle" width="90%">
</p>

<p align="center">
  <em>From discovering an opportunity to tracking its final outcome.</em>
</p>

---

## 🚀 Features

<table>
  <tr>
    <td width="50%">
      <h3>🏢 Application Management</h3>
      Track companies or universities, roles/programmes, application sources, and current status.
    </td>
    <td width="50%">
      <h3>👥 Contact Management</h3>
      Store recruiters, alumni, hiring managers, and admissions contacts.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>🔗 Relationship Mapping</h3>
      Link applications to required skills and relevant contacts through many-to-many junction tables.
    </td>
    <td width="50%">
      <h3>🎯 Interview Tracking</h3>
      Record interview rounds, dates, notes, and outcomes.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>📄 Document Management</h3>
      Store links to versioned resumes, cover letters, and statements of purpose.
    </td>
    <td width="50%">
      <h3>⚡ Automated Status Auditing</h3>
      Automatically audit every genuine application-status change with a SQLite trigger.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>⏰ Follow-up Monitoring</h3>
      Find active applications needing follow-up after 14 days.
    </td>
    <td width="50%">
      <h3>📈 Interview Analytics</h3>
      Compare pass rates for completed interview types.
    </td>
  </tr>
</table>

---

## 🗄️ Database Architecture

`applications` is the central table. Supporting tables avoid repeated data: a skill or contact can be associated with many applications, while each interview, document, and audit record belongs to one application.

<p align="center">
  <img src="images/database-architecture.png" alt="Database Architecture" width="100%">
</p>

---

## 📁 Project Structure

```text
.
├── README.md
├── images/
│   ├── application-lifecycle.png
│   └── database-architecture.png
└── outputs/
    ├── DESIGN.md       # Technical design and project limitations
    ├── schema.sql      # Tables, constraints, views, indexes, and trigger
    ├── seed.sql        # Realistic demo data
    └── queries.sql     # Annotated example SQL queries
```

---

## ⚙️ Getting Started

### Prerequisite

[SQLite](https://www.sqlite.org/)

### 1. Clone the repository

```bash
git clone https://github.com/ajala-02/job-application-tracker.git
cd job-application-tracker/outputs
sqlite3 tracker.db
```

### 2. Set up the database

At the `sqlite>` prompt, create the schema and load the sample records:

```sql
.read schema.sql
.read seed.sql
.headers on
.mode column
```

### 3. Try the reporting views

```sql
SELECT * FROM stale_applications;
SELECT * FROM interview_pass_rates;
```

---

## 🔍 Key Implementation Details

### 1. Status Audit Trigger

`log_status_change` runs after a real change to `applications.status`. It refreshes `current_stage_updated_at` and writes the old status, new status, and timestamp to `status_history`.

```sql
UPDATE applications
SET status = 'interviewing'
WHERE role_title = 'Graduate Software Engineer';

SELECT * FROM status_history ORDER BY id DESC LIMIT 3;
```

### 2. Views

- `stale_applications` lists non-closed applications with no status update in 14 or more days.
- `interview_pass_rates` reports the pass percentage for each completed interview type, excluding pending interviews.

### 3. Indexes

The project indexes `applications(status)`, `applications(company_id)`, and `interviews(application_id)` because dashboards and application-detail pages commonly filter on those columns.

---

## 🔮 Limitations & Future Work

This is a single-user local SQLite application. It does not currently support accounts, shared editing, salary or compensation tracking, negotiation workflows, reminders, or document-file storage.

Possible future extensions include an offer table, deadline reminders, and a web dashboard.

---

<h2 align="center">👩‍💻 Author</h2>

<p align="center">
  <strong>Ajala Nalawade</strong>
  <br>
  <em>Built with SQL and SQLite as a CS50 final project.</em>
</p>
