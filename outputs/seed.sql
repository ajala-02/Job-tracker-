-- Demo data for the Internship & Job Application Tracker.
-- Run this after schema.sql in a new database. The INSERT OR IGNORE statements
-- make the reference data safe to load again, but this is designed for a demo database.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- Employers and Irish universities/programme providers.
INSERT OR IGNORE INTO companies (name, website, industry, headquarters_country, size) VALUES
    ('Analog Devices', 'https://www.analog.com', 'Semiconductors', 'United States', 'enterprise'),
    ('Intel Ireland', 'https://www.intel.ie', 'Semiconductors', 'Ireland', 'enterprise'),
    ('Siemens Digital Industries Software', 'https://www.sw.siemens.com', 'Software', 'Germany', 'enterprise'),
    ('Dell Technologies', 'https://www.dell.com', 'Technology', 'United States', 'enterprise'),
    ('Johnson Controls', 'https://www.johnsoncontrols.com', 'Building Technology', 'Ireland', 'large'),
    ('University College Dublin', 'https://www.ucd.ie', 'Higher Education', 'Ireland', 'large'),
    ('Trinity College Dublin', 'https://www.tcd.ie', 'Higher Education', 'Ireland', 'large'),
    ('Qualcomm', 'https://www.qualcomm.com', 'Semiconductors', 'United States', 'enterprise');

-- Recruiters, alumni, and programme contacts.
INSERT OR IGNORE INTO contacts (company_id, name, role, email, linkedin_url, relationship) VALUES
    ((SELECT id FROM companies WHERE name = 'Analog Devices'), 'Aisling Murphy', 'University Recruiter', 'aisling.murphy@example.com', 'https://linkedin.com/in/aisling-murphy-demo', 'Recruiter'),
    ((SELECT id FROM companies WHERE name = 'Intel Ireland'), 'Conor Byrne', 'Talent Acquisition Partner', 'conor.byrne@example.com', 'https://linkedin.com/in/conor-byrne-demo', 'Recruiter'),
    ((SELECT id FROM companies WHERE name = 'Siemens Digital Industries Software'), 'Riya Shah', 'Embedded Software Engineer', 'riya.shah@example.com', 'https://linkedin.com/in/riya-shah-demo', 'Alumnus'),
    ((SELECT id FROM companies WHERE name = 'Dell Technologies'), 'Niamh Kelly', 'Graduate Recruitment Lead', 'niamh.kelly@example.com', 'https://linkedin.com/in/niamh-kelly-demo', 'Recruiter'),
    ((SELECT id FROM companies WHERE name = 'Johnson Controls'), 'Eoin Walsh', 'Engineering Manager', 'eoin.walsh@example.com', 'https://linkedin.com/in/eoin-walsh-demo', 'Referral'),
    ((SELECT id FROM companies WHERE name = 'University College Dublin'), 'Dr. Maeve O''Brien', 'Admissions Officer', 'maeve.obrien@example.com', 'https://linkedin.com/in/maeve-obrien-demo', 'Admissions contact'),
    ((SELECT id FROM companies WHERE name = 'Trinity College Dublin'), 'Prof. Sean Doyle', 'Programme Director', 'sean.doyle@example.com', 'https://linkedin.com/in/sean-doyle-demo', 'Faculty contact'),
    ((SELECT id FROM companies WHERE name = 'Qualcomm'), 'Priya Nair', 'Campus Recruiter', 'priya.nair@example.com', 'https://linkedin.com/in/priya-nair-demo', 'Recruiter');

-- Reusable skill catalogue.
INSERT OR IGNORE INTO skills (name) VALUES
    ('C'), ('C++'), ('Python'), ('SQL'), ('Embedded Systems'), ('Linux'),
    ('Digital Signal Processing'), ('Verilog'), ('Machine Learning'), ('Git'),
    ('Data Structures and Algorithms'), ('System Design'), ('Technical Writing');

