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

Measured with `--rw 7` on EpiNow2 1.9.0, seed 20260915:

| Quantity | Value |
| :--- | :--- |
| Max Rhat | 1.0064 |
| Min ESS | 544 |
| Divergent transitions | 0 |
| Fixed quantities excluded | 43 |
| Days with median Rt below 1 | 41 of 41 |
| Rt range | 0.76 to 0.94 |
| Mean absolute difference from inc2prev | 0.062 |
| Growth rate at 2021-03-01 | negative, halving time about 9.3 days |

The default Gaussian process does not converge on this window: max Rhat 1.0033
and 0 divergences, but minimum ESS 341 on `lp__`, below the threshold, so
estimates are withheld and the run exits non-zero. That is the intended
behaviour on real data, and is why the numbers above use a weekly random walk.

## Comparing intervals

Compare medians and direction, not credible intervals. The two happen to be
similar on this window (mean 90% width 0.063 for EpiNow2 against 0.074 for
inc2prev) but they are not measuring the same uncertainty: inc2prev's comes from
a prevalence survey, EpiNow2's from case counts. Interval overlap is not a
meaningful assertion here and should not be added.
