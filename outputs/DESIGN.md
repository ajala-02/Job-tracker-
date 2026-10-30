# Internship & Job Application Tracker

## Purpose and scope

This SQLite database supports a final-year ECE student who is simultaneously applying for internships, full-time positions, and Master's programmes in Ireland. Job searching quickly becomes a small information-management problem: the same employer can have several opportunities, a referral or recruiter can be relevant to more than one application, and every application may have several interview rounds, tailored documents, and changing outcomes. The tracker provides one consistent place to record that information and to answer practical questions such as “Which applications need a follow-up?”, “What is my next interview?”, and “How have I performed in technical interviews?”

The database is intentionally scoped to the application process rather than to a general career-management system. Its core unit is an application for one role or programme at one company or university. It stores the current status for fast everyday use and separately retains an audit trail of previous statuses. It can therefore support both a current dashboard and later retrospective analysis of the search process. SQLite is appropriate for this project because the intended use is a personal, single-user tracker with a portable local database file and no server deployment requirement.

## Entity-relationship diagram

**Placeholder:** an entity-relationship diagram will be embedded here as an image before submission. It will show `applications` as the central entity; `companies` has a one-to-many relationship with applications, while interviews, documents, and status-history records are owned by one application. The two junction tables express the many-to-many links to contacts and skills.

## Entities and relationships

`companies` represents an employer, university, or programme provider. Its unique name avoids accidentally creating duplicate organisations, and optional website, industry, country, and size fields add useful context without making an application depend on complete company research. The `size` check accepts a deliberately small controlled vocabulary, making reports more consistent than free-form descriptions.

`contacts` stores people at a company, such as recruiters, hiring managers, alumni, or referral sources. A contact belongs to one company through `company_id`; known email addresses are unique. Contacts are not copied into `applications` because a person can help with several roles and a single application can involve several people. `application_contacts` resolves that many-to-many relationship using a composite primary key, so the same contact cannot accidentally be linked twice to the same application. The contact’s `relationship` field records the nature of the connection without imposing a premature fixed taxonomy.

`applications` is the central table. It holds the role title, type, application date, source, current status, and when that status was last updated. The `job_type` check distinguishes internships, full-time roles, and Master's programmes; including the last category lets one workflow cover both professional and academic applications. The `status` check restricts lifecycle values to applied, online assessment received, interviewing, offer, rejected, and withdrawn. A uniqueness constraint on company, role title, and date applied prevents a duplicate submission record on the same day while still permitting applications to distinct roles at one company.

`interviews` represents an online assessment or one interview round. Each row belongs to exactly one application, has a positive round number, a constrained type, a scheduled date, and a pending, passed, or failed outcome. The unique `(application_id, round_number)` constraint ensures that a round cannot be recorded twice. Keeping interview data out of the application table is essential: an application may progress through a phone screen, technical round, and final round, so repeating interview columns would produce sparse and inflexible data.

`skills` is a canonical skill catalogue with a unique name. `application_skills` connects applications to the skills expected for them. This normalization eliminates repeated comma-separated skill lists, makes it possible to query all opportunities requiring a skill, and allows one spelling of a skill to be maintained in one row. Its composite primary key protects against duplicate links.

`documents` stores metadata for a submitted resume, cover letter, or statement of purpose. The actual file is deliberately external and referenced by `file_link`, which keeps the database compact while allowing files to live in local storage or a cloud drive. The `(application_id, doc_type, version_label)` uniqueness rule supports multiple versions without duplicating the same version. `status_history` is the audit table: it records the status before and after every real transition and timestamps the event. It is populated by `log_status_change`, an `AFTER UPDATE OF status` trigger that also refreshes `current_stage_updated_at`. The `WHEN OLD.status != NEW.status` condition means an update that reassigns the same status creates no misleading history row.

Foreign keys link every dependent record back to its owner. `ON DELETE CASCADE` keeps the database referentially sound when a user deliberately deletes an application or company: its dependent links, interviews, documents, and history cannot be left orphaned. SQLite requires `PRAGMA foreign_keys = ON` for this enforcement, so the schema and example queries call that out explicitly.

## Views, auditing, and optimizations

The `stale_applications` view exposes only active applications whose stage timestamp is at least fourteen days old, excluding offers, rejections, and withdrawals. It translates a recurring follow-up task into a simple query and calculates days since the last status change. The `interview_pass_rates` view groups completed passed and failed rounds by interview type and calculates a percentage. Pending interviews are excluded so the denominator represents only known outcomes.

The status-change trigger protects the audit trail from being a manual, error-prone process. Updating `applications.status` is all the user must do; the trigger records the old status, new status, and timestamp, then updates the stage timestamp used by the stale view. It does not log unchanged status assignments, preserving the meaning of the history data.

Three indexes target expected access patterns. `idx_applications_status` speeds dashboard filters such as active interviewing applications or a board grouped by current status. `idx_applications_company_id` speeds company detail pages and employer-level summaries because those queries first find a company and then retrieve its applications. `idx_interviews_application_id` speeds an application detail view that lists every interview round. The primary and unique keys already provide indexes for their own lookups, so additional indexes are kept intentionally narrow to avoid unnecessary write overhead in a personal database.

## Limitations and future work

The initial design assumes one user and one local SQLite file. It has no accounts, permissions, shared editing, conflict resolution, or synchronisation, so it is not a multi-user recruitment CRM. Dates are stored as SQLite-compatible text/date-time values and use the local application environment; timezone handling is not modelled. The design also does not capture compensation, benefits, salary expectations, relocation, visa eligibility, offer negotiation, or a negotiation workflow. Those can be added later through dedicated offer and compensation tables rather than overloading the status field.

The database tracks documents by link rather than storing file contents or validating that a link still exists. It also does not track every communication event, reminders, company offices, application deadlines, or one contact working at multiple companies over time. Status history is an audit of status transitions only, not a complete audit of every field edit. Finally, pass rates are descriptive rather than statistically robust: a small number of interviews, changing difficulty, and different employers make them a personal reflection tool rather than a performance benchmark.

## Video overview

Three-minute project video overview: https://youtu.be/7qt5hve1zH8
