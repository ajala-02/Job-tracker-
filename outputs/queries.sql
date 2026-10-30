
SELECT
    a.id,
    c.name AS company_name,
    a.role_title,
    MIN(i.scheduled_date) AS next_scheduled_interview
FROM applications AS a
JOIN companies AS c ON c.id = a.company_id
LEFT JOIN interviews AS i
    ON i.application_id = a.id
   AND i.outcome = 'pending'
   AND i.scheduled_date >= datetime('now')
WHERE a.status = 'interviewing'
GROUP BY a.id, c.name, a.role_title
ORDER BY next_scheduled_interview IS NULL, next_scheduled_interview;

-- INSERT: Add an application and its required skills.
-- This example assumes 'Analog Devices' already exists in companies (as in seed.sql).
BEGIN TRANSACTION;

INSERT OR IGNORE INTO skills (name) VALUES
    ('C'),
    ('Embedded Systems'),
    ('SQL');

INSERT INTO applications (company_id, role_title, job_type, date_applied, source)
VALUES (
    (SELECT id FROM companies WHERE name = 'Analog Devices'),
    'Embedded Software Intern',
    'internship',
    '2026-10-28',
    'Company careers page'
);

-- Link the most recently created matching application to the selected skills.
WITH target_application AS (
    SELECT id
    FROM applications
    WHERE company_id = (SELECT id FROM companies WHERE name = 'Analog Devices')
      AND role_title = 'Embedded Software Intern'
    ORDER BY id DESC
    LIMIT 1
)
INSERT INTO application_skills (application_id, skill_id)
SELECT target_application.id, skills.id
FROM target_application
CROSS JOIN skills
WHERE skills.name IN ('C', 'Embedded Systems', 'SQL');

COMMIT;

-- UPDATE: Move application 1 to interviewing. The log_status_change trigger
-- writes its old and new status to status_history automatically.
UPDATE applications
SET status = 'interviewing'
WHERE id = 1;

-- DELETE: Permanently remove an application after it has been withdrawn.
-- Related interview, document, link, and history records are removed via CASCADE.
DELETE FROM applications
WHERE id = 1
  AND status = 'withdrawn';

-- VIEW: Review active applications that need a follow-up after 14 days.
SELECT *
FROM stale_applications
ORDER BY days_since_status_update DESC, company_name;

-- VIEW: Compare pass rates across completed interview types.
SELECT *
FROM interview_pass_rates
ORDER BY pass_percentage DESC, interview_type;
