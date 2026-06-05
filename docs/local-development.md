# Local Development

This document records setup, preview, build, render, and validation commands. The `Makefile` is the canonical command interface for this repository.

Agents and maintainers should prefer `make` targets over rediscovering framework-specific commands from scratch. The underlying command may be Hugo, Jekyll, Quarto, Python, R, Node, or something else, but the public interface should stay stable whenever practical.

## Environment Files

Use `.env.local` for machine-specific values such as local Python paths, conda environment names, Box or Drive roots, private data roots, API keys, or local executable overrides.

Track `.env.local.example` as documentation. Do not track `.env.local`.

Recommended setup flow:

1. Inspect `.env.local.example` to learn the expected variables.
2. Copy `.env.local.example` to `.env.local` if local configuration is needed.
3. Fill in project-specific local values.
4. Verify required paths and commands exist on the current machine.
5. Run the smallest validation command that confirms the environment is ready.

Agents should inspect `.env.local.example` and then check whether `.env.local` exists before environment-dependent work. If `.env.local` exists, inspect it before running `make` targets that may depend on local configuration. Do not print secrets or copy private values into tracked files. If the task depends on local configuration and `.env.local` is missing, ask for missing local values before guessing.

If the project uses an external Box, Drive, raw-data, private-data, or other external root, document the root variable in `.env.local.example` and keep the private value in `.env.local`. Projects may expose that root through an ignored `_data/` symlink for local browsing. See `docs/external-data-layout.md`.

## Related Repositories

When a project needs local context from another repository, expose that clone through an ignored `_repos/[repo-name]` symlink and document its machine-specific path with a variable in `.env.local.example`. The template keeps `_repos/README.md` tracked so fresh clones have the directory and its local-use guidance, while all local symlinks under `_repos/` remain ignored.

List configured links in `PROJECT_RELATED_REPOS` as `link-name:ENV_VAR` entries, where `link-name` is the `_repos/` entry and `ENV_VAR` is the variable that stores the clone path. For example, `PROJECT_RELATED_REPOS=example:PROJECT_EXAMPLE_REPO` creates or refreshes `_repos/example` from `$PROJECT_EXAMPLE_REPO` when `make setup` runs.

If the related repository is required for normal development, include it in `PROJECT_RELATED_REPOS` and let `make setup` verify the target. If it is optional, document the workflows that need it and avoid making unrelated targets fail when the clone is absent.

## Claude Code Configuration

The template ships `.claude/settings.json.example` as a starter for Claude Code's per-project configuration. The two most-used fields are `permissions.allow` (pre-approved Bash patterns) and `permissions.additionalDirectories` (paths outside the repository Claude Code may read). Mirror any external paths through `.env.local`.

Use `.claude/settings.json` for shared, committed configuration and `.claude/settings.local.json` for per-machine settings; the template's `.gitignore` excludes the latter. Copy the example file to whichever fits.

## Software and Package Setup

Work with the human maintainer to identify the software, system packages, language packages, and local tools needed for the project. Do not assume a particular toolchain when the repository has not documented one.

Agents and users may not already know the best current setup pattern. When tooling choices matter, search online for current official documentation and reputable community practice before recommending a package manager, environment manager, or repository structure.

At the beginning of a project, clarify:

- what the project should produce
- who will run the project and on which platforms
- whether the project needs scripts, a package, a website, reports, notebooks, or data pipelines
- which data roots, credentials, external services, or local tools are needed
- whether reproducibility, speed, compatibility, or ease of onboarding is the highest priority
- which systems must remain compatible with the chosen tooling

Use project-appropriate package managers and document the choice. Common examples include:

- Homebrew for macOS system tools.
- conda or micromamba for Python, R, and scientific computing environments.
- `pip`, `uv`, `poetry`, or `pipenv` for Python packages.
- `npm`, `pnpm`, or `yarn` for Node packages.
- Bundler for Ruby gems.
- language-native tools such as Cargo, Go modules, or renv.

For example, a newer tool may improve speed or lockfile behavior, while an older or more common tool may have better compatibility with institutional systems, deployment platforms, or collaborators' machines. Choose based on the project's use cases rather than tool popularity alone.

Prefer encoding setup in `make setup` or `make install` once the commands are known. If a tool must be installed outside the repository, document the command, version expectation, and verification step here or in a project-specific setup doc.

Before installing new software or packages, confirm that the dependency is needed, fits the project conventions, and will not conflict with the user's local setup. If network access, system-level installation, or writes outside the repository are required, ask for approval through the normal permission flow.

## PDF and Office Document Tools

Projects that inspect PDFs, render PDF pages, extract PDF metadata, convert Microsoft Office or OpenDocument files, or export office documents to PDF should document the relevant local tool paths in `.env.local.example`.

Common variables to adapt during project setup:

| Variable | Purpose |
| --- | --- |
| `PROJECT_POPPLER_BIN` | Directory containing Poppler command-line tools, such as `pdfinfo`, `pdftoppm`, and `pdftocairo` |
| `PROJECT_PDFINFO` | Path to the `pdfinfo` executable for PDF metadata checks |
| `PROJECT_SOFFICE` | Path to the LibreOffice `soffice` executable for command-line document, spreadsheet, presentation, and PDF conversion |
| `PROJECT_LIBREOFFICE_APP` | Path to the macOS LibreOffice app bundle when workflows need the Homebrew Cask app |

