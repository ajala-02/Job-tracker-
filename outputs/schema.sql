-- Internship & Job Application Tracker
-- SQLite schema for CS50's Introduction to Databases with SQL final project.
-- Enable referential-integrity enforcement for every SQLite connection.
PRAGMA foreign_keys = ON;

-- One row per employer or university/programme provider.
CREATE TABLE companies (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    website TEXT,
    industry TEXT,
    headquarters_country TEXT,
    size TEXT CHECK (size IN ('startup', 'small', 'medium', 'large', 'enterprise'))
);

-- A person associated with a company. Email is unique when it is known.
CREATE TABLE contacts (
    id INTEGER PRIMARY KEY,
    company_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    role TEXT,
    email TEXT UNIQUE,
    linkedin_url TEXT,
    relationship TEXT,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

-- The central record for one role or programme application.
CREATE TABLE applications (
    id INTEGER PRIMARY KEY,
    company_id INTEGER NOT NULL,
    role_title TEXT NOT NULL,
    job_type TEXT NOT NULL CHECK (job_type IN ('internship', 'full-time', 'masters-program')),
    date_applied DATE NOT NULL DEFAULT CURRENT_DATE,
    source TEXT,
    status TEXT NOT NULL DEFAULT 'applied'
        CHECK (status IN ('applied', 'oa_received', 'interviewing', 'offer', 'rejected', 'withdrawn')),
    current_stage_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    UNIQUE (company_id, role_title, date_applied)
);

-- Links the people involved in an application without repeating contact data.
CREATE TABLE application_contacts (
    application_id INTEGER NOT NULL,
    contact_id INTEGER NOT NULL,
    PRIMARY KEY (application_id, contact_id),
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
);

-- One row for each interview or online-assessment round.
CREATE TABLE interviews (
    id INTEGER PRIMARY KEY,
    application_id INTEGER NOT NULL,
    round_number INTEGER NOT NULL CHECK (round_number > 0),
    interview_type TEXT NOT NULL
        CHECK (interview_type IN ('OA', 'phone_screen', 'technical', 'behavioral', 'system_design', 'final')),
    scheduled_date DATETIME NOT NULL,
    outcome TEXT NOT NULL DEFAULT 'pending' CHECK (outcome IN ('pending', 'passed', 'failed')),
    notes TEXT,
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    UNIQUE (application_id, round_number)
);

-- A canonical catalogue keeps a skill name in one place.
CREATE TABLE skills (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

-- Required or relevant skills for an application (many-to-many).
CREATE TABLE application_skills (
    application_id INTEGER NOT NULL,
    skill_id INTEGER NOT NULL,
    PRIMARY KEY (application_id, skill_id),
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
);

-- Documents are versioned per application and document type.
CREATE TABLE documents (
    id INTEGER PRIMARY KEY,
    application_id INTEGER NOT NULL,
    doc_type TEXT NOT NULL CHECK (doc_type IN ('resume', 'cover_letter', 'sop')),
    version_label TEXT NOT NULL,
    file_link TEXT NOT NULL,
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE,
    UNIQUE (application_id, doc_type, version_label)
);

-- Immutable status-transition audit trail. Changes are created by the trigger below.
CREATE TABLE status_history (
    id INTEGER PRIMARY KEY,
    application_id INTEGER NOT NULL,
    old_status TEXT NOT NULL
        CHECK (old_status IN ('applied', 'oa_received', 'interviewing', 'offer', 'rejected', 'withdrawn')),
    new_status TEXT NOT NULL
        CHECK (new_status IN ('applied', 'oa_received', 'interviewing', 'offer', 'rejected', 'withdrawn')),
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE
);

-- Dashboard queries commonly filter applications by their current status.
CREATE INDEX idx_applications_status ON applications(status);

-- Company detail pages and employer-level summaries look up applications by company.
CREATE INDEX idx_applications_company_id ON applications(company_id);

-- Application detail pages retrieve all interview rounds for one application.
CREATE INDEX idx_interviews_application_id ON interviews(application_id);

-- Flags active applications whose current stage has been unchanged for at least 14 days.
CREATE VIEW stale_applications AS
SELECT
    a.id,
    c.name AS company_name,
    a.role_title,
    a.job_type,
    a.status,
    a.date_applied,
    a.current_stage_updated_at,
    CAST(julianday('now') - julianday(a.current_stage_updated_at) AS INTEGER) AS days_since_status_update
FROM applications AS a
JOIN companies AS c ON c.id = a.company_id
WHERE a.status NOT IN ('offer', 'rejected', 'withdrawn')
  AND a.current_stage_updated_at <= datetime('now', '-14 days');

-- Summarizes completed interview outcomes by type; pending rounds do not affect the rate.
CREATE VIEW interview_pass_rates AS
SELECT
    interview_type,
    COUNT(*) AS completed_interviews,
    SUM(CASE WHEN outcome = 'passed' THEN 1 ELSE 0 END) AS passed_interviews,
    ROUND(
        100.0 * SUM(CASE WHEN outcome = 'passed' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS pass_percentage
FROM interviews
WHERE outcome IN ('passed', 'failed')
GROUP BY interview_type;

-- Records every real status transition and refreshes the application's stage timestamp.
CREATE TRIGGER log_status_change
AFTER UPDATE OF status ON applications
WHEN OLD.status != NEW.status
BEGIN
    UPDATE applications
    SET current_stage_updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.id;

    INSERT INTO status_history (application_id, old_status, new_status)
    VALUES (NEW.id, OLD.status, NEW.status);
END;
