# Reporting items for real-time outbreak estimates

Items for reporting a modelled estimate of an outbreak that is recomputed and republished as new data arrive.
Each item is stated as an assertion about the report that can be checked, with the document it belongs to, its sources, and the source text.

Sources are GATHER, EPIFORGE 2020, ISPOR-SMDM Task Force-7, TRACE, ORBIT, the WHO rapid risk assessment manual, the PHIA probability yardstick, and three studies of how readers use modelled estimates.

Ids are stable and are not the presentation order.
Retire an item rather than renumbering.

## Gap addressed

Three properties define the scope.
No single existing source has all three.

Real-time.
GATHER, EPIFORGE and ISPOR-7 assume a document published once.
Six items here exist because the report is republished: OR-03, OR-04, OR-05, OR-11, OR-15 and OR-26.

Synthesis.
ORBIT sets a minimum standard for the surveillance counts an authority publishes and carries no item on a modelled estimate.
GATHER covers health estimates without reference to outbreak response.
EPIFORGE covers forecasting as research rather than as a published report.
Each item below records which sources support it and where they are silent.

Agentic use.
Each item is worded as an assertion about the report, so it can be checked by a reader or by an agent against a page.

## Audience

The primary reader is a technically literate responder or analyst, at a national institute, a ministry, WHO, an NGO or a partner agency, who works with outbreak data and does not build models.
Secondary readers are modelling peers and the press.

Three references set this audience.

GATHER names two audiences and separates what each needs:

> Reporting of estimates should serve the needs of their two primary audiences: decision makers and researchers.
> \[...\] These users need information about data sources and analysis methods, including key assumptions and limitations, in a way that is accessible without advanced training in statistics.
> They also need an explanation of how new estimates compare to previously published estimates, including why they differ.
> Researchers require a higher degree of detail about methods, so that they can fully understand and potentially reproduce studies and advance methods.

ISPOR-7 requires the non-technical description to be unrestricted, which sets the lower bound on assumed expertise.

Hadley et al. interviewed policy and decision makers and science advisors in 13 countries about modelled COVID-19 evidence.
The reader-side items below are drawn from that population, so the audience is defined to match the population the evidence was collected from.

## Two documents

Non-technical: one document for the primary reader, available to anyone.

Technical: methods, evaluation and diagnostics, sufficient for a peer to reproduce.

ISPOR-7 defines the split:

> A nontechnical description should be made available to anyone — including model type and intended applications; funding sources; structure; inputs, outputs, other components that determine function, and their relationships; data sources; validation methods and results; and limitations.
> Technical documentation, written in sufficient detail to enable a reader with necessary expertise to evaluate the model and potentially reproduce it, should be made available openly or under agreements that protect intellectual property.

TRACE states the reading behaviour the split assumes:

> Readers will first want to see an overview and only then decide whether and where to go into more detail.
> Thus, to allow for hierarchical reading and to keep TRACE documents concise and readable, it is critical to start the entire document and each of its sections with an executive summary.
> \[...\] In general, summaries should always come first and details later.

## Index

Items are grouped by theme, and within a theme by the number of independent sources supporting them.
Items with no published source are last within their theme.
The sources column counts guidelines, with reader studies in brackets.

### Non-technical document

| Id    | Item                                         | Sources | Real-time |
|-------|----------------------------------------------|---------|-----------|
| OR-01 | Purpose and intended use                     | 4       |           |
| OR-24 | Domain of applicability                      | 1       |           |
| OR-02 | Quantities defined before use                | 1       |           |
| OR-09 | Known biases in the inputs                   | 2 (1)   |           |
| OR-08 | Data sources named                           | 2       |           |
| OR-06 | Headline estimate with one interval          | 2 (3)   |           |
| OR-27 | Bounded set of headline estimates            | 1 (1)   |           |
| OR-10 | Sources of uncertainty included and excluded | 1       |           |
| OR-13 | Confidence statement                         | 1       |           |
| OR-25 | Verbal probability on a defined scale        | 1       |           |
| OR-12 | Limitations                                  | 3       |           |
| OR-07 | Non-technical summary of results             | 2 (1)   |           |
| OR-14 | Implications for action                      | 2       |           |
| OR-03 | Data cut-off                                 | 1       | yes       |
| OR-05 | Change since the last update                 | 1       | yes       |
| OR-26 | Consistent presentation between updates      | 0 (1)   | yes       |
| OR-04 | Update cadence                               | 0       | yes       |
| OR-11 | Predictive performance                       | 2       | yes       |
| OR-16 | Code available                               | 2       |           |
| OR-15 | Estimates available as data                  | 2       | yes       |
| OR-17 | Authorship and funding                       | 2       |           |
| OR-18 | Contact and feedback route                   | 0       |           |

