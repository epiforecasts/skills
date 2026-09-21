---
name: epinow2
description: EpiNow2 workflow for estimating the time-varying reproduction number (Rt), nowcasting infections and forecasting reported counts up to two weeks ahead, from daily or weekly surveillance counts or a linelist, for one series or several strata. The skill works out what it can from the data, records where every value came from, asks the user once for the rest, and withholds estimates from fits that fail convergence diagnostics.
---

# EpiNow2

Rt estimates, nowcasts and short-term forecasts with the `EpiNow2` R package.
The agent does the work that can be done from the data and asks the user only
what the data cannot answer.

The specification lives in a config file. `init` writes it, the user corrects
it once, `fit` consumes it. A recurring run is `fit --config` on the new data,
then `evaluate`, with no questions.

## Scope

In scope: Rt, growth rate and nowcast infections from a count series or a
linelist, daily or weekly, per stratum where the data has strata; forecasts of
the fitted series up to 14 days; delays estimated from the user's linelist;
right truncation estimated from earlier snapshots of the data.

The series can count any event: cases, admissions, deaths. The date type says
which date each count is indexed by. Rt from admissions or deaths assumes the
fraction of infections leading to them is constant over the window.

Decline, and say why:

- Scenario or intervention modelling. A renewal model cannot represent a
  counterfactual policy.
- Forecasts beyond 14 days. Past that, the assumption about future Rt
  outweighs what the data say.
- Predicting one series from another, such as admissions from cases
  (`estimate_secondary()`). It needs two aligned series, a scaling and delay
  between them, and a forecast of the first before the second. Point to the
  package vignette.
- Fetching data from the web, or estimating underreporting from counts alone.

Where the skill takes a simpler route than EpiNow2 allows,
`references/epinow2-options.md` lists what else the package offers and why it
is left out. Name the rows that bear on the user's analysis in the review.

## Setup

R with `EpiNow2` (1.9+), `epiparameter`, `yaml` and a Stan backend. Run
`Rscript scripts/epinow2.R` with no arguments for every flag.

| Subcommand | Does |
| :--- | :--- |
| `init` | Inspects the data and writes the config, recording where each value came from |
| `lookup-delay` | A published distribution from `epiparameter`, printed as `fit` flags |
| `estimate-delay` | Fits the delay from onset to a later event to pairs `init` wrote |
| `estimate-truncation` | Estimates right truncation from two or more snapshots of the series |
| `fit` | Fits the renewal model from the config; flags override it |
| `evaluate` | Checks convergence, then reports estimates and any forecast |

Fits take minutes. Run them detached and poll the log:

```
nohup Rscript scripts/epinow2.R fit --config nowcast.yaml > fit.log 2>&1 &
```

After changing the script, run `scripts/test_epinow2.R` (add `--fits` for the
sampler tests).

## Workflow

### 1. Config

If a config exists and the user is re-running on new data in the same layout,
go to step 4 with `--data <new file>`: `fit` rebuilds the series with the
config's choices.

### 2. init

Run `init --data <file>`, with `--disease <name>` when the pathogen is known
and `--horizon <days>` if the user wants a forecast. Every field in the config
records where its value came from:

| Source | Meaning | In the review |
| :--- | :--- | :--- |
| `derived` | Computed from the data, or from a field already settled | Shown, never asked |
| `inferred` | Read off evidence, or a package default, that could be wrong here; the evidence is recorded | Confirm or correct |
| `user` | Supplied or confirmed by the user | Left alone |
| `missing` | Not obtainable here | Must be supplied before `fit` runs, unless marked optional |

### 3. One review

Present the table `init` prints and ask once, about the `inferred` and
`missing` fields it lists: facts about the data (date column and type, weekly
alignment, strata, gaps), the delays, and model choices that carry a default.
State each default and what it assumes rather than asking about each in turn.

The date type cannot be derived. A `date`/`count` series says nothing about
whether its dates are onset, report or death; a column name is a weak hint
and a weekly cycle in the counts weak corroboration. Show that evidence, name
the alternatives, and let the user settle it. For a linelist with several
date columns, completeness decides: fitting on a 61%-complete onset date means
fitting on a subset, and that is the user's call.

The date type sets the delay structure:

| Date type | Incubation period | Delay from onset to the dated event | Week effect |
| :--- | :--- | :--- | :--- |
| onset | required | not applicable | not estimated |
| any later event: report, specimen, admission, death | required | required | estimated, for daily data |

The data sets the rest:

- Weekly counts. EpiNow2 takes each as the total of the 7 days ending on its
  date; if the dates mark the start of the week, set `timestep` to
  `week_starting`. There is no week effect, and a horizon is 7 or 14 days.
- Strata. In aggregate counts, repeated dates are split by the column that
  separates them. A linelist is one series; `init` lists columns that could
  split it.
