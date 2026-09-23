# Sources for the reporting items

Source text and reasoning behind each item in [items.md](items.md), under the same id.
Where an item goes beyond its sources ("added"), the reasoning is given here.
Where a source is cited without quotation, the entry says so.

## Scope

The items adapt GATHER, EPIFORGE 2020, ISPOR-SMDM Task Force-7 and TRACE, which assume a document published once, to a report that is republished.
OR-15, OR-16, OR-17 in its real-time form, OR-18 and part of OR-14 arise only on republication.
Gostic et al., Charniga et al. and Abbott et al. supply the practice specific to real-time transmission and delay estimation.
WHO guidance on risk assessment and on communicating uncertainty supplies the practice specific to outbreak response.

ORBIT sets a minimum standard for the surveillance counts an authority publishes, and carries no item on a modelled estimate.
It is cited here for the counts a model takes as input (OR-05), for reporting cadence (OR-16), for the date a count refers to (OR-04), and for consistency between reports (OR-18).

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

## Items

### OR-01 Two documents

ISPOR-7 defines the split:

> A nontechnical description should be made available to anyone — including model type and intended applications; funding sources; structure; inputs, outputs, other components that determine function, and their relationships; data sources; validation methods and results; and limitations.
> Technical documentation, written in sufficient detail to enable a reader with necessary expertise to evaluate the model and potentially reproduce it, should be made available openly or under agreements that protect intellectual property.

TRACE states the reading order the split assumes:

> Readers will first want to see an overview and only then decide whether and where to go into more detail.
> \[...\] In general, summaries should always come first and details later.

GATHER's two audiences, quoted under Reader, need different levels of detail.

Keeping diagnostics technical is added.
The ISPOR-7 non-technical list contains validation results but no diagnostics.
The list is indicative ("including"), so its silence is weak support.
The main reason is the reader, who does not develop models and cannot act on a diagnostic.
TRACE places sensitivity analysis in model analysis, a technical element:

> (1) How sensitive model output is to changes in model parameters (sensitivity analysis), and (2) how well the emergence of model output has been understood.
> (TRACE 7, model analysis)

### OR-02 Purpose and intended use

All four guidelines place it first. ISPOR-7: "model type and intended applications", quoted at OR-01.

> Define the indicator(s), populations (including age, sex, and geographic entities), and time period(s) for which estimates were made.
> (GATHER 1)

> Define the purpose of study and forecasting targets.
> (EPIFORGE 2)

> The decision-making context in which the model will be used; the types of model clients or stakeholders addressed; a precise specification of the question(s) that should be answered with the model, including a specification of necessary model outputs.
> (TRACE 1, problem formulation)

### OR-03 Domain of applicability

The complement of OR-02.

> \[...\] and a statement of the domain of applicability of the model, including the extent of acceptable extrapolations.
> (TRACE 1, problem formulation)

> We recommend defining the scope of an analysis explicitly, including what it cannot address: e.g. a national Rt estimate cannot easily reveal local outbreak dynamics, aggregate case data cannot identify transmission chains, and symptom-based surveillance may not detect mild infections.
> These limitations help shape stakeholder expectations and prevent misuse of results.
> (Abbott et al., section 3.1)

### OR-04 Quantities defined before use

GATHER 1, quoted at OR-02, requires the definition.
The ordering requirement is added, and applies where a report presents tables and figures before the narrative that defines them.

ORBIT requires the case definition to be published with the counts, and accepts report date where diagnosis date is not feasible:

> This item represents the number of new confirmed cases, as defined by the case definition (which should be published with the reporting items), reported to public health authorities since the last report.
> Although the diagnosis date is preferred, especially for epidemiological modeling and analytics, most jurisdictions will find that the reporting date is most feasible.
> (ORBIT 1)

Gostic et al. on aligning a smoothed estimate to its date:

> If a wide smoothing window is needed, report R t for t corresponding to the middle of the window.
> (Gostic et al., section summary)

### OR-05 Data sources and their biases

Merges two earlier items: data sources named, and known biases in the inputs.
Showing the observed data is supported by ORBIT, whose nine items are the counts most models take as input, and by Charniga et al.

> Provide information about all included data sources and their main characteristics.
> For each data source used, report reference information or contact name/institution, population represented, data collection method, year(s) of data collection, sex and age range, diagnostic criteria or measurement method, and sample size, as relevant.
> (GATHER 5)

> Identify and describe any categories of input data that have potentially important biases (e.g., based on characteristics listed in item 5).
> (GATHER 6)

