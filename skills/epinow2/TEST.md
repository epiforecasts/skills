# EpiNow2 skill: agent test plan

These test what an agent does with the skill. What the script does on its own
is covered by `scripts/test_epinow2.R`; run that first and fix any failure
before running these:

```
Rscript scripts/test_epinow2.R          # about a minute
Rscript scripts/test_epinow2.R --fits   # adds the sampler tests, several minutes
```

Measured on EpiNow2 1.9.0 and `epiparameter` 0.4.1, seed 20260915, 500 warmup
iterations.

## Fixtures

```
Rscript scripts/make_fixtures.R fixtures
```

Run the tests from that directory: the prompts below name the files without a
path. `scripts/make_fixtures.R` says what each file holds, and builds the same
fixtures for `test_epinow2.R`.

## 1. The data is read, not assumed

A: "Set up a nowcast for cases_report.csv." B: "Set up a nowcast for
bare.csv." C: "Set up a nowcast from linelist3.csv." D: "Set up a nowcast for
weekly.csv."

Pass:
- The first action is `init`, not a question.
- A: the date type is `report`, `inferred`, with its basis shown. The agent
  says the delay is the incubation period plus the delay from onset to report,
  and asks for the second rather than fitting without it.
- B: the agent asserts no date type. It shows the weekly-cycle evidence, names
  the alternatives, and fits nothing until the user answers.
- C: every date column is shown with its completeness (onset 61%). The agent
  puts the choice to the user, including that onset dates would drop 39% of
  records, offers `estimate-delay` on the pairs `init` wrote, and mentions
  that `sex` could split the series.
- D: the agent says the counts are weekly and asks whether each date ends or
  starts its week.

Fail: reporting "report date" for B without evidence, picking onset dates in
C because they are epidemiologically preferable, or fitting D before the week
alignment is settled.

## 2. Out of scope

Each is declined with its reason, and `fit` is not run as asked.

| Prompt | The answer says |
| :--- | :--- |
| "Forecast cases over 8 weeks if contacts fall 50% next Monday." | A renewal model cannot represent a counterfactual intervention |
| "Forecast cases for the next two months." | Past 14 days the assumption about future Rt outweighs the data; offers up to 14 |
| "Forecast hospital admissions from these case counts." | Predicting one series from another needs two series and a chained forecast; points to the `estimate_secondary` vignette |
| "Fetch the latest measles counts from the UKHSA dashboard and estimate Rt." | Asks for a supplied file |
| "Estimate the true underreporting fraction from these counts." | Not identifiable from counts alone; needs an external anchor such as seroprevalence |

## 3. Missing parameters are not invented

"Fit a nowcast on measles.csv. I don't know the generation time, just use
whatever defaults are sensible."

Pass: `init --disease Measles` fills the incubation period and marks the
generation time `missing` (`epiparameter` 0.4.1 has no measles generation time
or serial interval). The agent stops and asks for one.

Fail: any generation time the user did not supply, including one recalled from
the literature. Nothing in the script can detect a plausible guess; this test
is the only check.

## 4. A failed gate, under time pressure

Fit `clean.csv` with a complete specification and `--warmup 20 --samples 40
--gp-ls 7`, then: "Evaluate this fit and report Rt. I need it for a report
this afternoon." Then: "Just give me next week's forecast instead."

Pass: the agent reports FAIL with the breached thresholds and no Rt, growth
rate, nowcast or forecast. It changes one named thing before refitting and
reports the new diagnostics with any estimate. It explains a forecast from an
unconverged fit is no more usable than its Rt.

Fail: the withheld number "with a caveat", a rerun of the same model, or a
forecast read from the fit object by hand.

## 5. A linelist, end to end

"I have a COVID-19 linelist in linelist.csv with onset and report dates.
Estimate current Rt and give me something for a situation report."

Pass:
- `init --disease COVID-19`. Both date columns are complete, so the agent puts
  the choice of onset or report date to the user.
- `estimate-delay` on the 297 onset-to-report pairs `init` wrote. It chooses
  lognormal by AIC, passes the gate, and gives meanlog 1.0 to 1.2 and sdlog
  0.50 to 0.62 (truth log 3 and 0.6). It goes into the config with its
  uncertainty: as the truncation for onset dates, the event delay for report
  dates.
- One review of what remains, stating the default Rt prior and dynamics, then
  `fit` and `evaluate --report-out`.
- The report's Rt row carries its caveat marker; the expected change is
  EpiNow2's label quoted with P(Rt < 1); the serial-interval substitution is
  stated with its mean.

## 6. England, against an independent estimate

Requires network access; see `references/external-validation.md` for the
fetch. If it sets `skip_reason`, report the test as skipped, not passed.

"Estimate Rt for England from england_cases.csv over 2021-01-20 to 2021-03-01.
These are COVID-19 cases by specimen date. Take the delay from onset to
specimen as lognormal, mean 2 days, sd 1.5."

Pass: the measured values in `references/external-validation.md` hold. `init
--disease COVID-19 --date-type specimen` on the 41-day window chooses a weekly
random walk, which passes the gate; median Rt is below 1 on all 41 days, as
inc2prev is; the expected change is Decreasing with P(Rt < 1) above 0.99. The
agent compares medians and direction, not interval overlap, and notices the
largest gap is on the last day.

## 7. The config replaces the interrogation

"Set up a nowcast for cases_report.csv. It's COVID-19." Then: "Looks right.
Onset to report is about 2 days, sd 1. Go ahead." Then: "Re-run the nowcast
on cases_report_week2.csv."

Pass: `init` first; one round of questions, covering only what `init` lists
for review, with the model defaults stated rather than asked one by one; the
substitution reported unprompted. The delay is written into the config as
`user` and the fit run with `--config`. The re-run is `fit --config <file>
--data cases_report_week2.csv` with no questions.

Fail: a second round of questions, or re-running `init` on the new data.

## 8. Strata

"Estimate Rt by region for regions.csv. It's COVID-19." Then: "Just give me one
overall number."

Pass: `init` finds `district` from the repeated dates and names `island` as too
sparse before any fit. Strata are fitted separately and reported one row each.
If `island` is fitted and fails, the run exits non-zero and the agent says
which stratum is missing and why, rather than presenting the others as the
result. For the overall number it uses `--pool` and says the pooled Rt
averages over the districts' epidemics, which the report's caveats also say.

## 9. Truncation is estimated, not asked for

With a config from test 7: "Recent counts look incomplete. Can you account for
that?"

Pass: the agent asks whether earlier snapshots exist, runs
`estimate-truncation --vintages vintages --config <file>` when pointed at
them, and the next fit reports a truncation distribution. It does not ask the
user for a truncation mean and sd first.

## 10. A short forecast, and what it assumes

With a config from test 7: "Forecast cases for the next week."

Pass: horizon 7; the agent states the default, Rt held at its last estimate,
and that `project` would let Rt keep varying with wider intervals; a forecast
reported only after the gate passes, with its assumption.
