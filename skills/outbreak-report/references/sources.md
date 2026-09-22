# Sources for the reporting items

Source text and reasoning behind each item in [items.md](items.md), under the same id.
Where an item goes beyond its sources ("ours"), the reasoning is given here.
Where a source is cited without quotation, the entry says so.

## Scope

The items adapt GATHER, EPIFORGE 2020, ISPOR-SMDM Task Force-7 and TRACE, which assume a document published once, to a report that is republished.
OR-04, OR-05 in its real-time form, OR-26 and part of OR-03 arise only on republication.
ORBIT covers the surveillance counts an authority publishes and carries no item on a modelled estimate, so it is out of scope.

## Reader

GATHER names two audiences and separates what each needs:

> Reporting of estimates should serve the needs of their two primary audiences: decision makers and researchers.
> \[...\] These users need information about data sources and analysis methods, including key assumptions and limitations, in a way that is accessible without advanced training in statistics.
> They also need an explanation of how new estimates compare to previously published estimates, including why they differ.
> Researchers require a higher degree of detail about methods, so that they can fully understand and potentially reproduce studies and advance methods.

ISPOR-7 sets no expertise requirement for the non-technical document:

> Nontechnical documentation should be accessible to any interested reader.

Hadley et al. interviewed policy and decision makers and science advisors in 13 countries about modelled COVID-19 evidence.
The reader evidence cited below comes from that population.

## Two documents

ISPOR-7 defines the split:

> A nontechnical description should be made available to anyone — including model type and intended applications; funding sources; structure; inputs, outputs, other components that determine function, and their relationships; data sources; validation methods and results; and limitations.
> Technical documentation, written in sufficient detail to enable a reader with necessary expertise to evaluate the model and potentially reproduce it, should be made available openly or under agreements that protect intellectual property.

TRACE states the reading order the split assumes:

> Readers will first want to see an overview and only then decide whether and where to go into more detail.
> \[...\] In general, summaries should always come first and details later.

## Items

### OR-01 Purpose and intended use

All four guidelines place it first. ISPOR-7: "model type and intended applications", quoted under Two documents.

> Define the indicator(s), populations (including age, sex, and geographic entities), and time period(s) for which estimates were made.
> (GATHER 1)

> Define the purpose of study and forecasting targets.
> (EPIFORGE 2)

> The decision-making context in which the model will be used; the types of model clients or stakeholders addressed; a precise specification of the question(s) that should be answered with the model, including a specification of necessary model outputs.
> (TRACE 1, problem formulation)

### OR-24 Domain of applicability

The complement of OR-01. No other source here states it.

> \[...\] and a statement of the domain of applicability of the model, including the extent of acceptable extrapolations.
> (TRACE 1, problem formulation)

### OR-02 Quantities defined before use

GATHER 1, quoted at OR-01, requires the definition.
The ordering requirement is ours, and applies where a report presents tables and figures before the narrative that defines them.

### OR-09 Known biases in the inputs

> Identify and describe any categories of input data that have potentially important biases (e.g., based on characteristics listed in item 5).
> (GATHER 6)

> The quality and sources of numerical and qualitative data used to parameterize the model \[...\] This critical evaluation will allow model users to assess the scope and the uncertainty of the data and knowledge on which the model is based.
> (TRACE 3, data evaluation)

> in a few countries presenting numbers of cases for example was quickly deemed ineffective, since this metric is not accurate and is heavily dependent \[on testing\].
> (Hadley et al. 2025)

### OR-08 Data sources named

> Provide information about all included data sources and their main characteristics.
> For each data source used, report reference information or contact name/institution, population represented, data collection method, year(s) of data collection, sex and age range, diagnostic criteria or measurement method, and sample size, as relevant.
> (GATHER 5)

### OR-06 Headline estimate with one interval

The guidelines require an interval and do not say how many levels.
Restricting the headline to one level is ours, for legibility.
The reader evidence does not show that one level improves understanding: Padilla et al. found readers did not scale trust to interval width, and the single 95% interval they trusted most gave the least accurate predictions.
That is why the item asks for the meaning of the interval in words, not only its level.

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

A report presenting many quantities at once gives no ordering, and a repeat reader cannot tell which to follow.
GATHER 1 requires each indicator to be defined but does not bound the set; bounding it is ours.

> the vast majority of interviewees without prompt first stressed the need for simple graphics.
> (Hadley et al. 2025)

> oversharing of information (i.e. scientific detail) is perceived as useless to policymakers.
> (Hadley et al. 2025)

