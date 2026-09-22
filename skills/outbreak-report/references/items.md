# Reporting items for real-time outbreak estimates

Items for reporting a modelled estimate of an outbreak that is recomputed and republished as new data arrive.
Each item is an assertion about the report, with a check stating what counts as met.

The basis line gives the sources and marks where an item goes beyond them ("added").
Source text, and the reasoning for each addition, is in [sources.md](sources.md) under the same id.
Consult it when an item is hard to check or when explaining the reason for an alternative.

Ids follow the presentation order.
Once the skill is released, retire an item rather than renumbering.

## Reader

The primary reader is a technically literate responder or analyst, at a national institute, a ministry, WHO, an NGO or a partner agency, who works with outbreak data and does not develop models.
Secondary readers are modelling peers and the press.

## Index

| Id    | Theme                     | Applies to    | Summary                                                          | Sources                                                    |
|-------|---------------------------|---------------|------------------------------------------------------------------|------------------------------------------------------------|
| OR-01 | Structure                 | Both          | A non-technical and a technical document, linked; diagnostics technical | ISPOR-7, TRACE, GATHER                              |
| OR-02 | Scope and purpose         | Non-technical | What the estimate is for and which decisions it supports         | GATHER 1, EPIFORGE 2, TRACE 1, ISPOR-7                     |
| OR-03 | Scope and purpose         | Non-technical | What the estimate should not be used for                         | TRACE 1, Abbott                                            |
| OR-04 | Scope and purpose         | Non-technical | Each quantity defined, with its reference date, before first use | GATHER 1, ORBIT, Gostic; ordering added                    |
| OR-05 | Data and inputs           | Non-technical | Each data source named, with its biases, and the data shown      | GATHER 5, 6, TRACE 3, ORBIT 1-6, Charniga, Hadley          |
| OR-06 | Estimates and uncertainty | Non-technical | A small, named, stable set of headline estimates                 | GATHER 1, Hadley; bounding added                           |
| OR-07 | Estimates and uncertainty | Non-technical | One interval per headline estimate, its meaning in words         | GATHER 16, EPIFORGE 14, Padilla, Hadley; one level added   |
| OR-08 | Estimates and uncertainty | Non-technical | Sources of uncertainty included and excluded                     | GATHER 13, Gostic, WHO 2017                                |
| OR-09 | Estimates and uncertainty | Non-technical | One plain sentence on confidence in the estimate                 | WHO 2012, PHIA; transfer added                             |
| OR-10 | Estimates and uncertainty | Non-technical | Probability words taken from a stated scale                      | PHIA; transfer added                                       |
| OR-11 | Interpretation            | Non-technical | Results summarised in non-technical terms                        | EPIFORGE 15, TRACE, Hadley                                 |
| OR-12 | Interpretation            | Non-technical | Limitations that affect interpretation                           | GATHER 18, EPIFORGE 17, ISPOR-7                            |
| OR-13 | Interpretation            | Non-technical | Implications for public health action                            | EPIFORGE 18, WHO 2012                                      |
| OR-14 | Currency and change       | Non-technical | Date the data were current to                                    | WHO 2025, EPIFORGE 4; date added                           |
| OR-15 | Currency and change       | Non-technical | Most recent estimates flagged as provisional                     | Gostic, Charniga, WHO 2025                                 |
| OR-16 | Currency and change       | Non-technical | Update frequency and next update                                 | ORBIT 7; stating it added                                  |
| OR-17 | Currency and change       | Non-technical | How and why the estimate changed since the last update           | GATHER 17, Abbott, WHO 2025                                |
| OR-18 | Currency and change       | Non-technical | Same presentation between updates, or the change announced       | Hadley, ORBIT                                              |
| OR-19 | Performance               | Non-technical | How past forecasts performed against a comparator                | EPIFORGE 11, 12, TRACE 8; placement added                  |
| OR-20 | Access                    | Non-technical | Estimates downloadable as versioned data                         | GATHER 15, EPIFORGE 16                                     |
| OR-21 | Access                    | Non-technical | Where the code is                                                | GATHER 14, EPIFORGE 9, Abbott, Charniga                    |
| OR-22 | Access                    | Non-technical | Authors and funders named                                        | GATHER 2, ISPOR-7                                          |
| OR-23 | Access                    | Non-technical | How to raise a correction or question                            | Added                                                      |
| OR-24 | Methods                   | Technical     | Methods, including key epidemiological inputs, enough to reproduce | GATHER 10, EPIFORGE 3, ISPOR-7, TRACE 2, Gostic, Charniga, Abbott |
| OR-25 | Methods                   | Technical     | How the model was evaluated and compared                         | GATHER 11, 12, EPIFORGE 10, TRACE 6, 7                     |

