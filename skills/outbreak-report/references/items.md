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

| Id    | Theme                     | Summary                                                          | Sources                                                    |
|-------|---------------------------|------------------------------------------------------------------|------------------------------------------------------------|
| OR-01 | Scope and purpose         | What the estimate is for and which decisions it supports         | GATHER 1, EPIFORGE 2, TRACE 1                              |
| OR-02 | Scope and purpose         | What the estimate should not be used for                         | TRACE 1, Abbott                                            |
| OR-03 | Scope and purpose         | Each quantity defined, with its reference date, before first use | GATHER 1, ORBIT, Gostic; ordering added                    |
| OR-04 | Data and inputs           | Each data source named, with its biases, and the data shown      | GATHER 5, 6, TRACE 3, ORBIT 1-6, Charniga, Hadley          |
| OR-05 | Estimates and uncertainty | A small, named, stable set of headline estimates                 | GATHER 1, Hadley; bounding added                           |
| OR-06 | Estimates and uncertainty | An interval per headline estimate, its level and meaning stated  | GATHER 16, EPIFORGE 14, Charniga, Padilla, Hadley          |
| OR-07 | Estimates and uncertainty | Kinds of uncertainty included and excluded, structural included  | GATHER 13, Thorén, den Boon, Howerton, Becker, IPCC, McCabe, Gostic, WHO 2017 |
| OR-08 | Estimates and uncertainty | Probability words taken from a stated scale                      | PHIA, SPI-M-O, IPCC, van der Bles                          |
| OR-09 | Estimates and uncertainty | Confidence in the evidence behind the estimate, on a stated scale | van der Bles, CDC CFA, SPI-M-O, WHO 2012, IPCC, GRADE, PHIA |
| OR-10 | Interpretation            | Results summarised in non-technical terms                        | EPIFORGE 15, TRACE, Hadley                                 |
| OR-11 | Interpretation            | Limitations that affect interpretation                           | GATHER 18, EPIFORGE 17                                     |
| OR-12 | Interpretation            | Implications for public health action                            | EPIFORGE 18, WHO 2012                                      |
| OR-13 | Currency and change       | Date the data were current to                                    | WHO 2025, EPIFORGE 4; date added                           |
| OR-14 | Currency and change       | Most recent estimates flagged as provisional                     | Gostic, Charniga, WHO 2025                                 |
| OR-15 | Currency and change       | Update frequency and next update                                 | ORBIT 7; stating it added                                  |
| OR-16 | Currency and change       | How and why the estimate changed since the last update           | GATHER 17, Abbott, WHO 2025                                |
| OR-17 | Currency and change       | Same presentation between updates, or the change announced       | Hadley, ORBIT                                              |
| OR-18 | Performance               | How well the model reproduces the data it was fitted to          | TRACE 6, GATHER 12, Abbott                                 |
| OR-19 | Performance               | How past forecasts performed against a comparator                | EPIFORGE 11, 12, TRACE 8; placement added                  |
| OR-20 | Access                    | Estimates downloadable as versioned data                         | GATHER 15, EPIFORGE 16                                     |
| OR-21 | Access                    | Where the code is                                                | GATHER 14, EPIFORGE 9, Abbott, Charniga, Becker, Zavalis   |
| OR-22 | Access                    | Authors and funders named                                        | GATHER 2, Zavalis, Boden                                   |
| OR-23 | Access                    | How to raise a correction or question                            | Added                                                      |
| OR-24 | Methods                   | Methods, including key epidemiological inputs, enough to reproduce | GATHER 10, EPIFORGE 3, TRACE 2, Gostic, Charniga, Abbott, Boden |
| OR-25 | Methods                   | How the model was evaluated, checked and compared                | GATHER 11, 12, EPIFORGE 10, TRACE 6, 7, Abbott             |

## Scope and purpose

### OR-01 Purpose and intended use

Recommendation: the report states what the estimate is for and which decisions it is intended to support.

Check: a sentence names the quantity estimated, its population, place and period, and a decision or use it informs.