### Technical document

| Id    | Item                                    | Sources | Real-time |
|-------|-----------------------------------------|---------|-----------|
| OR-19 | Methods sufficient to reproduce         | 4       |           |
| OR-20 | Model evaluation and comparison         | 3       |           |
| OR-22 | Prior sensitivity stays technical       | 2       |           |
| OR-21 | Inference diagnostics stay technical    | 1       |           |
| OR-23 | Component decomposition stays technical | 1       |           |

## Scope and purpose

### OR-01 Purpose and intended use

Recommendation: the report states what the estimate is for and which decisions it is intended to support.

Explanation: the intended use determines which quantities are reported and which readers the report is written for.
All four guidelines place it first.

Sources: GATHER 1, EPIFORGE 2, TRACE 1, ISPOR-7.

> Define the indicator(s), populations (including age, sex, and geographic entities), and time period(s) for which estimates were made.
> (GATHER 1)

> Define the purpose of study and forecasting targets.
> (EPIFORGE 2)

> The decision-making context in which the model will be used; the types of model clients or stakeholders addressed; a precise specification of the question(s) that should be answered with the model, including a specification of necessary model outputs.
> (TRACE 1, problem formulation)

### OR-24 Domain of applicability

Recommendation: the report states what the estimate should not be used for, and the limits of acceptable extrapolation.

Explanation: the complement of OR-01.
No other source in this list states it.

Sources: TRACE 1.

> \[...\] and a statement of the domain of applicability of the model, including the extent of acceptable extrapolations.
> (TRACE 1, problem formulation)

### OR-02 Quantities defined before use

Recommendation: every reported quantity is defined in words before its first number, including the population and geography it covers.

Explanation: GATHER 1 requires the definition.
The ordering requirement is ours, and applies where a report presents tables and figures before the narrative that defines them.

Sources: GATHER 1, quoted at OR-01.
Ordering: ours.

## Data and inputs

### OR-09 Known biases in the inputs

Recommendation: the report identifies which input data carry potentially important biases.

Explanation: an estimate cannot be weighed without knowing which inputs are systematically wrong and in which direction.

Sources: GATHER 6, TRACE 3, Hadley et al.

> Identify and describe any categories of input data that have potentially important biases (e.g., based on characteristics listed in item 5).
> (GATHER 6)

> The quality and sources of numerical and qualitative data used to parameterize the model \[...\] This critical evaluation will allow model users to assess the scope and the uncertainty of the data and knowledge on which the model is based.
> (TRACE 3, data evaluation)

> in a few countries presenting numbers of cases for example was quickly deemed ineffective, since this metric is not accurate and is heavily dependent \[on testing\].
> (Hadley et al. 2025)

### OR-08 Data sources named

Recommendation: the report names each data source, who produces it, and the period it covers.

Sources: GATHER 5, ORBIT.

> Provide information about all included data sources and their main characteristics.
> For each data source used, report reference information or contact name/institution, population represented, data collection method, year(s) of data collection, sex and age range, diagnostic criteria or measurement method, and sample size, as relevant.
> (GATHER 5)

## Estimates and uncertainty

### OR-06 Headline estimate with one interval

Recommendation: each headline quantity is given with a single uncertainty interval, whose meaning is stated in words at or before first use.

Explanation: the guidelines require an interval and do not specify how many levels.
Padilla et al. found that readers did not scale trust to interval width, and that the display readers trusted most produced the least accurate trend predictions.
The restriction to one level supports legibility and not comprehension.

Sources: GATHER 16, EPIFORGE 14, with reader evidence from Padilla et al., Hadley et al. and McCabe et al.
Restriction to one level: ours.

> Report a quantitative measure of the uncertainty of the estimates (e.g., uncertainty intervals).
> (GATHER 16)

> Present and explain uncertainty of forecasting results.
> (EPIFORGE 14)

> participants were most trusting of visualizations that showed less visual information, including a 95% confidence interval, single forecast, and grayscale encoded forecasts.
> Participants maintained high trust in intervals labeled with 50% and 25% and did not proportionally scale their trust to the indicated interval size.
> (Padilla et al. 2023)

> Despite the high trust, the 95% CI condition was the most likely to evoke predictions that did not correspond with the actual COVID-19 trend.
> (Padilla et al. 2023)

