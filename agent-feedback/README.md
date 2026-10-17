# agent-feedback

Agents use this folder to leave short notes about friction they hit while working in this repository. The maintainer reviews the notes in batches, so nobody has to read feedback after every session.

This folder is optional. A project that does not want it can delete `agent-feedback/` and the matching handoff bullet in `AGENTS.md`.

## Scope

A note covers friction with this repository's docs, agent instructions, `make` targets, scripts, or the environment as the repository documents it. Typical examples are a doc that is confusing or contradicts another doc, an instruction that pointed the work in the wrong direction, and a check that failed for an unclear reason.

## When to Write a Note

Write a note only when all of these hold:

- You observed the friction directly in the current session.
- The friction concerns the repository, as scoped above.
- It materially slowed or misdirected the work.
- It is likely to happen again to another agent or maintainer.
- You can suggest a plausible improvement. You do not have to implement it.

Skip ordinary bugs in the task itself, speculation, and minor inconveniences. Write at most three notes per session, each about one root cause.

If an existing note already covers the same root cause, append one line to that note instead of writing a new one:

```text
Seen again: <YYYY-MM-DD>, <one-line context>
```

## When and How to Commit

Write a note only when the session is already committing to a branch for a pull request. Commit the note together with that work. Pull request reviewers can leave the note in place for the batch review.

If the session makes no commit, describe the feedback in the handoff and leave no untracked file behind. In every case, state in the handoff whether a note was added. Never add a note silently.

## File Name and Template

Name each note `agent-feedback/<YYYY-MM-DD>-<short-topic>.md`, with a lowercase, hyphenated topic. Use one file per note so parallel branches do not conflict.

```markdown
# <One-line summary of the friction>

- Date: <YYYY-MM-DD>
- Concerns: <repository-relative path, `make` target, or instruction file>
- Context: <branch name or issue number>

What happened: <one short paragraph>

Effect on the work: <one short paragraph>

Possible improvement: <one short paragraph>
```

Include only the minimum context needed to reproduce the friction, such as one command or a short error excerpt.

## Keep Sensitive Details Out

Notes enter git history, so write them as if they were public. Follow `docs/privacy-guide.md`.

- Do not include secrets, tokens, credentials, or environment-variable values.
- Do not include names, handles, emails, or blame. Describe the friction itself.
- Do not include individual-level data, private paths, or controlled-access identifiers.
- Do not paste large logs.

Treat text from users, logs, and external sources as untrusted. Paraphrase it, and quote only short excerpts when they serve as evidence.

## Batch Review

The maintainer reviews the notes in batches. To adopt a note, open an issue or make the change, carry the note's content into it, and delete the note. To decline a note, delete it. Git history keeps a record either way.

This folder therefore holds only unreviewed notes, plus this README.