Basis: GATHER 1, EPIFORGE 2, TRACE 1.

### OR-02 Domain of applicability

Recommendation: the report states what the estimate should not be used for, and the limits of acceptable extrapolation.

Check: a statement of at least one use, population, place or time horizon the estimate does not cover.

Basis: TRACE 1, Abbott et al.

### OR-03 Quantities defined before use

Recommendation: every reported quantity is defined in words before its first number, including the population and geography it covers, the case definition it rests on, and, for a time-varying quantity, the date it refers to.

Check: for each headline quantity, a definition in words appears at or before the first number, figure or table showing it.
For a time-varying quantity, the definition says whether dates are of infection, onset, diagnosis or report.

Estimates that refer to different dates are not comparable, and a reproduction number by date of infection lags the data by the delay to report.

Basis: GATHER 1, ORBIT, Gostic et al. Ordering: added.

## Data and inputs

### OR-04 Data sources and their biases

Recommendation: the report names each data source, who produces it and the period it covers, identifies any that carry potentially important biases, and shows or links the observed data the estimate rests on.

Check: every input stream is named with its producer and period.
At least one input has the direction or nature of its bias stated, or the report says none is known.
The observed series appears on the page or is linked.

Basis: GATHER 5, GATHER 6, TRACE 3, ORBIT 1-6, Charniga et al., Hadley et al.

## Estimates and uncertainty

A report says how sure it is in two separate ways, and needs both.

| | Uncertainty in the estimate | Confidence in the evidence |
|---|---|---|
| Question it answers | What values could the quantity take? | How far can the model, data and assumptions behind that range be trusted? |
| Also called | Direct uncertainty | Indirect uncertainty |
| Expressed as | An interval, a probability, or a probability word from a stated scale | A level on a confidence scale, with the reasons for it |
| Items | OR-06 interval, OR-07 what the interval covers, OR-08 probability words | OR-09 confidence |

Neither stands in for the other.
A narrow interval can come with low confidence, when the model is precise but its structure or data are doubtful.
A wide interval can come with high confidence, when the evidence is sound and the outcome is simply variable.
Whatever OR-07 lists as left out of the interval is a reason to lower confidence at OR-09.

### OR-05 Bounded set of headline estimates

Recommendation: where the report presents several estimates together, it names which of them are headline, keeps that set small and unchanged between updates, and presents each in the same form.

Check: the headline quantities are identifiable as such.
With the previous edition, they match its headline quantities.

Readers prefer a few operational quantities (doubling time, time to a threshold, hospitalisations) over model parameters.

Basis: GATHER 1, Hadley et al. Bounding the set: added.

### OR-06 Headline estimate with an interval

Recommendation: each headline quantity is given with an uncertainty interval whose level is stated and whose meaning is stated in words at or before first use.
Where more than one level is shown, every headline quantity uses the same levels.

Check: each headline number has an interval with its level, and a sentence says what the interval means.

Readers do not scale their trust to interval width, so the level alone ("95%") does not tell them what the interval means.
No source prescribes a level. 90% and 95% are common; a 50% interval shows the range the value most likely falls in.
Choose the level the reader's decision needs, and keep it between updates (OR-17).

Basis: GATHER 16, EPIFORGE 14, Charniga et al., Padilla et al., Hadley et al.

### OR-07 Kinds of uncertainty included and excluded

Recommendation: the report states which kinds of uncertainty the intervals include and which they leave out: in the data (for example incomplete or delayed reporting), in the parameters, from chance, and in the model's structure and assumptions.
Where structural uncertainty is not in the intervals, the report says how it was explored (alternative models, an ensemble, sensitivity analysis) or that it was not.

Check: the included and the excluded kinds are both named, and model structure is addressed explicitly.
An included list alone is partly met.

An interval covers only the uncertainty the model represents.
Uncertainty about the model's own structure sits outside any single model's interval, so it has to be stated separately.

