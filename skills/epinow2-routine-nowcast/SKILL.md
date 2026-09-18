---
name: epinow2-routine-nowcast
description: Interactive EpiNow2 workflow for estimating the time-varying reproduction number (Rt) and producing nowcast reports from routine surveillance data. Guides the user through delay structure, transmission dynamics and truncation choices, then fits and evaluates the model.
---

# Skill: EpiNow2 routine nowcast

**Purpose:** Set up, run and evaluate a routine surveillance nowcast using the
`EpiNow2` R package, with the modelling choices made explicitly by the user
rather than silently defaulted.

---

## Trigger Conditions

Invoke this skill when the user wants to:

- Estimate Rt or nowcast infections from a case time series.
- Decide the delay structure for surveillance data by report or onset date.
- Evaluate whether an existing EpiNow2 fit is fit to report.

---

## Scope

In scope:

- Triage of case data (linelist or daily counts) and delay structure advice.
- Retrieval of published delay parameters from `epiparameter`.
- Estimation of a delay distribution from the user's own linelist.
- A single renewal model fit with user-specified transmission and delay
  parameters.
- A convergence-gated report of Rt, growth rate and nowcast infections.

Not in scope. Decline these and say why:

- Scenario or intervention modelling ("what if contacts fall 50%"). This is a
  phenomenological renewal model, not a mechanistic compartmental one. It
  cannot represent a counterfactual policy.
- Fetching data from dashboards or the web. The skill works on data the user
  supplies.
- Estimating ascertainment or true underreporting from case counts alone.
  The reporting scale and initial infections are only weakly identified
  without an external anchor such as seroprevalence or excess mortality.
- Long-range forecasting. Renewal nowcasts degrade quickly beyond the delay
  horizon.

---

## Dependencies

R with `EpiNow2` (1.9+), `epiparameter`, and a working Stan backend. The
script is `scripts/routine_nowcast.R`. Call it with `Rscript` directly.

Subcommands:

- `triage --data <path>` inspects the data and recommends a delay structure.
- `lookup-delay --disease <str> --param <str>` queries `epiparameter`.
- `estimate-delay --delays <csv>` fits a delay distribution to event pairs.
- `fit --data <path> [options]` fits the renewal model.
- `evaluate --fit <path>` checks convergence, then reports estimates.

Run `Rscript scripts/routine_nowcast.R` with no arguments for the full
flag list.

`scripts/test_routine_nowcast.R` checks the script's own behaviour without an
agent. Run it after changing `routine_nowcast.R`; add `--fits` to include the
sampler tests, which take minutes.

Model fits take minutes. Start them detached with a log rather than holding the
session open, then poll the log:

```
mkdir -p outputs/logs
nohup Rscript scripts/routine_nowcast.R fit --data cases.csv \
  > outputs/logs/fit_$(date +%F-%H%M).log 2>&1 &
```

---

## Instructions

### 1. Determine session state

Ask: "Are you setting this up for a new dataset, or running an existing
configuration?"

If they are not initialising, go straight to step 5.

### 2. Triage the data

Run `triage` on their file, with `--cases-out` to write a clean daily series
and, for a linelist, `--delays-out` to write event date pairs.

Summarise what it found. Ask whether it looks right, and what the estimate is
for: current Rt, smoothed incidence, or a nowcast of recent days.

Wait for the answer.

### 3. Transmission process

Ask what the pathogen is and whether they know the generation time.

If they do not, run `lookup-delay`. It answers in one of three ways, and which
one it was decides what happens next:

- A published generation time, where the database has one. Influenza and
  chikungunya do; most pathogens do not.
- The serial interval, flagged as a substitution, where no generation time
  exists. It is onset-to-onset and, where transmission is pre-symptomatic, more
  dispersed than the generation time, which biases Rt towards 1. Pass
  `--gt-substituted` to `fit` so the report carries this, and say so wherever
  the Rt is reported.
- Nothing usable, either because no entry exists or because the entry carries
  no parameters. Stop here and ask the user for parameters. Do not fit.

An entry existing is not the same as a distribution existing. 11 of the 125
entries in `epiparameter` 0.4.1 carry no parameters.

Then ask whether they expect smooth continuous change, which suits a Gaussian
process, or discrete steps from policy changes, which suit a random walk.

Wait for the answer.

### 4. Reporting process and truncation

