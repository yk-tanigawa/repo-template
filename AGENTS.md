# AGENTS.md

This repository is a template for projects that should carry their own shared instructions. Keep this file focused on agent-specific behavior. Put project overview, hosting, local development, workflow, and layout details in `README.md` and `docs/`.

When adopting this template, replace bracketed placeholders with project-specific values and add focused docs only when the project needs them.

## Start-of-Work Sequence

When resuming work in this repository:

1. Read `README.md`.
2. Read this file.
3. Read `TEMPLATE_SOURCE.md` if it exists, especially before changing shared setup or instruction files.
4. Read `docs/local-development.md` before running project commands.
5. Inspect `Makefile` to learn the available targets and whether they depend on local configuration.
6. Inspect `.env.local.example` to learn expected machine-specific variables.
7. If `.env.local` exists, inspect it before running environment-dependent commands. Do not print secrets or copy private values into tracked files.
8. If the task depends on local configuration and `.env.local` is missing or required values are unset, ask for missing machine-specific values before assuming paths, environment names, credentials, or data roots.
9. Read the other relevant document in `docs/`.
10. Inspect the target source file before editing it.
11. After the relevant docs, local configuration, and target files are understood, run the appropriate `make` target when needed.

## Primary Rules

- Use paths relative to the repository root in documentation, comments, and handoffs.
- Do not include machine-local absolute paths in tracked files unless the user explicitly asks for a machine-specific note.
- Treat tracked source files as the source of truth. Do not commit generated artifacts unless the project documents them as published assets.
- Keep machine-specific settings in `.env.local`, and keep `.env.local` untracked.
- Use `Makefile` targets for install, preview, build, test, lint, format, and cleanup tasks when targets exist.
- When a durable command is missing, help add it to `Makefile` and document it in `docs/local-development.md`.
- When project structure or tooling choices are not settled, work with the human maintainer to clarify goals and use cases before choosing a convention.
- When relevant best practices may have changed, search online for current official documentation and reputable sources before recommending or adopting a toolchain, repository convention, or writing standard.
- Preserve existing content and naming conventions unless the user asks for a rewrite or migration.
- Prefer small, coherent edits over broad rewrites.
- Do not invent facts, affiliations, announcements, citations, dates, or scientific claims.
- For current factual or scientific claims, verify against trusted sources before updating public-facing content.
- Update the relevant docs when you introduce a new durable convention.

## Docs Map

- `docs/writing-guide.md`: general prose, structure, links, paths, placeholders, and documentation checks.
- `docs/scientific-integrity.md`: source hierarchy and claim-checking rules for scientific or scholarly content.
- `docs/testing-guide.md`: test-driven development principles, test scenarios, `make test`, and minimum build checks.
- `docs/privacy-guide.md`: individual-level data protection, data minimization, and personal-information handling.
- `docs/automation-guide.md`: repeated work, scripts, `make` targets, pipelines, and consistency improvements.
- `docs/template-adoption.md`: recording the source template version and catching up with upstream template changes.
- `docs/local-development.md`: `Makefile` targets, environment setup, preview commands, build commands, and validation checklist.
- `docs/repository-layout.md`: top-level files, path conventions, generated artifacts, and how to document project-specific layout.
- `docs/project-specific-guidelines.md`: how agents and maintainers should identify and create focused project-specific docs.

If a doc does not exist in the adopted project, infer the local pattern from nearby files and update the docs when the convention becomes stable.

## Writing and Sourcing

Use `docs/writing-guide.md` for general prose and documentation changes. Use `docs/scientific-integrity.md` when the repository contains scientific, scholarly, clinical, biomedical, statistical, or data-driven claims.

Scientific accuracy and source fidelity are more important than polished prose. Prefer primary literature, official organization pages, project-owned pages, and source documents already tracked or referenced by the repository. Use PubMed or PubMed Central when relevant.

For scientific or technical writing, ask for the intended audience and useful examples such as previous projects, papers, reports, websites, or venue instructions. Search reputable external writing guidance when it would help clarify structure, style, or reporting expectations.

## Testing Discipline

