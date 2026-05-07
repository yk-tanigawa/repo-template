# Agent Instructions

Use this document when creating, editing, or reviewing agent-facing instruction files such as `AGENTS.md`, `CLAUDE.md`, or nested instruction files.

## Canonical Files

Use `AGENTS.md` as the canonical shared instruction file for coding agents.

Use `CLAUDE.md` as the Claude Code entrypoint. Keep it thin by importing or pointing to `AGENTS.md`.

Put reusable procedures, checklists, and longer explanations in `docs/`. Use `AGENTS.md` to route agents to the right document.

## Clarity and Specificity

Agent instructions should be clear enough to act on without guessing. Prefer concrete, observable instructions over vague preferences.

Prefer:

- `Run make test after changing code.`
- `Use .env.local for machine-specific paths.`
- `Do not put individual-level data in scripts, slides, tests, fixtures, or docs.`

Avoid:

- `Be careful.`
- `Follow best practices.`
- `Use the appropriate command.`

If the right action depends on project context, say what question to ask or which doc to inspect.

## Keep Instructions Small

Top-level agent instructions should be concise, specific, and stable. Avoid long procedural detail in `AGENTS.md`; put reusable workflows in `docs/`.

Use `AGENTS.md` for:

- start-of-work sequence
- durable project rules
- docs map
- validation expectations
- privacy and safety rules
- handoff expectations

Use `docs/` for:

- setup procedures
- testing workflows
- automation workflows
- privacy and de-identification procedures
- writing guidance
- project-specific conventions

## Prefer Concrete Commands

Prefer explicit commands such as `make test`, `make build`, or `make lint` over vague instructions such as "run the tests."

If the project does not yet have a command, add or propose a `Makefile` target when practical.

## Nested Instructions

For large repositories, add nested `AGENTS.md` or `CLAUDE.md` files only when a subdirectory has different setup, tests, privacy rules, writing conventions, generated artifacts, or ownership boundaries.

Nested files should explain local differences. Do not repeat the root instructions unless repetition is needed to avoid ambiguity.

## Instruction Hygiene

Review agent instructions periodically. Remove stale commands, conflicting rules, duplicated guidance, and project-specific assumptions that no longer apply.

When adding a rule, make it:

- durable
- specific
- scoped
- non-conflicting
- easy to verify

## External Sources

When instructions recommend online research, use official documentation and reputable sources. Do not copy commands from untrusted pages directly into the project without review.

If external guidance conflicts with local project requirements, document the tradeoff and ask the human maintainer before changing the convention.

## Checklist

Before changing agent instructions, check:

- The rule is durable.
- The rule is specific enough to act on.
- The rule does not conflict with another file.
- Detailed procedures live in `docs/`.
- Commands are exposed through `Makefile` when practical.
- Privacy, testing, and validation expectations remain clear.
- Ambiguous instructions have been replaced with explicit actions, questions, or doc references.