Basis: GATHER 13, Thorén and Gerlee, den Boon et al., Howerton et al., Becker et al., IPCC, McCabe et al., Gostic et al., WHO 2017.

### OR-08 Verbal probability on a defined scale

Recommendation: where the report expresses a probability in words, the words come from a published scale, and the scale is stated or linked.

Check: every probability word ("likely", "unlikely", "almost certain") maps to a stated or linked scale.
Not applicable where the report gives no probability in words.

This is uncertainty in the estimate, in words.
It is not confidence: "likely" is a probability, and says nothing about how sound the evidence is.
A published scale narrows the spread in how readers interpret probability words, without closing it.

Basis: PHIA probability yardstick, as used by SPI-M-O; IPCC likelihood scale; van der Bles et al.

### OR-09 Confidence in the evidence

Recommendation: the report states, separately from the interval and any probability words, how much confidence to place in the evidence behind the headline estimate, as a level on a stated scale, with the reasons that set the level.

Check: a confidence level, the scale it comes from, and at least one reason.
A level in plain words with no stated scale is partly met.
A statement that only restates the interval ("the estimate is uncertain") is not met.

Confidence rates the soundness of the model, data and assumptions, not the width of the interval (OR-06) or the probability of an outcome (OR-08).
The reasons usually come from what the interval leaves out (OR-07), the quality of the data (OR-04), and how well the model fits (OR-18) and has predicted (OR-19).

Published scales, any of which can be used:

- CDC Center for Forecasting and Outbreak Analytics: low, moderate or high, set by the quality and amount of evidence and how well lines of evidence corroborate one another. Used for real-time outbreak risk and scenario assessments.
- WHO rapid risk assessment: a descriptive scale from very low to very high, set by the reliability, completeness and quality of the information and the assumptions made.
- IPCC: five levels (very low, low, medium, high, very high), assigned by rating the evidence (limited, medium, robust) and the agreement between lines of evidence (low, medium, high). This is the most structured route and leaves a traceable account.
- GRADE: four levels of certainty (high, moderate, low, very low), for a body of evidence rather than a single model estimate.

Both can be given in one sentence, each on its own scale: SPI-M-O wrote that it considered a finding "likely, with low confidence".

Basis: van der Bles et al., CDC CFA, SPI-M-O, WHO rapid risk assessment manual, IPCC, GRADE, PHIA.

## Interpretation

### OR-10 Non-technical summary of results

Recommendation: the report summarises the results in non-technical terms, including a non-technical interpretation of the uncertainty and of the confidence in the evidence.

Check: a summary a non-modeller could restate, with the uncertainty and the confidence in words, placed before the detail.

The summary is passed on by readers who are not modellers, so it must survive restatement by them.

Basis: EPIFORGE 15, TRACE, Hadley et al.

### OR-11 Limitations

Recommendation: the report states its limitations, including the modelling assumptions and data limitations that affect interpretation.

Check: at least one assumption and one data limitation, each with what it does to interpretation.

Basis: GATHER 18, EPIFORGE 17.

### OR-12 Implications for action

Recommendation: the report states what its results imply for public health action and decision-making.

Check: a statement linking the result to a decision named at OR-01.

Basis: EPIFORGE 18, WHO rapid risk assessment manual.

## Currency and change

### OR-13 Data cut-off

Recommendation: the report states the date the data were current to, and which situation report or release that corresponds to.

Check: a data cut-off date, distinct from the publication date, near the headline.

Basis: WHO uncertainty guidance, related to EPIFORGE 4. The date as the form of the label: added.

### OR-14 Provisional recent estimates

Recommendation: the report says that estimates for the most recent period rest on incomplete data, are less certain, and are likely to be revised as delayed reports arrive.

Check: a statement, on the page or on the figure, marking the recent period as provisional, or showing it with a visibly wider interval and a note saying why.
Not applicable where the estimate does not depend on data subject to reporting delay.

Recent counts are incomplete because of reporting delays, so an estimate that does not adjust for this runs low at the end of a growing series; one that does adjust is more uncertain there.

