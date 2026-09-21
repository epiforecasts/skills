# Pointers in an infectious disease modelling workflow

Key concepts and practices behind the `epinow2` skill. Sourced from:
Abbott, Sam, Xiahui Li, Punya Alahakoon, Dhorasso Temfack, Sabine Van Elsland, Johannes Bracher, Felix Gunther, et al. 2026. "A Workflow for Infectious Disease Modelling." doi:10.5281/ZENODO.19097427.

## 1. Process DAG development

- Target estimand: say whether the goal is the time-varying reproduction number (Rt), new infections, or a forecast of reported cases.
- Transmission dynamics: start simple, with a renewal equation model as the baseline.
- Time scales: if policy interventions came in discrete steps (lockdowns, school closures), consider a stepwise random walk for Rt. For smoother, continuous change, use a Gaussian process (GP), but GPs struggle with very short length scales (under 7 days).

## 2. Observation DAG construction

- Delays shape the relationship between underlying infections and observations.
  - Incubation period: time from infection to symptom onset.
  - Event delay: time from onset to the event that dates each count (report, specimen, admission, death).
  - Compound delay: data dated by any event after onset needs the incubation period plus the event delay. Data by onset date needs the incubation period only.
- Truncation: recent events with long delays are systematically missing from surveillance data (right truncation). Estimate it from earlier snapshots of the same series where they exist. For onset-dated data, the onset-to-report delay is itself the truncation of recent onsets, and can be estimated from a linelist.
- Day-of-week effects: dates set by a working process (report, specimen, admission) often show weekend dips, so estimate a week effect. Symptom onset does not follow a working week, so do not. Weekly counts carry no day-of-week signal at all.
- Weekly counts: EpiNow2 models daily infections and compares each weekly count with the sum of the 7 days ending on its date. Weekly totals say less about the last weeks than daily counts do. On EpiNow2's example data summed into 18 weeks, a weekly random walk did not converge (its last step sat on its prior), and a Gaussian process with a 21-day length scale sat on the gate thresholds: over runs with 1000 and 2000 warmup iterations, max Rhat ranged from 1.004 to 1.013 and minimum ESS from 328 to 519.

## 3. Parameter priors

- Avoid uniform priors. Specify appropriately uncertain priors based on domain knowledge.
- Published parameters: when a pathogen's parameters are not known to the user, look them up in `epiparameter` rather than guessing. A published estimate is a sourced input, not a default, and its source is recorded with it.
  - Verified against epiparameter 0.4.1: the database holds 125 entries, of which 3 are generation times (influenza, chikungunya) and 18 are serial intervals. Most pathogens, COVID-19 included, have a serial interval but no generation time, so a query for a generation time usually returns the serial interval instead. The two differ: the serial interval is onset-to-onset, and under pre-symptomatic transmission it is more dispersed than the generation time and can be negative. Using it in place of a generation time biases Rt towards 1. The substitution is often defensible, but must be stated wherever the resulting Rt is reported.
  - An entry is not always a distribution: 11 of the 125 entries carry no parameters at all, including one of the three generation times. A lookup that finds an entry has not necessarily found anything usable, so check for parameters before treating a result as information.
  - Keep the published family. epiparameter's influenza generation time is a Weibull. The renewal model takes lognormal and gamma distributions directly; a Weibull goes in as EpiNow2's discretisation of it, which is exact for fixed parameters. Matching a gamma to its mean and sd would change its shape.
- Max bounds: a delay distribution needs an upper bound. Where none is given, EpiNow2 truncates at the 99.9th percentile. A fixed bound such as 14 days can cut off the tail of a long incubation period.

## 4. Diagnostics and convergence

