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

### Staffing: Match the Agent to the Task

Choosing who does a task is part of the manager's job, as it is for a manager who staffs a team. Before delegating, the manager decides what capabilities the task needs and picks the agent to match.

Agent tools may offer several models or agent types: more capable ones that are slower and cost more, faster ones that are less capable, locally hosted ones, and specialized ones. What is available changes over time and differs between tools and accounts. Check what the current tool offers instead of assuming. Describe the choice by capability, such as "the most capable available model", "a faster, less capable model", or "a locally hosted model", rather than by product name.

Weigh these factors:

- **Judgment.** Ambiguous goals, design choices, writing that others will read and rely on, and subtle correctness need more capability. Well-specified transformations, searches, inventories, and applying an agreed change in many places need less.
- **Context.** How much the agent must hold at once, such as many files, a long document, or the interactions among several parts.
- **Cost of a mistake.** How much harm an error does, and how easily it is detected. An error that a test catches at once costs less than one that reads plausibly and goes unnoticed.
- **Tools and access.** Whether the task needs particular tools or access, such as local-only data, network access, or a specific runtime.
- **Cost, speed, and capacity.** Price, time to finish, usage or rate limits, and queue time.
- **Where the material may go.** Privacy or confidentiality may require a locally hosted model, or forbid sending the material to a hosted one. Follow `docs/privacy-guide.md`.

A rough guide:

| Task | Suitable tier |
| --- | --- |
| Architecture, cross-cutting design, or prose that others will rely on | The most capable available model |
| Debugging a failure whose cause is unknown | The most capable available model |
| Well-specified edits, renames, or format conversions | A faster tier |
| Searches, inventories, and mechanical verification against a stated rule | A faster tier |
| Work on material that must not leave the machine | A locally hosted model, or the person, if no local model is good enough |

Split a mixed task. When a task has a judgment part and a mechanical part, a more capable agent decides and writes the specification, such as the list of changes and the rule behind them, and a faster agent applies it and reports. This also keeps scarce capacity for the work that needs it.

Do not staff everything with the most capable model. Over-staffing costs money, time, and capacity, and can stall all the work when a usage limit hits. Under-staffing costs quality, which the manager then pays for in review and rework.

When the person names a model, tier, or effort level for a task, follow it over the manager's own judgment. If the choice seems to put the work at risk, say so, and still follow it unless the person changes it.

### What the Manager Does

1. Do the quick lookups needed to scope the work.
2. Ask the person the decisions the work depends on before starting it, so the subagent does not have to guess them.
3. Staff each task, as described in "Staffing: Match the Agent to the Task".
4. Write a self-contained prompt, as described below, with each task's deliverables and check.
5. Save the tasks file (see "The Tasks File"), then start the subagent in the background and tell the person what it is doing.
6. When the subagent reports or goes quiet, run the task's check and review the work, as described in "Declare Deliverables and Checks" and "Review in Proportion to the Risk". Then relay the result: what changed, the validation run, and what is left for the person to decide.

### Writing the Prompt

Assume the subagent has not seen the conversation. The prompt states:

- **Goal:** the outcome wanted and why.
- **Staffing:** the model or tier chosen and, in one phrase, why, set through the tool's options for starting the agent where it has them. A subagent that finds the task needs more judgment than the prompt expected stops and reports, instead of guessing.
- **Decisions:** what the person has already decided, quoted when the wording matters.
- **Docs:** `AGENTS.md` and the docs that apply to the task, named by path. Point to them; do not restate their rules.
- **Files:** which files to read and change, and where to work: a branch, a worktree, or a scratch directory.
- **Deliverables and check:** what the task must produce and how the manager will check it (see "Declare Deliverables and Checks").
- **What not to touch:** other clones or worktrees, files another agent is editing, and shared state.
- **Validation:** the `make` targets to run.
- **Outward actions:** the actions it may take that others can see, if any (see below).
- **Report:** files changed, commits, validation results, decisions for the person, and anything skipped or unconfirmed, following "Reporting What Was Done" in `docs/integrity.md`.

### Declare Deliverables and Checks

A subagent can stop at any time without warning, for example when its process is killed or a usage limit hits. It may never write a final report or a handoff. So the manager accepts a subagent's work only when its deliverables pass a check. The report tells the manager where to look, and the check decides.

