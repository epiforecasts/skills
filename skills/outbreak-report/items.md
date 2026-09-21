# Reporting items for a real-time outbreak estimate

A local implementation of relevant reporting guidelines for epidemiological
modelling: GATHER, EPIFORGE and ISPOR-SMDM Task Force-7. Aimed at real-time
outbreak reports using continuously updated modelling estimates based on
refreshed data. Each item states a checkable assertion about the reporting
item, says which document it belongs to, and names the source.

Ids are stable. Retire an item rather than renumbering.

## Audience

The primary reader is a technically literate responder or analyst, at a
national institute, WHO, an NGO or a partner agency, who works with outbreak
data but does not build models. Secondary readers are modelling peers and the
press.

This matches GATHER's own split:

> Reporting of estimates should serve the needs of their two primary
> audiences: decision makers and researchers. [...] These users need
> information about data sources and analysis methods, including key
> assumptions and limitations, in a way that is accessible without advanced
> training in statistics. They also need an explanation of how new estimates
> compare to previously published estimates, including why they differ.
> Researchers require a higher degree of detail about methods, so that they
> can fully understand and potentially reproduce studies and advance methods.

## Two documents

Non-technical: one page for the primary reader, available to anyone.

Technical: methods, evaluation and diagnostics, sufficient for a peer to
reproduce.

The split is ISPOR-7's:

> A nontechnical description should be made available to anyone — including
> model type and intended applications; funding sources; structure; inputs,
> outputs, other components that determine function, and their relationships;
> data sources; validation methods and results; and limitations. Technical
> documentation, written in sufficient detail to enable a reader with
> necessary expertise to evaluate the model and potentially reproduce it,
> should be made available openly or under agreements that protect
> intellectual property.

## Index

| Id | Item | Document | Real-time |
|---|---|---|---|
| OR-01 | Purpose and intended use | Non-technical | |
| OR-02 | Quantities defined before use | Non-technical | |
| OR-03 | Data cut-off | Non-technical | yes |
| OR-04 | Update cadence | Non-technical | yes |
| OR-05 | Change since the last update | Non-technical | yes |
| OR-06 | Headline estimate with one interval | Non-technical | |
| OR-07 | Non-technical summary of results | Non-technical | |
| OR-08 | Data sources named | Non-technical | |
| OR-09 | Known biases in the inputs | Non-technical | |
| OR-10 | Sources of uncertainty included and excluded | Non-technical | |
| OR-11 | Predictive performance | Non-technical | yes |
| OR-12 | Limitations | Non-technical | |
| OR-13 | Confidence statement | Non-technical | |
| OR-14 | Implications for action | Non-technical | |
| OR-15 | Estimates available as data | Non-technical | yes |
| OR-16 | Code available | Non-technical | |
| OR-17 | Authorship and funding | Non-technical | |
| OR-18 | Contact and feedback route | Non-technical | |
| OR-19 | Methods sufficient to reproduce | Technical | |
| OR-20 | Model evaluation and comparison | Technical | |
| OR-21 | Inference diagnostics stay technical | Technical | |
| OR-22 | Prior sensitivity stays technical | Technical | |
| OR-23 | Component decomposition stays technical | Technical | |

The real-time items exist because the report is republished. The source
guidelines assume a document published once, and carry only OR-05 among them.

## Items

### OR-01 Purpose and intended use

The report states what the estimate is for and which decisions it is intended
to support.

GATHER item 1, EPIFORGE item 2, ISPOR-7.

> Define the indicator(s), populations (including age, sex, and geographic
> entities), and time period(s) for which estimates were made. (GATHER 1)

> Define the purpose of study and forecasting targets. (EPIFORGE 2)

### OR-02 Quantities defined before use

Every reported quantity is defined in words before its first number, including
the population and geography it covers.

GATHER item 1, as above. The before-first-use ordering is ours.

### OR-03 Data cut-off

The report states the date the data were current to, and which situation
report or release that corresponds to.

EPIFORGE item 4.

> Identify whether the forecast was performed prospectively, in real time,
> and/or retrospectively. (EPIFORGE 4)

### OR-04 Update cadence

The report states how often it is updated and when the next update is due.

