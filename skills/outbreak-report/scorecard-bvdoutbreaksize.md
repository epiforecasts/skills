# Scorecard: BVDOutbreakSize summary page

An audit of one report against [items.md](items.md), at a fixed point. The
items are the standard; this file is evidence about one repository and will go
stale.

Repository: [epiforecasts/BVDOutbreakSize](https://github.com/epiforecasts/BVDOutbreakSize).
Page audited: `docs/src/summary.md`, the non-technical document.
Scored on 2026-09-21 against `701e5488` (branch `reporting`, open pull request
782, which reorganises this page), with `582537a2` (`main`) noted where the two
differ. Line numbers are the `reporting` branch.

Part of what the page renders is not in `summary.md`. The headline bullets and
the four tables are generated in `docs/examples/analysis.jl` and written to
`docs/src/summary_assets/`, so some findings land there instead.

4 pass, 5 partial, 15 fail, 1 not applicable.

| Id | Item | Verdict |
|---|---|---|
| OR-01 | Purpose and intended use | fail |
| OR-02 | Quantities defined before use | fail |
| OR-03 | Data cut-off | partial |
| OR-04 | Update cadence | fail |
| OR-05 | Change since the last update | fail |
| OR-06 | Headline estimate with one interval | fail |
| OR-07 | Non-technical summary of results | fail |
| OR-08 | Data sources named | fail |
| OR-09 | Known biases in the inputs | partial |
| OR-10 | Sources of uncertainty included and excluded | fail |
| OR-11 | Predictive performance | fail |
| OR-12 | Limitations | fail |
| OR-13 | Confidence statement | fail |
| OR-14 | Implications for action | fail |
| OR-15 | Estimates available as data | partial |
| OR-16 | Code available | pass |
| OR-17 | Authorship and funding | partial |
| OR-18 | Contact and feedback route | partial |
| OR-19 | Methods sufficient to reproduce | pass |
| OR-20 | Model evaluation and comparison | pass |
| OR-21 | Inference diagnostics stay technical | fail |
| OR-22 | Prior sensitivity stays technical | fail |
| OR-23 | Component decomposition stays technical | pass |
| OR-24 | Domain of applicability | fail |
| OR-25 | Verbal probability on a defined scale | not applicable |

## Evidence

OR-01, fail. Pull request 782 adds `aim.md`. The summary page neither states a
purpose nor links to it. On `main` there is no such page.

OR-02, fail. The reproduction number is defined at line 76 and used at lines
42, 44 and 45. Ascertainment is used at lines 44 and 45 and as a table column,
and is never defined. Data stream is used at lines 99 to 103 and never
defined.

OR-03, partial. A data cut-off date renders at the top from `cutoff.md`. The
situation report it corresponds to is not named on the page.

OR-04, fail. The README says the report is re-run as new data arrive. The page
says nothing, so a reader cannot judge how old a number is relative to the
cadence.

OR-05, fail. The sensitivity page plots estimate evolution across releases.
The summary page carries neither the change nor the reason for it.

OR-06, fail. Three interval levels per quantity, nested on one line, generated
at `analysis.jl` lines 2341 to 2366. The levels are named at line 38, after
two tables have already used them. The sentence claiming all intervals are
30, 60 and 90 per cent is contradicted at line 43, where the province table is
a median with a 90 per cent interval.

OR-07, fail. The headline is seven bullets of the form "Label: the X is
estimated to have been A, B, C", assembled by string interpolation. No prose
interpretation of the uncertainty appears on the page.

OR-08, fail. Streams are named but never sourced. Line 6 points at a
repository file rather than a link a web reader can follow.

OR-09, partial. Under-ascertainment is modelled and its consequence stated at
line 90. It is not named as a bias in the inputs, and the reduced-stream
periods are not flagged on the page.

OR-10, fail. Absent.

OR-11, fail. Forecast validation and baseline scoring exist on the sensitivity
page. The summary page shows sampler diagnostics instead, which are not
evidence that the model predicts well.

OR-12, fail. Pull request 782 moves limitations to their own page. The summary
page does not link it.

OR-13, fail. The page defines R-hat, bulk effective sample size and divergent
transitions at lines 59 to 61, then leaves the reader to form a judgement from
quantities they have just been taught.

OR-14, fail. Absent. The page ends on a per-stream comparison.

OR-15, partial. Every push publishes CSVs, thinned draws and a versioned
release. The summary page does not link them.

OR-16, pass. The footer links the repository.

OR-17, partial. Pull request 782 adds an authors and funding page. The summary
page does not link it.

OR-18, partial. The footer links the repository. Nothing names a person or a
route for a reader who does not use GitHub.

OR-19, pass. The analysis page carries a full generative methods section.

OR-20, pass. The sensitivity page carries forecast validation and comparisons
with McCabe et al. and Chamla et al.

OR-21, fail. R-hat, bulk effective sample size and divergent transitions are
on the summary page at lines 53 to 72, with definitions. Pull request 782
folds them into a dropdown, which hides them rather than moving them.

OR-22, fail. The shift-from-priors bullet, reported in prior interquartile
ranges, sits inside the headline bullets. Generated at `analysis.jl` lines
2359 to 2365.

OR-24, fail. Nothing on the page says what the estimate should not be used
for. The README's scope paragraph describes what the work adds, not where it
stops.

OR-25, not applicable. The page makes no probability claim in words. Every
statement is numeric or definitional, so there is nothing to band. The item
becomes live the moment OR-07 is satisfied, because plain prose about a
growing outbreak cannot avoid words like probably and likely.

OR-23, pass on `reporting`, fail on `main`. The per-stream reproduction number
was a summary section; 782 replaces it with a link, which satisfies the item.

## Separate findings

Two defects found while auditing that no item covers, because they are
correctness rather than reporting.

Line 42 says the national count is "the sum of the three below". The table has
four rows. `N_PATCHES` is `length(PROVINCE_NAMES)`, which is four, and
`docs/examples/_setup.jl:251` calls that the report's single source for the
count. The fourth row is "Other provinces", an aggregate, so the claim is
wrong either way.

Line 38 and line 43 contradict each other on the interval levels, as recorded
under OR-06.