> The quality and sources of numerical and qualitative data used to parameterize the model \[...\] This critical evaluation will allow model users to assess the scope and the uncertainty of the data and knowledge on which the model is based.
> (TRACE 3, data evaluation)

> in a few countries presenting numbers of cases for example was quickly deemed ineffective, since this metric is not accurate and is heavily dependent \[on testing\].
> (Hadley et al. 2025)

> The number of new confirmed cases registered during the previous reporting period.
> (ORBIT 1; items 2 to 6 give the same for hospital admissions and deaths, new and cumulative)

> Estimates of delays should be accompanied by contextual information to aid in interpretation.
> For example, we recommend reporting the study sample size; the epidemic curve; \[...\]
> The epidemic curve can indicate at which stage of the epidemic the analysis took place and whether the outbreak is now over (i.e., whether certain biases need to be adjusted for).
> (Charniga et al.)

### OR-06 Bounded set of headline estimates

A report presenting many quantities at once gives no ordering, and a repeat reader cannot tell which to follow.
GATHER 1 requires each indicator to be defined but does not bound the set; bounding it is added.

> the vast majority of interviewees without prompt first stressed the need for simple graphics.
> (Hadley et al. 2025)

> oversharing of information (i.e. scientific detail) is perceived as useless to policymakers.
> (Hadley et al. 2025)

> Streamlining advice by presenting modelling findings in terms of these more operational concepts (doubling time, time to X, hospitalisations, deaths) was preferred in a few different settings.
> (Hadley et al. 2025)

### OR-07 Headline estimate with an interval

The guidelines require an interval and do not say which level or how many.
An earlier draft restricted the headline to one level; no source supports that, and it was dropped.
Padilla et al. found readers did not scale trust to interval width, and the single 95% interval they trusted most gave the least accurate predictions.
That is why the item asks for the meaning of the interval in words, not only its level.
Charniga et al. note the levels usually used, and ask for the level to be reported.

> All summary statistics should always be accompanied by credible intervals or confidence intervals for Bayesian and frequentist analyses, respectively (usually 90% or 95% with the width of the reported interval also being reported).
> (Charniga et al.)

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

### OR-08 Kinds of uncertainty included and excluded

The kinds named in the item follow ISPOR-SMDM Task Force-6, adapted to outbreak data: observation and reporting (Gostic et al.), parameters, chance (McCabe et al.), and model structure.
IPCC asks for the role of structural uncertainty to be stated whenever a range is given.

> Describe methods of calculating uncertainty of the estimates.
> State which sources of uncertainty were, and were not, accounted for in the uncertainty analysis.
> (GATHER 13)

> because the estimation methods reviewed here assume all infections are observed, confidence or credible intervals obtained using these methods will not include uncertainty from incomplete observation.
> Without these statistical adjustments, practitioners and policy makers should beware false precision in reported R t estimates.
> (Gostic et al., "Accounting for incomplete observation")

> Communication by authorities to the public should include explicit information about uncertainties associated with risks, events and interventions, and indicate what is known and not known at a given time.
> (WHO 2017, recommendation A.2, communicating uncertainty; strong recommendation, moderate quality evidence)

> Stochastic (first-order) uncertainty is distinguished from both parameter (second-order) uncertainty and from heterogeneity, with structural uncertainty relating to the model itself forming another level of uncertainty to consider.
> (ISPOR-SMDM Task Force-6, abstract)

> State any assumptions made and estimate the role of structural uncertainties.
> (IPCC 2010, paragraph 11)

> Uncertainty can also be introduced into simulations via the use of stochastic models, which, unlike deterministic models, incorporate the effects of random chance and are inherently 'noisy'.
> (McCabe et al. 2021)

> The combination of two sources of uncertainty lead to much greater variation in trajectories than that which is observed under the models with a single source of uncertainty.
> (McCabe et al. 2021)

### OR-09 Confidence statement

WHO assesses a public health risk rather than a model estimate, so its descriptive scale transfers and its hazard, exposure and context structure does not.
The transfer is added.

> It is important to document the risk assessment team's level of confidence in the assessment and the reasons for any limitations.
> This will depend on the reliability, completeness and quality of the information used, and the underlying assumptions made with respect to the hazard, exposure and context.
> \[...\] The degree of confidence can be expressed using a descriptive scale that ranges from very low to very high.
> (WHO 2012, p23)

> It should be emphasized that a quantitative risk assessment that uses poor data or inappropriate quantitative techniques can be far less scientific and defensible than a well-structured qualitative assessment.
> (WHO 2012, p25)