## Structure

### OR-01 Two documents

Recommendation: the estimate is published as two linked documents.
The non-technical document is for the primary reader, open to anyone, with the summary first and detail after.
The technical document gives methods, evaluation and diagnostics in enough detail for a peer to evaluate and reproduce the analysis.
Model diagnostics (sampler diagnostics, prior sensitivity, per-component decompositions) appear only in the technical document.

Check: the non-technical page opens with a summary and links to a technical document or code repository.
It carries no diagnostic output beyond that link.

A reader who does not develop models cannot act on a diagnostic.

Basis: ISPOR-7, TRACE, GATHER. Keeping diagnostics technical: added, from the reader.

## Scope and purpose

### OR-02 Purpose and intended use

Recommendation: the report states what the estimate is for and which decisions it is intended to support.

Check: a sentence names the quantity estimated, its population, place and period, and a decision or use it informs.

Basis: GATHER 1, EPIFORGE 2, TRACE 1, ISPOR-7.

### OR-03 Domain of applicability

Recommendation: the report states what the estimate should not be used for, and the limits of acceptable extrapolation.

Check: a statement of at least one use, population, place or time horizon the estimate does not cover.

Basis: TRACE 1, Abbott et al.

### OR-04 Quantities defined before use

Recommendation: every reported quantity is defined in words before its first number, including the population and geography it covers, the case definition it rests on, and, for a time-varying quantity, the date it refers to.

Check: for each headline quantity, a definition in words appears at or before the first number, figure or table showing it.
For a time-varying quantity, the definition says whether dates are of infection, onset, diagnosis or report.

Estimates that refer to different dates are not comparable, and a reproduction number by date of infection lags the data by the delay to report.

Basis: GATHER 1, ORBIT, Gostic et al. Ordering: added.

## Data and inputs

### OR-05 Data sources and their biases

Recommendation: the report names each data source, who produces it and the period it covers, identifies any that carry potentially important biases, and shows or links the observed data the estimate rests on.

Check: every input stream is named with its producer and period.
At least one input has the direction or nature of its bias stated, or the report says none is known.
The observed series appears on the page or is linked.

Basis: GATHER 5, GATHER 6, TRACE 3, ORBIT 1-6, Charniga et al., Hadley et al.

## Estimates and uncertainty

### OR-06 Bounded set of headline estimates

Recommendation: where the report presents several estimates together, it names which of them are headline, keeps that set small and unchanged between updates, and presents each in the same form.

Check: the headline quantities are identifiable as such.
With the previous edition, they match its headline quantities.

Readers prefer a few operational quantities (doubling time, time to a threshold, hospitalisations) over model parameters.

Basis: GATHER 1, Hadley et al. Bounding the set: added.

### OR-07 Headline estimate with one interval

Recommendation: each headline quantity is given with a single uncertainty interval, whose meaning is stated in words at or before first use.

Check: each headline number has one interval, and a sentence says what the interval means.

Readers do not scale their trust to interval width, so the level alone ("95%") does not tell them what the interval means.
One level keeps the headline legible; it is not shown to improve understanding.

Basis: GATHER 16, EPIFORGE 14, Padilla et al., Hadley et al. One level: added.

### OR-08 Sources of uncertainty included and excluded

Recommendation: the report states which sources of uncertainty the intervals account for, and which they do not.

Check: both lists are present. An included list alone is partly met.

Intervals from many methods assume every infection is observed, so they omit uncertainty from incomplete observation unless the model adds it.

Basis: GATHER 13, Gostic et al., WHO 2017.

### OR-09 Confidence statement

Recommendation: the report states in one sentence of plain language how much confidence to place in the headline estimate, and why.

Check: a sentence gives a confidence level, on a named scale or in plain words, with its reason.

Confidence is about the soundness of the evidence behind the estimate.
It is distinct from the probability of an outcome (OR-10) and from the numeric interval (OR-07).

Basis: WHO rapid risk assessment manual, PHIA. Transfer to a model estimate: added.

### OR-10 Verbal probability on a defined scale

Recommendation: where the report expresses a probability in words, the words come from a published scale, and the scale is stated or linked.

Check: every probability word ("likely", "unlikely", "almost certain") maps to a stated or linked scale.
Not applicable where the report gives no probability in words.

A published scale narrows the spread in how readers interpret probability words, without closing it.

Basis: PHIA probability yardstick. Transfer to outbreak reporting: added.

## Interpretation

### OR-11 Non-technical summary of results

Recommendation: the report summarises the results in non-technical terms, including a non-technical interpretation of the uncertainty.

