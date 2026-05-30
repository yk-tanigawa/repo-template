# Inbox Triage

Use this workflow when files arrive in `_inbox/` and need to be moved to either tracked repository sources or the external `_data/` tree.

## Core Rule

Files in `_inbox/` are temporary. Classify them promptly, move them to the right home, and leave `_inbox/` empty unless a handoff explicitly records why a file remains.

Default to external storage when a file is sensitive, large, generated, received from a third party, a prior version, binary source material, raw data, or not clearly meant to become tracked source of truth. Move a file into the tracked repo only when it is small, reusable, privacy-safe source material that fits the documented repository layout.

## Before You Start

Read `docs/privacy-guide.md`, `docs/repository-layout.md`, and `docs/external-data-layout.md`. If `_data/` is missing and the task depends on external storage, inspect `.env.local.example` and `.env.local` before running `make setup` or asking for the missing local root.

List incoming files without printing contents:

```bash
find _inbox -maxdepth 2 -type f -print | sort
```

Check file type and size before opening a file body:

```bash
file "_inbox/FILE"
du -h "_inbox/FILE"
```

Inspect contents only as much as needed to classify the file. Prefer filenames, titles, page headers, metadata, or sheet names over full body text when privacy may matter.

## Destination Rules

Move a file into the tracked repo only when all of these are true:

- it is authored project source, not a raw input, scanned original, generated output, binary source file, or prior version
- it is small enough for git
- it contains no private correspondence, individual-level records, sensitive identifiers, restricted source material, credentials, financial details, HR details, or other project-protected data
- it belongs under an existing documented source directory

Move a file into `_data/` when any of these are true:

- it contains or may contain sensitive, private, access-controlled, individual-level, or third-party material
- it is a large PDF, DOCX, spreadsheet, slide deck, exported document, raw dataset, media file, screenshot, or prior planning draft
- it is useful for project memory but should be referenced rather than versioned
- the right destination is unclear and storing it in git would be hard to undo safely

Use `docs/external-data-layout.md` as the canonical reference for external subfolders. If no documented category fits, create a narrowly named subfolder under `_data/` and update the external-data documentation when the category is durable.

## Move Procedure

Create the destination directory when needed:

```bash
mkdir -p "_data/DESTINATION"
```

Move the file:

```bash
mv "_inbox/FILE" "_data/DESTINATION/"
```

For files that belong in the tracked repo, move them to the appropriate repo directory, then review the file for privacy, paths, and source-of-truth fit before staging.

If a tracked doc needs to mention an external file, summarize it at a high level and reference it through the configured environment variable, such as `$PROJECT_EXTERNAL_DATA_ROOT/path/to/source-file.ext`.

## Verification

After triage, run:

```bash
find _inbox -maxdepth 2 -type f -print | sort
git status --short
git status --ignored --short _inbox _data
git diff --check
```

Expected results:

- `_inbox/` has no remaining files unless the handoff explains why
- `_data/` remains ignored
- `git status --short` shows only intentional tracked source or documentation changes
- no sensitive or large `_inbox/` file appears as an untracked repo file

## Handoff

Report which files were moved, their destination directory, docs updated, validation performed, and any files left in `_inbox/` with the reason.
