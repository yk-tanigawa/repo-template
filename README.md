# [Project Name]

This repository contains [short description of the project]. It is structured so human maintainers and AI agents can understand the project purpose, source files, local commands, and content conventions from the repository itself.

## What This Repo Is For

Use this section to define the project in one or two paragraphs. State what belongs in the repository, what should stay outside the repository, and which files are the source of truth.

Examples:

- A Hugo or Jekyll academic website where Markdown content and static assets are the source of truth.
- A Quarto notes repository where `.qmd` files and book manifests are the source of truth.
- A documentation repository where Markdown files and structured metadata are the source of truth.

## Design Goals

- Keep the project easy to inspect from `README.md`, `AGENTS.md`, and `docs/`.
- Keep source files versioned and generated artifacts out of git unless they are intentionally published assets.
- Keep sensitive, large, received, or machine-local source material outside git and reference it through documented local configuration.
- Use stable, relative paths in documentation and metadata.
- Prefer small, reviewable changes over broad rewrites.
- Keep reusable procedures in `docs/`; keep source directories focused on source material, current status, and project facts.
- Make local setup and validation commands explicit.
- Preserve project-specific naming, content, and editorial conventions.

## Current Hosting

Fill this in for websites or hosted documentation.

- Site URL: `[production URL]`
- Preview or staging URL: `[preview URL]`
- Hosting provider: `[GitHub Pages, Netlify, other]`
- Build configuration: `[netlify.toml, _config.yml, config/_default/hugo.yaml, other]`
- CI configuration: `[.github/workflows/*.yml, other]`

Delete this section if the repository is not hosted.

## Local Development

Use `make` as the project command interface. The `Makefile` should define the common commands so humans and agents do not have to rediscover framework-specific commands on each machine.

Before running `make` targets that depend on local paths, credentials, external data, or rendering tools, inspect `.env.local.example` and check whether `.env.local` is configured. Machine-specific values such as local Python paths, conda environment names, Box or Drive roots, API keys, and private data roots should live in `.env.local`. Track `.env.local.example` as documentation and keep `.env.local` untracked.

When the project needs local context from another clone, keep that clone path in `.env.local`, list it in `PROJECT_RELATED_REPOS`, and expose it through the tracked `_repos/` directory as an ignored symlink. Run `make setup` to create or refresh configured `_repos/` links.

Common targets:

```bash
make help
make setup
make install
make dev
make build
make test
make lint
make format
make clean
```

Document what each target does in `docs/local-development.md`. Put the underlying project-specific commands in `Makefile`.

## Development Workflow

Use a branch-based workflow for substantive changes.

1. Create a branch from the default branch.
2. Make focused edits.
3. Run the relevant `make` target from `docs/local-development.md`.
4. Review the changed pages or rendered files.
5. Commit the change on the branch.
6. Push the branch and open a pull request.
7. Review CI, preview builds, and the diff before merging.

Small, self-contained edits can be committed directly to the default branch when that matches the project norm.

## Repo Layout

Update this list to match the project. Keep the top-level documentation stable and put project-specific source, asset, and configuration layout in `docs/repository-layout.md` after those conventions are known.

- `AGENTS.md`: agent-specific operating rules and handoff instructions
- `CLAUDE.md`: Claude Code entrypoint that imports or points to `AGENTS.md`
- `README.md`: project overview, workflow, and high-level layout
- `Makefile`: stable command interface for humans and agents
- `docs/`: maintainer notes and durable conventions
- `_inbox/`: short-lived local intake area for unsorted files; contents are ignored except `_inbox/README.md`
- `_data/`: optional per-machine symlink to an external Box, Drive, or data root; ignored by git
- `_repos/`: tracked README plus ignored local symlinks to related repository clones when a project needs cross-repo context
- `TEMPLATE_SOURCE.md`: record of the template version used to initialize or refresh the project
- `.env.local.example`: documented machine-specific configuration variables
- `.gitignore`: local config, dependencies, and generated artifacts

## Common Tasks

See the Docs Map in `AGENTS.md` for the canonical list of `docs/` files and when to use each. Project-specific docs such as `docs/testing.md`, `docs/publications.md`, `docs/navigation.md`, `docs/team-directory.md`, `docs/textbook-notes.md`, or `docs/data-management.md` can be added later when the project needs them.

Use `docs/related-repositories.md` when the project needs local context from sibling or upstream repositories through ignored `_repos/` symlinks.

## Notes for Agents

Contributor and agent instructions live in `AGENTS.md`. Agents should use `Makefile` targets when running project commands and should help maintainers document project-specific conventions as they become clear.