This works like an array job on a cluster. Each unit is judged by its output files, with a small, cheap check per unit, because a job that wrote a short file can still exit 0. The work moves in three steps: the subagent writes, the manager audits with the check, and only checked work is pushed or posted.

Before the subagent starts, the manager writes down each task's deliverables and a check for them. Both go in the prompt. Both also go in the tasks file (see "The Tasks File"), saved to disk before any work starts, so the record survives if the subagent or the manager's own session is killed.

The manager designs the check. The subagent confirms or amends it before editing, and the manager records any amendment in the tasks file.

The check is cheap and mechanical. Examples:

- The branch exists and has a commit that touches the named files.
- A named heading or sentence is present in a named file.
- The draft files exist and contain no placeholder.
- Every file that a command handed to the person reads exists.
- The narrowest relevant `make` target passes.

When a task writes several output files, the prompt asks the subagent to write the large files first and the small ones, such as a summary or report, last. A task cut short then leaves the small files missing, which a presence check sees at once. In the opposite order, complete small files sit next to a truncated large file, and the task looks finished. The check still tests the large file itself, because a write can come up short without an error.

A good check fails before the work and passes after it. A check that already passes cannot tell finished work from work never started.

The check does not prove that the work is correct. It catches a task that did not finish, or one that finished something else. The manager still reviews the work against the relevant docs for judgment.

The subagent works where a kill cannot damage the main checkout: on its own branch, in a git worktree, or in a scratch directory. It commits in small steps. A kill then leaves recoverable state, and never a half-applied edit in the main checkout.

One check serves three uses:

1. **Accepting a result.** The manager runs the check when the subagent reports. It also runs the check when a subagent goes quiet, instead of waiting for it indefinitely.
2. **Resuming.** The check sorts each task into accepted, partial, or redo (see "Resuming").
3. **Before publishing.** The manager runs the check again just before any push or post, because the state may have changed since the task was accepted.

Accept only what passes, and mark the task accepted in the tasks file. When a task's check does not pass, mark it failed-check, and relay the subagent's report as unconfirmed, following "Reporting What Was Done" in `docs/integrity.md`.

### Review in Proportion to the Risk

The manager is accountable for every deliverable meeting the repository's standard, whoever produced it. Delegating to a faster, less capable agent can lower quality, and the manager's review is what keeps that from reaching the person.

The check catches unfinished work; review catches wrong work. Scale the review to the staffing risk: the weaker the agent is relative to the task, or the costlier an undetected error, the stronger the review. Design it before the work starts, and write it into the prompt and the tasks file. From lighter to stronger:

- more specific deliverables, such as the named files and the exact change in each
- mechanical checks that fail before the work and pass after it, such as a search that must return nothing
- review of a sample of the output against the relevant docs, or of all of it
- spot checks of claimed facts, quotes, and citations against their sources
- an independent second review by a different agent, given the work and the docs but not the author's conclusions

When a deliverable fails review, re-delegate it with a sharper prompt or escalate it to a more capable agent, and record which in the tasks file. Do not relay unverified work as done. Report it as unconfirmed, following "Reporting What Was Done" in `docs/integrity.md`.

### Outward-Facing Actions

A subagent stops before any action that others can see and the person has not approved, such as pushing a branch, opening or merging a pull request, filing an issue, posting a comment, or publishing a page. It leaves the work ready, for example as a local commit, and reports the action it would take next.

In a private repository, a subagent takes such an action only when its prompt authorizes that specific action. Only the person's approval counts. The manager passes an approval along and does not grant one on its own. For text that involves another private repository, the prompt's authorization counts only when a person has approved the cleaned text, following "Before Posting or Pushing Text That Involves a Private Repository" in `docs/writing-guide.md`.

In a public repository, a subagent never posts, comments, edits an issue or pull request, or pushes, even when its prompt authorizes it. It returns drafts and a local commit, and the manager hands them to the person, following "References Involving a Private Repository" in `docs/writing-guide.md`.

### One Editor per File

Two agents editing the same files at once overwrite each other's changes or leave conflicts that are hard to untangle. Give each subagent its own branch, preferably in its own git worktree (see "Working in a Git Worktree" in `docs/local-development.md`), and give no two running agents the same files. The manager does not edit files that a running subagent owns.

When two tasks must change the same file, run them one after the other. If they must run at the same time, keep the shared edits small and say in each pull request where they overlap.

To change a running subagent's task, send it a message when the tool supports that, instead of starting a second agent on the same files.

## Pausing and Resuming