Basis: Gostic et al., Charniga et al., WHO uncertainty guidance.

### OR-15 Update cadence

Recommendation: the report states how often it is updated and when the next update is due.

Check: a cadence or a next-update date.

Without a cadence a reader cannot tell whether a number is current.

Basis: ORBIT 7. Stating the cadence in the report: added.

### OR-16 Change since the last update

Recommendation: the report states how the headline estimate has changed since the previous version, and why it changed.

Check: the direction or size of change, and a reason (new data, revised data, method change).
A series of past estimates without a reason is partly met.
With the previous edition, the stated change matches it.

Basis: GATHER 17, Abbott et al., WHO uncertainty guidance.

### OR-17 Consistent presentation between updates

Recommendation: successive updates keep the same quantities, in the same order, in the same format, and say so when that changes.

Check: needs the previous edition.
Headline quantities, order, units and figure types match it, or the change is announced.

This item constrains every other: a change made to satisfy one item breaks continuity, and OR-16 is where that change is announced.

Basis: Hadley et al., ORBIT.

## Performance

### OR-18 Fit to the data

Recommendation: the report shows how well the model reproduces the data it was fitted to, for example modelled against observed counts, and labels this as fit, distinct from predictive performance (OR-19).

Check: a figure or statement comparing model output with the observed data used in fitting, labelled as fit.
The checks used are described under OR-25.

A model that cannot reproduce its own data is not credible.
Good fit is weaker evidence than good prediction, because the data were used to fit the model.

Basis: TRACE 6, GATHER 12, Abbott et al.

### OR-19 Predictive performance

Recommendation: where the report forecasts, it states how its previous forecasts performed, against a named comparator.

Check: a performance statement on forecasts made before the data that tested them, with a comparator.
Fit to the data used in fitting does not count here; that is OR-18.
Not applicable where the report does not forecast.

Basis: EPIFORGE 11, EPIFORGE 12, TRACE 8. Placement alongside the headline: added.

## Access

### OR-20 Estimates available as data

Recommendation: the published estimates are downloadable in a format data can be extracted from, carrying a version or timestamp.

Check: a link to the estimates as CSV or similar, with a version or date.

Basis: GATHER 15, EPIFORGE 16.

### OR-21 Code available

Recommendation: the analysis code is accessible, and the report says where.

Check: a working link to the code, or a stated reason it is not available.

Basis: GATHER 14, EPIFORGE 9, Abbott et al., Charniga et al., Becker et al., Zavalis and Ioannidis.

### OR-22 Authorship and funding

Recommendation: the report names its authors and its funding sources.

Check: authors or the responsible team, and funders, are named.

Basis: GATHER 2, Zavalis and Ioannidis, Boden and McKendrick.

### OR-23 Contact and feedback route

Recommendation: the report states how to raise a correction or a question, and with whom.

Check: an address, form or issue tracker.

Basis: added.

## Methods

### OR-24 Methods sufficient to reproduce

Recommendation: the report, or methods documentation it links to, describes every step of the analysis, including the mathematics and the key epidemiological inputs, in enough detail to reproduce it.

Check: needs the methods documentation where it is separate.
Model equations, data processing steps, and priors or fixed parameters are stated.
Each delay or generation-interval distribution is given with its form, parameters, uncertainty and source.
Full reproduction is outside the check.

Basis: GATHER 10, EPIFORGE 3, TRACE 2, Gostic et al., Charniga et al., Abbott et al., Boden and McKendrick.

### OR-25 Model evaluation and comparison

Recommendation: the report, or methods documentation it links to, reports how the model was evaluated and how it compares with other published estimates.

Check: needs the methods documentation where it is separate.
An evaluation method and its results, including checks of fit to the data (for example posterior predictive checks) and sensitivity analysis where done, and a comparison or a statement that none exists.

Basis: GATHER 11, GATHER 12, EPIFORGE 10, TRACE 6, TRACE 7, Abbott et al.