> diagrams with extremely wide confidence intervals were not helpful, dubbed "crayon diagrams" - diagrams with huge uncertainty that could have been drawn with a crayon.
> (Hadley et al. 2025)

### OR-27 Bounded set of headline estimates

Recommendation: where the report presents several estimates together, it names which of them are headline, keeps that set small and unchanged between updates, and presents each in the same form.

Explanation: a report presenting many quantities at once gives no ordering, and a repeat reader cannot tell which quantity to follow.
GATHER 1 requires each indicator to be defined but does not bound the set.
Reader evidence supports a small set and a preference for operational quantities over model parameters.

Sources: GATHER 1, Hadley et al.
Bounding the set: ours.

> the vast majority of interviewees without prompt first stressed the need for simple graphics.
> (Hadley et al. 2025)

> oversharing of information (i.e. scientific detail) is perceived as useless to policymakers.
> (Hadley et al. 2025)

> Streamlining advice by presenting modelling findings in terms of these more operational concepts (doubling time, time to X, hospitalisations, deaths) was preferred in a few different settings.
> (Hadley et al. 2025)

### OR-10 Sources of uncertainty included and excluded

Recommendation: the report states which sources of uncertainty the intervals account for, and which they do not.

Sources: GATHER 13.

> Describe methods of calculating uncertainty of the estimates.
> State which sources of uncertainty were, and were not, accounted for in the uncertainty analysis.
> (GATHER 13)

### OR-13 Confidence statement

Recommendation: the report states in one sentence of plain language how much confidence to place in the headline estimate.

Explanation: the confidence axis, distinct from the likelihood axis at OR-25 and from the numeric interval at OR-06.
WHO assesses a public health risk rather than a model estimate, so the descriptive scale transfers and the hazard, exposure and context structure does not.

Sources: WHO rapid risk assessment manual.
Transfer to a model estimate: ours.

> It is important to document the risk assessment team's level of confidence in the assessment and the reasons for any limitations.
> This will depend on the reliability, completeness and quality of the information used, and the underlying assumptions made with respect to the hazard, exposure and context.
> \[...\] The degree of confidence can be expressed using a descriptive scale that ranges from very low to very high.
> (WHO 2012, p23)

> It should be emphasized that a quantitative risk assessment that uses poor data or inappropriate quantitative techniques can be far less scientific and defensible than a well-structured qualitative assessment.
> (WHO 2012, p25)

> Whereas probability reflects the likelihood that a statement is true, analytical confidence reflects the soundness and stability of the foundations on which the assessment of likelihood has been made.
> (PHIA)

### OR-25 Verbal probability on a defined scale

Recommendation: where the report expresses a probability in words, the words come from a published scale, and the scale is stated or linked.

Explanation: applies only where the report carries prose, which is OR-07.
A report of numbers alone does not trigger it.
The yardstick is UK intelligence practice rather than health reporting.
A published scale narrows the spread in how readers interpret probability words without closing it.

Sources: PHIA probability yardstick.
Transfer to outbreak reporting: ours.

> > 0% - \~5%: Remote Chance.
> > \~10% - \~20%: Highly Unlikely.
> > \~25% - \~35%: Unlikely.
> > \~40% - \<50%: Realistic Possibility.
> > \~55% - \~75%: Likely or Probable.
> > \~80% - \~90%: Highly Likely.
> > \~95% - \<100%: Almost Certain.
> > (PHIA)

> The application of a standard process and terminology reduces or mitigates subjectivity in the evaluation process, enabling consistency in how the relative strengths and limitations of an assessment are identified, explained and communicated.
> (PHIA)

## Interpretation

### OR-12 Limitations

Recommendation: the report states its limitations, including the modelling assumptions and data limitations that affect interpretation.

Sources: GATHER 18, EPIFORGE 17, ISPOR-7.

> Discuss limitations of the estimates.
> Include a discussion of any modelling assumptions or data limitations that affect interpretation of the estimates.
> (GATHER 18)

> Describe the weaknesses of the forecast, including weaknesses specific to data quality and methods.
> (EPIFORGE 17)

### OR-07 Non-technical summary of results

Recommendation: the report summarises the results in non-technical terms, including a non-technical interpretation of the uncertainty.

Explanation: the summary is passed on by readers who are not modellers, so it must survive restatement by them.

Sources: EPIFORGE 15, ISPOR-7, Hadley et al.

> Briefly summarize the results in nontechnical terms, including a nontechnical interpretation of forecast uncertainty.
> (EPIFORGE 15)

