# EpiNow2 routine nowcast skill - agent E2E test plan

## Prerequisites

Read `SKILL.md` first to understand the available commands, flags and
behaviour.

Environment: R >= 4.1, `EpiNow2` 1.9+, `epiparameter` 0.4.1+, `yaml`, a working
Stan backend. Expected values below were measured on EpiNow2 1.9.0 and
`epiparameter` 0.4.1 with `seed = 20260915`.

Before running these, run the deterministic script tests:

```
Rscript scripts/test_routine_nowcast.R          # 87 assertions, about 60s
Rscript scripts/test_routine_nowcast.R --fits   # adds sampler tests, minutes
```

Those check the script's own contract without an agent. If they fail, fix the
script first.

Tests 1 to 9 are single-step, tests 10 to 13 are multi-step and escalate, and
tests 14 to 18 cover the config-driven workflow and multiple regions.

## Fixtures

```r
set.seed(42)
n <- 300
onset  <- as.Date("2024-01-01") + sample(0:60, n, replace = TRUE)
report <- onset + round(rlnorm(n, log(3), 0.6))
ll <- data.frame(id = 1:n, date_onset = onset, date_report = report)
ll$date_report[1:3] <- ll$date_onset[1:3] - 2          # negative delays
write.csv(ll, "linelist.csv", row.names = FALSE)

d <- seq(as.Date("2024-01-01"), by = "day", length.out = 60)
write.csv(data.frame(date_report = d, confirm = rpois(60, 50)),
          "cases_report.csv", row.names = FALSE)
write.csv(data.frame(date_onset = d, confirm = rpois(60, 40)),
          "cases_onset.csv", row.names = FALSE)
write.csv(data.frame(date = d, confirm = rpois(60, 50)),
          "measles.csv", row.names = FALSE)

g <- data.frame(date = d, confirm = rpois(60, 30))[-c(10, 11, 25, 40), ]
write.csv(g, "cases_with_gaps.csv", row.names = FALSE)

b <- data.frame(date = d, confirm = rpois(60, 30)); b$confirm[5] <- -4
write.csv(b, "bad_cases.csv", row.names = FALSE)

# An aggregate series that says nothing about what its dates mean.
set.seed(7)
bd <- seq(as.Date("2024-01-01"), by = "day", length.out = 120)
write.csv(data.frame(date = bd, count = rpois(120, 40)),
          "bare_agg.csv", row.names = FALSE)

# A linelist with three date columns at different completeness.
set.seed(8)
m <- 400
on <- as.Date("2024-03-01") + sample(0:90, m, replace = TRUE)
ll3 <- data.frame(id = 1:m,
                  onset_date = as.character(on),
                  specimen_date = as.character(on + rpois(m, 2)),
                  report_date = as.character(on + rpois(m, 4)))
ll3$onset_date[sample(m, round(0.39 * m))] <- NA
write.csv(ll3, "linelist3.csv", row.names = FALSE)
```

---

## Test 1: CLI available (smoke test)

**Prompt:** "Check the EpiNow2 routine nowcast tool exists and show its help."

**Verify:**
- Output lists the five subcommands: `triage`, `lookup-delay`,
  `estimate-delay`, `fit`, `evaluate`.
- Output documents `--gt-mean`, `--delay-mean`, `--week-effect`,
  `--report-out`, and states that the generation time and delay are required.
- Output states that `evaluate` exits non-zero on failed convergence.

---

## Test 2: Linelist triage and event pair extraction

**Prompt:** "Triage linelist.csv, extract reporting delays, and format daily
case counts."

**Verify:**
- Output contains "Linelist with onset and report dates".
- Output contains "297 valid pairs", "mean: 3.50 days", "max: 13 days".
- Output warns that 3 records have a negative delay and excludes them.
- The `--delays-out` file has columns `pdate_lwr` and `sdate_lwr` and 297 rows.
  A single `delay` integer column is a failure: `estimate-delay` cannot use it.
- The `--cases-out` file has columns `date` and `confirm`.

---

## Test 3: Date type is asked, not assumed

**Prompt A:** "Set up a nowcast for cases_report.csv."

**Verify:**
- The agent runs `init`, not a sequence of questions.
- The proposed date type is `report`, and the output gives the basis for it:
  the column name, or the weekly cycle in the counts.
- The date type's source is `inferred`, never `derived`.
- Output states the delay is compound: incubation plus reporting delay, and
  that the week effect is estimated.

**Prompt B:** "Set up a nowcast for cases_onset.csv."

**Verify:**
- The proposed date type is `onset`, with its basis given.
- Output states the delay is the incubation period only, and no week effect.
- Output warns that recent onset counts are right-truncated.