Check: a summary a non-modeller could restate, with the uncertainty in words, placed before the detail.

The summary is passed on by readers who are not modellers, so it must survive restatement by them.

Basis: EPIFORGE 15, TRACE, Hadley et al.

### OR-12 Limitations

Recommendation: the report states its limitations, including the modelling assumptions and data limitations that affect interpretation.

Check: at least one assumption and one data limitation, each with what it does to interpretation.

Basis: GATHER 18, EPIFORGE 17, ISPOR-7.

### OR-13 Implications for action

Recommendation: the report states what its results imply for public health action and decision-making.

Check: a statement linking the result to a decision named at OR-02.

Basis: EPIFORGE 18, WHO rapid risk assessment manual.

## Currency and change

### OR-14 Data cut-off

Recommendation: the report states the date the data were current to, and which situation report or release that corresponds to.

Check: a data cut-off date, distinct from the publication date, near the headline.

Basis: WHO uncertainty guidance, related to EPIFORGE 4. The date as the form of the label: added.

### OR-15 Provisional recent estimates

Recommendation: the report says that estimates for the most recent period rest on incomplete data, are less certain, and are likely to be revised as delayed reports arrive.

Check: a statement, on the page or on the figure, marking the recent period as provisional, or showing it with a visibly wider interval and a note saying why.
Not applicable where the estimate does not depend on data subject to reporting delay.

Recent counts are incomplete because of reporting delays, so an estimate that does not adjust for this runs low at the end of a growing series; one that does adjust is more uncertain there.

Basis: Gostic et al., Charniga et al., WHO uncertainty guidance.

### OR-16 Update cadence

Recommendation: the report states how often it is updated and when the next update is due.

Check: a cadence or a next-update date.

Without a cadence a reader cannot tell whether a number is current.

Basis: ORBIT 7. Stating the cadence in the report: added.

### OR-17 Change since the last update

Recommendation: the report states how the headline estimate has changed since the previous version, and why it changed.

Check: the direction or size of change, and a reason (new data, revised data, method change).
A series of past estimates without a reason is partly met.
With the previous edition, the stated change matches it.

Basis: GATHER 17, Abbott et al., WHO uncertainty guidance.

### OR-18 Consistent presentation between updates

Recommendation: successive updates keep the same quantities, in the same order, in the same format, and say so when that changes.

Check: needs the previous edition.
Headline quantities, order, units and figure types match it, or the change is announced.

This item constrains every other: a change made to satisfy one item breaks continuity, and OR-17 is where that change is announced.

Basis: Hadley et al., ORBIT.

## Performance

### OR-19 Predictive performance

Recommendation: where the report forecasts, it states how its previous forecasts performed, against a named comparator.

Check: a performance statement on forecasts made before the data that tested them, with a comparator.
Fit to the data used in fitting does not count.
Not applicable where the report does not forecast.

Basis: EPIFORGE 11, EPIFORGE 12, TRACE 8. Placement in the non-technical document: added.

## Access

### OR-20 Estimates available as data

Recommendation: the published estimates are downloadable in a format data can be extracted from, carrying a version or timestamp.

Check: a link to the estimates as CSV or similar, with a version or date.

Basis: GATHER 15, EPIFORGE 16.

### OR-21 Code available

Recommendation: the analysis code is accessible, and the report says where.

Check: a working link to the code, or a stated reason it is not available.

Basis: GATHER 14, EPIFORGE 9, Abbott et al., Charniga et al.

### OR-22 Authorship and funding

Recommendation: the report names its authors and its funding sources.

Check: authors or the responsible team, and funders, are named.

Basis: GATHER 2, ISPOR-7.

### OR-23 Contact and feedback route

Recommendation: the report states how to raise a correction or a question, and with whom.

Check: an address, form or issue tracker.

Basis: added.

## Methods

### OR-24 Methods sufficient to reproduce

Recommendation: the technical document describes every step of the analysis, including the mathematics and the key epidemiological inputs, in enough detail to reproduce it.

Check: needs the technical document.
Model equations, data processing steps, and priors or fixed parameters are stated.
Each delay or generation-interval distribution is given with its form, parameters, uncertainty and source.
Full reproduction is outside the check.

Basis: GATHER 10, EPIFORGE 3, ISPOR-7, TRACE 2, Gostic et al., Charniga et al., Abbott et al.

### OR-25 Model evaluation and comparison

Recommendation: the technical document reports how the model was evaluated and how it compares with other published estimates.

Check: needs the technical document.
An evaluation method and its results, including sensitivity analysis where done, and a comparison or a statement that none exists.

Basis: GATHER 11, GATHER 12, EPIFORGE 10, TRACE 6, TRACE 7.
