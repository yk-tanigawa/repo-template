# Template Adoption and Updates

Use this document when a new project adopts this repository template or when an existing project wants to catch up with newer template guidance.

## Why Track Template Version

Projects that start from this template should record the exact template version they used. A commit hash, tag, release, or archive checksum makes it possible to compare the adopted project against later template versions and selectively apply improvements.

The project should keep that record in `TEMPLATE_SOURCE.md`.

Adopted projects may also keep a local path to this template clone in `.env.local` as `PROJECT_TEMPLATE_REPO`. If template updates are a recurring workflow, add a project-specific `make setup` check or equivalent command that verifies `PROJECT_TEMPLATE_REPO` points to a local git worktree.

## Initial Adoption

When creating a new project from this template:

1. Create the repository with the GitHub "Use this template" button, or copy the template files into an existing project.
2. Fill in `TEMPLATE_SOURCE.md`.
3. Record the template repository and identifier.
4. Record the adoption date and copied or adapted files.
5. Confirm `.env.local.example` documents `PROJECT_TEMPLATE_REPO` when the project will compare against a local template clone.
6. Choose a license for the new project and add it as `LICENSE`.
7. Delete the "About This Template" section from `README.md`, which describes the template repository rather than the adopting project.
8. Commit the initial project setup.

The template is published under MIT No Attribution, which imposes no conditions on adopted projects. An adopted project picks its own license and does not need to carry the template's `LICENSE` file, reproduce its copyright notice, or credit the template. `TEMPLATE_SOURCE.md` records provenance for maintenance purposes, which is independent of any license obligation.

If the template source is a git repository, use the source commit hash:

```bash
git rev-parse HEAD
```

If the template source is not available as a git repository, record another stable identifier such as a release tag, archive checksum, or dated source URL.

## Catching Up With Upstream

Template updates should be reviewed deliberately. Do not blindly overwrite project-specific files.

Recommended update process:

1. Read `TEMPLATE_SOURCE.md` to identify the current template baseline.
2. Identify the latest template identifier to review.
3. Compare the old and new template versions.
4. Decide which upstream changes apply to the project.
5. Adapt the selected changes into the project.
6. Run the relevant validation target, usually `make build`, `make test`, or a documentation review.
7. Append an entry to the `Template Update Log` in `TEMPLATE_SOURCE.md`.

If the template is available in a local git clone, keep its path in `PROJECT_TEMPLATE_REPO`. Downstream projects can expose these checks through `make setup`, `make template-status`, or another documented local command. Useful comparison commands include:

```bash
git -C "$PROJECT_TEMPLATE_REPO" rev-parse HEAD
git -C "$PROJECT_TEMPLATE_REPO" log --oneline [old-template-id]..[new-template-id]
git -C "$PROJECT_TEMPLATE_REPO" diff [old-template-id]..[new-template-id] -- README.md AGENTS.md docs Makefile .env.local.example .gitignore TEMPLATE_SOURCE.md _repos/README.md
```

Apply relevant changes to the downstream project with normal review.

## Updating the Template From Examples

When improving this template based on a real project, separate the reusable pattern from the example project's local facts before committing the change to the template.

Start from the problem the example revealed, not from the example's exact implementation. The template should preserve general conventions, decision prompts, validation expectations, and reusable folder patterns. It should not inherit project names, institution names, private paths, dates, component names, local workflows, policy references, data categories, source subfolders, or domain-specific outputs unless they are intentionally framed as examples.

Run a de-contamination pass before handing the template update back for review:

- Search changed files for project names, people, institutions, acronyms, local paths, private root variables, event names, deadlines, and domain-specific nouns from the example project.
- Replace example-specific names with neutral placeholders or project-owned variable names.
- Move procedural detail into `docs/`; keep `README.md`, `AGENTS.md`, and other top-level files as maps and entrypoints.
- Remove concrete subfolder inventories, source categories, command names, and validation steps unless they are truly reusable across projects.
- Keep examples short and clearly labeled as examples.
- Check that `.env.local.example`, `.gitignore`, and `Makefile` use generic variable names and do not assume one maintainer's machine or storage provider.
- Confirm the resulting text still tells an adopted project what to decide, where to document the decision, and how to validate the convention.

If a useful pattern is only partially reusable, document the generic rule in the template and leave the project-specific implementation in the downstream project.

## What to Review

Pay special attention to changes in:

- `AGENTS.md`
- `README.md`
- `docs/`
- `Makefile`
- `.env.local.example`
- `.gitignore`
- `TEMPLATE_SOURCE.md`

Also check whether the template added new reusable docs that the project should adopt, such as testing, privacy, automation, writing, or local-development guidance.

## Recording Updates

Each update entry in `TEMPLATE_SOURCE.md` should record:

- previous template identifier
- reviewed template identifier
- review date
- changes adopted
- changes skipped and why
- local files updated
- validation run
- follow-up items

This record lets future maintainers understand whether the project is intentionally behind the template, fully caught up, or selectively adapted.

## Agent Behavior

Agents should read `TEMPLATE_SOURCE.md` when present. Before changing shared instructions, agents should preserve the adoption history and update it when reviewing or applying newer template guidance.

When a downstream project asks to catch up with the template, agents should compare the recorded baseline with the latest template version, summarize the upstream changes, ask about project-specific tradeoffs when needed, and apply only the changes that make sense for the project.
