# AGENTS.md

This repository is a template for projects that should carry their own shared instructions. Keep this file focused on agent-specific behavior. Put project overview, hosting, local development, workflow, and layout details in `README.md` and `docs/`.

When adopting this template, replace bracketed placeholders with project-specific values and add focused docs only when the project needs them.

## Start-of-Work Sequence

When resuming work in this repository:

**Always:**

1. Read `README.md`.
2. Read this file.
3. Read `TEMPLATE_SOURCE.md` if it exists, especially before changing shared setup or instruction files.

**Before running project commands or environment-dependent work:**

4. Read `docs/local-development.md`.
5. Inspect `Makefile` to learn the available targets and whether they depend on local configuration.
6. Inspect `.env.local.example` for expected variables, and `.env.local` if it exists. Do not print secrets or copy private values into tracked files.
7. If the task depends on local configuration and required values are unset, ask for missing machine-specific values before assuming paths, environment names, credentials, or data roots.

**For the specific task:**

8. Read the relevant documents in `docs/` (see Docs Map below).
9. Inspect target source files before editing them.
10. Run the appropriate `make` target when needed.

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
- `docs/agent-instructions.md`: maintaining clear, specific, non-conflicting `AGENTS.md`, `CLAUDE.md`, and nested instruction files.
- `docs/template-adoption.md`: recording the source template version and catching up with upstream template changes.
- `docs/local-development.md`: `Makefile` targets, environment setup, preview commands, build commands, and validation checklist.
- `docs/repository-layout.md`: top-level files, path conventions, generated artifacts, and how to document project-specific layout.
- `docs/project-specific-guidelines.md`: how agents and maintainers should identify and create focused project-specific docs.

If a doc does not exist in the adopted project, infer the local pattern from nearby files and update the docs when the convention becomes stable.

## Agent Instruction Hygiene

Follow `docs/agent-instructions.md` when editing agent-facing instructions. Keep top-level files (`AGENTS.md`, `CLAUDE.md`) concise, specific, and non-conflicting. Put durable procedures in `docs/`. Use nested `AGENTS.md` only when a subdirectory needs different instructions.

## Writing and Sourcing

For prose and documentation changes, follow `docs/writing-guide.md`. For scientific, scholarly, clinical, biomedical, statistical, or data-driven claims, also follow `docs/scientific-integrity.md`. Prefer primary literature, official organization pages, project-owned pages, and source documents already tracked by the repository. Use PubMed or PubMed Central for biomedical references when relevant.

## Testing Discipline

For coding projects, follow `docs/testing-guide.md`. Identify expected behavior, positive controls, negative controls, and edge cases before changing behavior, and prefer adding or updating tests before implementation. For websites or rendered documentation, at minimum confirm `make build` succeeds.

## Automation Discipline

When work involves repeated manual steps, follow `docs/automation-guide.md`. Notice repeated manual labor and propose scripts, `make` targets, tests, or pipelines that reduce variance. For repeated writing or review, propose reusable templates, rubrics, or checklists.

## Privacy and Personal Data

When a project may touch individual-level data or personal information, follow `docs/privacy-guide.md`. Do not put real individual-level data in scripts, slides, examples, tests, fixtures, notebooks, or documentation without explicit human-maintainer approval. Prefer programmatic de-identification over manual agent inspection of raw records. Use role labels (such as "the student") in documentation when names are not necessary.

## Environment Behavior

Use `.env.local` for machine-specific values; treat `.env.local.example` as documentation. Before running `make` targets that may depend on local paths, credentials, external data, or rendering tools, check whether required values are set and ask the user for missing values rather than guessing. Continue with task parts that do not depend on the local environment.

For new projects or unsettled tooling, first clarify what the project should produce, who will run it, what data and environments it depends on, and which compatibility constraints matter before choosing package managers, repository structure, or `Makefile` targets.

## Validation

Before finishing a change, run the narrowest relevant `make` target documented in `docs/local-development.md` when practical. For Markdown-only docs, review changed files for links, paths, headings, and placeholders. If validation is skipped or fails, report that clearly and include the reason.

## Project-Specific Docs

When a convention is durable, repeated, or easy to get wrong, create a focused doc under `docs/`. Do not keep narrow docs in this base template, but help create them when a real project needs them. See `docs/project-specific-guidelines.md` for examples and the adoption checklist.

## Template Adoption

When this structure is adopted by another project, fill in `TEMPLATE_SOURCE.md` with the template repository, identifier, adoption date, copied files, and local adaptations. To catch up with a newer template version, follow `docs/template-adoption.md`.

## Handoff Behavior

When handing work back to the user:

- Summarize the files changed.
- Mention validation performed.
- Mention any remaining placeholders, missing local configuration, or follow-up checks.

Do not assume context outside the repository unless it is documented in `README.md`, this file, `docs/`, or the user explicitly provides it.
