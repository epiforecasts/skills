---
name: epinow2-routine-nowcast
description: EpiNow2 workflow for estimating the time-varying reproduction number (Rt) and producing nowcast reports from routine surveillance data, one region or many. Works out the delay structure, transmission dynamics and truncation it can from the data, records where every value came from, and puts the rest to the user before fitting and evaluating.
---

# Skill: EpiNow2 routine nowcast

**Purpose:** Set up, run and evaluate a routine surveillance nowcast using the
`EpiNow2` R package, with every modelling choice either computed from the data
or made explicitly by the user, and never silently defaulted.

The specification lives in a config file. `init` writes it, the user corrects
it once, `fit` consumes it. A recurring nowcast re-runs `fit --config` with no
questions at all.

---

## Trigger Conditions

Invoke this skill when the user wants to:

- Estimate Rt or nowcast infections from a case time series, for one area or
  for several at once.
- Decide the delay structure for surveillance data by report or onset date.
- Re-run an existing configuration on new data.
- Evaluate whether an existing EpiNow2 fit is fit to report.

---

## Scope

In scope:

- Triage of case data (linelist or daily counts) and delay structure advice.
- Retrieval of published delay parameters from `epiparameter`.
- Estimation of a delay distribution from the user's own linelist.
- Estimation of right truncation from data vintages, where the user has them.
- A renewal model fit with user-specified transmission and delay parameters,
  fitted per region when the data carries regions.
- A convergence-gated report of Rt, growth rate and nowcast infections, gated
  per region.

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

It also needs the `yaml` package to read and write config files.

Subcommands:

- `init --data <path> [--disease <str>]` inspects the data, works out what it
  can, and writes a config recording the provenance of every value.
- `triage --data <path>` inspects the data and recommends a delay structure.
- `lookup-delay --disease <str> --param <str>` queries `epiparameter`.
- `estimate-delay --delays <csv>` fits a delay distribution to event pairs.
- `estimate-truncation --vintages <dir>` estimates right truncation from
  snapshots of the same series taken on different days.
- `fit --config <yaml>` fits the renewal model; flags override the config.
- `evaluate --fit <path>` checks convergence, then reports estimates.

Run `Rscript scripts/routine_nowcast.R` with no arguments for the full
flag list.

`scripts/test_routine_nowcast.R` checks the script's own behaviour without an
agent. Run it after changing `routine_nowcast.R`; add `--fits` to include the
sampler and regional tests, which take minutes. 87 assertions without `--fits`,
117 with.

Model fits take minutes. Start them detached with a log rather than holding the
session open, then poll the log:

```
mkdir -p outputs/logs
nohup Rscript scripts/routine_nowcast.R fit --config nowcast.yaml \
  > outputs/logs/fit_$(date +%F-%H%M).log 2>&1 &
```

---

## Instructions

### 1. Is there a config already?

Look for a config file (`nowcast.yaml` by default). If one exists and the user
is re-running on new data, go straight to step 4. A recurring nowcast asks the
user nothing: the questions were answered when the config was written.

If there is no config, go to step 2.

### 2. Build the specification

Run `init --data <their file>`, adding `--disease <name>` whenever the pathogen
is known, so published parameters are fetched in the same pass.

`init` writes a config in which every field records where its value came from:

| Source | Meaning | What to do with it |
| :--- | :--- | :--- |
| `derived` | Computed from the data, or from another field already settled | Show it. Do not ask about it |
| `inferred` | Read off evidence that could be wrong; the evidence is printed with it | Put it to the user with its evidence |
| `user` | Supplied or confirmed by the user | Leave it alone |
| `missing` | Not obtainable here | Must be filled before `fit` will run |

Present the table `init` prints. Do not re-ask what it has already derived.

### 3. One review, then fill the gaps

Ask once, covering only the `inferred` and `missing` fields. In practice that
is the date type, the generation time, the delay, and sometimes truncation.

The date type is the one to put carefully, because it cannot be derived and
everything downstream follows from it. An aggregate `date`/`count` series
carries no evidence of what its dates mean; a column name is a weak hint; a
weekly cycle in the counts is weak corroboration of an administrative reporting
date. Show the evidence `init` found, name the alternatives, and let the user
settle it. For a linelist with several date columns, the completeness figures
are the deciding fact: fitting on a 61%-complete onset date means fitting on a
biased subset, and that is the user's call, not the agent's.

Fill the gaps with the tool that suits each one:

- Generation time: `lookup-delay --disease <name> --param 'generation time'`.
  It answers in one of three ways, and which one decides what happens next:
  a published generation time, where the database has one (influenza and
  chikungunya do; most pathogens do not); the serial interval, flagged as a
  substitution, where no generation time exists; or nothing usable, either
  because no entry exists or because the entry carries no parameters. On the
  third, stop and ask the user for parameters. Do not fit.
- Reporting delay: `estimate-delay` on the user's own linelist is better than
  a literature default, because it reflects their own surveillance system. Use
  `triage --delays-out` to write the event pairs it needs.
- Right truncation: if the user holds earlier snapshots of the same series,
  `estimate-truncation --vintages <dir> --config <file>` estimates it from the
  data and writes it in. Ask for the snapshots before asking for a
  distribution.

A serial interval standing in for a generation time is onset-to-onset and,
under pre-symptomatic transmission, more dispersed, which biases Rt towards 1.
`init` records the substitution in the config and `fit` carries it into the
report's caveats. Say so wherever the Rt is reported.

An entry existing is not the same as a distribution existing. 11 of the 125
entries in `epiparameter` 0.4.1 carry no parameters.

Write the user's answers back into the config, and mark what they supplied as
`user`. Do not re-derive `week_effect` yourself: it follows the date type and
is recomputed on every read.

### 4. Fit

Run `fit --config <file>`. Anything passed as a flag overrides the config, so a
one-off sensitivity run does not require editing the file.

`fit` refuses to run while a required field is missing, and names the fields.
Do not fill them with plausible values to get past the refusal. The generation
time and the delay have no default, because a default is one pathogen's biology
applied to another, and an Rt computed on the wrong pathogen's parameters is
not an estimate of anything.

Where the data carries a `region` column with more than one region, each region
is fitted separately. Pooling them estimates an Rt for a population that does
not exist, so it happens only with `--pool`, and is recorded as a caveat.

Run the fit detached, as above. Poll the log. Regional fits take proportionally
longer.

### 5. Evaluate

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

A regional fit is gated per region: each region is judged on its own diagnostics
and reported as one row of a table. Regions that pass are reported; regions that
fail have their estimates withheld and are listed with the diagnostic that
failed. The run still exits non-zero if any region failed, because a table with
a hole in it reads as a table. Say which regions are missing and why, rather
than presenting the ones that worked as the result. A sparse region is the
usual cause, so check its counts before changing the model for every region.

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
  `init --cases-out` or `triage --cases-out`.
- Setting a Gaussian process length scale below 7 days. Use a random walk.
- Asking the user about a field the config marks `derived`. It was computed
  from their data; asking implies it was a matter of preference.
- Presenting an `inferred` field as settled. The date type in particular is a
  reading of weak evidence, not a finding.
- Treating a date column as a date type. A column called `date` in an aggregate
  series says nothing about whether it is onset, specimen or report.
- Reporting the regions that converged as though they were the answer, when
  others were withheld.
- Pooling regions to avoid a sparse-region failure without saying that the
  resulting Rt is for a population that does not exist.
