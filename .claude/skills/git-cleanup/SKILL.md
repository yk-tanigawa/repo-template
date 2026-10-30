---
name: git-cleanup
description: Use when local git worktrees or branches have piled up in a checkout of this repository and the person wants to tidy them, such as "clean up old branches", "remove merged worktrees", "what can I delete in .claude/worktrees", or after a batch of pull requests merges. Runs the dry-run cleanup script, shows what it would delete, and leaves the deletion and any remote-branch deletion to the person.
---

# Clean Up Merged Branches and Worktrees

Canonical doc: `docs/local-development.md` ("Git Housekeeping"). Read it before running anything. This skill gives the order of the steps and holds no rules of its own.

## What you decide

These stay with the person; ask, do not choose:

- whether to run `--execute` after reading the dry run;
- whether any unmerged branch can be dropped with `--include-unmerged`;
- whether to delete the remote branches the script lists.

## Steps

1. Fast-forward `main` first, so "in origin/main" reflects what has merged.
2. Run the dry run, `make git-cleanup`, and show its whole output: the DELETE and KEEP lines, the unmerged commits, the remote list, and any note that open pull requests were not checked.
3. For each unmerged branch, say what its commits are and whether they reached `main` another way (for example, a squash merge, or a pull request merged into another branch instead of `main`). Do not call a branch safe to drop without that check.
4. For a worktree kept for uncommitted changes, compare those changes with `main` and report the result; do not discard them.
5. Give the person the commands to run: `make git-cleanup` with `GIT_CLEANUP_ARGS=--execute` (and `--include-unmerged` only if they chose it), and the printed `git push origin --delete` line for remote branches. They run these themselves, for example with `!` in the Claude Code prompt.
6. After they run it, run the dry run again and report what is left.