> Whereas probability reflects the likelihood that a statement is true, analytical confidence reflects the soundness and stability of the foundations on which the assessment of likelihood has been made.
> (PHIA)

IPCC gives the most structured route: rate the evidence and the agreement, then assign a level, and record how.

> Use the following dimensions to evaluate the validity of a finding: the type, amount, quality, and consistency of evidence (summary terms: "limited," "medium," or "robust"), and the degree of agreement (summary terms: "low," "medium," or "high").
> \[...\] Provide a traceable account describing your evaluation of evidence and agreement in the text of your chapter.
> (IPCC 2010, paragraph 8)

> A level of confidence is expressed using five qualifiers: "very low," "low," "medium," "high," and "very high."
> It synthesizes the author teams' judgments about the validity of findings as determined through evaluation of evidence and agreement.
> \[...\] Confidence should not be interpreted probabilistically, and it is distinct from "statistical confidence."
> (IPCC 2010, paragraph 9)

GRADE rates a body of evidence rather than a model output, so it fits best where the estimate rests on external evidence (for example a delay distribution taken from the literature).

> Based on the answers to these questions, an expression of certainty in the body of evidence can be articulated (GRADE uses four levels of certainty: high, moderate, low, and very low).
> (Schünemann et al. 2020)

### OR-10 Verbal probability on a defined scale

The yardstick is UK intelligence practice rather than health reporting; the transfer is added.
It is one published scale among several; the IPCC likelihood scale, below, is another.

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

> Virtually certain 99-100% probability.
> Very likely 90-100% probability.
> Likely 66-100% probability.
> About as likely as not 33 to 66% probability.
> Unlikely 0-33% probability.
> Very unlikely 0-10% probability.
> Exceptionally unlikely 0-1% probability.
> (IPCC 2010, Table 1)

### OR-11 Non-technical summary of results

TRACE's summary-first ordering is quoted at OR-01.

> Briefly summarize the results in nontechnical terms, including a nontechnical interpretation of forecast uncertainty.
> (EPIFORGE 15)

> Several respondents also identified a focus on whether what modellers explained could be easily explained and translated again by non-modellers.
> (Hadley et al. 2025)

### OR-12 Limitations

ISPOR-7 lists "limitations" in the non-technical description, quoted at OR-01.

> Discuss limitations of the estimates.
> Include a discussion of any modelling assumptions or data limitations that affect interpretation of the estimates.
> (GATHER 18)

> Describe the weaknesses of the forecast, including weaknesses specific to data quality and methods.
> (EPIFORGE 17)

### OR-13 Implications for action

WHO pairs the confidence statement (OR-09) with the recommendation in a single step.

> If the research is applicable to a specific epidemic, comment on its potential implications and impact for public health action and decisionmaking.
> (EPIFORGE 18)

> Undertake a full risk assessment and state the level of confidence in the assessment.
> Provide recommendations for decision-makers, including which actions should be taken and which should have the highest priority.
> (WHO 2012, p7)

### OR-14 Data cut-off

WHO asks for statements to be labelled as based on what is known at the time.
A data cut-off date is the form that label takes for a model estimate; that form is added.
EPIFORGE 4 asks whether a forecast was made in real time, which implies but does not require the date.

> Label your messages with the caution that they are based on what you know at that point in time.
> (WHO 2025, tip 2)

> Identify whether the forecast was performed prospectively, in real time, and/or retrospectively.
> (EPIFORGE 4)

### OR-15 Provisional recent estimates

Gostic et al. and Charniga et al. address the analyst: adjust for right truncation or drop the incomplete dates.
WHO addresses the reader: say that information will change.
The item joins the two: whatever the adjustment, the report tells the reader the recent period is provisional.

> Due to reporting delays, infections at the end of a growing time series will be undercounted.
> To avoid systematic underestimation of R t on the most recent dates, adjust for the right truncation using 1 of many available methods or truncate the time series to the last date with complete reporting.
> (Gostic et al., section summary)

> Right truncation is defined as the inability to observe intervals (e.g., incubation periods) greater than a threshold (e.g., greater than the number of days elapsed since infection).
> It typically applies to real-time settings, when events with longer intervals may not have occurred yet, leading to an overrepresentation of shorter intervals when estimating delays.
> (Charniga et al.)

> Clearly state that all these adjustments have been made, and report both right-truncation-adjusted and right-truncation-unadjusted estimates.
> (Charniga et al., Table 2)

> Set expectations that information and guidance are likely to change throughout the event as you know more.
> Repeat this message often.
> Helping people understand that the situation and recommendations may change over time increases trust.
> (WHO 2025, tip 3)

