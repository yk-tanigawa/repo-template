# Issue Comments

This document describes how to write an issue body and progress comments on an issue in GitHub or a similar tracker. It applies to people and agents. The goal is that anyone can tell where an issue stands by reading its latest comment.

## Status Words

Many trackers record only whether an issue is open or closed. Record a finer status as the first line of each progress comment, using one of these words:

| Status | Meaning |
| --- | --- |
| `todo` | The work is agreed and actionable. Nobody has started it. |
| `in_progress` | Someone is actively working on it. Name that person. |
| `in_review` | The work waits on a named person's review, decision, or approval. A request to nobody in particular does not count. |
| `blocked` | The work cannot continue until something specific changes. Name the blocker and who must act. Link the blocking issue if there is one. |
| `done` | The work is complete and needs no follow-up. Close the issue in the same step. |

A `done` comment lists no follow-up work. If follow-up remains, keep a status other than `done`. You can also open a new issue for the follow-up, link it, and then close the original issue.

An adopting project may rename these words or map them to tracker labels. If it does, it updates the table in this file so the table stays the single source of truth.

## Comment Format

Start with a status line. It holds the status word and a brief reason. For `in_progress`, `in_review`, and `blocked`, it also names who acts next.

Follow the status line with short bullets for what is done, what remains, what blocks progress, and the next action with its owner. Omit any bullet that would be empty. Every progress comment states the next action and its owner.

Example:

```markdown
in_review: waiting on @owner to approve the new build step.

- Done: added a `make lint` target and documented it in `docs/local-development.md` (#14).
- Remaining: run the lint target in CI after approval.
- Next: @owner reviews #14.
```

## Content Rules

- Refer to issues and pull requests as `#N`. Refer to files by repository-relative path.
- Report only what changed since the last comment.
- Put long logs or output in a file, gist, or CI run, and link to it.
- Do not repeat a `blocked` comment when nothing has changed. Comment again only when there is new information, such as a reply, a status change, or the blocker clearing.
- Follow "Reporting What Was Done" in `docs/integrity.md` for claims about completed work.

## Issue Body and Comments

The issue body holds the current plan. When the plan changes, edit the body and add a comment that says what changed in it. Comments record progress and decisions over time.

## Comments Written With an Agent

When an agent posts a comment on a person's behalf, the comment starts with a line that says so, such as "Written with Claude Code". When the comment records that person's decisions, keep their decisions in a separate section from the agent's own notes.
