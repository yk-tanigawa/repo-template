# Testing Guide

Use this document for coding projects, websites, rendered documents, scripts, data-processing workflows, and other projects where changes can be checked by executable commands.

## Core Principle

Prefer test-driven or test-aware development. Before changing behavior, identify what should work, what should fail, and how the repository can verify the difference.

When practical, write or update tests before implementation. For existing code without tests, first add a characterization test that captures current expected behavior, then make the smallest code change that satisfies the new expectation.

## Testing Scenarios

Work with the human maintainer to identify meaningful scenarios. Useful categories include:

- Positive controls: ordinary inputs that should succeed.
- Negative controls: invalid inputs that should fail clearly.
- Edge cases: empty inputs, missing fields, boundary values, unusual but valid inputs, and duplicated records.
- Regression cases: examples that previously failed or are easy to break.
- Integration paths: behavior that crosses files, modules, services, or rendering steps.
- User-facing checks: pages, commands, outputs, or files that a user is expected to inspect.

Avoid testing only the implementation detail. Test the behavior that matters to the project.

## Makefile Expectations

Expose testing through `make` whenever practical.

Recommended targets:

- `make test` for the primary automated test suite.
- `make lint` for static checks.
- `make build` for build, render, or packaging checks.
- `make dev` for local preview when visual inspection is needed.

Even small coding projects benefit from a `make test` target. If there is no test suite yet, the target can run the smallest meaningful check or explain what still needs to be configured.

## Website and Documentation Projects

For websites, the minimum validation is a successful build with `make build`. When practical, add checks for broken links, missing assets, route generation, or rendered page smoke tests.

For Markdown-only documentation changes, automated tests may be unnecessary. Still check relative paths, links, headings, placeholders, and consistency with `README.md`, `AGENTS.md`, and `docs/`.

For rendered documents, notebooks, or reports, run the relevant render command through `make build` or a project-specific target.

## Project-Specific Testing Docs

Create `docs/testing.md` or another focused project-specific doc when testing has durable conventions.

Document:

- what `make test`, `make lint`, and `make build` run
- required local setup or fixtures
- positive and negative control examples
- slow tests and how to skip or run them
- external services, data roots, or credentials
- expected artifacts and where they appear
- what must pass before a pull request or release

If a testing scenario is unclear, ask the human maintainer before inventing requirements.

## Handoff Checklist

When finishing coding work, report:

- tests added or updated
- positive, negative, and edge cases covered
- `make` targets run
- any skipped validation and why
- remaining test gaps or scenarios needing human judgment