No source found. Ours.

### OR-05 Change since the last update

The report states how the headline estimate has changed since the previous
version, and why it changed.

GATHER item 17.

> Interpret results in light of existing evidence. If updating a previous set
> of estimates, describe the reasons for changes in estimates. (GATHER 17)

GATHER asks for the reason, not only the series.

### OR-06 Headline estimate with one interval

Each headline quantity is given with a single uncertainty interval, whose
meaning is stated in words at or before first use.

GATHER item 16, EPIFORGE item 14.

> Report a quantitative measure of the uncertainty of the estimates (e.g.,
> uncertainty intervals). (GATHER 16)

> Present and explain uncertainty of forecasting results. (EPIFORGE 14)

Neither source specifies a number of levels. The restriction to one is ours,
and follows from the audience.

### OR-07 Non-technical summary of results

The report summarises the results in non-technical terms, including a
non-technical interpretation of the uncertainty.

EPIFORGE item 15.

> Briefly summarize the results in nontechnical terms, including a
> nontechnical interpretation of forecast uncertainty. (EPIFORGE 15)

### OR-08 Data sources named

The report names each data source, who produces it, and the period it covers.

GATHER item 5.

> Provide information about all included data sources and their main
> characteristics. For each data source used, report reference information or
> contact name/institution, population represented, data collection method,
> year(s) of data collection, sex and age range, diagnostic criteria or
> measurement method, and sample size, as relevant. (GATHER 5)

### OR-09 Known biases in the inputs

The report identifies which input data carry potentially important biases.

GATHER item 6.

> Identify and describe any categories of input data that have potentially
> important biases (e.g., based on characteristics listed in item 5).
> (GATHER 6)

### OR-10 Sources of uncertainty included and excluded

The report states which sources of uncertainty the intervals account for, and
which they do not.

GATHER item 13.

> Describe methods of calculating uncertainty of the estimates. State which
> sources of uncertainty were, and were not, accounted for in the uncertainty
> analysis. (GATHER 13)

### OR-11 Predictive performance

Where the report forecasts, it states how its previous forecasts performed,
against a named comparator.

EPIFORGE items 11 and 12.

> Describe the forecast accuracy evaluation method used, with justification.
> (EPIFORGE 11)

> Where possible, compare model results to a benchmark or other comparator
> model, with justification of comparator choice. (EPIFORGE 12)

EPIFORGE places these in the methods of a study. Surfacing the result in the
non-technical document is ours, and is what a reader needs in place of
sampler diagnostics.

### OR-12 Limitations

The report states its limitations, including the modelling assumptions and
data limitations that affect interpretation.

GATHER item 18, EPIFORGE item 17.

> Discuss limitations of the estimates. Include a discussion of any modelling
> assumptions or data limitations that affect interpretation of the
> estimates. (GATHER 18)

> Describe the weaknesses of the forecast, including weaknesses specific to
> data quality and methods. (EPIFORGE 17)

### OR-13 Confidence statement

The report states in one sentence of plain language how much confidence to
place in the headline estimate.

WHO Rapid Risk Assessment template v2.1, which carries a confidence-level
field alongside the risk assessment. Paraphrase, not a quotation: the template
itself is not openly readable, and this is the weakest citation in the list.

### OR-14 Implications for action

The report comments on what its results imply for public health action and
decision-making.

EPIFORGE item 18.

> If the research is applicable to a specific epidemic, comment on its
> potential implications and impact for public health action and
> decisionmaking. (EPIFORGE 18)

### OR-15 Estimates available as data

The published estimates are downloadable in a format data can be extracted
from, carrying a version or timestamp.

GATHER item 15, EPIFORGE item 16.

> Provide published estimates in a file format from which data can be
> efficiently extracted. (GATHER 15)

> If results are published as a data object, encourage a time-stamped version
> number. (EPIFORGE 16)

### OR-16 Code available

The analysis code is accessible, and the report says where.

GATHER item 14, EPIFORGE item 9.

> State how analytic or statistical source code used to generate estimates
> can be accessed. (GATHER 14)

> Make the model code available, or document the reasons why this was not
> possible. (EPIFORGE 9)

### OR-17 Authorship and funding

