# Agent Delegation

This document describes how a main agent hands substantial editing work to subagents that run in the background. It applies to agent tools that can start subagents, such as Claude Code. The goal is that the conversation with the person stays free for discussion and decisions while the editing happens elsewhere.

## When to Delegate

Delegate when a request needs substantial file editing, such as:

- changes across several files
- an implementation, with tests to write and run
- a long validation or test run
- a contribution to another repository, such as an upstream issue and pull request

Keep in the main conversation: quick lookups, reading a file to answer a question, a one-line edit the person is watching, and every decision that belongs to the person.

## What the Main Agent Does

1. Do the quick lookups needed to scope the work.
2. Ask the person the decisions the work depends on before starting it, so the subagent does not have to guess them.
3. Write a self-contained prompt, as described below.
4. Start the subagent in the background and tell the person what it is doing.
5. When the subagent reports, check the evidence in its report and relay the result: what changed, the validation run, and what is left for the person to decide.

## Writing the Prompt

Assume the subagent has not seen the conversation. The prompt states:

- **Goal:** the outcome wanted and why.
- **Decisions:** what the person has already decided, quoted when the wording matters.
- **Constraints:** conventions to follow, docs to read first, and privacy or public-repository rules that apply.
- **Files:** which files to read and change, and where to work, such as a branch or worktree.
- **What not to touch:** other clones or worktrees, files another agent is editing, and shared state.
- **Validation:** the `make` targets to run.
- **Outward actions:** the actions it may take that others can see, if any (see below).
- **Report:** files changed, commits, validation results, and anything skipped or unconfirmed, following "Reporting What Was Done" in `docs/integrity.md`.

## Outward-Facing Actions

A subagent stops before any action that others can see and the person has not approved, such as pushing a branch, opening or merging a pull request, filing an issue, posting a comment, or publishing a page. It leaves the work ready, for example as a local commit, and reports the action it would take next.

A subagent takes such an action only when its prompt authorizes that specific action. Only the person's approval counts. The main agent passes an approval along and does not grant one on its own.

## One Editor per File

Two agents editing the same files at once overwrite each other's changes or leave conflicts that are hard to untangle. Give each subagent its own branch, preferably in its own git worktree (see "Working in a Git Worktree" in `docs/local-development.md`), and give no two running agents the same files. The main agent does not edit files that a running subagent owns.

When two tasks must change the same file, run them one after the other. If they must run at the same time, keep the shared edits small and say in each pull request where they overlap.

To change a running subagent's task, send it a message when the tool supports that, instead of starting a second agent on the same files.
