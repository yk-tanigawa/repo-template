# Privacy and Individual-Level Data

Use this document for any project that may touch individual-level data, personal information, education records, research supervision notes, clinical or biomedical records, survey responses, interview notes, private communications, or other sensitive material.

## Core Rule

Do not put individual-level data in the repository unless the project has an explicit, documented reason and the human maintainer confirms that it is appropriate to track.

When in doubt, keep individual-level data outside git and reference it through documented local paths, secure storage, or approved data-access systems.

## Code, Scripts, Slides, and Examples

Analysis scripts, lecture slides, examples, tests, fixtures, notebooks, and documentation should not contain real individual-level data.

Use synthetic, aggregated, anonymized, or toy data when examples need data-like content. Make sure toy data cannot be mistaken for real people.

Do not include:

- names tied to records
- student IDs, patient IDs, employee IDs, or account IDs
- emails, phone numbers, addresses, or private URLs
- exact dates or timestamps tied to identifiable events
- free-text notes copied from private records
- small-cell summaries that could identify a person
- screenshots that reveal personal information

## Documentation About People

Some projects intentionally support education, mentoring, research supervision, team coordination, or collaboration. In those cases, documentation may need to refer to people or roles.

Use data minimization:

- Prefer roles over names when the identity is not necessary.
- Write "the student", "the trainee", "the collaborator", or "the instructor" when that is sufficient.
- Avoid repeating a person's name across multiple files when one reference or a role label would work.
- Avoid private biographical details, performance notes, health information, demographic details, or contact information unless the project explicitly requires them.
- Keep sensitive supervision or evaluation notes outside the repository unless the human maintainer confirms the repository is the appropriate place.

## Data Handling

Document where sensitive or individual-level data lives, who can access it, and which commands use it. Put local data roots in `.env.local`, not in tracked files.

Prefer workflows where tracked code operates on:

- synthetic fixtures
- public example data
- aggregated summaries
- de-identified derived data that has been reviewed for re-identification risk

If a test or example requires sensitive data, document the required local setup and keep the data untracked.

## De-Identification Procedure

Projects that deal with individual-level data should consider developing a documented de-identification procedure as part of project adoption and code development.

De-identification should be performed by a deterministic program or documented data-processing pipeline, not by an agent manually reviewing and editing individual records. Programmatic processing is more consistent, more auditable, and reduces the risk of exposing individual-level data to agent APIs.

The procedure should describe:

- which input fields may identify a person
- which fields must be removed, generalized, masked, or aggregated
- how dates, locations, free text, IDs, and rare categories are handled
- how small-cell counts and other re-identification risks are checked
- where raw data lives and where de-identified outputs may be written
- which `make` target or script runs the de-identification step
- how de-identified outputs are reviewed before use in examples, tests, slides, or documentation

Prefer making de-identification an explicit step before analysis scripts, examples, tests, or teaching materials consume data. If possible, encode the step in a reusable script and expose it through a documented `make` target.

Agents may help write, test, document, and review the de-identification code using synthetic or already de-identified examples. Agents should avoid manually inspecting raw individual-level records unless the human maintainer explicitly confirms that doing so is appropriate and necessary.

Do not assume de-identification is complete just because names or direct identifiers have been removed. Review whether combinations of fields can still identify a person.

## Review Checklist

Before committing, check:

- No real individual-level data is present in scripts, slides, notebooks, tests, fixtures, or docs.
- Personal names are used only when needed.
- Role labels replace names where possible.
- A documented de-identification procedure exists when the project handles individual-level data.
- De-identification is applied by a script, pipeline, or other programmatic process rather than manual agent review.
- Analysis, examples, tests, slides, and docs use de-identified, synthetic, aggregated, or public data whenever possible.
- Local data paths are referenced through `.env.local` variables.
- Screenshots, figures, tables, and examples do not reveal personal information.
- Any remaining individual-level reference has a clear project purpose and human approval.