-- All rows start as applied. The status updates below intentionally demonstrate
-- log_status_change and produce a useful audit trail.
INSERT OR IGNORE INTO applications (company_id, role_title, job_type, date_applied, source, status) VALUES
    ((SELECT id FROM companies WHERE name = 'Analog Devices'), 'Embedded Systems Intern', 'internship', '2026-09-20', 'University careers portal', 'applied'),
    ((SELECT id FROM companies WHERE name = 'Intel Ireland'), 'Graduate Software Engineer', 'full-time', '2026-09-25', 'LinkedIn', 'applied'),
    ((SELECT id FROM companies WHERE name = 'Siemens Digital Industries Software'), 'Software Engineering Intern', 'internship', '2026-10-01', 'Employee referral', 'applied'),
    ((SELECT id FROM companies WHERE name = 'Dell Technologies'), 'Associate Systems Engineer', 'full-time', '2026-10-03', 'Company careers page', 'applied'),
    ((SELECT id FROM companies WHERE name = 'Johnson Controls'), 'Firmware Engineering Intern', 'internship', '2026-10-05', 'Handshake', 'applied'),
    ((SELECT id FROM companies WHERE name = 'University College Dublin'), 'MSc Computer Science', 'masters-program', '2026-10-07', 'University application portal', 'applied'),
    ((SELECT id FROM companies WHERE name = 'Trinity College Dublin'), 'MSc Interactive Digital Media', 'masters-program', '2026-10-09', 'University application portal', 'applied'),
    ((SELECT id FROM companies WHERE name = 'Qualcomm'), '5G Modem Software Intern', 'internship', '2026-10-10', 'LinkedIn', 'applied'),
    ((SELECT id FROM companies WHERE name = 'Analog Devices'), 'Graduate Applications Engineer', 'full-time', '2026-10-12', 'Company careers page', 'applied'),
    ((SELECT id FROM companies WHERE name = 'Intel Ireland'), 'FPGA Design Intern', 'internship', '2026-10-14', 'University careers portal', 'applied'),
    ((SELECT id FROM companies WHERE name = 'Dell Technologies'), 'Data Analyst Graduate Programme', 'full-time', '2026-10-16', 'LinkedIn', 'applied'),
    ((SELECT id FROM companies WHERE name = 'Johnson Controls'), 'Controls Systems Graduate Engineer', 'full-time', '2026-10-18', 'Company careers page', 'applied');

-- Status transitions: each statement fires the audit trigger when a real change occurs.
UPDATE applications SET status = 'oa_received' WHERE role_title = 'Embedded Systems Intern';
UPDATE applications SET status = 'interviewing' WHERE role_title = 'Embedded Systems Intern';
UPDATE applications SET status = 'oa_received' WHERE role_title = 'Graduate Software Engineer';
UPDATE applications SET status = 'interviewing' WHERE role_title = 'Software Engineering Intern';
UPDATE applications SET status = 'interviewing' WHERE role_title = 'Firmware Engineering Intern';
UPDATE applications SET status = 'offer' WHERE role_title = 'MSc Computer Science';
UPDATE applications SET status = 'rejected' WHERE role_title = 'MSc Interactive Digital Media';
UPDATE applications SET status = 'oa_received' WHERE role_title = '5G Modem Software Intern';
UPDATE applications SET status = 'withdrawn' WHERE role_title = 'FPGA Design Intern';
UPDATE applications SET status = 'interviewing' WHERE role_title = 'Controls Systems Graduate Engineer';

-- Make active records old enough to appear in stale_applications for the demo.
UPDATE applications
SET current_stage_updated_at = datetime('now', '-21 days')
WHERE role_title IN ('Graduate Software Engineer', 'Associate Systems Engineer', '5G Modem Software Intern');

-- Attach the relevant contact to each application.
INSERT OR IGNORE INTO application_contacts (application_id, contact_id)
SELECT a.id, c.id
FROM applications AS a
JOIN companies AS co ON co.id = a.company_id
JOIN contacts AS c ON c.company_id = co.id;

-- Associate selected skills with applications. This makes it easy to extend the
-- example with queries such as "all roles that need C++".
INSERT OR IGNORE INTO application_skills (application_id, skill_id)
SELECT a.id, s.id
FROM applications AS a
JOIN skills AS s
WHERE (a.role_title IN ('Embedded Systems Intern', 'Firmware Engineering Intern', '5G Modem Software Intern')
       AND s.name IN ('C', 'C++', 'Embedded Systems', 'Linux', 'Git'))
   OR (a.role_title IN ('Graduate Software Engineer', 'Software Engineering Intern', 'Associate Systems Engineer')
       AND s.name IN ('Python', 'SQL', 'Data Structures and Algorithms', 'Git'))
   OR (a.role_title = 'FPGA Design Intern' AND s.name IN ('Verilog', 'C', 'Digital Signal Processing'))
   OR (a.role_title = 'Data Analyst Graduate Programme' AND s.name IN ('Python', 'SQL', 'Machine Learning'))
   OR (a.job_type = 'masters-program' AND s.name IN ('Technical Writing', 'Python'))
   OR (a.role_title = 'Controls Systems Graduate Engineer' AND s.name IN ('C++', 'System Design', 'Git'));