> Several respondents also identified a focus on whether what modellers explained could be easily explained and translated again by non-modellers.
> (Hadley et al. 2025)

### OR-14 Implications for action

Recommendation: the report states what its results imply for public health action and decision-making.

Explanation: WHO pairs the confidence statement at OR-13 with the recommendation in a single step.

Sources: EPIFORGE 18, WHO rapid risk assessment manual.

> If the research is applicable to a specific epidemic, comment on its potential implications and impact for public health action and decisionmaking.
> (EPIFORGE 18)

> Undertake a full risk assessment and state the level of confidence in the assessment.
> Provide recommendations for decision-makers, including which actions should be taken and which should have the highest priority.
> (WHO 2012, p7)

## Currency and change

### OR-03 Data cut-off

Recommendation: the report states the date the data were current to, and which situation report or release that corresponds to.

Sources: EPIFORGE 4.

> Identify whether the forecast was performed prospectively, in real time, and/or retrospectively.
> (EPIFORGE 4)

### OR-05 Change since the last update

Recommendation: the report states how the headline estimate has changed since the previous version, and why it changed.

Explanation: GATHER requires the reason, not only the series of past estimates.

Sources: GATHER 17.

> Interpret results in light of existing evidence.
> If updating a previous set of estimates, describe the reasons for changes in estimates.
> (GATHER 17)

### OR-26 Consistent presentation between updates

Recommendation: successive updates keep the same quantities, in the same order, in the same format, and say so when that changes.

Explanation: no guideline carries this item, because a document published once cannot be inconsistent with itself.
It constrains every other item, since a change made to satisfy one breaks continuity with the previous edition.
OR-05 is the resolution.

Sources: Hadley et al.

> Lastly, interviewees agreed that consistency in colours, styles, graphs etc. is important.
> "Be consistent with the way you packaged the first information".
> Presenting in the same format each week enabled policymakers and advisors to gain familiarity and to provide a pattern of feedback.
> (Hadley et al. 2025)

### OR-04 Update cadence

Recommendation: the report states how often it is updated and when the next update is due.

Explanation: without a cadence a reader cannot tell whether a number is current.
No published source found.

Sources: none.
Ours.

## Performance

### OR-11 Predictive performance

Recommendation: where the report forecasts, it states how its previous forecasts performed, against a named comparator.

Explanation: EPIFORGE places the evaluation in the methods of a study.
Surfacing the result in the non-technical document is ours.
TRACE separates agreement with the data used in fitting from comparison against data not used, and only the second is evidence of prediction.

Sources: EPIFORGE 11, EPIFORGE 12, TRACE 8.
Placement in the non-technical document: ours.

> Describe the forecast accuracy evaluation method used, with justification.
> (EPIFORGE 11)

> Where possible, compare model results to a benchmark or other comparator model, with justification of comparator choice.
> (EPIFORGE 12)

> How model predictions compare to independent data and patterns that were not used, and preferably not even known, while the model was developed, parameterized, and verified.
> (TRACE 8, model output corroboration)

## Access

### OR-16 Code available

Recommendation: the analysis code is accessible, and the report says where.

Sources: GATHER 14, EPIFORGE 9.

> State how analytic or statistical source code used to generate estimates can be accessed.
> (GATHER 14)

> Make the model code available, or document the reasons why this was not possible.
> (EPIFORGE 9)

### OR-15 Estimates available as data

Recommendation: the published estimates are downloadable in a format data can be extracted from, carrying a version or timestamp.

Sources: GATHER 15, EPIFORGE 16.

> Provide published estimates in a file format from which data can be efficiently extracted.
> (GATHER 15)

> If results are published as a data object, encourage a time-stamped version number.
> (EPIFORGE 16)

### OR-17 Authorship and funding

Recommendation: the report names its authors and its funding sources.

Sources: GATHER 2, ISPOR-7.

> List the funding sources for the work.
> (GATHER 2)

### OR-18 Contact and feedback route

Recommendation: the report states how to raise a correction or a question, and with whom.

Explanation: no published source found.
GATHER 5 requires a contact for data that cannot be shared, which is a narrower case.

Sources: none.
Ours.

## Technical document

### OR-19 Methods sufficient to reproduce

Recommendation: the technical document describes every step of the analysis, including the mathematics, in enough detail to reproduce it.

Sources: GATHER 10, EPIFORGE 3, ISPOR-7, TRACE 2.