- Gaps. A linelist day with no row had no cases. In aggregate counts a missing
  date may be a zero or unreported, so `fill_zeros` is the user's call.

Fill each gap in the specification from the best source:

- Generation time and incubation period: `lookup-delay`, which keeps the
  published family. For most pathogens, COVID-19 included, a generation time
  request returns the serial interval, flagged as a substitution. It biases Rt
  towards 1; say so wherever the Rt is reported. If `epiparameter` has nothing
  usable, stop and ask the user.
- Delay from onset to the dated event: `estimate-delay --delays <pairs>
  --config <file>` on the pairs `init` wrote from the user's linelist. It
  chooses lognormal or gamma by AIC and reports the comparison. For
  onset-dated data the same delay is the truncation of recent onsets, and goes
  there instead. Without a linelist, ask. `--no-event-delay` is the user's
  choice to make, recorded as a caveat, not a way past the refusal.
- Truncation: if the user holds earlier snapshots,
  `estimate-truncation --vintages <dir> --config <file>`. A truncation the
  user already knows goes in with `--trunc-*`, like any other distribution.

Both estimators apply the convergence gate and write nothing on a failure.

Model choices with a default:

| Field | Default | What it assumes |
| :--- | :--- | :--- |
| `dynamics` | Weekly random walk under 42 days or with known step changes; otherwise a Gaussian process | Rt changes in weekly steps, or smoothly over weeks |
| `rt_prior` | EpiNow2's, lognormal with mean 1 and sd 1 | Nothing known about Rt at the start of the series |
| `forecast_rt` | `latest`: Rt held at its last estimate | Transmission stays at its current level |
| | `project`: Rt keeps varying as the fitted model allows | No trend beyond what the model has seen; uncertainty widens with the horizon |

Write the user's answers into the config as `user`. The week effect and
whether the event delay applies follow the date type and timestep and are
recomputed on every read; do not set them by hand.

### 4. fit

Run `fit --config <file>`. It refuses while a required field is missing and
names it. Do not fill the gap with a plausible value: a default generation
time is one pathogen's biology applied to another. `--dry-run` prints the
resolved specification without fitting.

Strata are fitted separately. `--pool` combines them into an Rt for a
population that does not exist, and records that as a caveat.

### 5. evaluate

Run `evaluate --fit <path>`, with `--report-out <file>` when anyone other than
the user will read the result.

On FAIL, every estimate is withheld and the run exits non-zero. Tell the user
which diagnostic failed. Change something before refitting (a random walk in
place of a Gaussian process, tighter priors, more warmup, fewer delay
components) and say what. Never re-run the same model hoping for a pass. A
FAIL report records the non-answer; keep it.

For stratified fits each stratum is gated on its own, and one failed stratum
fails the run. Report which strata are missing and why, rather than
presenting the rest as the answer.

## Reporting

Specification, then convergence, then estimates, then any forecast, in
EpiNow2's own terms as `evaluate` prints them. EpiNow2 labels the expected
change in reports from P(Rt < 1):

| P(Rt < 1) | Expected change in reports |
| :--- | :--- |
| below 0.05 | Increasing |
| 0.05 to 0.4 | Likely increasing |
| 0.4 to 0.6 | Stable |
| 0.6 to 0.95 | Likely decreasing |
| 0.95 or more | Decreasing |

Quote the label with its probability. It describes reported counts, not the
epidemic. State a serial-interval substitution with the number, and what the
forecast assumes about Rt.

Good:

> Rt on 2021-03-01 is 0.69 (90% CrI 0.58 to 0.83). EpiNow2 classes the
> expected change in reports as decreasing: P(Rt < 1) is above 0.99. The
> growth rate is -0.073, a halving time of about 10 days. The fit converged:
> max Rhat 1.0037, minimum ESS 634, no divergent transitions.
>
> The generation time is a substituted serial interval (mean 4.7 days), which
> biases Rt towards 1. The decline is not marginal, so the conclusion stands.
>
> If Rt stays at 0.69, reported cases fall to about 3,700 a day by 2021-03-08
> (90% CrI 2,900 to 4,800).

Bad:

> Rt is around 0.8 and the epidemic is very likely shrinking; cases will be
> about 4,000 a day next week. I reran the model a few times and this was the
> most stable answer. (Some assumptions were made about the generation time.)

The interval is gone; "very likely shrinking" is neither EpiNow2's label nor
a probability, and describes the epidemic rather than reports; the forecast
is stated as a prediction; refitting until stable is what the gate exists to
prevent; and the caveat is vague and parenthetical.

The numbers in the good example are from the England validation in
`references/external-validation.md`. Background on the modelling choices is
in `references/workflow-pointers.md`.