> Streamlining advice by presenting modelling findings in terms of these more operational concepts (doubling time, time to X, hospitalisations, deaths) was preferred in a few different settings.
> (Hadley et al. 2025)

### OR-10 Sources of uncertainty included and excluded

> Describe methods of calculating uncertainty of the estimates.
> State which sources of uncertainty were, and were not, accounted for in the uncertainty analysis.
> (GATHER 13)

### OR-13 Confidence statement

WHO assesses a public health risk rather than a model estimate, so its descriptive scale transfers and its hazard, exposure and context structure does not.
The transfer is ours.

> It is important to document the risk assessment team's level of confidence in the assessment and the reasons for any limitations.
> This will depend on the reliability, completeness and quality of the information used, and the underlying assumptions made with respect to the hazard, exposure and context.
> \[...\] The degree of confidence can be expressed using a descriptive scale that ranges from very low to very high.
> (WHO 2012, p23)

> It should be emphasized that a quantitative risk assessment that uses poor data or inappropriate quantitative techniques can be far less scientific and defensible than a well-structured qualitative assessment.
> (WHO 2012, p25)

> Whereas probability reflects the likelihood that a statement is true, analytical confidence reflects the soundness and stability of the foundations on which the assessment of likelihood has been made.
> (PHIA)

### OR-25 Verbal probability on a defined scale

The yardstick is UK intelligence practice rather than health reporting; the transfer is ours.
It is one published scale among several.

> 0% - \~5%: Remote Chance.
> \~10% - \~20%: Highly Unlikely.
> \~25% - \~35%: Unlikely.
> \~40% - \<50%: Realistic Possibility.
> \~55% - \~75%: Likely or Probable.
> \~80% - \~90%: Highly Likely.
> \~95% - \<100%: Almost Certain.
> (PHIA)

> The application of a standard process and terminology reduces or mitigates subjectivity in the evaluation process, enabling consistency in how the relative strengths and limitations of an assessment are identified, explained and communicated.
> (PHIA)

### OR-12 Limitations

ISPOR-7 lists "limitations" in the non-technical description, quoted under Two documents.

> Discuss limitations of the estimates.
> Include a discussion of any modelling assumptions or data limitations that affect interpretation of the estimates.
> (GATHER 18)

> Describe the weaknesses of the forecast, including weaknesses specific to data quality and methods.
> (EPIFORGE 17)

### OR-07 Non-technical summary of results

TRACE's summary-first ordering is quoted under Two documents.

> Briefly summarize the results in nontechnical terms, including a nontechnical interpretation of forecast uncertainty.
> (EPIFORGE 15)

> Several respondents also identified a focus on whether what modellers explained could be easily explained and translated again by non-modellers.
> (Hadley et al. 2025)

### OR-14 Implications for action

WHO pairs the confidence statement (OR-13) with the recommendation in a single step.

> If the research is applicable to a specific epidemic, comment on its potential implications and impact for public health action and decisionmaking.
> (EPIFORGE 18)

> Undertake a full risk assessment and state the level of confidence in the assessment.
> Provide recommendations for decision-makers, including which actions should be taken and which should have the highest priority.
> (WHO 2012, p7)

### OR-03 Data cut-off

EPIFORGE 4 asks whether a forecast was made in real time, which implies but does not require the date.
Requiring the date is ours.

> Identify whether the forecast was performed prospectively, in real time, and/or retrospectively.
> (EPIFORGE 4)

### OR-05 Change since the last update

GATHER requires the reason, not only the series of past estimates.

> Interpret results in light of existing evidence.
> If updating a previous set of estimates, describe the reasons for changes in estimates.
> (GATHER 17)

### OR-26 Consistent presentation between updates

No guideline carries this item, because a document published once cannot be inconsistent with itself.

> Lastly, interviewees agreed that consistency in colours, styles, graphs etc. is important.
> "Be consistent with the way you packaged the first information".
> Presenting in the same format each week enabled policymakers and advisors to gain familiarity and to provide a pattern of feedback.
> (Hadley et al. 2025)

### OR-04 Update cadence

No published source found. Ours.

### OR-11 Predictive performance

EPIFORGE places the evaluation in the methods of a study; surfacing the result in the non-technical document is ours.
TRACE separates agreement with the data used in fitting from comparison against data not used, and only the second is evidence of prediction.

> Describe the forecast accuracy evaluation method used, with justification.
> (EPIFORGE 11)