ORBIT notes the same bias in a testing-lag indicator it recommends beyond its core items:

> This item represents an indicator for testing lag and has the potential to be subject to right truncation bias in an exponentially growing epidemic.
> (ORBIT, additional recommendation 1)

### OR-16 Update cadence

ORBIT sets a minimum cadence for the authority's counts.
It does not require the report to state its cadence; that is added.

> Establish weekly reporting.
> This item specifies that public health authorities should, at a minimum, report to the public weekly.
> (ORBIT 7)

### OR-17 Change since the last update

GATHER requires the reason, not only the series of past estimates.

> Interpret results in light of existing evidence.
> If updating a previous set of estimates, describe the reasons for changes in estimates.
> (GATHER 17)

> Two types of changes during outbreaks require revisiting our suggested workflow.
> First, new information emerges \[...\]
> Second, research questions commonly evolve as outbreak priorities shift \[...\]
> (Abbott et al., section 4.1)

> To avoid being accused of inconsistency as and when guidance is updated, you need to proclaim and explain uncertainty – prominently and repeatedly – and make clear that science-based advice may change as science evolves.
> (WHO 2025)

### OR-18 Consistent presentation between updates

No guideline on modelled estimates carries this item, because a document published once cannot be inconsistent with itself.
ORBIT asks for it between jurisdictions and over time.

> Lastly, interviewees agreed that consistency in colours, styles, graphs etc. is important.
> "Be consistent with the way you packaged the first information".
> Presenting in the same format each week enabled policymakers and advisors to gain familiarity and to provide a pattern of feedback.
> (Hadley et al. 2025)

> Reporting needs may change over the course of an outbreak.
> Therefore, we encourage coordination among public health authorities to maintain uniformity and comparability of reporting.
> (ORBIT, discussion)

### OR-19 Fit to the data

ISPOR-7 names comparison with real-world results (external validity) and with prospectively observed events (predictive validity) as the two strongest forms of validation.
OR-19 is the first, OR-20 the second.

> (1) How well model output matches observations and (2) how much calibration and effects of environmental drivers were involved in obtaining good fits of model output and data.
> (TRACE 6, model output verification)

> Validation involves face validity (wherein experts evaluate model structure, data sources, assumptions, and results), verification or internal validity (check accuracy of coding), cross validity (comparison of results with other models analyzing the same problem), external validity (comparing model results with real-world results), and predictive validity (comparing model results with prospectively observed events).
> The last two are the strongest form of validation.
> (ISPOR-7, abstract)

> We use posterior- and mixed-predictive checks \[...\] to assess whether fitted models reproduce key features across all integrated sources.
> These checks form the foundation of model validation by comparing model-generated predictions against observed patterns.
> (Abbott et al., section 3.9.4)

GATHER 12 is quoted at OR-26.

### OR-20 Predictive performance

EPIFORGE places the evaluation in the methods of a study; surfacing the result in the non-technical document is added.
TRACE separates agreement with the data used in fitting from comparison against data not used, and only the second is evidence of prediction.

> Describe the forecast accuracy evaluation method used, with justification.
> (EPIFORGE 11)

> Where possible, compare model results to a benchmark or other comparator model, with justification of comparator choice.
> (EPIFORGE 12)

> How model predictions compare to independent data and patterns that were not used, and preferably not even known, while the model was developed, parameterized, and verified.
> (TRACE 8, model output corroboration)

### OR-21 Estimates available as data

> Provide published estimates in a file format from which data can be efficiently extracted.
> (GATHER 15)

> If results are published as a data object, encourage a time-stamped version number.
> (EPIFORGE 16)

### OR-22 Code available

> State how analytic or statistical source code used to generate estimates can be accessed.
> (GATHER 14)

> Make the model code available, or document the reasons why this was not possible.
> (EPIFORGE 9)

> We recommend sharing code and data alongside results because it enables verification, accelerates progress, and is just as much a part of the analysis as the manuscript.
> (Abbott et al., section 4.2)

