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

Tailoring to the audience is itself one of three strategies a rapid scoping
review of 16 evidence-communication frameworks identified, alongside
information packaging:

> Three primary evidence communication strategies, comprising eleven
> substrategies, emerged: "Health information packaging", "Targeting and
> tailoring messages to the audience", and "Combined communication
> strategies". (Barreto et al. 2024)

That review covers the process of communicating evidence rather than what a
report must contain, and mentions uncertainty nowhere, so it sources no item
here.

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

TRACE gives the reason the split works, which is that readers descend into
detail only once they have the overview:

> Readers will first want to see an overview and only then decide whether and
> where to go into more detail. Thus, to allow for hierarchical reading and to
> keep TRACE documents concise and readable, it is critical to start the
> entire document and each of its sections with an executive summary. [...]
> In general, summaries should always come first and details later.

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
| OR-24 | Domain of applicability | Non-technical | |
| OR-25 | Verbal probability on a defined scale | Non-technical | |
| OR-26 | Consistent presentation between updates | Non-technical | yes |

The real-time items exist because the report is republished. The source
guidelines assume a document published once, and carry only OR-05 among them.

## Items

### OR-01 Purpose and intended use

The report states what the estimate is for and which decisions it is intended
to support.

GATHER item 1, EPIFORGE item 2, TRACE element 1, ISPOR-7.

> Define the indicator(s), populations (including age, sex, and geographic
> entities), and time period(s) for which estimates were made. (GATHER 1)

> Define the purpose of study and forecasting targets. (EPIFORGE 2)

> The decision-making context in which the model will be used; the types of
> model clients or stakeholders addressed; a precise specification of the
> question(s) that should be answered with the model, including a
> specification of necessary model outputs. (TRACE 1, problem formulation)

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

Neither source specifies a number of levels. The restriction to one for a
headline quantity is ours, and follows from the audience. McCabe et al. put
the audience first but themselves use two levels for a trajectory and one for
the decision-relevant summary:

> The most important considerations when deciding on a data visualisation is
> knowing who the audiences are and ensuring that key messages can be easily
> and quickly absorbed. (McCabe et al. 2021)

> Trajectories are summarised using the median with 50% and 95% credible
> intervals [...] Additionally, we have provided two metrics of importance to
> decision-makers: the timing and the magnitude of peak ICU bed demand per
> simulation, presented as point estimates and 95% credible intervals.
> (McCabe et al. 2021)

Padilla et al. tested this empirically on 1299 participants, and the finding
cuts both ways:

> participants were most trusting of visualizations that showed less visual
> information, including a 95% confidence interval, single forecast, and
> grayscale encoded forecasts. Participants maintained high trust in intervals
> labeled with 50% and 25% and did not proportionally scale their trust to the
> indicated interval size. (Padilla et al. 2023)

> Despite the high trust, the 95% CI condition was the most likely to evoke
> predictions that did not correspond with the actual COVID-19 trend.
> (Padilla et al. 2023)

Readers did not adjust their trust for interval width, which is the argument
for showing one interval and naming it. Trust is not accuracy, though, and the
simplest display produced the worst trend predictions, so this item buys
legibility rather than comprehension.

Policy and decision makers in 13 countries asked for the same simplicity, and
named the opposite failure:

> the vast majority of interviewees without prompt first stressed the need for
> simple graphics. (Hadley et al. 2025)

> diagrams with extremely wide confidence intervals were not helpful, dubbed
> "crayon diagrams" - diagrams with huge uncertainty that could have been
> drawn with a crayon. (Hadley et al. 2025)

### OR-07 Non-technical summary of results

The report summarises the results in non-technical terms, including a
non-technical interpretation of the uncertainty.

EPIFORGE item 15.

> Briefly summarize the results in nontechnical terms, including a
> nontechnical interpretation of forecast uncertainty. (EPIFORGE 15)

Hadley et al. give the test the summary has to pass, which is that somebody
who is not a modeller has to be able to say it again:

> Several respondents also identified a focus on whether what modellers
> explained could be easily explained and translated again by non-modellers.
> (Hadley et al. 2025)

> oversharing of information (i.e. scientific detail) is perceived as useless
> to policymakers. (Hadley et al. 2025)

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

TRACE element 3 asks for the same judgement, and says who it is for:

> The quality and sources of numerical and qualitative data used to
> parameterize the model [...] This critical evaluation will allow model users
> to assess the scope and the uncertainty of the data and knowledge on which
> the model is based. (TRACE 3, data evaluation)