LibreOffice can open and save Microsoft Office formats, including Word, Excel, and PowerPoint Open XML files. Its Document Converter handles Microsoft Word, Excel, and PowerPoint sources, and the command-line conversion filters include Calc spreadsheet formats and PDF export. Use these capabilities for `.docx`, `.xlsx`, `.pptx`, OpenDocument, and PDF conversion workflows when they fit the project. Complex Office formatting, formulas, charts, macros, and layout features may require visual or automated verification after conversion.

Official references:

- [Using Microsoft Office and LibreOffice](https://help.libreoffice.org/latest/en-GB/text/shared/guide/ms_user.html)
- [Document Converter](https://help.libreoffice.org/latest/en-GB/text/shared/autopi/01130000.html)
- [File Conversion Filters Tables](https://help.libreoffice.org/latest/ug/text/shared/guide/convertfilters.html)

On Apple Silicon macOS with Homebrew-managed command-line tools and LibreOffice installed via Homebrew Cask, the common paths are `/opt/homebrew/bin` for Poppler tools, `/opt/homebrew/bin/pdfinfo`, `/opt/homebrew/bin/soffice`, and `/Applications/LibreOffice.app`. Intel Homebrew, conda environments, Linux packages, and manually installed app bundles may use different paths. Put the actual values in `.env.local`, and keep commands and tracked docs pointed at the variable names.

## Makefile Contract

Create or update `Makefile` when adopting this template. Keep targets small, predictable, and documented by `make help`.

Before running a `make` target, inspect `Makefile` and check whether required `.env.local` values are present. This avoids treating a failing command as discovery when the repository already documents the required environment.

Recommended targets:

| Task | Command |
| --- | --- |
| Show commands | `make help` |
| Prepare local environment | `make setup` |
| Install dependencies | `make install` |
| Start local preview or development server | `make dev` |
| Build or render the project | `make build` |
| Run tests | `make test` |
| Run lint checks | `make lint` |
| Apply formatting | `make format` |
| Remove generated artifacts | `make clean` |

Delete targets that truly do not apply, or keep them as documented no-ops if a consistent interface is more useful for the project.

When a project uses `_data/`, `make setup` should verify the external root and create or refresh the ignored `_data/` symlink when practical. When a project uses `_repos/`, `make setup` should verify each configured related clone and create or refresh the ignored `_repos/[repo-name]` symlink.

## Underlying Commands

Document the underlying commands here after adoption.

| Make target | Underlying command | Notes |
| --- | --- | --- |
| `make setup` | Create or refresh configured `_data/` and `_repos/` symlinks, then run project-specific setup checks | Add required local variables to `.env.local.example` before adoption |
| `make install` | `[install command]` | `[dependency notes]` |
| `make dev` | `[dev command]` | `[preview URL or behavior]` |
| `make build` | `[build command]` | `[output location]` |
| `make test` | `[test command]` | `[test scope]` |
| `make lint` | `[lint command]` | `[lint scope]` |
| `make format` | `[format command]` | `[what it changes]` |

If an agent discovers a command that should be reused, it should add or update a `Makefile` target rather than relying on a one-off shell command in future work.

## Automation Workflow

When a manual command sequence or editing pattern recurs, consider turning it into a script, `make` target, test, or project-specific workflow. This reduces variance across runs and users, improves consistency, and can avoid inefficient repeated computation.

Prefer adding a small deterministic script and exposing it through `make` over repeating ad hoc commands. Pair the automation with a test, fixture, or smoke check when practical. Document inputs, outputs, generated files, local configuration, and validation steps.

## Testing Workflow

For coding projects, `make test` should run the primary automated test suite. Tests should cover expected behavior with positive controls, failure behavior with negative controls, and edge cases that are easy to break.

Prefer adding or updating tests before implementation when practical. If the project has little or no test coverage, work with the human maintainer to identify the smallest meaningful testing scenario and document it in `docs/testing.md` or another focused project-specific doc.

For websites and rendered-output projects, `make build` is the minimum validation when practical. Add `make test` or `make lint` checks for broken links, missing assets, generated routes, or smoke tests when those checks become useful.

## Preview and Build Checklist

For visual or hosted-output changes:

- Start the local preview server with `make dev` if visual inspection is needed.
- Build locally with `make build` before publishing substantive changes.
- Check the changed output in the relevant viewer when practical.
- Confirm links, images, assets, and generated routes resolve when applicable.

For rendered document or notebook-style changes:

- Render the changed file when practical, preferably through a documented `make` target.
- Prefer rendering the source file without overriding its declared output format.
- Keep rendered artifacts out of git unless this project intentionally tracks them.
- Confirm external source files such as data, media, or source documents resolve from documented local config.

For external-data or inbox changes:

- Confirm `_data/` points to the documented external root when needed.
- Confirm `_repos/[repo-name]` points to the documented related clone when cross-repo context is needed.
- Keep `_inbox/` contents, `_data/`, and `_repos/` entries other than `_repos/README.md` ignored by git.
- Use `docs/inbox-triage.md` before moving incoming files.
- Refer to external files through the documented environment variable in tracked documentation.

For Markdown-only documentation changes:

- Review headings, links, relative paths, and remaining placeholders.
- Confirm docs agree with `README.md` and `AGENTS.md`.

## Generated Artifacts

Document which generated files should stay out of git after the project type is known.

For each generated path, record:

- which `make` target creates it
- whether it is safe to delete
- whether it should be ignored by git
- whether any generated artifact is intentionally tracked

Avoid broad ignore rules for file types that may also contain intentional source or published assets.

## Troubleshooting Notes

Record durable fixes here when local setup has project-specific constraints, such as a pinned Ruby version, a required Quarto extension, a specific Hugo module, or a Python environment needed for PDF tooling.