> Code and data should be uploaded to repositories, such as GitHub (https://github.com/) or Zenodo (https://zenodo.org/), to ensure reproducibility of the analysis and facilitate re-use of the code.
> (Charniga et al.)

### OR-23 Authorship and funding

ISPOR-7 lists "funding sources" in the non-technical description, quoted at OR-01.

> List the funding sources for the work.
> (GATHER 2)

### OR-24 Contact and feedback route

No published source found. Added.
GATHER 5 (quoted at OR-05) requires a contact for data that cannot be shared, a narrower case.

### OR-25 Methods sufficient to reproduce

ISPOR-7's technical documentation requirement is quoted at OR-01.

> Provide a detailed description of all steps of the analysis, including mathematical formulae.
> This description should cover, as relevant, data cleaning, data pre-processing, data adjustments and weighting of data sources, and mathematical or statistical model(s).
> (GATHER 10)

> Fully document the methods.
> (EPIFORGE 3)

> The model, i.e. a detailed written model description.
> \[...\] Model users should learn what the model is, how it works, and what guided its design.
> (TRACE 2, model description)

> The intrinsic generation interval is required to correctly define the relationship between R t and incident infections.
> (Gostic et al., section summary)

> E.g., for the gamma distribution, report shape and scale; for the lognormal distribution, report logmean and log standard deviation.
> If possible, the probability density function should be specified to avoid ambiguity about the parameters.
> (Charniga et al., Table 2)

> Reporting decisions made at each stage of the workflow is essential, including rationales for data source selection, integration method choices, model structure assumptions, and validation procedures undertaken.
> (Abbott et al., section 4.2)

### OR-26 Model evaluation and comparison

TRACE 7 is quoted at OR-01; TRACE 6 and the Abbott et al. passage on predictive checks at OR-19.

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

ORBIT. Grégoire V, Zhu AW, Brown CM, et al.
Public reporting guidelines for outbreak data: Enabling accountability for effective outbreak response by developing standards for transparency and uniformity.
Public Health 2026;251:106102.
Nine items, Delphi with 35 panellists. Quotations are from the Results (items numbered as in Table 3), the additional recommendations and the Discussion.

Gostic KM, McGough L, Baskerville EB, et al.
Practical considerations for measuring the effective reproductive number, Rt.
PLOS Computational Biology 2020;16(12):e1008409.
Quotations are from the section summaries.

Charniga K, Park SW, Akhmetzhanov AR, et al.
Best practices for estimating and reporting epidemiological delay distributions of infectious diseases.
PLOS Computational Biology 2024;20(10):e1012520.
Quotations are from Table 2 and the text.

Abbott S, Li X, Alahakoon P, et al.
A workflow for infectious disease modelling.
2026. https://github.com/seabbs/a-workflow-for-infectious-disease-modelling.

WHO 2012. Rapid Risk Assessment of Acute Public Health Events.
Geneva: World Health Organization, 2012.
WHO/HSE/GAR/ARO/2012.1.
Quotations are from the sections "Level of confidence in the risk assessment" and "Quantification in risk assessment", and from the response-actions table.

WHO 2017. Communicating risk in public health emergencies: a WHO guideline for emergency risk communication (ERC) policy and practice.
Geneva: World Health Organization, 2017.
Quotation is recommendation A.2.

WHO 2025. Communicating uncertainty in health emergencies: guidance and tips.
Copenhagen: WHO Regional Office for Europe, 2025.

ISPOR-6. Briggs AH, Weinstein MC, Fenwick EA, et al.
Model Parameter Estimation and Uncertainty: A Report of the ISPOR-SMDM Modeling Good Research Practices Task Force-6.
Value in Health 2012;15(6):835-842.
Quotation is from the abstract.

IPCC 2010. Mastrandrea MD, Field CB, Stocker TF, et al.
Guidance Note for Lead Authors of the IPCC Fifth Assessment Report on Consistent Treatment of Uncertainties.
Intergovernmental Panel on Climate Change, 2010.

GRADE. Schünemann HJ, Santesso N, Vist GE, et al.
Using GRADE in situations of emergencies and urgencies: certainty in evidence and recommendations matters during the COVID-19 pandemic, now more than ever and no matter what.
Journal of Clinical Epidemiology 2020;127:202-207.

McCabe R, Kont MD, Schmit N, et al.
Communicating uncertainty in epidemic models.
Epidemics 2021;37:100520.

PHIA. Professional Head of Intelligence Assessment probability yardstick, in Explaining uncertainty in UK intelligence assessment.
UK Government.
Seven probability bands, and the distinction between probability and analytical confidence.

Hadley L, Rich C, Tasker A, Restif O, Funk S.
Visual preferences for communicating modelling: a global analysis of COVID-19 policy and decision makers.
Infectious Disease Modelling 2025;10(3):924-934.

Padilla L, Hosseinpour H, Fygenson R, et al.
Multiple Forecast Visualizations: trade-offs in trust and performance in multiple COVID-19 forecast visualizations.
IEEE Transactions on Visualization and Computer Graphics 2023.
Three studies, 1299 participants.
