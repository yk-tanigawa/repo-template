# Repository Layout

This document describes top-level files, path conventions, generated artifacts, and the process for documenting project-specific layout. Keep it synchronized with `README.md`.

## Top-Level Entries

- `README.md`: project overview, local workflow, and high-level layout.
- `AGENTS.md`: agent-specific operating rules and handoff behavior.
- `Makefile`: stable command interface for humans and agents.
- `docs/`: maintainer notes for durable conventions.
- `_inbox/`: short-lived intake folder for unsorted files; contents are ignored except `_inbox/README.md`.
- `_data/`: optional per-machine symlink to a Box, Drive, or external data root; ignored by git.
- `TEMPLATE_SOURCE.md`: template source identifier and update history.
- `.env.local.example`: documented local configuration variables.
- `.gitignore`: local config, dependency folders, and build artifacts.

## Optional Local Entries

- `_repos/`: ignored local symlinks to related repository clones when cross-repo context is needed.

## Project-Specific Layout

Source directories, asset directories, configuration files, and generated outputs are project-specific. Do not keep a generic framework inventory here after adoption.

Before settling the layout, clarify the project goals, use cases, data and environment requirements, and expected users. Repository structure should follow those needs rather than a generic template or the first tool an agent recognizes.

Instead, document the actual repository layout once it is known. For each important directory, state:

- what belongs there
- what should not be placed there
- which files are source of truth
- which files are generated
- which `make` target validates changes there

Useful questions:

- Where does source content live?
- Where do tests live?
- Where do static or binary assets live?
- Where does configuration live?
- Which generated directories are safe to delete?
- Which paths are part of the public API or stable URL structure?

## Docs vs. Source Notes

Keep durable conventions, reusable procedures, schema definitions, privacy rules, validation expectations, and update workflows under `docs/`.

Project source directories should primarily contain source material, current status, project facts, data records, and concise human-editable working notes. Avoid maintaining the same procedure in both `docs/` and a source directory. If a source directory needs orientation, use a short note that points to the canonical `docs/` page and lists only local source files, current data status, and non-duplicative follow-up notes.

## Path Conventions

Use repository-relative paths in docs and handoffs, such as `README.md`, `AGENTS.md`, or `docs/local-development.md`.

Use project-native relative paths for source references. If the project generates a website or package, document public URL or import-path conventions in a project-specific doc.

Avoid absolute local paths in tracked files. Put local roots in `.env.local` and reference them through documented variables.

Use `_data/` only as an ignored local convenience path. Tracked documentation and scripts should refer to external files through the configured environment variable, such as `$PROJECT_EXTERNAL_DATA_ROOT`, so the reference remains portable.

## Related Repositories

Use `_repos/` for ignored local symlinks to related repository clones when a project needs cross-repo context. Document the purpose, environment variable, and source-of-truth boundary for each related clone in `docs/related-repositories.md` or a focused project-specific doc.

Do not commit `_repos/` entries. Keep machine-local clone paths in `.env.local`, and keep tracked docs pointed at repository-relative symlink paths such as `_repos/[repo-name]` or documented environment variables.

## External and Intake Files

Use `docs/external-data-layout.md` to document the boundary between git-tracked source files and external storage such as Box, Drive, raw-data folders, private-data folders, and generated local extracts.

Use `_inbox/` for short-lived file intake only. Triage incoming files with `docs/inbox-triage.md`, then move them into either tracked source directories or the ignored `_data/` tree.

## Generated Files

Document generated files in `docs/local-development.md` and `.gitignore`.

Before adding a new generated artifact to git, confirm that it is intentionally published, small enough for the repository, and allowed by any relevant license or publisher terms.

## Adding a New Convention

When a convention becomes durable, document it here or in a focused project-specific doc under `docs/`. Good conventions include filename patterns, metadata schemas, asset locations, render commands, test scopes, external data roots, release processes, and redirect workflows.