-- Versioned document metadata; the file links are safe placeholders for a demo.
INSERT OR IGNORE INTO documents (application_id, doc_type, version_label, file_link) VALUES
    ((SELECT id FROM applications WHERE role_title = 'Embedded Systems Intern'), 'resume', 'v3-tailored', 'https://example.com/docs/adi-resume-v3.pdf'),
    ((SELECT id FROM applications WHERE role_title = 'Embedded Systems Intern'), 'cover_letter', 'v1', 'https://example.com/docs/adi-cover-letter-v1.pdf'),
    ((SELECT id FROM applications WHERE role_title = 'Graduate Software Engineer'), 'resume', 'v2-intel', 'https://example.com/docs/intel-resume-v2.pdf'),
    ((SELECT id FROM applications WHERE role_title = 'MSc Computer Science'), 'sop', 'v2-ucd', 'https://example.com/docs/ucd-sop-v2.pdf'),
    ((SELECT id FROM applications WHERE role_title = 'MSc Computer Science'), 'resume', 'v4-masters', 'https://example.com/docs/masters-resume-v4.pdf'),
    ((SELECT id FROM applications WHERE role_title = 'MSc Interactive Digital Media'), 'sop', 'v1-tcd', 'https://example.com/docs/tcd-sop-v1.pdf');

-- Completed and pending interview rounds create non-empty results for both views.
INSERT OR IGNORE INTO interviews (application_id, round_number, interview_type, scheduled_date, outcome, notes) VALUES
    ((SELECT id FROM applications WHERE role_title = 'Embedded Systems Intern'), 1, 'OA', '2026-10-02 10:00:00', 'passed', 'C and digital-logic assessment.'),
    ((SELECT id FROM applications WHERE role_title = 'Embedded Systems Intern'), 2, 'technical', '2026-11-03 14:00:00', 'pending', 'Discuss embedded C, RTOS concepts, and debugging.'),
    ((SELECT id FROM applications WHERE role_title = 'Graduate Software Engineer'), 1, 'OA', '2026-10-12 09:30:00', 'pending', 'Coding assessment link received.'),
    ((SELECT id FROM applications WHERE role_title = 'Software Engineering Intern'), 1, 'phone_screen', '2026-10-15 15:00:00', 'passed', 'Recruiter call completed.'),
    ((SELECT id FROM applications WHERE role_title = 'Software Engineering Intern'), 2, 'technical', '2026-11-06 11:00:00', 'pending', 'Algorithms and Python discussion.'),
    ((SELECT id FROM applications WHERE role_title = 'Firmware Engineering Intern'), 1, 'technical', '2026-11-05 13:30:00', 'pending', 'Firmware and microcontroller interview.'),
    ((SELECT id FROM applications WHERE role_title = 'Controls Systems Graduate Engineer'), 1, 'behavioral', '2026-11-10 16:00:00', 'pending', 'STAR-format competency questions.'),
    ((SELECT id FROM applications WHERE role_title = 'MSc Computer Science'), 1, 'final', '2026-10-20 12:00:00', 'passed', 'Programme offer received.'),
    ((SELECT id FROM applications WHERE role_title = 'MSc Interactive Digital Media'), 1, 'final', '2026-10-21 10:00:00', 'failed', 'Application was unsuccessful.'),
    ((SELECT id FROM applications WHERE role_title = '5G Modem Software Intern'), 1, 'OA', '2026-10-18 09:00:00', 'pending', 'Assessment invitation received.');

COMMIT;

-- Useful post-load checks for a recorded demo:
-- SELECT COUNT(*) AS application_count FROM applications;
-- SELECT * FROM stale_applications ORDER BY days_since_status_update DESC;
-- SELECT * FROM interview_pass_rates ORDER BY interview_type;
-- SELECT * FROM status_history ORDER BY changed_at, id;
