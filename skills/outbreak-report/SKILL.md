---
name: outbreak-report
description: Check a published or draft report of a modelled outbreak estimate (nowcast, forecast, outbreak size, reproduction number) that is republished as data arrive, against a sourced list of reporting items drawn from GATHER, EPIFORGE, ISPOR-7 and TRACE. Returns which items are met, with evidence from the report, and offers an alternative wording or layout for each gap. Use when reviewing a situation report, dashboard or summary page that presents model estimates to responders.
---

# Outbreak report check

Checks one report of a modelled outbreak estimate against the items in [references/items.md](references/items.md), and offers an alternative for each item not met.

The reader the items assume is a technically literate responder or analyst who works with outbreak data and does not develop models.

## Out of scope

- Whether the estimate is right, or the model sound. The check is of what the report says, not of the analysis.
- Reports of surveillance counts with no modelled estimate. ORBIT covers those.
- Research papers about a forecasting method. Use EPIFORGE directly.
- Writing a report from scratch.

Say so and stop if the task is one of these.

## Inputs

1. The non-technical report: a rendered page, a URL, or its source (`.qmd`, `.Rmd`, `.md`, HTML). Required.
2. The previous edition. Optional; without it OR-05, OR-26 and OR-27 are checked only as far as the current page allows.
3. The technical document or code repository. Optional; without it OR-19 and OR-20 are not checked.

Ask for 2 and 3 once if they are not given, then proceed with what is available.
Where the report is source code, check what the rendered page would show, not the code comments.

## Procedure

1. Read [references/items.md](references/items.md) in full.
   Do not load [references/sources.md](references/sources.md) up front.
   Open it, at the item's id, only when an item is hard to check against this report, or when a gap needs its reason explained.
2. Read the report. Identify the headline quantities, whether the report forecasts (OR-11), and whether it expresses probability in words (OR-25).
   State these back to the user before scoring, since they decide which items apply.
3. For each item, assign one status using the item's `Check` line:
   - `met`
   - `partly met`: say which part is missing
   - `not met`
   - `not applicable`: say why
   - `not checked`: the input the item needs was not given
4. For every status other than `not applicable` and `not checked`, quote or point to the part of the report that shows it (heading, line or figure).
   For `not met`, say where you looked.
5. For each `partly met` or `not met` item, offer an alternative (see below).

## Alternatives

The alternative shows one way the report could meet the item.
It is an option for the authors, not a correction.

- Build it from the report's own content: its quantities, dates, sources and wording. Never invent a number, date, performance score, funder or contact. Where one is needed, leave a marked placeholder such as `[data cut-off date]`.
- Keep it short: a sentence, a table row, a caption, or a one-line layout change. Do not rewrite sections.
- Match the report's existing style, terms and structure.
- Give the reason in one clause, so the authors can weigh it. Take it from the item, or from its entry in `references/sources.md` if the item alone does not make it clear.
- Where the items name a published scale (WHO confidence at OR-13, PHIA probability at OR-25), offer it as one choice among others, not as required.
- Where the gap may be deliberate (a house style, a platform limit, an audience decision), say that it may be, and accept the authors' reason if they give one.
- An alternative that changes presentation costs continuity (OR-26). Say so, and suggest announcing the change (OR-05).

## Output

A table in index order, grouped by document:

| Id | Item | Status | Evidence | Alternative |
|----|------|--------|----------|-------------|

Then, in no more than five lines, the gaps most likely to mislead the primary reader, in order.
No overall score: the items are not equally weighted and a count would suggest they are.
