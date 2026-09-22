# Reporting items for real-time outbreak estimates

Items for reporting a modelled estimate of an outbreak that is recomputed and republished as new data arrive.
Each item is an assertion about the report, with a check stating what counts as met.

The basis line gives the sources and marks where an item goes beyond them ("ours").
Source text, and the reasoning for each "ours", is in [sources.md](sources.md) under the same id.
Consult it when an item is hard to check or when explaining the reason for an alternative.

Ids are stable and are not the presentation order.
Retire an item rather than renumbering.
Retired: OR-22 and OR-23, merged into OR-21.

## Reader

The primary reader is a technically literate responder or analyst, at a national institute, a ministry, WHO, an NGO or a partner agency, who works with outbreak data and does not develop models.
Secondary readers are modelling peers and the press.

## Two documents

Non-technical: one document for the primary reader, available to anyone, with a summary first and detail after.

Technical: methods, evaluation and diagnostics, in enough detail for a peer to evaluate and reproduce the analysis.

Most items apply to the non-technical document.
OR-19 and OR-20 apply to the technical document.

## Index

Real-time: the item arises only because the report is republished, or matters more because of it.
Needs: what the check has to see. Page: the non-technical page alone. Previous: the previous edition. Technical: the technical document or code.

### Non-technical document

| Id    | Item                                         | Real-time | Needs          |
|-------|----------------------------------------------|-----------|----------------|
| OR-01 | Purpose and intended use                     |           | Page           |
| OR-24 | Domain of applicability                      |           | Page           |
| OR-02 | Quantities defined before use                |           | Page           |
| OR-09 | Known biases in the inputs                   |           | Page           |
| OR-08 | Data sources named                           |           | Page           |
| OR-06 | Headline estimate with one interval          |           | Page           |
| OR-27 | Bounded set of headline estimates            | yes       | Page, Previous |
| OR-10 | Sources of uncertainty included and excluded |           | Page           |
| OR-13 | Confidence statement                         |           | Page           |
| OR-25 | Verbal probability on a defined scale        |           | Page           |
| OR-12 | Limitations                                  |           | Page           |
| OR-07 | Non-technical summary of results             |           | Page           |
| OR-14 | Implications for action                      |           | Page           |
| OR-03 | Data cut-off                                 | yes       | Page           |
| OR-05 | Change since the last update                 | yes       | Page, Previous |
| OR-26 | Consistent presentation between updates      | yes       | Previous       |
| OR-04 | Update cadence                               | yes       | Page           |
| OR-11 | Predictive performance                       |           | Page           |
| OR-16 | Code available                               |           | Page           |
| OR-15 | Estimates available as data                  |           | Page           |
| OR-17 | Authorship and funding                       |           | Page           |
| OR-18 | Contact and feedback route                   |           | Page           |
| OR-21 | Model diagnostics stay technical             |           | Page           |

### Technical document

| Id    | Item                            | Needs     |
|-------|---------------------------------|-----------|
| OR-19 | Methods sufficient to reproduce | Technical |
| OR-20 | Model evaluation and comparison | Technical |

## Scope and purpose

### OR-01 Purpose and intended use

Recommendation: the report states what the estimate is for and which decisions it is intended to support.

Check: a sentence names the quantity estimated, its population, place and period, and a decision or use it informs.

Basis: GATHER 1, EPIFORGE 2, TRACE 1, ISPOR-7.

### OR-24 Domain of applicability

Recommendation: the report states what the estimate should not be used for, and the limits of acceptable extrapolation.

Check: a statement of at least one use, population, place or time horizon the estimate does not cover.

Basis: TRACE 1.

### OR-02 Quantities defined before use

Recommendation: every reported quantity is defined in words before its first number, including the population and geography it covers.

Check: for each headline quantity, a definition in words appears at or before the first number, figure or table showing it.

Basis: GATHER 1. Ordering: ours.

## Data and inputs

### OR-09 Known biases in the inputs

Recommendation: the report identifies which input data carry potentially important biases.

Check: at least one named input with the direction or nature of its bias, or an explicit statement that none is known.

Basis: GATHER 6, TRACE 3, Hadley et al.

### OR-08 Data sources named

Recommendation: the report names each data source, who produces it, and the period it covers.

Check: every input stream is named with its producer and period.

Basis: GATHER 5.

## Estimates and uncertainty

### OR-06 Headline estimate with one interval

Recommendation: each headline quantity is given with a single uncertainty interval, whose meaning is stated in words at or before first use.

Check: each headline number has one interval, and a sentence says what the interval means.

Readers do not scale their trust to interval width, so the level alone ("95%") does not tell them what the interval means.
One level keeps the headline legible; it is not shown to improve understanding.

Basis: GATHER 16, EPIFORGE 14, Padilla et al., Hadley et al. One level: ours.

### OR-27 Bounded set of headline estimates

Recommendation: where the report presents several estimates together, it names which of them are headline, keeps that set small and unchanged between updates, and presents each in the same form.

Check: the headline quantities are identifiable as such, and match the previous edition's.

Readers prefer a few operational quantities (doubling time, time to a threshold, hospitalisations) over model parameters.

Basis: GATHER 1, Hadley et al. Bounding the set: ours.

### OR-10 Sources of uncertainty included and excluded