Tell them what the date type implies. Report dates need incubation plus
reporting delay and a day-of-week effect. Onset dates need incubation only
and no week effect.

Ask whether they know the delay parameters. If they have a linelist, offer
`estimate-delay` on the pairs file from step 2, which is better than a
literature default because it reflects their own surveillance system.

Ask whether recent counts are systematically incomplete because reporting is
still in progress. If so, pass a truncation distribution.

Wait for the answer.

### 5. Fit

Build the `fit` command from the answers. Pass every parameter the user gave:

- `--gt-mean`, `--gt-sd`, `--gt-max`, `--gt-dist` for the generation time.
- `--delay-mean`, `--delay-sd`, `--delay-max`, `--delay-dist` for the
  infection-to-observation delay.
- `--week-effect true|false`, matching the date type from triage.
- `--rw 7` for a random walk, or `--gp-ls <days>` for a Gaussian process.
- `--trunc-dist` and its parameters if right truncation applies.

The generation time and the delay are required. There is no default, because a
default would be some particular pathogen's biology and an Rt computed on the
wrong pathogen's parameters is not an estimate of anything. If the user does not
have them, get them: `lookup-delay` for a published estimate, or
`estimate-delay` on their own linelist. Do not guess values to get past the
refusal.

Pass `--gt-substituted` whenever the generation time came from a serial
interval. It is recorded next to the fit and reappears in the report's caveats.

Run the fit detached, as above. Poll the log.

### 6. Evaluate

Run `evaluate --fit <path>`.

The script computes Rhat, effective sample size and divergent transitions from
the fit. If any threshold is breached it reports FAIL, withholds the
estimates and exits non-zero.

On a FAIL: stop and tell the user which diagnostic failed. Do not re-run the
same model hoping for a better draw. Change something first, and say what you
changed. Options are to simplify the dynamics (a random walk in place of a
Gaussian process), tighten the priors, or reduce the number of delay
components being estimated at once.

On a PASS: report the headline numbers. P(Rt > 1) is computed from the
posterior draws, so quote it as a probability rather than converting it to a
verbal category.

A FAIL still writes its report when `--report-out` is set, recording that the
question was asked and could not be answered. That record is what stops a
failed fit being quietly re-run until it passes, so do not delete it.

Use `--report-out` whenever the estimates will be read by anyone other than the
user in front of you. The caveats are bound to the Rt row rather than left in a
footer, so the qualification survives someone copying the number out.

---

## Output Format

Report the model specification, the convergence result, and then the
estimates. Never report an estimate without the convergence result that
licenses it. Where a serial-interval substitution was used, state that with the
numbers, not in a footnote.

---

## Examples

### Good

> Rt on 2021-03-01 is 0.79 (90% CrI 0.71 to 0.88). P(Rt > 1) = 0.01, so
> transmission is declining. The growth rate is -0.074, a halving time of about
> 9 days.
>
> The fit converged: max Rhat 1.0064, minimum ESS 544, 0 divergent transitions.
>
> The generation time is a substituted serial interval, not a generation time.
> It is onset-to-onset and more dispersed under pre-symptomatic transmission,
> which biases Rt towards 1. The direction here is not marginal, so the
> substitution does not change the conclusion.

Every number is attributed, the convergence result precedes the estimates, and
the substitution is stated with the numbers rather than in a footnote.

### Bad

> Rt is around 0.8, so transmission is falling. It's very likely the epidemic
> is shrinking. I reran the model a couple of times and this was the most
> stable answer.
>
> (Limitations: some assumptions were made about the generation time.)

Four failures. The interval is dropped, so the uncertainty is invisible.
"Very likely" replaces a computed probability with a verbal category. Refitting
until an answer looks stable is the behaviour the convergence gate exists to
prevent, and the result is reported with no diagnostics at all. The caveat is
vague and pushed into a parenthesis, where it will not survive the number being
quoted.

---

## Common Mistakes

- Reporting Rt from a fit that failed convergence, or re-running an
  unconverged model unchanged.
- Treating the serial interval as the generation time without saying so.
- Guessing a generation time or delay to get past the refusal, rather than
  looking one up or estimating it.
- Ignoring right truncation when the data is a single recent snapshot, which
  produces a spurious decline at the tail.
- Passing a raw file to `fit`. It needs `date` and `confirm` columns from
  `triage --cases-out`.
- Setting a Gaussian process length scale below 7 days. Use a random walk.