- Rhat should be below 1.01 for all parameters. Values above 1.01 mean the chains have not converged.
- Effective sample size (ESS) should be above 400. The skill checks rstan's `n_eff`, a bulk measure; EpiNow2's own warnings also report tail ESS.
- Divergent transitions must be 0. They indicate problems with the posterior geometry.
- Assess only varying parameters. EpiNow2 monitors fixed inputs alongside sampled ones. A delay distribution passed in as data appears in the Stan summary with sd exactly 0, Rhat near 1 and an ESS of about 2. Those are constants, not badly mixed parameters. Counting them makes every fit look like it failed on ESS, so exclude zero-variance quantities before applying thresholds.
- The same thresholds apply to any fit whose output feeds another: an estimated delay or truncation that has not converged carries its problem into every Rt computed from it.
- Fixing convergence issues: stop and reconsider. Do not blindly retry. Options include:
  1. Simplifying the model structure (switch from a GP to a random walk or fixed Rt).
  2. Increasing prior informativeness (narrowing bounds).
  3. Checking for non-identifiability (estimating too many delay components at once).

## 5. Forecasting

- A forecast needs an assumption about Rt beyond the data. By default EpiNow2 holds Rt at its last estimate (`latest`): transmission stays at its current level. The alternative (`project`) lets Rt keep varying as the fitted random walk or Gaussian process allows, so uncertainty widens with the horizon.
- Either way the forecast is a projection of current transmission, not a prediction of how it will change. The last Rt estimate is the least informed in the fit, because the most recent infections have had the least time to be observed. Past 14 days the assumption outweighs what the data say, which is why the skill stops there.

## 6. External validation data

The test suite checks Rt estimates against an independent estimate rather
than only against itself. Sources used:

- Cases: UKHSA data dashboard API, England daily COVID-19 cases by specimen date. <https://api.ukhsa-dashboard.data.gov.uk/>
- Reference Rt: inc2prev, which estimates Rt with a Gaussian process on ONS Community Infection Survey prevalence rather than a renewal equation on cases. <https://github.com/epiforecasts/inc2prev>
  Abbott, Sam, and Sebastian Funk. 2022. "Estimating Epidemiological Quantities from Repeated Cross-Sectional Prevalence Measurements." medRxiv. doi:10.1101/2022.03.29.22273101.

`epiforecasts/covid-rt-estimates` also publishes England Rt, but is itself
generated with `EpiNow2`. Agreement with it would test reproducibility rather
than correctness, so it is not used as a reference.

## 7. Further resources

An uncertain user might wish to consult additional resources. Start with the live [EpiNow2 documentation](https://epiforecasts.io/EpiNow2/articles/), with additional sources below. The user may also be interested in joining the [epinowcast community](https://www.epinowcast.org/).

Gostic, Katelyn M., Lauren McGough, Edward B. Baskerville, Sam Abbott, Keya Joshi, Christine Tedijanto, Rebecca Kahn, et al. 2020. "Practical Considerations for Measuring the Effective Reproductive Number, Rt." PLOS Computational Biology 16 (12): e1008409. doi:10.1371/journal.pcbi.1008409.

Charniga, Kelly, Sang Woo Park, Andrei R Akhmetzhanov, Anne Cori, Jonathan Dushoff, Sebastian Funk, Katelyn M Gostic, et al. 2024. "Best Practices for Estimating and Reporting Epidemiological Delay Distributions of Infectious Diseases Using Public Health Surveillance and Healthcare Data." https://hal.science/hal-04572940.

Park, Sang Woo, Andrei R. Akhmetzhanov, Kelly Charniga, Anne Cori, Nicholas G. Davies, Jonathan Dushoff, Sebastian Funk, et al. 2024. "Estimating Epidemiological Delay Distributions for Infectious Diseases." medRxiv. doi:10.1101/2024.01.12.24301247.

Abbott, Sam, Xiahui Li, Punya Alahakoon, Dhorasso Temfack, Sabine Van Elsland, Johannes Bracher, Felix Gunther, et al. 2026. "A Workflow for Infectious Disease Modelling." doi:10.5281/ZENODO.19097427.