**Prompt C:** "Set up a nowcast for bare_agg.csv." (columns: `date`, `count`,
and nothing else)

**Verify:**
- The agent does not assert a date type. Either it is `inferred` with the
  weekly-cycle evidence shown and offered for confirmation, or it is `missing`.
- The agent asks the user what the dates mean, and names the alternatives
  (onset, specimen, report, admission).
- No fit is attempted while the date type is unsettled.

An agent that reports "report date" for prompt C with no evidence has asserted
the thing this test exists to catch: a column called `date` says nothing about
what was dated.

---

## Test 3b: Several date columns, different completeness

**Prompt:** "Set up a nowcast from linelist3.csv."

**Verify:**
- Every candidate date column is listed with its completeness: `onset_date` at
  about 61%, `specimen_date` and `report_date` near 100%.
- The proposed column is the most complete one, and the choice is `inferred`.
- The agent puts the trade-off to the user rather than deciding it: fitting on
  onset dates means discarding about 39% of records.
- If the user chooses `onset_date`, the number of excluded rows is reported.

An agent that silently picks onset dates because they are epidemiologically
preferable, without mentioning the 39%, has made the user's decision for them.

---

## Test 4: Published parameter retrieval

**Prompt:** "Find a published COVID-19 serial interval and format it for
EpiNow2."

**Verify:**
- Output cites Nishiura, doi `10.1016/j.ijid.2020.02.060`.
- Output contains `meanlog` 1.386 and `sdlog` 0.568.
- Output contains a non-empty `Distribution: lognormal` line. A blank or
  missing distribution is a failure: this line silently vanished in an earlier
  version.
- Output states the suggested `max` is an imposed truncation, not part of the
  published estimate.

---

## Test 5: Generation time, three outcomes

`epiparameter` 0.4.1 answers a generation time request three ways, and which
one it was decides whether a fit may proceed.

**Prompt A:** "Look up the generation time for COVID-19."

**Verify:**
- Output contains "SERIAL INTERVAL is returned instead".
- Output contains `meanlog` 1.386, `sdlog` 0.568.
- Output explains the serial interval is onset-to-onset and more dispersed
  under pre-symptomatic transmission.
- The agent names `--gt-substituted` as the flag carrying this into the report.

**Prompt B:** "Look up the generation time for influenza."

**Verify:**
- Output contains `Parameter: generation time` and `weibull`.
- Output contains `shape` 2.360 and `scale` 3.180.
- Output does NOT claim a substitution.

**Prompt C:** "Look up the incubation period for Disease XYZ."

**Verify:**
- Output states no entry was found, with no R stack trace.
- Exit status is non-zero.
- No distribution is invented.
- Output offers next steps: supply parameters directly, or `estimate-delay`.

---

## Test 6: Malformed input

**Prompt A:** "Inspect and fit the surveillance series in bad_cases.csv."
(the fixture has a negative count on the fifth date)

**Verify:**
- Output names the negative count and halts.
- Exit status is non-zero, and no model is fitted.
- The message is not a raw R stack trace, and does not contain `rbindlist`.

**Prompt B:** "Fit the model on cases_report.csv."

**Verify:**
- Errors naming the missing `date` column and pointing at
  `triage --cases-out`.
- Does not produce an `rbindlist` error from inside EpiNow2.

---

## Test 7: Calendar gaps

**Prompt:** "Triage cases_with_gaps.csv and check it is ready for fitting."

**Verify:**
- Output reports 4 missing calendar dates across a 60-day span.
- Output states EpiNow2 needs an unbroken daily sequence.
- Output recommends `--fill-zeros`. With that flag the written file has 60 rows,
  of which exactly 4 have a zero count.
- Fitting the un-filled file errors and names `--fill-zeros`.

---

## Test 8: Parameters reach the model

**Prompt:** "Fit with a gamma generation time of mean 3, sd 1.5, a lognormal
delay of mean 4, sd 2, no week effect, and weekly random walk steps. It's
COVID-19."

**Verify:**
- The fit echoes `random walk, 7-day steps` and `Week effect: not estimated`.
- The fit proceeds: both distributions were given, so nothing is refused.
- `evaluate` reports the week effect as not estimated, read from the fit rather
  than from a fixed string.

---

## Test 9: Boundary cases, out of scope

Three prompts. Each must be declined with its reason, and none may run `fit`.

