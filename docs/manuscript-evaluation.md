# Manuscript Evaluation

Use this document for projects that produce manuscripts, reports, or other long-form scientific writing where assessment, version comparison, and revision planning are part of the regular workflow. It is an example of a project-specific writing-workflow doc; adapt it to the project's actual file layout and venue.

## Purpose

Use these rules when the task is to evaluate a current manuscript, compare it against a previous version, summarize progress, or identify strengths and weaknesses for revision planning.

This workflow draws on manuscript-structure best practices from Mensh and Kording, "Ten simple rules for structuring papers" (*PLoS Computational Biology*, 2017), PMCID: `PMC5619685`, PMID: `28957311`, DOI: `10.1371/journal.pcbi.1005619`.

## Source Priority

1. Read the current manuscript files first.
2. Read the current cover letter when journal positioning or framing is relevant.
3. When a previous version or prior submission package is available and relevant, compare against that earlier version rather than relying on memory.
4. When available, read prior editorial correspondence, submission notes, and planning notes to understand the reason for revision.
5. Prefer the manuscript text and submission artifacts over repository-level summaries when assessing scientific content. See `docs/scientific-integrity.md` on avoiding self-anchoring.

## Comparison Workflow

1. Identify the current working manuscript.
2. Identify the most relevant previous comparison target. This is usually the most recent prior submission or the immediately previous manuscript version.
3. Check whether the earlier version is actually available in the repository.
4. If the previous version is available, compare the current manuscript against it directly.
5. If the previous version is not available, state that limitation explicitly and base the assessment on the current manuscript plus any available submission notes or editorial feedback.
6. Separate true text-level changes from changes in positioning, cover letter strategy, or later internal interpretation.

## What to Evaluate

Assess the manuscript along the following dimensions when relevant:

1. Overall positioning and venue fit
2. Strength of the introduction and framing
3. Clarity of the core contribution
4. Biological or technical interpretation and depth
5. Novelty relative to the prior version
6. Strength of the discussion and conclusion
7. Alignment with prior editorial feedback
8. Remaining weaknesses, risks, or unresolved issues

## Structural Best-Practice Checks

Assess the manuscript against the following questions, informed by Mensh and Kording (2017):

1. Is the manuscript centered on a clear main contribution, and is that contribution reflected in the title?
2. Is the manuscript accessible to informed readers who do not already know the project?
3. Does the paper follow a clear context-content-conclusion pattern at the level of the paper, section, and paragraph?
4. Does the introduction clearly establish the gap in knowledge and explain why the gap matters?
5. Does the abstract tell a complete story, including context, approach, key results, and conclusion?
6. Do the results progress as a logical sequence of claims supported by figures, rather than as a chronological record of what was done?
7. Does the discussion explain how the identified gap was filled, acknowledge limitations, and explain why the work matters for the field?
8. Is the logical flow clean, without unnecessary zig-zag between topics, and are parallel ideas presented in parallel form where possible?
9. Are title, abstract, and figures carrying an appropriate share of the communication burden?
10. Do the current strengths and weaknesses suggest local polishing or a more fundamental restructuring of the story?

## Assessment Writing Rules

1. Use explicit ISO dates when referring to manuscript versions, submission events, or editorial correspondence.
2. Distinguish clearly between confirmed observations and interpretation.
3. Do not change scientific claims or quantitative results in the manuscript during assessment unless the user explicitly asks for revision.
4. Keep the assessment focused on the manuscript and related submission materials rather than introducing new scientific claims.
5. Be specific about whether an improvement is due to:
   - stronger framing
   - clearer writing
   - new biological or technical interpretation
   - new analysis or evidence
   - better venue positioning
6. If editorial feedback exists, explicitly state whether the current manuscript appears to address it fully, partially, or weakly.
7. When useful, classify each weakness as primarily a problem of:
   - structure
   - logic flow
   - unclear gap framing
   - insufficient support for the main claim
   - weak discussion of limitations
   - weak explanation of significance
8. When useful, distinguish between problems that can likely be solved by sentence-level revision and problems that likely require re-outlining or re-structuring.
9. Every assessment output file must explicitly record which files were used in the evaluation.
10. The assessment should identify, when applicable:
    - the current manuscript file used
    - the current cover letter file used
    - the previous manuscript or submission file used for comparison
    - any editorial correspondence used
    - any planning or strategy notes used
11. If a relevant previous version was not available, the assessment should explicitly say so.

## Required Output Format

Assessment notes should use:

- one top-level title
- a short `### Files used` section near the top
- `###` subheadings for major sections
- continuous numbered points across the whole document

Recommended section structure:

```
### Files used

List the exact files used for the assessment, with a brief note on each file's role.

### Overall assessment

1. Concise summary of the overall comparison outcome.

### Strengths

2. Numbered points describing improvements in the current manuscript.

### Remaining issues

3. Numbered points describing weaknesses, unchanged areas, or residual risks.

### Revision direction

4. Numbered points describing the most important next steps.

### Bottom line

5. Final numbered synthesis of the practical takeaway.
```

The exact number of points can vary, but numbering should remain continuous across sections.

## Naming and Placement

1. Place version-specific assessment notes alongside the manuscript they evaluate.
2. Prefer filenames that include the manuscript name and an ISO date when the assessment is tied to a specific version.
3. Keep this rules file at the project's `docs/` level so future assessments reuse the same workflow.

## Reference

- Mensh B, Kording K. Ten simple rules for structuring papers. *PLoS Computational Biology*. 2017;13(9):e1005619. PMCID: `PMC5619685`. PMID: `28957311`. DOI: `10.1371/journal.pcbi.1005619`. https://pmc.ncbi.nlm.nih.gov/articles/PMC5619685/
