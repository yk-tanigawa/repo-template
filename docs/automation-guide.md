# Automation and Repeated Work

Use this document when a project has repeated manual steps, recurring checks, generated files, data-processing workflows, report builds, release steps, or other tasks that are easy to perform inconsistently by hand.

## Core Principle

Agents and maintainers should notice repeated manual labor and consider whether it should become an automated script, `make` target, documented checklist, or reproducible pipeline.

Automation reduces variance, improves consistency, makes review easier, and can improve computing efficiency by avoiding repeated ad hoc work. Good automation should also be testable, so pair scripts and workflows with tests, fixtures, or smoke checks when practical.

## When to Automate

Consider automation when:

- the same command sequence is run more than once
- manual steps affect generated outputs
- a task is easy to forget or perform in the wrong order
- a step touches many files or records
- consistency matters across users, machines, or runs
- a task is slow and could be cached, parallelized, or scoped
- a task handles sensitive data and should avoid manual inspection
- a check should run before pull requests or releases

Not every task needs a large framework. A short script plus a `make` target is often enough.

## Preferred Forms

Use the lightest durable mechanism that fits the task:

- `Makefile` targets for common commands and workflows.
- Small scripts for deterministic transformations.
- Project-specific docs for procedures that need human judgment.
- Tests and fixtures for repeated behavior checks.
- CI jobs for checks that should run on every pull request.
- Data pipelines or workflow tools when dependency tracking, caching, or parallel execution matters.

Expose reusable automation through `make` whenever practical.

For documentation and writing projects, the equivalent of automation may be a reusable template, rubric, or checklist rather than a script. For example, manuscript drafts can be evaluated with the same manuscript evaluation template across revisions so writing quality is judged against consistent criteria.

## Testing and TDD

Automation and test-driven development reinforce each other. Before automating behavior, identify the expected result, at least one positive control, and relevant negative or edge cases.

When practical, write or update tests before implementing the automation. If full tests are too heavy, add a smoke check that verifies the command runs on a small fixture and produces the expected output.

Useful targets include:

- `make test` for automated behavior checks.
- `make build` for generated outputs or rendered artifacts.
- `make lint` for static checks.
- a project-specific `make` target for expensive full workflows.

Document what each automated workflow verifies, not just what command it runs. See `docs/testing-guide.md` for the broader testing approach.

## Designing Automation

Good automation should be:

- deterministic for the same inputs
- documented with expected inputs and outputs
- narrow enough to review
- safe to rerun
- explicit about generated files
- clear about which local configuration it needs
- efficient enough for regular use

If a task is computationally expensive, document how to run a small smoke test and how to run the full workflow.

## Agent Behavior

When agents see repeated manual steps, they should suggest automation before repeating the same work many times.

For repeated writing or review work, agents should suggest templates, rubrics, or checklists before improvising a new evaluation each time.

Before adding automation, agents should clarify:

- which parts are deterministic
- which parts require human judgment
- which positive controls, negative controls, or edge cases should verify the workflow
- which command should appear in `Makefile`
- which inputs and outputs should be tracked
- which generated files should be ignored
- which tests or smoke checks should verify the automation

After adding automation, document it in `docs/local-development.md` or a focused project-specific doc.