Some readers act on this by dropping the quantity:

> in a few countries presenting numbers of cases for example was quickly
> deemed ineffective, since this metric is not accurate and is heavily
> dependent [on testing]. (Hadley et al. 2025)

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

WHO rapid risk assessment manual, section "Level of confidence in the risk
assessment".

> It is important to document the risk assessment team's level of confidence
> in the assessment and the reasons for any limitations. This will depend on
> the reliability, completeness and quality of the information used, and the
> underlying assumptions made with respect to the hazard, exposure and
> context. The more evidence there is to inform the hazard, exposure and
> context assessments, the greater confidence the team can have in the
> results. The degree of confidence can be expressed using a descriptive scale
> that ranges from very low to very high. (WHO 2012, p23)

The manual assesses a public health risk, not a model estimate, so the
transfer is ours: the scale carries over, the hazard, exposure and context
structure does not. WHO also warns against the failure mode this item guards
against, which is numbers standing in for judgement:

> It should be emphasized that a quantitative risk assessment that uses poor
> data or inappropriate quantitative techniques can be far less scientific and
> defensible than a well-structured qualitative assessment. (WHO 2012, p25)

This item is the confidence axis, not the likelihood axis. The two are
separate and are routinely conflated. See OR-25.

> Whereas probability reflects the likelihood that a statement is true,
> analytical confidence reflects the soundness and stability of the
> foundations on which the assessment of likelihood has been made. (PHIA)

### OR-14 Implications for action

The report comments on what its results imply for public health action and
decision-making.

EPIFORGE item 18, WHO rapid risk assessment manual.

> If the research is applicable to a specific epidemic, comment on its
> potential implications and impact for public health action and
> decisionmaking. (EPIFORGE 18)

WHO pairs the confidence statement with the recommendation, in the same step:

> Undertake a full risk assessment and state the level of confidence in the
> assessment. Provide recommendations for decision-makers, including which
> actions should be taken and which should have the highest priority.
> (WHO 2012, p7)

Hadley et al. found the implication is carried by the choice of quantity, not
only by a closing paragraph:

> Streamlining advice by presenting modelling findings in terms of these more
> operational concepts (doubling time, time to X, hospitalisations, deaths)
> was preferred in a few different settings. (Hadley et al. 2025)

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

> The model, i.e. a detailed written model description. [...] Model users
> should learn what the model is, how it works, and what guided its design.
> (TRACE 2, model description)

### OR-20 Model evaluation and comparison

The technical document reports how the model was evaluated and how it compares
with other published estimates.

GATHER items 11 and 12, EPIFORGE item 10, TRACE.

> Describe how candidate models were evaluated and how the final model(s) were
> selected. (GATHER 11)

> Provide the results of an evaluation of model performance, if done, as well
> as the results of any relevant sensitivity analysis. (GATHER 12)

> Describe the model validation, and justify the approach. (EPIFORGE 10)

TRACE separates fit from independent corroboration, and only the second is
evidence the model predicts:

> (1) How well model output matches observations and (2) how much calibration
> and effects of environmental drivers were involved in obtaining good fits of
> model output and data. (TRACE 6, model output verification)

> How model predictions compare to independent data and patterns that were not
> used, and preferably not even known, while the model was developed,
> parameterized, and verified. (TRACE 8, model output corroboration)

### OR-21 Inference diagnostics stay technical

Sampler diagnostics do not appear in the non-technical document.

ISPOR-7, by exclusion. Its non-technical list is closed and contains no
diagnostic of the fitting algorithm. No source guideline asks for one in a
document written for decision makers.

### OR-22 Prior sensitivity stays technical

Prior-data conflict diagnostics do not appear in the non-technical document.

ISPOR-7, by exclusion, as above. GATHER 12 places sensitivity analysis results
in the methods and results of the study, not in the non-technical summary.
TRACE puts sensitivity in its own technical element:

> (1) How sensitive model output is to changes in model parameters
> (sensitivity analysis), and (2) how well the emergence of model output has
> been understood. (TRACE 7, model analysis)

### OR-23 Component decomposition stays technical

Per-stream or per-component decompositions do not appear in the non-technical
document, beyond a link.

ISPOR-7, by exclusion. Ours in its specific form.

### OR-24 Domain of applicability

The report states what the estimate should not be used for, and the limits of
acceptable extrapolation.