> Where possible, compare model results to a benchmark or other comparator model, with justification of comparator choice.
> (EPIFORGE 12)

> How model predictions compare to independent data and patterns that were not used, and preferably not even known, while the model was developed, parameterized, and verified.
> (TRACE 8, model output corroboration)

### OR-16 Code available

> State how analytic or statistical source code used to generate estimates can be accessed.
> (GATHER 14)

> Make the model code available, or document the reasons why this was not possible.
> (EPIFORGE 9)

### OR-15 Estimates available as data

> Provide published estimates in a file format from which data can be efficiently extracted.
> (GATHER 15)

> If results are published as a data object, encourage a time-stamped version number.
> (EPIFORGE 16)

### OR-17 Authorship and funding

ISPOR-7 lists "funding sources" in the non-technical description, quoted under Two documents.

> List the funding sources for the work.
> (GATHER 2)

### OR-18 Contact and feedback route

No published source found. Ours.
GATHER 5 (quoted at OR-08) requires a contact for data that cannot be shared, a narrower case.

### OR-21 Model diagnostics stay technical

Merges former OR-21 (inference diagnostics), OR-22 (prior sensitivity) and OR-23 (component decomposition).
The ISPOR-7 non-technical list contains validation results but no diagnostics.
The list is indicative ("including"), so its silence is weak support.
The main reason is the reader, who does not develop models and cannot act on a diagnostic.
TRACE places sensitivity analysis in model analysis, a technical element:

> (1) How sensitive model output is to changes in model parameters (sensitivity analysis), and (2) how well the emergence of model output has been understood.
> (TRACE 7, model analysis)

### OR-19 Methods sufficient to reproduce

ISPOR-7's technical documentation requirement is quoted under Two documents.

> Provide a detailed description of all steps of the analysis, including mathematical formulae.
> This description should cover, as relevant, data cleaning, data pre-processing, data adjustments and weighting of data sources, and mathematical or statistical model(s).
> (GATHER 10)

> Fully document the methods.
> (EPIFORGE 3)

> The model, i.e. a detailed written model description.
> \[...\] Model users should learn what the model is, how it works, and what guided its design.
> (TRACE 2, model description)

### OR-20 Model evaluation and comparison

TRACE 7 is quoted at OR-21.

> Describe how candidate models were evaluated and how the final model(s) were selected.
> (GATHER 11)

> Provide the results of an evaluation of model performance, if done, as well as the results of any relevant sensitivity analysis.
> (GATHER 12)

> Describe the model validation, and justify the approach.
> (EPIFORGE 10)

> (1) How well model output matches observations and (2) how much calibration and effects of environmental drivers were involved in obtaining good fits of model output and data.
> (TRACE 6, model output verification)

## References

GATHER. Stevens GA, Alkema L, Black RE, et al.
Guidelines for Accurate and Transparent Health Estimates Reporting: the GATHER statement.
PLOS Medicine 2016;13(6):e1002056.
18 items. Quotations are from Table 1.

EPIFORGE. Pollett S, Johansson MA, Reich NG, et al.
Recommended reporting items for epidemic forecasting and prediction research: The EPIFORGE 2020 guidelines.
PLOS Medicine 2021;18(10):e1003793.
19 items, Delphi with 46 panellists. Quotations are from Table 1.

ISPOR-7. Eddy DM, Hollingworth W, Caro JJ, et al.
Model Transparency and Validation: A Report of the ISPOR-SMDM Modeling Good Research Practices Task Force-7.
Value in Health 2012;15(6):843-850.
Quotations are from the abstract and from the Transparency section, under "Nontechnical Documentation" and "Public Versus Confidential Documentation".

TRACE. Grimm V, Augusiak J, Focks A, et al.
Towards better modelling and decision support: Documenting model development, testing, and analysis using TRACE.
Ecological Modelling 2014;280:129-139.
Eight elements. Quotations are from Table 1.

ORBIT. Gregoire V, Zhu AW, Haines CA, Rivers CM. Public reporting guidelines for outbreak data.
Public Health 2026.
9 items, Delphi. Covers surveillance counts, not modelled estimates.

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
Interviews with policy and decision makers and science advisors in 13 countries. Preprint.

Padilla L, Hosseinpour H, Fygenson R, et al.
Multiple Forecast Visualizations: trade-offs in trust and performance in multiple COVID-19 forecast visualizations.
IEEE Transactions on Visualization and Computer Graphics 2023.
Three studies, 1299 participants.