Recommendation: the report states which sources of uncertainty the intervals account for, and which they do not.

Check: both lists are present. An included list alone is partly met.

Basis: GATHER 13.

### OR-13 Confidence statement

Recommendation: the report states in one sentence of plain language how much confidence to place in the headline estimate, and why.

Check: a sentence gives a confidence level, on a named scale or in plain words, with its reason.

Confidence is about the soundness of the evidence behind the estimate.
It is distinct from the probability of an outcome (OR-25) and from the numeric interval (OR-06).

Basis: WHO rapid risk assessment manual, PHIA. Transfer to a model estimate: ours.

### OR-25 Verbal probability on a defined scale

Recommendation: where the report expresses a probability in words, the words come from a published scale, and the scale is stated or linked.

Check: every probability word ("likely", "unlikely", "almost certain") maps to a stated or linked scale.
Not applicable where the report gives no probability in words.

A published scale narrows the spread in how readers interpret probability words, without closing it.

Basis: PHIA probability yardstick. Transfer to outbreak reporting: ours.

## Interpretation

### OR-12 Limitations

Recommendation: the report states its limitations, including the modelling assumptions and data limitations that affect interpretation.

Check: at least one assumption and one data limitation, each with what it does to interpretation.

Basis: GATHER 18, EPIFORGE 17, ISPOR-7.

### OR-07 Non-technical summary of results

Recommendation: the report summarises the results in non-technical terms, including a non-technical interpretation of the uncertainty.

Check: a summary a non-modeller could restate, with the uncertainty in words, placed before the detail.

The summary is passed on by readers who are not modellers, so it must survive restatement by them.

Basis: EPIFORGE 15, TRACE, Hadley et al.

### OR-14 Implications for action

Recommendation: the report states what its results imply for public health action and decision-making.

Check: a statement linking the result to a decision named at OR-01.

Basis: EPIFORGE 18, WHO rapid risk assessment manual.

## Currency and change

### OR-03 Data cut-off

Recommendation: the report states the date the data were current to, and which situation report or release that corresponds to.

Check: a data cut-off date, distinct from the publication date, near the headline.

Basis: related to EPIFORGE 4. Requirement for the date: ours.

### OR-05 Change since the last update

Recommendation: the report states how the headline estimate has changed since the previous version, and why it changed.

Check: the direction or size of change, and a reason (new data, revised data, method change).
A series of past estimates without a reason is partly met.

Basis: GATHER 17.

### OR-26 Consistent presentation between updates

Recommendation: successive updates keep the same quantities, in the same order, in the same format, and say so when that changes.

Check: against the previous edition, headline quantities, order, units and figure types match, or the change is announced.

This item constrains every other: a change made to satisfy one item breaks continuity, and OR-05 is where that change is announced.

Basis: Hadley et al. No guideline carries it.

### OR-04 Update cadence

Recommendation: the report states how often it is updated and when the next update is due.

Check: a cadence or a next-update date.

Without a cadence a reader cannot tell whether a number is current.

Basis: ours.

## Performance

### OR-11 Predictive performance

Recommendation: where the report forecasts, it states how its previous forecasts performed, against a named comparator.

Check: a performance statement on forecasts made before the data that tested them, with a comparator.
Fit to the data used in fitting does not count.
Not applicable where the report does not forecast.

Basis: EPIFORGE 11, EPIFORGE 12, TRACE 8. Placement in the non-technical document: ours.

## Access

### OR-16 Code available

Recommendation: the analysis code is accessible, and the report says where.

Check: a working link to the code, or a stated reason it is not available.

Basis: GATHER 14, EPIFORGE 9.

### OR-15 Estimates available as data

Recommendation: the published estimates are downloadable in a format data can be extracted from, carrying a version or timestamp.

Check: a link to the estimates as CSV or similar, with a version or date.

Basis: GATHER 15, EPIFORGE 16.

### OR-17 Authorship and funding

Recommendation: the report names its authors and its funding sources.

Check: authors or the responsible team, and funders, are named.

Basis: GATHER 2, ISPOR-7.

### OR-18 Contact and feedback route

Recommendation: the report states how to raise a correction or a question, and with whom.

Check: an address, form or issue tracker.

Basis: ours.

### OR-21 Model diagnostics stay technical

Recommendation: the non-technical document does not carry model diagnostics (sampler diagnostics, prior sensitivity, per-component decompositions) beyond a link to the technical document.

Check: no diagnostic output on the non-technical page other than a link.

A reader who does not develop models cannot act on a diagnostic.

Basis: ours, from the reader. ISPOR-7 by omission.

## Technical document

### OR-19 Methods sufficient to reproduce

Recommendation: the technical document describes every step of the analysis, including the mathematics, in enough detail to reproduce it.

Check: model equations, data processing steps, and priors or fixed parameters are all stated.
Full reproduction is outside the check.

Basis: GATHER 10, EPIFORGE 3, ISPOR-7, TRACE 2.

### OR-20 Model evaluation and comparison

Recommendation: the technical document reports how the model was evaluated and how it compares with other published estimates.

Check: an evaluation method and its results, including sensitivity analysis where done, and a comparison or a statement that none exists.

Basis: GATHER 11, GATHER 12, EPIFORGE 10, TRACE 6, TRACE 7.