> Provide a detailed description of all steps of the analysis, including mathematical formulae.
> This description should cover, as relevant, data cleaning, data pre-processing, data adjustments and weighting of data sources, and mathematical or statistical model(s).
> (GATHER 10)

> Fully document the methods.
> (EPIFORGE 3)

> The model, i.e. a detailed written model description.
> \[...\] Model users should learn what the model is, how it works, and what guided its design.
> (TRACE 2, model description)

### OR-20 Model evaluation and comparison

Recommendation: the technical document reports how the model was evaluated and how it compares with other published estimates.

Sources: GATHER 11, GATHER 12, EPIFORGE 10, TRACE 6, TRACE 8.

> Describe how candidate models were evaluated and how the final model(s) were selected.
> (GATHER 11)

> Provide the results of an evaluation of model performance, if done, as well as the results of any relevant sensitivity analysis.
> (GATHER 12)

> Describe the model validation, and justify the approach.
> (EPIFORGE 10)

> (1) How well model output matches observations and (2) how much calibration and effects of environmental drivers were involved in obtaining good fits of model output and data. (TRACE 6, model output verification)

## Exclusions

These items state what the non-technical document does not contain.
Each is supported by exclusion: the ISPOR-7 non-technical list is closed and contains no such entry.

### OR-22 Prior sensitivity stays technical

Recommendation: prior-data conflict diagnostics do not appear in the non-technical document.

Sources: ISPOR-7 by exclusion, GATHER 12, TRACE 7.

> (1) How sensitive model output is to changes in model parameters (sensitivity analysis), and (2) how well the emergence of model output has been understood. (TRACE 7, model analysis)

### OR-21 Inference diagnostics stay technical

Recommendation: sampler diagnostics do not appear in the non-technical document.

Sources: ISPOR-7 by exclusion.

### OR-23 Component decomposition stays technical

Recommendation: per-stream or per-component decompositions do not appear in the non-technical document, beyond a link.

Sources: ISPOR-7 by exclusion.
Specific form: ours.

## Sources

GATHER. Stevens GA, Alkema L, Black RE, et al.
Guidelines for Accurate and Transparent Health Estimates Reporting: the GATHER statement.
PLOS Medicine 2016;13(6):e1002056.
18 items.
Quotations are from Table 1.

EPIFORGE. Pollett S, Johansson MA, Reich NG, et al.
Recommended reporting items for epidemic forecasting and prediction research: The EPIFORGE 2020 guidelines.
PLOS Medicine 2021;18(10):e1003793.
19 items, Delphi with 46 panellists.
Quotations are from Table 1.

ISPOR-7.
Eddy DM, Hollingworth W, Caro JJ, et al.
Model Transparency and Validation: A Report of the ISPOR-SMDM Modeling Good Research Practices Task Force-7.
Value in Health 2012;15(6):843-850.
Quotation is from the abstract.

TRACE. Grimm V, Augusiak J, Focks A, et al.
Towards better modelling and decision support: Documenting model development, testing, and analysis using TRACE.
Ecological Modelling 2014;280:129-139.
Eight elements.
Quotations are from Table 1.

ORBIT. Gregoire V, Zhu AW, Haines CA, Rivers CM. Public reporting guidelines for outbreak data.
Public Health 2026.
9 items, Delphi.
Covers the surveillance counts an authority publishes and carries no item on a modelled estimate.

WHO. Rapid Risk Assessment of Acute Public Health Events.
Geneva: World Health Organization, 2012.
WHO/HSE/GAR/ARO/2012.1.
Quotations are from the sections "Level of confidence in the risk assessment" and "Quantification in risk assessment", and from the response-actions table.

PHIA. Professional Head of Intelligence Assessment probability yardstick, in Explaining uncertainty in UK intelligence assessment.
UK Government.
Seven probability bands, and the distinction between probability and analytical confidence.

Hadley L, Kremer P, Pulford J, et al.
Visual preferences for communicating modelling: a global analysis of COVID-19 policy and decision makers.
medRxiv 2025, 10.1101/2024.11.05.24316774.
Interviews with policy and decision makers and science advisors in 13 countries.
Preprint.

Padilla L, Hosseinpour H, Fygenson R, et al.
Multiple Forecast Visualizations: trade-offs in trust and performance in multiple COVID-19 forecast visualizations.
IEEE Transactions on Visualization and Computer Graphics 2023.
Three studies, 1299 participants.

McCabe R, Kont MD, Schmit N, et al.
Communicating uncertainty in epidemic models.
Epidemics 2021;37:100520.
A commentary, cited for its reasoning about audience and presentation.