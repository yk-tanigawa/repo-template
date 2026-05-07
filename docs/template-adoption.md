# Template Adoption and Updates

Use this document when a new project adopts this repository template or when an existing project wants to catch up with newer template guidance.

## Why Track Template Version

Projects that start from this template should record the exact template version they used. A commit hash, tag, release, or archive checksum makes it possible to compare the adopted project against later template versions and selectively apply improvements.

The project should keep that record in `TEMPLATE_SOURCE.md`.

## Initial Adoption

When creating a new project from this template:

1. Copy the template files into the new project.
2. Fill in `TEMPLATE_SOURCE.md`.
3. Record the template repository and identifier.
4. Record the adoption date and copied or adapted files.
5. Commit the initial project setup.

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

If the template is available in a local git clone, useful comparison commands include:

```bash
git log --oneline [old-template-id]..[new-template-id]
git diff [old-template-id]..[new-template-id] -- README.md AGENTS.md docs Makefile .env.local.example .gitignore TEMPLATE_SOURCE.md
```

Run those commands in the template repository, then apply relevant changes to the downstream project with normal review.

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
