# External Data Layout

Use this document when a project needs local files that should not live in git, such as Box or Drive folders, received files, raw data, binary source files, private notes, generated extracts, or individual-level material.

## Core Rule

Tracked files are the source of truth for project code, documentation, small reusable source material, and privacy-safe working records. External storage is the source of truth for material that is sensitive, large, received from third parties, machine-local, generated, or not appropriate for git history.

Do not copy external material into tracked files unless the human maintainer explicitly approves it and the project privacy rules allow it. Prefer a short summary plus a path that uses a documented environment variable.

## Root Variable

Each adopted project should choose a project-specific variable for its external root, such as `$PROJECT_EXTERNAL_DATA_ROOT`, `$PROJECT_BOX_ROOT`, or a more specific project prefix. Document that variable in `.env.local.example` and set the private machine-local value in `.env.local`.

Tracked files should reference external paths through the variable, for example:

```text
$PROJECT_EXTERNAL_DATA_ROOT/path/to/source-file.ext
```

Do not put machine-local absolute paths in tracked files.

## `_data/` Symlink

Projects may use `_data/` as a convenience symlink from the repository root to the configured external root:

```text
_data -> $PROJECT_EXTERNAL_DATA_ROOT
```

The `_data/` path is ignored by git. It exists only on machines where the external folder is available. Use `_data/` for local browsing and shell commands. In tracked documentation and scripts, prefer the environment variable path so the reference remains meaningful when the symlink is absent.

The leading underscore keeps the external-data link near `_inbox/` in file browsers and reduces confusion with project source directories named `data`.

## What Belongs Outside Git

Store these categories under the external root unless a project-specific doc explicitly says otherwise:

- received files, external source documents, and prior versions
- raw datasets, individual-level records, private notes, and access-controlled files
- large binaries such as PDFs, DOCX files, slide decks, scans, media, and screenshots
- source documents that should be cited or summarized rather than versioned
- generated extracts and intermediate files that are useful locally but not published source
- machine-local exports, downloads, and prior versions

Store only small, reusable, privacy-safe source material in git.

## Project-Specific Subfolders

Adopted projects should document their actual external subfolders only after the structure is known. Keep those details in this document or in a focused project-specific data-management doc.

For each durable external subfolder, document what belongs there, what must stay out, which tracked files may reference it, and which command validates or refreshes it when one exists.

When a tracked file needs to cite external material, use the project-specific environment variable and a concise source description. Do not paste private correspondence, individual-level records, access-controlled source text, or large extracted content into tracked files.

## Validation

For changes involving external data layout:

- confirm `.env.local.example` documents the root variable
- confirm `_data/` and external outputs are ignored by `.gitignore`
- run `git status --short` and check that external files are not untracked
- run `git status --ignored --short _data _inbox` when triaging local files
- update this document or a project-specific data-management doc when the external folder structure changes
