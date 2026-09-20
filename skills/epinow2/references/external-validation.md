# External validation fixtures

Supporting material for the external data test in `TEST.md`. Fetches England
COVID-19 cases and an independently estimated Rt curve to check against.

Both sources are live and outside this repo's control. A row count that has
drifted is a reason to re-measure the numbers below, not a test failure.

Cases come from the UKHSA dashboard API. The reference Rt comes from inc2prev
(Abbott and Funk 2022, doi 10.1101/2022.03.29.22273101), which estimates Rt with
a Gaussian process on ONS Community Infection Survey prevalence.

## Fetching

Both fetches are wrapped in `tryCatch()`. If either source is unreachable, or
`jsonlite` is missing, the block sets `skip_reason` and writes no files. Check
`skip_reason` before running the test: if it is non-`NULL`, stop and report the
test as skipped. A skip is not a pass.

```r
skip_reason <- NULL

fetch_fixtures <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    return("jsonlite is not installed")
  }

  base <- paste0(
    "https://api.ukhsa-dashboard.data.gov.uk/themes/infectious_disease",
    "/sub_themes/respiratory/topics/COVID-19/geography_types/Nation",
    "/geographies/England/metrics/COVID-19_cases_casesByDay"
  )
  cases <- tryCatch(
    do.call(rbind, lapply(2020:2022, function(y) {
      url <- sprintf("%s?page_size=400&year=%d", base, y)
      jsonlite::fromJSON(url)$results[, c("date", "metric_value")]
    })),
    error = function(e) e
  )
  if (inherits(cases, "error")) {
    return(paste("UKHSA dashboard unreachable:", conditionMessage(cases)))
  }

  # NOTE the published column layout is shifted: `name` holds the variable,
  # `variable` holds the geography. Property of the file, not a bug here.
  ip <- tryCatch(
    read.csv(paste0(
      "https://raw.githubusercontent.com/epiforecasts/inc2prev",
      "/main/outputs/estimates_national.csv"
    )),
    error = function(e) e
  )
  if (inherits(ip, "error")) {
    return(paste("inc2prev outputs unreachable:", conditionMessage(ip)))
  }

  # Write only once both fetches have succeeded, so a half-fetched pair never
  # looks like a usable fixture on disk.
  cases <- cases[order(cases$date), ]
  ref_rt <- ip[
    ip$name == "R" & ip$variable == "England",
    c("date", "median", "q5", "q95")
  ]
  if (nrow(cases) == 0 || nrow(ref_rt) == 0) {
    return("a source returned no usable rows; its schema may have changed")
  }

  write.csv(
    data.frame(date = cases$date, confirm = cases$metric_value),
    "england_cases.csv",
    row.names = FALSE
  )
  write.csv(ref_rt, "inc2prev_england_rt.csv", row.names = FALSE)
  NULL
}

skip_reason <- fetch_fixtures()
if (!is.null(skip_reason)) {
  message("SKIP: ", skip_reason)
}
```

## Measured values

Fetched successfully: `england_cases.csv` has 1067 contiguous daily rows,
2020-01-30 to 2022-12-31. `inc2prev_england_rt.csv` has 1039 rows, 2020-04-26
to 2023-02-28.

Window under test: 2021-01-20 to 2021-03-01, the post-peak decline. 41 days,
cases 4,112 to 32,678. The inc2prev median is below 1 on all 41 days, range
0.80 to 0.93, so the reference direction is unambiguous.

Specification, as TEST.md test 6 sets it up: `init --disease COVID-19
--date-type specimen --horizon 7`, then the onset-to-specimen delay from the
prompt (lognormal, mean 2, sd 1.5, max 10) as `user`. That gives the COVID-19
serial interval from `epiparameter` as a substituted generation time (mean
4.70), its incubation period (mean 5.60), a week effect following the specimen
date type, EpiNow2's default Rt prior and, for a 41-day series, a weekly
random walk. Measured on EpiNow2 1.9.0, seed 20260915 (Stan and R), 500 warmup
iterations:

| Quantity | Weekly random walk (`init`'s choice) | Gaussian process (`--rw 0`) |
| :--- | :--- | :--- |
| Max Rhat | 1.0037 | 1.0140 |
| Min ESS | 634 | 300 |
| Divergent transitions | 0 | 0 |
| Fixed quantities excluded | 91 | 91 |
| Convergence | PASS | FAIL, estimates withheld |
| Days with median Rt below 1 | 41 of 41 | - |
| Rt range | 0.69 to 0.96 | - |
| Mean absolute difference from inc2prev | 0.098 | - |
| Rt at 2021-03-01 | 0.69 (90% CrI 0.58 to 0.83) | - |
| Expected change in reports | Decreasing, P(Rt < 1) above 0.99 | - |
| Growth rate at 2021-03-01 | -0.073 (-0.105 to -0.039), halving time about 9.5 days | - |

The Gaussian process does not converge on this window, and exits non-zero
with its estimates withheld. That is the intended behaviour on real data, and
`init` does not choose it for a series this short.

Before the skill left the Rt prior to EpiNow2, it set a lognormal with mean 2
and sd 1. On this window that moved the random walk's results by no more than
0.01 in Rt.

The largest disagreement with inc2prev is at the end of the window: 0.69
against 0.93 on 2021-03-01. The last days of a renewal fit are its least
informed, because the most recent infections have had the least time to be
observed. An agent that notices this and says so has done better than one
that reports agreement on direction alone.

## Forecast against what happened

The 7-day forecast from the random walk fit, under each choice of Rt over the
forecast. The cases later reported for those days are in the same file:

| Date | `latest`: median (90% CrI) | `project`: median (90% CrI) | Reported |
| :--- | :--- | :--- | ---: |
| 2021-03-02 | 5,106 (4,498 to 5,795) | 5,135 (4,562 to 5,851) | 5,950 |
| 2021-03-03 | 4,748 (4,109 to 5,483) | 4,754 (4,133 to 5,455) | 5,305 |
| 2021-03-04 | 4,322 (3,648 to 5,093) | 4,327 (3,696 to 5,100) | 5,011 |
| 2021-03-05 | 3,766 (3,147 to 4,568) | 3,805 (3,176 to 4,548) | 4,728 |
| 2021-03-06 | 2,758 (2,235 to 3,385) | 2,768 (2,247 to 3,428) | 3,832 |
| 2021-03-07 | 2,478 (1,961 to 3,161) | 2,503 (1,985 to 3,180) | 3,677 |
| 2021-03-08 | 3,707 (2,861 to 4,775) | 3,744 (2,842 to 4,953) | 5,818 |

Reported cases fell more slowly than projected, and were inside the 90%
interval on 2 of 7 days under either choice. Over 7 days a weekly random walk
has at most one more step, so `project` barely widens the interval here; the
difference grows with the horizon. The shortfall is consistent with the low
final Rt above. Schools in England reopened on 8 March 2021 with mass lateral
flow testing of secondary pupils, so the last day also carries a change in
testing that no case-based forecast could anticipate. This is not an assertion
in TEST.md; it is here so nobody reads a forecast from this skill as more than
it is.

EpiNow2's third choice, `estimate`, held Rt fixed over the last 24 days of the
window as well as the forecast, and failed the gate with 15 divergent
transitions. The skill does not offer it.

## Comparing intervals

Compare medians and direction, not credible intervals. The two differ on this
window (mean 90% width 0.116 for EpiNow2 against 0.074 for inc2prev) and they
are not measuring the same uncertainty: inc2prev's comes from a prevalence
survey, EpiNow2's from case counts. Interval overlap is not a meaningful
assertion here and should not be added.