TRACE element 1.

> [...] and a statement of the domain of applicability of the model, including
> the extent of acceptable extrapolations. (TRACE 1, problem formulation)

No other source in this list carries this. It is the only item that tells a
reader where to stop.

### OR-25 Verbal probability on a defined scale

Where the report expresses a probability in words, the words come from a
published scale, and the scale is stated or linked.

PHIA probability yardstick, seven bands:

> >0% - ~5%: Remote Chance. ~10% - ~20%: Highly Unlikely. ~25% - ~35%:
> Unlikely. ~40% - <50%: Realistic Possibility. ~55% - ~75%: Likely or
> Probable. ~80% - ~90%: Highly Likely. ~95% - <100%: Almost Certain. (PHIA)

> The application of a standard process and terminology reduces or mitigates
> subjectivity in the evaluation process, enabling consistency in how the
> relative strengths and limitations of an assessment are identified,
> explained and communicated. (PHIA)

This is the likelihood axis. OR-13 is the confidence axis, and OR-06 is the
numeric interval on a quantity. Three different things.

The item binds only once a report carries plain-language prose, which is
OR-07. A report of numbers alone never triggers it.

Two caveats, both ours. The yardstick is UK intelligence practice, not health
reporting, so the transfer is an argument rather than a precedent. And a
published scale narrows the spread in how readers interpret probability words
without closing it, so a band is a discipline on the writer more than a
guarantee about the reader.

### OR-26 Consistent presentation between updates

Successive updates keep the same quantities, in the same order, in the same
format, and say so when that changes.

Hadley et al. 2025.

> Lastly, interviewees agreed that consistency in colours, styles, graphs etc.
> is important. "Be consistent with the way you packaged the first
> information". Presenting in the same format each week enabled policymakers
> and advisors to gain familiarity and to provide a pattern of feedback.
> (Hadley et al. 2025)

This is the only item sourced to evidence gathered from readers of real
outbreak reports rather than from a guideline committee. It exists because the
report is republished: a document published once cannot be inconsistent with
itself.

It pulls against every other item here, since each change to satisfy one of
them breaks continuity with the last edition. The resolution is OR-05, which
requires the report to say what changed.

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

WHO. Rapid Risk Assessment of Acute Public Health Events. Geneva: World Health
Organization, 2012. WHO/HSE/GAR/ARO/2012.1, 44 pages. Quotations are from the
sections "Level of confidence in the risk assessment" and "Quantification in
risk assessment", and from the response-actions table. Assesses a public
health risk rather than a model estimate, so it is cited for the confidence
scale and its pairing with recommended actions, not for its assessment
structure.

TRACE. Grimm V, Augusiak J, Focks A, et al. Towards better modelling and
decision support: Documenting model development, testing, and analysis using
TRACE. Ecological Modelling 2014;280:129-139. Eight elements of model
documentation. Quotations are from Table 1.

PHIA. Professional Head of Intelligence Assessment probability yardstick, in
Explaining uncertainty in UK intelligence assessment. UK Government. Seven
probability bands, and the distinction between probability and analytical
confidence. UK intelligence practice rather than health reporting, so the
transfer is argued at OR-25 rather than assumed.

Hadley L, Kremer P, Pulford J, et al. Visual preferences for communicating
modelling: a global analysis of COVID-19 policy and decision makers. medRxiv
2025, 10.1101/2024.11.05.24316774. Interviews with policy and decision makers
and science advisors in 13 countries. Preprint. Sources OR-26 and supports
OR-06, OR-07, OR-09 and OR-14.

Padilla L, Hosseinpour H, Fygenson R, et al. Multiple Forecast Visualizations:
trade-offs in trust and performance in multiple COVID-19 forecast
visualizations. IEEE Transactions on Visualization and Computer Graphics 2023.
Three studies, 1299 participants. Cited at OR-06 for both its finding and its
counter-finding.

Barreto JOM, et al. Research evidence communication for policy-makers: a rapid
scoping review on frameworks, guidance and tools. 2024. 16 frameworks for the
process of communicating evidence. Cited in the audience section only. It
sources no item, because it covers how communication is organised rather than
what a report contains, and does not mention uncertainty.

McCabe R, Kont MD, Schmit N, et al. Communicating uncertainty in epidemic
models. Epidemics 2021;37:100520. A commentary rather than a checklist, so it
is cited for its reasoning about audience and presentation, not as the source
of an item.

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