The report names its authors and its funding sources.

GATHER item 2, ISPOR-7.

> List the funding sources for the work. (GATHER 2)

### OR-18 Contact and feedback route

The report says how to raise a correction or a question, and with whom.

No source found. Ours. GATHER 5 requires a contact for data that cannot be
shared, which is a narrower case.

### OR-19 Methods sufficient to reproduce

The technical document describes every step of the analysis, including the
mathematics, in enough detail to reproduce it.

GATHER item 10, EPIFORGE item 3, ISPOR-7, TRACE.

> Provide a detailed description of all steps of the analysis, including
> mathematical formulae. This description should cover, as relevant, data
> cleaning, data pre-processing, data adjustments and weighting of data
> sources, and mathematical or statistical model(s). (GATHER 10)

> Fully document the methods. (EPIFORGE 3)

### OR-20 Model evaluation and comparison

The technical document reports how the model was evaluated and how it compares
with other published estimates.

GATHER items 11 and 12, EPIFORGE item 10, TRACE.

> Describe how candidate models were evaluated and how the final model(s) were
> selected. (GATHER 11)

> Provide the results of an evaluation of model performance, if done, as well
> as the results of any relevant sensitivity analysis. (GATHER 12)

> Describe the model validation, and justify the approach. (EPIFORGE 10)

### OR-21 Inference diagnostics stay technical

Sampler diagnostics do not appear in the non-technical document.

ISPOR-7, by exclusion. Its non-technical list is closed and contains no
diagnostic of the fitting algorithm. No source guideline asks for one in a
document written for decision makers.

### OR-22 Prior sensitivity stays technical

Prior-data conflict diagnostics do not appear in the non-technical document.

ISPOR-7, by exclusion, as above. GATHER 12 places sensitivity analysis results
in the methods and results of the study, not in the non-technical summary.

### OR-23 Component decomposition stays technical

Per-stream or per-component decompositions do not appear in the non-technical
document, beyond a link.

ISPOR-7, by exclusion. Ours in its specific form.

## Sources

GATHER. Stevens GA, Alkema L, Black RE, et al. Guidelines for Accurate and
Transparent Health Estimates Reporting: the GATHER statement. PLOS Medicine
2016;13(6):e1002056. 18 items. Quotations are from Table 1.

EPIFORGE. Pollett S, Johansson MA, Reich NG, et al. Recommended reporting
items for epidemic forecasting and prediction research: The EPIFORGE 2020
guidelines. PLOS Medicine 2021;18(10):e1003793. 19 items, Delphi with 46
panellists. Quotations are from Table 1.

ISPOR-7. Eddy DM, Hollingworth W, Caro JJ, et al. Model Transparency and
Validation: A Report of the ISPOR-SMDM Modeling Good Research Practices Task
Force-7. Value in Health 2012;15(6):843-850. Quotation is from the abstract.

ORBIT. Gregoire V, Zhu AW, Haines CA, Rivers CM. Public reporting guidelines
for outbreak data. Public Health 2026. 9 items, Delphi. Bounds this list
rather than overlapping it: it covers surveillance counts an authority
publishes and contains no item on model-derived estimates.

WHO Rapid Risk Assessment template v2.1 and its accompanying guidance.
Paraphrased, see OR-13.

TRACE. Grimm V, Augusiak J, Focks A, et al. Towards better modelling and
decision support: Documenting model development, testing, and analysis using
TRACE. Ecological Modelling 2014;280:129-139. Eight elements of model
documentation. Cited for structure only; element names taken from secondary
description, not quoted.

## What this list does not cover

Surveillance counts an authority publishes. That is ORBIT, which reached
consensus on nine items and is the standard to follow for those.

> The Delphi process yielded nine core reporting items representing a minimum
> standard for public outbreak reporting: numbers of new confirmed cases, new
> hospital admissions, new deaths, cumulative confirmed cases, cumulative
> hospital admissions, and cumulative deaths, each reported weekly and at
> Administrative Level 1 (typically state or province), and stratified by sex,
> age group, and race/ethnicity. (ORBIT abstract)

Prose style. Where a report carries its own writing conventions, those take
precedence over anything implied here.
