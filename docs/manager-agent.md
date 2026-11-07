# Manager Agent

This document describes how an agent works with subagents and with the person it works for. It applies to agent tools that can start subagents running in the background, such as Claude Code.

## The Manager Model

The main agent acts as a manager. The person talks to the manager, and the manager works with its subagents. The manager stays available for conversation and decisions, hands substantial work to subagents, relays their results, and pauses and resumes the work when the person asks.

Subagents do not ask the person directly. A subagent that reaches a decision returns it to the manager, which asks the person and passes the answer back.

Delegation never relaxes the repository's rules. The manager and every subagent follow `AGENTS.md` and the docs it routes to, in the same way. The manager's prompt points a subagent to the relevant docs instead of restating their rules, and the manager checks each result against those docs before relaying it.

## Delegating Work

### When to Delegate

Delegate when a request needs substantial file editing, such as:

- changes across several files
- an implementation, with tests to write and run
- a long validation or test run
- a contribution to another repository, such as an upstream issue and pull request

Keep with the manager: quick lookups, reading a file to answer a question, a one-line edit the person is watching, and every decision that belongs to the person.

### What the Manager Does

1. Do the quick lookups needed to scope the work.
2. Ask the person the decisions the work depends on before starting it, so the subagent does not have to guess them.
3. Write a self-contained prompt, as described below.
4. Start the subagent in the background and tell the person what it is doing.
5. When the subagent reports, check its evidence and its work against the relevant docs, then relay the result: what changed, the validation run, and what is left for the person to decide.

### Writing the Prompt

Assume the subagent has not seen the conversation. The prompt states:

- **Goal:** the outcome wanted and why.
- **Decisions:** what the person has already decided, quoted when the wording matters.
- **Docs:** `AGENTS.md` and the docs that apply to the task, named by path. Point to them; do not restate their rules.
- **Files:** which files to read and change, and where to work, such as a branch or worktree.
- **What not to touch:** other clones or worktrees, files another agent is editing, and shared state.
- **Validation:** the `make` targets to run.
- **Outward actions:** the actions it may take that others can see, if any (see below).
- **Report:** files changed, commits, validation results, decisions for the person, and anything skipped or unconfirmed, following "Reporting What Was Done" in `docs/integrity.md`.

### Outward-Facing Actions

A subagent stops before any action that others can see and the person has not approved, such as pushing a branch, opening or merging a pull request, filing an issue, posting a comment, or publishing a page. It leaves the work ready, for example as a local commit, and reports the action it would take next.

In a private repository, a subagent takes such an action only when its prompt authorizes that specific action. Only the person's approval counts. The manager passes an approval along and does not grant one on its own. For text that involves another private repository, the prompt's authorization counts only when a person has approved the cleaned text, following "Before Posting or Pushing Text That Involves a Private Repository" in `docs/writing-guide.md`.

In a public repository, a subagent never posts, comments, edits an issue or pull request, or pushes, even when its prompt authorizes it. It returns drafts and a local commit, and the manager hands them to the person, following "References Involving a Private Repository" in `docs/writing-guide.md`.

### One Editor per File

Two agents editing the same files at once overwrite each other's changes or leave conflicts that are hard to untangle. Give each subagent its own branch, preferably in its own git worktree (see "Working in a Git Worktree" in `docs/local-development.md`), and give no two running agents the same files. The manager does not edit files that a running subagent owns.

When two tasks must change the same file, run them one after the other. If they must run at the same time, keep the shared edits small and say in each pull request where they overlap.

To change a running subagent's task, send it a message when the tool supports that, instead of starting a second agent on the same files.

## Pausing and Resuming

A session can end partway through a task, for example when a usage limit is close. When the person asks to pause, the manager and its subagents write handoff files, and a later session resumes from them.

### Where Handoffs Live

Handoff files go in `.claude/handoffs/` at the top level of the main checkout. Git ignores this directory (see `.gitignore`), because handoffs are working notes that may name local paths and decisions the person has not made yet.

An agent working in a linked git worktree, such as `.claude/worktrees/<name>`, still writes to the main checkout's directory. The worktree may be deleted before the work resumes, and the next session usually starts in the main checkout. The main checkout is the first entry of `git worktree list --porcelain`:

```bash
main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
mkdir -p "$main/.claude/handoffs"
```

### File Names

Name the manager's handoff `YYYY-MM-DD-HHMMSSZ-<session>.md`, with the time in UTC so names sort in order across machines and time zones. `date -u +%Y-%m-%d-%H%M%SZ` prints the time part. `<session>` is a short name for the task, such as `lint-target`.

A subagent's handoff uses the same session name followed by its agent name: `YYYY-MM-DD-HHMMSSZ-<session>-<agent>.md`. The manager gives the session name in the pause instruction.

### What a Handoff Contains

- **Task:** what the work is and why it was requested.
- **Done:** completed steps with their evidence, such as commit SHAs, branches, worktree paths relative to the main checkout, files changed, and test results.
- **In progress:** what was started and not finished, and the state it was left in.
- **Next step:** the exact next action, such as the command to run or the file and section to edit.
- **Open decisions:** questions waiting for the person.
- **Do not repeat:** outward actions already taken, such as pushes, issues, pull requests, comments, or submitted jobs, with their URLs or IDs.
- **Subagent handoffs:** in the manager's handoff only, the file name of each subagent's handoff.

Claims in a handoff follow "Reporting What Was Done" in `docs/integrity.md`.

### Pausing

When the person asks to pause:

1. The manager sends a pause instruction to every running subagent, with the session name and the handoff directory.
2. Each subagent stops at a safe point. No edit is left half applied, and its work is either committed on its branch or left as a clean diff that its handoff describes. It does not push or post in the middle of a step. It writes its handoff and reports the file name.
3. The manager waits for each subagent's report. A subagent that does not answer is listed in the manager's handoff with its state marked unknown, to check on resume.
4. The manager writes its own handoff, tells the person the file name, and stops.

### Resuming

1. List `.claude/handoffs/` in the main checkout. Read the newest handoff for the session and every subagent handoff it lists.
2. Check each claim against the current state before acting: `git status`, `git worktree list`, the branches and their latest commits, and the state of each named pull request and issue (`gh pr view`, `gh issue view`). The person or another session may have changed things since the pause. When the state disagrees with the handoff, trust the state and tell the person.
3. Ask the person the open decisions that are still open, then continue from the next step, delegating again as above.

### Resolved Handoffs

When the work a handoff describes is finished and its results are recorded where they belong, such as in commits, pull requests, and issue comments, delete the handoff. Delete the subagent handoffs it lists at the same time. The directory then holds only pending work, so a resuming agent can read everything in it.

Handoffs are untracked, so a deleted handoff cannot be recovered. Check that nothing in it is still pending before deleting it.