For coding projects, follow `docs/testing-guide.md`. Before changing behavior, identify expected behavior, positive controls, negative controls, edge cases, and the relevant `make` target that verifies the change.

Prefer adding or updating tests before implementation when practical. If the repository lacks tests, work with the human maintainer to identify a minimal testing scenario and document the testing procedure in `docs/`.

For websites or rendered documentation, at least confirm the project builds with `make build` when practical. Add stronger tests such as link checks, smoke tests, or visual checks when the project warrants them.

## Automation Discipline

Follow `docs/automation-guide.md` when work involves repeated manual steps. Agents should notice repeated manual labor and propose scripts, `make` targets, tests, or pipelines that reduce variance, improve consistency, and improve computing efficiency.

Keep automation as small as the problem allows. Prefer deterministic scripts and documented `make` targets for repeated commands, generated outputs, data transformations, and validation steps. Pair automation with tests, fixtures, or smoke checks when practical.

For repeated writing or documentation work, propose reusable templates, rubrics, or checklists. For example, manuscript drafts can use a manuscript evaluation template so each draft is reviewed with the same criteria.

## Privacy and Personal Data

Follow `docs/privacy-guide.md` when a project may touch individual-level data or personal information. Analysis scripts, lecture slides, examples, tests, fixtures, notebooks, and documentation should not contain real individual-level data unless the project has an explicit, documented reason and the human maintainer confirms it is appropriate.

For projects that handle individual-level data, work with the human maintainer to define a programmatic de-identification procedure and make it part of data adoption and code development. Prefer reusable scripts, pipelines, and `make` targets for de-identification steps. Avoid manually inspecting raw individual-level records through agent workflows unless the human maintainer explicitly confirms that it is appropriate and necessary.

Use data minimization in documentation. If a project supports education, mentoring, research supervision, or team coordination, refer to people by role when the name is not necessary. For example, write "the student" instead of repeating a student's name across files.

## Environment Behavior

Use `.env.local` for local paths and machine-specific settings. Treat `.env.local.example` as documentation of required variables, not as an active configuration file.

Check local configuration before running `make` targets that may depend on local paths, credentials, external data, rendering tools, or machine-specific executables. If the task depends on those values and `.env.local` is missing or required values are unset, ask the user for the missing local values before guessing. If a task can proceed without those values, continue with the parts that do not depend on the local environment.

For new projects or unsettled tooling, first clarify what the project needs to achieve, who will run it, what data and environments it depends on, and which compatibility constraints matter. Use those answers, plus current best-practice research when needed, to guide package manager choices, repository structure, and `Makefile` targets.

## Validation

Before finishing a change, run the narrowest relevant `make` target documented in `docs/local-development.md` when practical.

Common examples:

- Install dependencies: `make install`
- Start local preview: `make dev`
- Build or render: `make build`
- Run tests: `make test`
- Run linters: `make lint`
- Website or rendered-output minimum: `make build`
- Markdown-only docs: review changed files for links, paths, headings, and placeholders

If validation is skipped or fails, report that clearly and include the reason.

## Project-Specific Docs

Project-specific docs are encouraged when a convention is durable, repeated, or easy to get wrong. Do not keep narrow docs in this base template, but help create them when a real project needs them.

Examples include:

- `docs/publications.md`
- `docs/navigation.md`
- `docs/team-directory.md`
- `docs/textbook-notes.md`
- `docs/data-management.md`
- `docs/release-process.md`
- `docs/testing.md`
- `docs/automation.md`

When the required convention is unclear, ask concise questions and document the answer in `docs/` once it becomes stable.

## Template Adoption

When this structure is adopted by another project, fill in `TEMPLATE_SOURCE.md` with the template repository, commit hash or other stable identifier, adoption date, copied files, and local adaptations.

When a project wants to catch up with a newer template version, follow `docs/template-adoption.md`. Compare the recorded template baseline with the newer template, apply relevant changes deliberately, and append a template update log entry.

## Handoff Behavior

When handing work back to the user:

- Summarize the files changed.
- Mention validation performed.
- Mention any remaining placeholders, missing local configuration, or follow-up checks.

Do not assume context outside the repository unless it is documented in `README.md`, this file, `docs/`, or the user explicitly provides it.
