# Pointers in an infectious disease modelling workflow

This document contains key concepts and best practices to guide the `epinow2-routine-nowcast` skill. Sourced from: 
Abbott, Sam, Xiahui Li, Punya Alahakoon, Dhorasso Temfack, Sabine Van Elsland, Johannes Bracher, Felix Gunther, et al. 2026. “A Workflow for Infectious Disease Modelling.” doi:10.5281/ZENODO.19097427.

## 1. Process DAG Development
*   **Target Estimand**: Clearly define whether you are estimating the time-varying reproduction number ($R_t$), new infections, or forecasting.
*   **Transmission Dynamics**: Start simple. Use a renewal equation model as the baseline. 
*   **Time Scales**: If policy interventions occurred in discrete steps (e.g. lockdowns, school closures), consider a step-wise random walk for $R_t$. For smoother, continuous changes, use a Gaussian Process (GP), but be aware that GPs struggle with very short length scales (< 7 days).

## 2. Observation DAG Construction
*   **Delays**: Delays shape the relationship between underlying infections and observations. 
    *   *Incubation period*: Time from infection to symptom onset.
    *   *Reporting delay*: Time from onset to case reporting.
    *   *Compound delay*: If your data is by report date, the total delay is incubation + reporting. If data is by onset date, only incubation is needed.
*   **Truncation**: Recent events with long delays are systematically missing from surveillance data (right-truncation). If you only have a single snapshot of data, explicitly provide a truncation distribution based on the assumed reporting delay.
*   **Day-of-week effects**: Administrative data (report dates) often show weekend dips. Use `week_effect = TRUE`. Biological data (onset dates) do not. Use `week_effect = FALSE`.

## 3. Parameter Priors and Defaults
*   **Avoid Uniform Priors**: Always specify appropriately uncertain priors based on domain knowledge.
*   **Defaulting via Packages**: When specific pathogen parameters are unknown, use tools like `epiparameter` to extract sensible defaults from the literature rather than guessing.
    *   *Caveat verified against epiparameter 0.4.1*: the database holds 125
        entries, of which 3 are generation times (influenza, chikungunya) and
        18 are serial intervals. Most pathogens, COVID-19 included, have a
        serial interval but no generation time, so a query for a generation
        time usually returns the serial interval instead. The two differ: the
        serial interval is onset-to-onset, and under pre-symptomatic
        transmission it is more dispersed than the generation time and can be
        negative. Using it in place of a generation time biases Rt towards 1.
        The substitution is often defensible, but must be stated wherever the
        resulting Rt is reported.
    *   *An entry is not always a distribution*: 11 of the 125 entries carry no
        parameters at all, including one of the three generation times. A
        lookup that finds an entry has not necessarily found anything usable,
        so check for parameters before treating a result as information.
*   **Max bounds**: Always specify a `max` bound on delay distributions (e.g., `max = 14` or `20`) to prevent excessively long tails that cause computational issues.

## 4. Diagnostics and Convergence
*   **Rhat**: Should be < 1.01 for all parameters. Values > 1.01 indicate chains have not converged.
*   **Effective Sample Size (ESS)**: Bulk and tail ESS should be > 400.
*   **Divergent Transitions**: Must be 0. Indicates problems with the posterior geometry.
*   **Assess only varying parameters**: EpiNow2 monitors fixed inputs
    alongside sampled ones. A delay distribution passed in as data appears in
    the Stan summary with sd exactly 0, Rhat near 1 and an ESS of about 2.
    Those are constants, not badly mixed parameters. Counting them makes every
    fit look like it failed on ESS, so exclude zero-variance quantities before
    applying thresholds.
*   **Fixing Convergence Issues**: If convergence fails, **stop and reconsider**. Do not blindly retry. Options include:
    1.  Simplifying the model structure (e.g., switch from a GP to a Random Walk or fixed $R_t$).
    2.  Increasing prior informativeness (narrowing bounds).
    3.  Checking for non-identifiability (e.g. trying to estimate too many delay components simultaneously).

## 5. External validation data

The test suite checks Rt estimates against an independent estimate rather than
only against itself. Sources used:

*   **Cases**: UKHSA data dashboard API, England daily COVID-19 cases by
    specimen date. <https://api.ukhsa-dashboard.data.gov.uk/>
*   **Reference Rt**: inc2prev, which estimates Rt with a Gaussian process on
    ONS Community Infection Survey prevalence rather than a renewal equation on
    cases. <https://github.com/epiforecasts/inc2prev>
    Abbott, Sam, and Sebastian Funk. 2022. "Estimating Epidemiological
    Quantities from Repeated Cross-Sectional Prevalence Measurements." medRxiv.
    doi:10.1101/2022.03.29.22273101.

Note that `epiforecasts/covid-rt-estimates` also publishes England Rt, but is
itself generated with `EpiNow2`. Agreement with it would test reproducibility
rather than correctness, so it is not used as a reference.

## 6. Further resources

An uncertain user might wish to consult additional resources. Start with the live [Epinow2 documentation](https://epiforecasts.io/EpiNow2/articles/), with additional sources below.
The user may also be interested in joining the 
[epinowcast community](https://www.epinowcast.org/).

Gostic, Katelyn M., Lauren McGough, Edward B. Baskerville, Sam Abbott, Keya Joshi, Christine Tedijanto, Rebecca Kahn, et al. 2020. “Practical Considerations for Measuring the Effective Reproductive Number, Rt.” PLOS Computational Biology 16 (12). Public Library of Science: e1008409. doi:10.1371/journal.pcbi.1008409.

Charniga, Kelly, Sang Woo Park, Andrei R Akhmetzhanov, Anne Cori, Jonathan Dushoff, Sebastian Funk, Katelyn M Gostic, et al. 2024. “Best Practices for Estimating and Reporting Epidemiological Delay Distributions of Infectious Diseases Using Public Health Surveillance and Healthcare Data.” https://hal.science/hal-04572940.

Park, Sang Woo, Andrei R. Akhmetzhanov, Kelly Charniga, Anne Cori, Nicholas G. Davies, Jonathan Dushoff, Sebastian Funk, et al. 2024. “Estimating Epidemiological Delay Distributions for Infectious Diseases.” medRxiv. doi:10.1101/2024.01.12.24301247.

Abbott, Sam, Xiahui Li, Punya Alahakoon, Dhorasso Temfack, Sabine Van Elsland, Johannes Bracher, Felix Gunther, et al. 2026. “A Workflow for Infectious Disease Modelling.” doi:10.5281/ZENODO.19097427.