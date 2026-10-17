# Integrity

This document applies to every project. It covers accurate claims in prose and honest reports of work. The `## Scientific and Scholarly Claims` section applies to projects with scientific, scholarly, clinical, biomedical, statistical, or data-driven content. A project without such content trims that section during adoption and keeps the rest.

## Core Rule

Accuracy comes before style. Public-facing prose, notes, summaries, reports, figures, citations, and metadata should faithfully reflect the source material and the work that was actually done.

Do not invent facts, claims, affiliations, funding details, dates, sample sizes, methods, results, citations, conclusions, or outcomes of actions.

## Reporting What Was Done

A report of work is a factual claim and follows the core rule. This includes handoffs, issue comments, pull request descriptions, and job or run summaries, whether a person or an agent writes them.

- **Name the evidence.** Claim an action only after you see it take effect, and say what showed it. Examples include the URL returned when a pull request or comment was created, the job or run ID printed by a scheduler or CI system, the size or checksum of a written file, and the exit status and relevant output of a command.
- **Verify writes directly.** Check that a write happened instead of assuming it did. In a shell pipeline the exit status belongs to the last command, so piping a command into `tail` or `head` can hide its failure. Check the status of the command that did the work, and check that its result exists.
- **Report unconfirmed actions plainly.** When an action could not be confirmed, call it failed or unconfirmed. Reserve words such as "sent", "posted", and "submitted" for actions with evidence.
- **Stop after two failures.** If the same action fails twice in a row, stop retrying it. Report it as failed and continue with work that does not depend on it.
- **Promise only real follow-up.** Write "I will check back" or "this will report when done" only when a named job, schedule, or reminder will do it. Name that mechanism and when it runs.
- **Report skipped work.** List skipped steps and checks that were not run as skipped, and give the reason.

## General Checklist

Before publishing content or handing off work, check:

- Claims are supported by the cited or linked source.
- Numbers, names, dates, and identifiers are accurate.
- Uncertainty and limitations are preserved.
- Every reported action names its evidence, and anything unconfirmed or skipped is reported as such.

## Scientific and Scholarly Claims

This section applies to projects with scientific, scholarly, clinical, biomedical, statistical, or data-driven content, and non-scientific projects may trim it.

### Source Hierarchy

Use the best available source for the claim being edited.

- Primary papers and source documents are preferred for scientific claims.
- PubMed Central full text is preferred when available for biomedical papers.
- Journal pages, PubMed records, DOI landing pages, and preprint server pages are useful for citation and publication metadata.
- Official institutional pages are preferred for affiliations, appointments, and contact details.
- Repository-tracked source files and user-provided materials are preferred for project-specific facts.

For papers indexed in PubMed, verify citation details against PubMed when practical. Check title, author list, journal, year, volume, issue, pages, DOI, PMID, and PMCID.

### Writing Scientific Claims

State what the source supports. Qualify uncertainty when the source is uncertain.

When preparing scientific or technical writing, use relevant external guidance when helpful. Good sources include journal author instructions, reporting guidelines, technical documentation guides, field-specific style guides, and clear examples from reputable publications or peer projects.

Avoid overstating association as causation. Avoid presenting preliminary, preprint, or exploratory findings as settled conclusions.

Preserve important context such as population, model assumptions, study design, measurement limits, and scope.

For summaries, lead with the main contribution or result. Prefer "The study estimated..." or "The method identifies..." over vague claims such as "This work explores..."

### Avoid Self-Anchoring

When the project will be evaluated, summarized, or compared across versions, do not generate repository-level summaries of the scientific content. Future sessions may anchor on those summaries instead of reading the source material independently. This biases evaluation of new versions, can mask drift between drafts, and can propagate errors that a fresh reading would catch.

When project context is needed, link to the source material such as the manuscript files, cover letter, or results files rather than restating their content in tracked documentation. If a stable reference summary is needed for a specific purpose, generate it from the source on demand instead of relying on a previously written summary.

### Citation and Metadata Checks

When editing citation metadata, verify:

- title
- author list
- venue
- publication or posting date
- volume, issue, and pages
- DOI or preprint identifier
- PMID and PMCID when available

If the source is not available or cannot be verified, say so in the handoff instead of silently guessing.

### Scientific Checklist

Before publishing scientific content, also check:

- Terminology matches the source field.
- Citation metadata has been checked against a trusted source when practical.
- The prose is understandable without changing the scientific meaning.
