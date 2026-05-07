# Writing Guide

This document contains general writing guidance for documentation, README files, issues, pull requests, websites, notes, and other prose. It is intentionally project-neutral.

## Core Principles

Write for the next person who has to use the repository. That person may be a maintainer, a collaborator, an agent, or your future self.

Agents and users may not already know the clearest current writing conventions for a project type or audience. When writing standards matter, search online for reputable guidance such as field style guides, journal or venue instructions, documentation style guides, and examples from high-quality peer projects.

Prefer clear, direct prose. Use short sentences when possible. Put the main point early, then add the details needed to act on it.

Keep one paragraph focused on one main message. If a paragraph starts doing two jobs, split it.

Remove filler. If a sentence does not add information beyond the heading or surrounding paragraph, delete it.

Use concrete nouns and verbs. Prefer "Run `make build` before opening a pull request" over "Ensure appropriate validation has been performed."

Adapt the style to the intended use case. A lab website, API reference, scientific report, textbook note, grant text, and internal runbook may need different levels of detail, formality, citation, and assumed background.

## Structure

Use headings to help readers scan. Keep heading names literal and predictable.

Put the most frequently needed information first. Setup commands, source-of-truth files, and validation steps should be easy to find.

Use lists for steps, requirements, and checklists. Use prose for context, rationale, and tradeoffs.

When documenting a workflow, include:

1. When to use the workflow.
2. Inputs or prerequisites.
3. Commands or steps.
4. Expected output.
5. How to verify success.

## Templates and Evaluation Rubrics

For repeated writing tasks, use templates, rubrics, and checklists to improve consistency. This is the writing equivalent of automation in coding projects.

Examples include:

- manuscript evaluation templates
- grant review checklists
- lecture-slide review rubrics
- README or documentation templates
- peer-review response templates
- paper summary templates
- project proposal templates

When preparing or reviewing a manuscript draft, consider creating a manuscript evaluation document with stable criteria. Reusing the same criteria helps evaluate writing quality consistently across drafts, sections, projects, and reviewers.

Good templates should state:

- the intended audience
- the document type and purpose
- the criteria used for evaluation
- required evidence, citations, or examples
- questions for the human author
- decisions or revisions that require human judgment

When a writing workflow repeats, add the template or rubric under `docs/`, `templates/`, or another documented project-specific location.

## Links and Paths

Use paths relative to the repository root, such as `README.md`, `AGENTS.md`, or `docs/local-development.md`.

Avoid machine-local absolute paths in tracked files. Put local roots in `.env.local` and document the variable name instead.

Use stable internal links when possible. If a link depends on a generated site URL, document where that URL is configured.

## Personal Information

Use data minimization when writing about people. Prefer role labels such as "the student", "the trainee", "the collaborator", or "the instructor" when the person's identity is not needed.

Avoid repeating personal information across files. Keep private supervision notes, education records, health details, contact details, and other sensitive information out of tracked documentation unless the project explicitly requires it and the human maintainer confirms it is appropriate.

## Placeholders

Use bracketed placeholders sparingly, such as `[project name]` or `[build command]`. Remove placeholders when adopting this template in a real project.

If a placeholder requires a decision, document the question in `docs/project-specific-guidelines.md` or ask the human maintainer directly.

## Check Before Publishing

Before publishing documentation changes, check:

- The main point is easy to find.
- Paths are relative to the repository root.
- Commands match the `Makefile` or `docs/local-development.md`.
- Placeholders are intentional.
- The text does not assume private local paths or hidden context.
- The relevant validation step has been run or the reason for skipping it is recorded.