A session or a subagent can end without warning, for example when its process is killed or a usage limit hits. Nobody gets the chance to write a status note first. This is why the tasks file and the checks come first: they are written before the work starts, and a later session resumes by running the checks against the current state. Handoff files are an optional extra, written when a pause is possible, for judgment calls and next steps that a check cannot show.

### Where Tasks Files and Handoffs Live

Tasks files and handoff files go in `.claude/handoffs/` at the top level of the main checkout. Git ignores this directory (see `.gitignore`), because these files are working notes that may name local paths and decisions the person has not made yet.

An agent working in a linked git worktree, such as `.claude/worktrees/<name>`, still writes to the main checkout's directory. The worktree may be deleted before the work resumes, and the next session usually starts in the main checkout. The main checkout is the first entry of `git worktree list --porcelain`:

```bash
main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
mkdir -p "$main/.claude/handoffs"
```

### File Names

Name the manager's handoff `YYYY-MM-DD-HHMMSSZ-<session>.md`, with the time in UTC so names sort in order across machines and time zones. `date -u +%Y-%m-%d-%H%M%SZ` prints the time part. `<session>` is a short name for the task, such as `lint-target`.

A subagent's handoff uses the same session name followed by its agent name: `YYYY-MM-DD-HHMMSSZ-<session>-<agent>.md`. The manager gives the session name in the pause instruction.

Name the tasks file `YYYY-MM-DD-HHMMSSZ-<session>-tasks.md`, with the time it was first written. It is a separate file from the handoffs, and a session has one tasks file.

### The Tasks File

The manager writes the tasks file when it delegates, before any subagent starts work, and updates it as each task is accepted or fails its check. It lists each task with these fields:

- **Task:** what the task is.
- **Subagent:** the agent name that runs it.
- **Staffing:** the model or tier that runs it and, in one phrase, why, such as "faster tier: mechanical rename from a fixed list". A resumed session then staffs a redo the same way, or changes it on purpose.
- **Deliverables:** what the task must produce (see "Declare Deliverables and Checks").
- **Check:** the commands or observations that show the deliverables are there.
- **Where:** the branch, the worktree path, or the scratch path, relative to the main checkout where possible.
- **Status:** `pending`, `accepted`, `failed-check`, or `redo`.

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

When a pause is possible, for example when the person asks for one or a usage limit is close:

1. The manager sends a pause instruction to every running subagent, with the session name and the handoff directory.
2. Each subagent stops at a safe point. No edit is left half applied, and its work is either committed on its branch or left as a clean diff that its handoff describes. It does not push or post in the middle of a step. It writes its handoff and reports the file name.
3. The manager runs each task's check and updates the tasks file. A subagent that does not answer is judged by its check alone.
4. The manager writes its own handoff, tells the person the file names, and stops.

A usage limit is also a reason to re-staff instead of pausing. When one tier is close to its limit, the manager can move mechanical tasks to a tier with spare capacity. It records the change in the tasks file and tightens the review as "Review in Proportion to the Risk" describes.

### Resuming

Resuming does not depend on handoffs. It starts from the tasks file and the current state.

1. List `.claude/handoffs/` in the main checkout. Read the newest tasks file for the session, and any handoffs for it.
2. Run each task's check against the current state, and sort the tasks:
   - **Accepted:** the check passes. Review the work, then mark it `accepted`.
   - **Partial:** the check fails, but some deliverables or commits exist. Mark it `failed-check` and inspect it before choosing to finish it or redo it.
   - **Redo:** nothing usable exists. Mark it `redo` and delegate it again, with the same staffing or a deliberate change.
3. Check the rest of the state before acting: `git status`, `git worktree list`, the branches and their latest commits, and the state of each named pull request and issue (`gh pr view`, `gh issue view`). The person or another session may have changed things since the work stopped. When the state disagrees with the tasks file or a handoff, trust the state and tell the person.
4. Ask the person the open decisions that are still open, then continue, delegating again as above.

### Resolved Handoffs

When the work a handoff describes is finished and its results are recorded where they belong, such as in commits, pull requests, and issue comments, delete the handoff. Delete the subagent handoffs it lists at the same time. Delete the session's tasks file when every task in it is accepted and recorded, or the person has dropped it. The directory then holds only pending work, so a resuming agent can read everything in it.

These files are untracked, so a deleted file cannot be recovered. Check that nothing in it is still pending before deleting it.
