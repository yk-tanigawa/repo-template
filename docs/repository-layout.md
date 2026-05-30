# Repository Layout

This document describes top-level files, path conventions, generated artifacts, and the process for documenting project-specific layout. Keep it synchronized with `README.md`.

## Required Top-Level Files

- `README.md`: project overview, local workflow, and high-level layout.
- `AGENTS.md`: agent-specific operating rules and handoff behavior.
- `Makefile`: stable command interface for humans and agents.
- `docs/`: maintainer notes for durable conventions.
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

## Path Conventions

Use repository-relative paths in docs and handoffs, such as `README.md`, `AGENTS.md`, or `docs/local-development.md`.

Use project-native relative paths for source references. If the project generates a website or package, document public URL or import-path conventions in a project-specific doc.

Avoid absolute local paths in tracked files. Put local roots in `.env.local` and reference them through documented variables.

## Related Repositories

Use `_repos/` for ignored local symlinks to related repository clones when a project needs cross-repo context. Document the purpose, environment variable, and source-of-truth boundary for each related clone in `docs/related-repositories.md` or a focused project-specific doc.

Do not commit `_repos/` entries. Keep machine-local clone paths in `.env.local`, and keep tracked docs pointed at repository-relative symlink paths such as `_repos/[repo-name]` or documented environment variables.

## Generated Files

Document generated files in `docs/local-development.md` and `.gitignore`.

Before adding a new generated artifact to git, confirm that it is intentionally published, small enough for the repository, and allowed by any relevant license or publisher terms.

## Adding a New Convention

When a convention becomes durable, document it here or in a focused project-specific doc under `docs/`. Good conventions include filename patterns, metadata schemas, asset locations, render commands, test scopes, data roots, release processes, and redirect workflows.
