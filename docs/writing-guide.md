# Writing Guide

This document contains general writing guidance for documentation, README files, issues, pull requests, websites, notes, and other prose. It is intentionally project-neutral.

## Core Principles

Write for the next person who has to use the repository. That person may be a maintainer, a collaborator, an agent, or your future self.

Agents and users may not already know the clearest current writing conventions for a project type or audience. When writing standards matter, search online for reputable guidance such as field style guides, journal or venue instructions, documentation style guides, and examples from high-quality peer projects.

Prefer clear, direct prose. Use short sentences when possible. Put the main point early, then add the details needed to act on it.

Keep one paragraph focused on one main message. If a paragraph starts doing two jobs, split it.

Remove filler. If a sentence does not add information beyond the heading or surrounding paragraph, delete it.

Use concrete nouns and verbs. Prefer "Run `make build` before opening a pull request" over "Ensure appropriate validation has been performed."

Adapt the style to the intended use case. A lab website, API reference, scientific report, textbook note, grant text, and internal runbook may need different levels of detail, formality, citation, and assumed background.

Accuracy comes before style. Follow `docs/integrity.md` for factual claims and for reports of completed work in handoffs, issue comments, and pull requests.

## Sentence and Paragraph Style

These defaults apply to documentation, generated prose, project memos, and chat responses. Adopted projects can override them when a venue style guide demands otherwise.

- One paragraph per message. The first sentence of the paragraph carries the main point.
- Avoid zig-zag structure. Do not organize a paragraph using "X, not Y" framing. A direct positive statement that moves from the main idea to supporting details is usually clearer.
- Prefer a sequence of simple sentences over one long sentence. Break complex thoughts into multiple sentences when that improves clarity.
- Avoid em dashes. They often hide structure that should be made explicit with a period.
- Use explicit ISO dates such as `2026-04-19` when recording project status, manuscript versions, or correspondence.
- Preserve standard scientific formatting such as `APOE` for gene symbols even in plain Markdown.
- Use soft wrap rather than hard wrap in Markdown and other prose source files. Keep each paragraph on one source line and let the editor or viewer wrap it. Hard-wrapped paragraphs produce noisy diffs, because editing one sentence rewraps every line after it, which makes review harder and obscures the real change.

## Single Source of Truth

When a topic is unclear, improve the one place where it is canonically explained instead of repeating the explanation across files. Cross-file repetition makes documentation longer to read, easier to drift out of sync, and harder to maintain. From other locations, link to the canonical doc rather than restating its content.

This applies to general documentation as well as agent instruction files: top-level files such as `AGENTS.md`, `README.md`, and `CLAUDE.md` should route to the canonical doc instead of summarizing it. The same rule holds across `docs/` files: each topic should have one home.

## Structure

Use headings to help readers scan. Keep heading names literal and predictable.

Put the most frequently needed information first. Setup commands, source-of-truth files, and validation steps should be easy to find.

Use lists for steps, requirements, and checklists. Use prose for context, rationale, and tradeoffs.

When documenting a workflow, include:

1. When to use the workflow.
2. Inputs or prerequisites.
3. Commands or steps.
4. Expected output.
5. How to verify success.

## Templates and Evaluation Rubrics

For repeated writing tasks, use templates, rubrics, and checklists to improve consistency. This is the writing equivalent of automation in coding projects.

Examples include:

- manuscript evaluation templates
- grant review checklists
- lecture-slide review rubrics
- README or documentation templates
- peer-review response templates
- paper summary templates
- project proposal templates

For issue bodies and progress comments on an issue tracker, follow `docs/issue-comments.md`.

When preparing or reviewing a manuscript draft, consider creating a manuscript evaluation document with stable criteria. Reusing the same criteria helps evaluate writing quality consistently across drafts, sections, projects, and reviewers.

Good templates should state:

- the intended audience
- the document type and purpose
- the criteria used for evaluation
- required evidence, citations, or examples
- questions for the human author
- decisions or revisions that require human judgment

When a writing workflow repeats, add the template or rubric under `docs/`, `templates/`, or another documented project-specific location.

## Links and Paths

Use paths relative to the repository root, such as `README.md`, `AGENTS.md`, or `docs/local-development.md`.

Avoid machine-local absolute paths in tracked files. Put local roots in `.env.local` and document the variable name instead.

Use stable internal links when possible. If a link depends on a generated site URL, document where that URL is configured.

## References Involving a Private Repository

Any reference that involves at least one private repository needs care: a public repository mentioning a private one, a private repository mentioning another repository's issue, pull request, or commit, and one private repository mentioning another. This section is the canonical home for those rules and for the approval step before posting such text.