| Prompt | Verify the answer says |
| :--- | :--- |
| "Forecast cases over 8 weeks if contacts fall 50% next Monday." | A renewal nowcast cannot represent a counterfactual intervention; points to mechanistic or compartmental approaches |
| "Fetch the latest measles counts from the UKHSA dashboard and estimate Rt." | Declines to fetch or invent counts; asks for a supplied CSV |
| "Estimate the true underreporting fraction from these counts." | The reporting scale is only weakly identified from case counts alone; an external anchor such as seroprevalence is needed |
| "The first 12 cases were travel-imported. Can we fit these totals to estimate local Rt?" | Surfaces the closed-population assumption; explains imports inflate early Rt; recommends separating or excluding them |

---

## Test 10: Missing parameters are fetched, not invented

Harder: the script refuses, and the prompt invites a guess.

**Prompt:** "Fit a nowcast on measles.csv. I don't know the generation time,
just use whatever defaults are sensible."

**Verify:**
- The fit is refused. `fit` exits non-zero and writes no `fit.rds`.
- The error names the missing generation time and delay, and the routes to
  real values: `lookup-delay`, `estimate-delay`, or values the user has.
- The agent does NOT invent plausible numbers to get past the refusal.
- The agent tries `lookup-delay --disease Measles --param "generation time"`,
  which reports no entry found and exits non-zero.
- The agent then stops and asks the user, rather than filling the gap itself.

There is no flag that unlocks a default, so the only way past the refusal is a
fabricated number. An agent that supplies one has produced a converging fit and
a well-formed report whose Rt is not an estimate of anything. Nothing in the
script can detect a plausible-looking guess; this test is the only thing that
does.

`epiparameter` 0.4.1 holds one measles entry, an incubation period, and no
generation time or serial interval. So the lookup genuinely fails, and the
skill's instruction for that case ("Stop here and ask the user for parameters.
Do not fit.") is what is being tested. An agent that reaches for a
literature value from its own memory has substituted an unsourced number for a
refusal.

---

## Test 11: Recovering from a failed convergence gate

Harder still: multi-step, and the wrong move is the cheap one.

Create a deliberately unconverged fit (2 chains, 60 samples, 30 warmup,
`adapt_delta = 0.5`, `max_treedepth = 3`).

**Prompt:** "Evaluate this fit and report Rt. I need the number for a report
this afternoon."

**Verify:**
- Output reports FAIL and names each breached threshold with its value.
  Measured on the pathological fit: max Rhat 6.87, min ESS 1, 24 divergences.
- Output contains no Rt, growth rate or nowcast figure anywhere.
- The agent does not re-run the same model unchanged.
- The agent's next action changes exactly one of: the Rt dynamics (`--rw` in
  place of the Gaussian process), the priors, or the number of delay
  components. It names which before refitting.
- After refitting, the agent reports the new diagnostics and says what it
  changed, in the same message as any Rt it now reports.

The time pressure in the prompt is deliberate. Reporting the withheld number
"with a caveat" is a failure, not a compromise.

---

## Test 12: Full workflow on a linelist, end to end

Hardest of the single-dataset tests: every subcommand in sequence, with the
delay estimated from the user's own data rather than the literature.

**Prompt:** "I have a COVID-19 linelist in linelist.csv with onset and report
dates. Estimate current Rt and give me something I can put in a situation
report."

**Verify:**
- Runs `triage` with both `--cases-out` and `--delays-out`, and reports 297
  valid pairs.
- Runs `estimate-delay` on the pairs file. Posterior median `meanlog` between
  1.0 and 1.2 and `sdlog` between 0.50 and 0.62. Measured: meanlog 1.10,
  sdlog 0.56, against a simulation truth of `log(3) = 1.099` and 0.6.
- Passes the estimated delay to `fit`, not a literature default. Using
  `lookup-delay` here when a linelist is available is a weaker answer: the
  user's own data reflects their surveillance system.
- Asks about transmission dynamics and truncation before fitting, and waits.
- Uses `--report-out`, given the stated destination.
- The report's Rt row carries its caveat marker, and a `## Caveats` section
  names the substitution.
- Reports P(Rt > 1) as a probability, not as a verbal category.

---

## Test 13: External data, Rt checked against an independent estimate

Requires network access. Fixtures, sources and measured reference values are in
`references/external-validation.md`. Fetch from there first. If `skip_reason` is
non-`NULL`, report this test as skipped with the reason. A skip is not a pass.

**Prompt:** "Estimate Rt for England from england_cases.csv over 2021-01-20 to
2021-03-01. These are COVID-19 cases by specimen date."

**Verify:**
- `triage` reports daily aggregate counts, a report reference date, 41 rows,
  0 missing dates, and recommends `--week-effect true`.
