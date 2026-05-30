# Project-Specific Guidelines

This template starts with a small set of reusable docs. Most useful repository instructions are project-specific and should be discovered with the human maintainer as the project takes shape.

## When to Create a New Guideline

Create a dedicated doc when a convention is durable, repeated, or easy to get wrong.

Good signals include:

- The same question comes up more than once.
- A workflow has several steps or depends on a specific file layout.
- A content type has required metadata.
- The project needs an explicit toolchain, package manager, or environment manager choice.
- A naming convention affects links, generated output, or external users.
- The project has validation commands that differ by content type.
- The project has repeated manual steps that should become scripts, `make` targets, or pipelines.
- The project has repeated writing or review tasks that should use templates, rubrics, or checklists.
- A mistake would be hard to notice in review.
- A source directory starts accumulating repeated procedure text that belongs in `docs/`.
- The project needs a stable boundary between git-tracked source files and Box, Drive, raw-data, private-data, or other external storage.

## How Agents Should Help

Agents should work with the human maintainer to identify documentation requirements. Start from the files already in the repository, then ask concise questions when a convention cannot be inferred safely.

Useful questions include:

- What is the project trying to produce or publish?
- Are there previous projects, repositories, papers, websites, reports, or examples that should guide this one?
- Who will run the project, and on which operating systems or platforms?
- Which use cases matter most: reproducibility, speed, collaboration, deployment, teaching, or exploration?
- Which data, environment variables, credentials, or external services are required?
- Which files belong in git, which belong in external storage, and which environment variable names the external root?
- Could any workflow expose individual-level data or personal information?
- If individual-level data is involved, what programmatic de-identification procedure should run before analysis, examples, tests, slides, or docs use the data?
- Which package manager or environment manager best fits those constraints?
- Which audience will read the writing, and are there style guides, venue instructions, or example documents to follow?
- Which files are the source of truth?
- Which received, raw, generated, binary, or sensitive files should stay outside git?
- Which generated files should stay out of git?
- Which commands should exist in the `Makefile`?
- Which repeated manual steps should be automated?
- Which repeated writing or review tasks should use a template, rubric, or checklist?
- Which positive controls, negative controls, and edge cases should tests cover?
- Which metadata fields are required for this content type?
- Which links or filenames need to remain stable?
- Which validation step should run before a pull request?
- Which decisions require human review?

After the convention is clear, document it in `docs/` and add or update the relevant `Makefile` target if commands are involved.

When the best option depends on a changing tool landscape, search online for current official documentation and reputable sources before recommending a convention. Summarize the tradeoffs for the human maintainer, then document the decision once adopted.

## Base Docs to Adapt

The base template includes `docs/external-data-layout.md` and `docs/inbox-triage.md` because the tracked-source versus external-storage boundary is easy to get wrong. When a project does not use external files, remove or simplify those docs during adoption. When it does, adapt them to the project's actual root variable, external subfolders, and validation commands.

## Common Project-Specific Docs

These docs are examples, not part of the base template.

- `docs/publications.md` for publication metadata, citation checks, assets, and preprint-to-paper workflows.
- `docs/navigation.md` for menus, redirects, route conventions, and stable links.
- `docs/team-directory.md` for people profile fields, ordering, alumni status, and profile assets.
- `docs/textbook-notes.md` for Quarto chapter structure, manifests, PDF locations, and rendering.
- `docs/data-management.md` for data roots, derived files, privacy boundaries, and reproducibility.
- `docs/privacy.md` for project-specific privacy boundaries, data-access rules, de-identification procedures, and individual-level data handling.
- `docs/release-process.md` for versioning, changelogs, artifacts, and deployment.
- `docs/testing.md` for testing scenarios, fixtures, positive and negative controls, slow tests, and CI expectations.
- `docs/environment.md` or `docs/setup.md` for package managers, system tools, environment variables, and platform-specific setup.
- `docs/automation.md` for repeated workflows, generated outputs, scripts, and pipeline conventions.
- `docs/writing-workflow.md` for writing templates, review rubrics, manuscript evaluation criteria, and revision procedures (see `docs/manuscript-evaluation.md` for a worked example).
- `docs/project-context.md` for stable project assumptions and pending-documentation notes.

Prefer adding a focused doc over burying project-specific rules in `AGENTS.md`.

## Project Context Patterns

Two short patterns help keep agents aligned across sessions without filling `AGENTS.md` with project facts.

**Safe assumptions.** As stable facts about the project become clear, such as central datasets, methods, scope, and current status, record them in a short focused doc (for example `docs/project-context.md`). Future sessions can read these instead of inferring from scratch or asking the user repeatedly. Update the file when assumptions change.

**Pending documentation.** When root-level files such as `README.md` or planning notes are still placeholder drafts, mark them explicitly so agents do not treat the placeholder content as authoritative. Either flag the file in its own opening paragraph ("This README is a starter draft pending project context") or list pending files in `docs/project-context.md`.

Both patterns work best as project-specific docs rather than as additions to `AGENTS.md`, which should stay short.

## Adoption Checklist

When adapting this template to a new repository:

- Remove docs that do not apply.
- Add focused docs for recurring project-specific workflows.
- Update `README.md` with the project purpose and high-level map.
- Update `AGENTS.md` so agents know which docs to read first.
- Decide whether `_inbox/` and `_data/` apply; if they do, document the external root variable in `.env.local.example`.
- Configure `Makefile` targets for install, dev, build, test, lint, format, and clean as applicable.