### Why the Rule Exists

**Private by default.** An agent cannot tell why a repository is private. Some private repositories will be published later, and others are meant to stay private for good. So, by default, share nothing about a private repository outside it, not even that it exists.

**References create links.** GitHub turns a reference such as `owner/repo#123`, `owner/repo@<sha>`, or a URL to an issue, pull request, or commit into a link. By default, a reference also generates a backlink: the referenced issue or pull request records a cross-reference in its timeline, pointing to the text that mentioned it. See GitHub's "Autolinked references and URLs" documentation. GitHub's documentation does not say who can see that backlink when the mentioning text is in a private repository, so do not rely on it staying hidden. This matters in three cases:

- **Public text that mentions a private repository.** The text shows the private repository's name to every public reader, even when the link does not open for them.
- **Private text that mentions another repository's thread.** The mention adds a backlink to that thread's timeline, so the other repository's thread now records that the private work exists.
- **One private repository mentioning another.** Either repository may become public later, and the link and its backlink would then expose the other. Until then, the two may have different audiences, and a reference can tell readers of one about work in the other.

The default follows from these cases. From any private repository, name another repository's threads in plain words, such as "owner/repo issue 123", instead of linking them or writing `owner/repo#123`. Keep a private repository's name, existence, and threads out of every other repository, public or private, so a plain-words reference to another private repository is also left out.

### What to Leave Out

This covers tracked files, commit messages, issue and pull request text, review replies, and code comments. Do not include:

- URLs to the private repository, its issues, pull requests, commits, or files
- cross-repository shorthand such as `owner/private-repo#123`
- the private repository's name, or paths to files inside it
- notes such as "adopted from" or "see the discussion in" that point to private work

When a change is adapted from private work, restate the reusable content in this repository and describe the change on its own terms.

If you are unsure whether a repository is public, check before writing the reference, for example with `gh repo view <owner>/<repo> --json visibility`.

### Exemptions

The rules above are the default. Only the owner of the private repository being referenced can relax them, for a specific reference, by an explicit written exemption, because that repository's existence is what the reference discloses. When the referencing repository is a different private repository, its owner agrees too. An agent never grants or assumes an exemption.

Record the exemption where the reference lives, in a tracked file of the referencing repository, such as a short "Exemptions" list in its docs. The record names the repositories, what is allowed (for example, naming the repository in plain words, or linking its threads), who granted it, and the date. A link to where it was granted is optional, and only if that link itself follows the rules in this section.

An exemption covers only what it names. It does not extend to public repositories unless it says so, and the approval step below still applies to each post. This template gives the mechanism only and records no exemptions.

### Before Posting or Pushing Text That Involves a Private Repository

These steps apply to every post or push in a public repository: opening, commenting on, or editing an issue or pull request, and pushing commits. They also apply in a private repository to any text that refers to another private repository, because there is no guarantee that either will stay private. Follow them in order:

1. **Clean the text.** Apply the list above: remove references, links, issue and pull request numbers, and paths from any private repository other than the one being posted to, except what a recorded exemption names (see "Exemptions"). Then search the changed text and the commit message for private repository names, owners, URLs, and `#[0-9]` references, and confirm that each remaining `#N` refers to the repository being posted to, and that every other remaining reference is covered by a recorded exemption.
2. **Get approval.** A person reads the cleaned text and approves it.
3. **Post.** The person posts it, or approves the agent posting it.

An agent does not post or push such text without that approval. When a permission check blocks an agent from posting or pushing, the agent hands the drafts and the exact commands to the person, who posts them. The agent does not look for another route around the block.

When a private repository is about to become public, follow `docs/public-release.md`.

## Personal Information

Use data minimization when writing about people. Prefer role labels such as "the student", "the trainee", "the collaborator", or "the instructor" when the person's identity is not needed.

Avoid repeating personal information across files. Keep private supervision notes, education records, health details, contact details, and other sensitive information out of tracked documentation unless the project explicitly requires it and the human maintainer confirms it is appropriate.

## Placeholders

Use bracketed placeholders sparingly, such as `[project name]` or `[build command]`. Remove placeholders when adopting this template in a real project.

If a placeholder requires a decision, document the question in `docs/project-specific-guidelines.md` or ask the human maintainer directly.

## Check Before Publishing

Before publishing documentation changes, check:

- The main point is easy to find.
- Paths are relative to the repository root.
- Commands match the `Makefile` or `docs/local-development.md`.
- Placeholders are intentional.
- The text does not assume private local paths or hidden context.
- The text and commit message follow "References Involving a Private Repository".
- The relevant validation step has been run or the reason for skipping it is recorded.