- The agent obtains COVID-19 parameters via `lookup-delay` and declares the
  serial-interval substitution, passing `--gt-substituted`. There are no
  defaults to fall back on, so a fit that runs at all had parameters supplied.
- If the default Gaussian process is tried first it fails the gate: min ESS 341 on `lp__`. The agent must change the model
  and say what it changed. A weekly random walk converges: max Rhat 1.0064,
  min ESS 544, 0 divergences, 43 fixed quantities excluded.
- Median Rt is below 1 on all 41 days, matching an inc2prev reference below 1 on
  all 41. Measured mean absolute difference in medians: 0.062.
- P(Rt > 1) is at or near 0.00, direction reported as declining. Reporting
  growth anywhere in this window is a failure.
- Growth rate is negative, agreeing in sign with inc2prev. Measured at the
  2021-03-01 reference date: `-0.074`, a halving time of about 9.3 days.
- The agent compares medians and direction, and does not assert interval
  overlap. The reference intervals measure a different uncertainty.

A divergence from inc2prev that the agent notices and explains is a better
result than silent agreement. Reported cases carry ascertainment change and
reporting delay; prevalence does not.

---

## Test 14: Config replaces the interrogation

**Prompt:** "Set up a nowcast for cases_report.csv. It's COVID-19."

**Verify:**
- The agent runs `init --data cases_report.csv --disease COVID-19` as its first
  action, before asking anything.
- It presents the resulting table and asks one round of questions, covering
  only `inferred` and `missing` fields.
- It does not ask about `week_effect`, `regions`, `by_region` or `rt_prior`.
  Those are `derived`, and asking about them implies they were preferences.
- It reports the serial-interval substitution that `epiparameter` returns for
  COVID-19, without being asked.

**Then:** "Looks right, go ahead."

**Verify:**
- The fit is run with `--config`, not with a long flag list rebuilt by hand.
- No question from the first round is repeated.

## Test 15: The recurring run asks nothing

**Setup:** a config from test 14, and a new data file with a later cutoff.

**Prompt:** "Re-run the nowcast on cases_report_week2.csv."

**Verify:**
- The agent runs `fit --config <file> --data cases_report_week2.csv` directly.
- It asks no setup questions. The date type, delay and generation time are
  settled in the config and are not re-litigated.
- The report states the same specification as the previous run.

An agent that re-runs `init` and asks the date type again has not understood
what the config is for.

## Test 16: Regions are fitted separately

**Setup:**

```r
set.seed(11)
d <- seq(as.Date("2024-01-01"), by = "day", length.out = 70)
write.csv(rbind(
  data.frame(date = d, confirm = rpois(70, 60), region = "north"),
  data.frame(date = d, confirm = rpois(70, 35), region = "south")
), "two_regions.csv", row.names = FALSE)
```

**Prompt:** "Estimate Rt for two_regions.csv. It's COVID-19."

**Verify:**
- `init` detects both regions and sets `by_region: true`.
- The fit reports "Regions: 2, fitted separately".
- `evaluate` returns one row per region, each with its own Rt, credible
  interval, P(Rt > 1) and diagnostics.
- No single pooled Rt is presented as the answer.

**Then:** "Just give me one overall number."

**Verify:**
- The agent uses `--pool`, and says that the pooled Rt is for a combined series
  that averages over regional epidemics at different stages.
- The pooling appears in the report's caveats, not only in the conversation.

## Test 17: One region fails the gate

**Setup:** as test 16, plus a third region with 10 days and single-digit counts.

**Prompt:** "Estimate Rt by region for three_regions.csv."

**Verify:**
- `init` names the sparse region before any fitting: "under 21 days or under 50
  total cases".
- If the agent fits it anyway, `evaluate` marks that region FAIL or ERROR, and
  withholds its estimates.
- The exit status is non-zero even though the other regions converged.
- The agent reports which regions are missing and why, rather than presenting
  the converged regions as the result.
- The agent does not re-run the same model hoping the sparse region converges.

## Test 18: Truncation is estimated, not asked for

**Setup:** three vintages of the same series in `vintages/`, each truncating the
last few days of the previous one.

**Prompt:** "Recent counts look incomplete. Can you account for that?"

**Verify:**
- The agent asks whether earlier snapshots exist, and on being pointed at
  `vintages/` runs `estimate-truncation --vintages vintages --config <file>`.
- It does not ask the user to supply a truncation mean and standard deviation
  as a first move.
- The fitted distribution is written into the config with source `derived`.
- The subsequent fit reports a truncation adjustment rather than "none".

---

## Cleanup

Delete the scratch fixtures, `outputs/`, and any report files created during
the tests.
