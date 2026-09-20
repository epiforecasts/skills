#!/usr/bin/env Rscript

# Contract tests for epinow2.R: what it refuses, what it records, what it
# exits with. No agent is involved; agent behaviour is in TEST.md.
#
#   Rscript scripts/test_epinow2.R          # no sampler, about a minute
#   Rscript scripts/test_epinow2.R --fits   # adds sampler tests, several minutes

self <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
script <- normalizePath(file.path(dirname(self), "epinow2.R"))
source(file.path(dirname(self), "make_fixtures.R"))
run_fits <- "--fits" %in% commandArgs(TRUE)

pass <- 0L
failures <- character(0)

cli <- function(...) {
  out <- suppressWarnings(system2("Rscript", c(script, shQuote(unlist(list(...)))), stdout = TRUE, stderr = TRUE))
  list(text = paste(out, collapse = "\n"), status = if (is.null(attr(out, "status"))) 0L else attr(out, "status"))
}
has <- function(r, pattern) grepl(pattern, r$text, ignore.case = TRUE)
check <- function(label, ok, detail = "") {
  if (isTRUE(ok)) {
    pass <<- pass + 1L
    cat("  ok   ", label, "\n", sep = "")
  } else {
    failures <<- c(failures, label)
    cat("  FAIL ", label, if (nzchar(detail)) paste0(": ", substr(detail, 1, 400)), "\n", sep = "")
  }
}
yml <- function(path) yaml::read_yaml(path)

work <- file.path(tempdir(), "epinow2_skill_tests")
make_fixtures(work)
setwd(work)

gt <- c("--gt-mean", "3.6", "--gt-sd", "3.1")
inc <- c("--incubation-mean", "5", "--incubation-sd", "2")
ed <- c("--event-delay-mean", "2", "--event-delay-sd", "1")
full <- c("--data", "clean.csv", "--date-type", "report", gt, inc, ed, "--dry-run")

# --- Arguments ---------------------------------------------------------------

cat("\nArguments\n")
r <- cli("fit", full, "--gt-maen", "3")
check("an unknown flag is refused by name", r$status != 0 && has(r, "--gt-maen"))

# --- init: the specification is built, not asked for -------------------------

cat("\ninit\n")
sources <- c("derived", "inferred", "user", "missing")

r <- cli("init", "--data", "bare.csv", "--out", "bare.yaml", "--cases-out", "bare_cases.csv")
cfg <- yml("bare.yaml")
check("every field records one of the four sources", all(vapply(cfg, function(f) isTRUE(f$source %in% sources), logical(1))))
check("a bare date column is never a derived date type, and carries its evidence",
      cfg$date_type$source %in% c("inferred", "missing") && nzchar(cfg$date_type$evidence))
check("distributions are missing, not guessed", cfg$generation_time$source == "missing" && cfg$incubation$source == "missing")
check("the Rt prior is EpiNow2's, put to the user as a choice",
      cfg$rt_prior$value == "default" && cfg$rt_prior$source == "inferred")
check("only inferred and missing fields are put to the user",
      has(r, "Check these before fitting") && !has(r, "  - week_effect") && !has(r, "  - timestep") && !has(r, "  - strata"))

r <- cli("init", "--data", "cases_report.csv", "--disease", "COVID-19", "--out", "covid.yaml", "--cases-out", "covid_cases.csv")
covid <- yml("covid.yaml")
check("epiparameter fills the incubation period in its published form",
      covid$incubation$source == "inferred" && !is.null(covid$incubation$value$meanlog))
check("the serial-interval substitution is recorded", isTRUE(covid$generation_time$value$substituted))
check("report dates leave the onset-to-report delay missing, and fit is blocked on it",
      covid$event_delay$source == "missing" && has(r, "refuse until these are set: event_delay"))

r <- cli("init", "--data", "linelist3.csv", "--out", "ll3.yaml", "--cases-out", "ll3_cases.csv", "--delays-out", "ll3_pairs.csv")
ll3 <- yml("ll3.yaml")
check("every date column is listed with its completeness", has(r, "onset_date \\| onset \\| 61\\.0%"))
check("the most complete column is chosen, as an inference",
      ll3$date_column$value != "onset_date" && ll3$date_column$source == "inferred")
check("onset-to-date pairs are written and offered for the event delay",
      file.exists("ll3_pairs.csv") && grepl("estimate-delay --delays ll3_pairs.csv", ll3$event_delay$evidence))
check("a linelist is one series, with the columns that could split it listed",
      ll3$strata$value == "none" && ll3$strata$source == "inferred" && grepl("sex", ll3$strata$evidence))

r <- cli("init", "--data", "linelist.csv", "--out", "ll1.yaml", "--cases-out", "ll1_cases.csv", "--delays-out", "ll1_pairs.csv")
ll1 <- yml("ll1.yaml")
check("for onset dates the pairs are offered as truncation instead",
      identical(ll1$event_delay$value, "none") && grepl("estimate-delay", ll1$truncation$evidence))
check("pairs exclude report-before-onset records", nrow(read.csv("ll1_pairs.csv")) == 297L)

r <- cli("init", "--data", "sparse_ll.csv", "--out", "sparse.yaml", "--cases-out", "sparse_cases.csv")
check("a linelist's days without cases are zeros, not gaps", nrow(read.csv("sparse_cases.csv")) == 21L && has(r, "filled with zero"))

r <- cli("init", "--data", "regions.csv", "--out", "reg.yaml", "--cases-out", "reg_cases.csv")
check("strata are found from repeated dates, whatever the column is called, and a sparse one is named",
      yml("reg.yaml")$strata$value == "district" && has(r, "under 50 total cases in: island") &&
        "region" %in% names(read.csv("reg_cases.csv")))
r <- cli("init", "--data", "regions.csv", "--out", "reg_none.yaml", "--cases-out", "reg_none.csv", "--strata", "none")
check("--strata none sums the strata into one series", nrow(read.csv("reg_none.csv")) == 60L)
r <- cli("init", "--data", "dup_dates.csv", "--out", "dup.yaml")
check("repeated dates that no column separates halt init", r$status != 0 && has(r, "no single column separates"))

r <- cli("init", "--data", "gappy.csv", "--out", "gap.yaml", "--cases-out", "gap_cases.csv")
check("gaps in aggregate counts are put to the user, not filled",
      yml("gap.yaml")$fill_zeros$source == "inferred" && has(r, "3 calendar days have no row") && nrow(read.csv("gap_cases.csv")) == 57L)
r <- cli("init", "--data", "gappy.csv", "--out", "gapf.yaml", "--cases-out", "gap_cases.csv", "--fill-zeros")
check("--fill-zeros fills them", nrow(read.csv("gap_cases.csv")) == 60L)
r <- cli("init", "--data", "negative.csv", "--out", "neg.yaml")
check("negative counts halt init", r$status != 0 && has(r, "negative case counts"))

r <- cli("init", "--data", "weekly.csv", "--out", "wk.yaml", "--cases-out", "wk_cases.csv")
wk <- yml("wk.yaml")
check("weekly counts are detected, with the end-of-week reading put to the user and no week effect",
      wk$timestep$value == "week_ending" && wk$timestep$source == "inferred" && grepl("week_starting", wk$timestep$evidence) &&
        isFALSE(wk$week_effect$value))
r <- cli("init", "--data", "weekly.csv", "--out", "wk2.yaml", "--cases-out", "wk2_cases.csv", "--week-start")
check("--week-start moves each date to the end of its week",
      as.Date(read.csv("wk2_cases.csv")$date[1]) == as.Date(read.csv("weekly.csv")$week_ending[1]) + 6)
check("a weekly horizon must be whole weeks", cli("init", "--data", "weekly.csv", "--out", "wk3.yaml", "--horizon", "10")$status != 0)

# --- lookup-delay -------------------------------------------------------------

cat("\nlookup-delay\n")
r <- cli("lookup-delay", "--disease", "COVID-19", "--param", "generation time")
check("COVID-19 generation time returns the serial interval, flagged",
      has(r, "SERIAL INTERVAL is returned") && has(r, "--gt-meanlog 1\\.386") && has(r, "--gt-substituted"))
r <- cli("lookup-delay", "--disease", "Influenza", "--param", "generation time")
check("influenza returns its own generation time, a Weibull kept as published",
      !has(r, "SERIAL INTERVAL") && has(r, "--gt-dist weibull --gt-shape 2\\.36 --gt-scale 3\\.18") && has(r, "mean 2\\.8"))
r <- cli("lookup-delay", "--disease", "Disease XYZ", "--param", "incubation period")
check("an unknown disease exits non-zero with no distribution", r$status != 0 && !has(r, "As fit flags"))
check("there is no default disease", has(cli("lookup-delay", "--param", "generation time"), "requires --disease"))

# --- fit: refusals and resolution --------------------------------------------

cat("\nfit\n")
r <- cli("fit", "--data", "clean.csv")
check("with no specification, fit names every missing part and writes nothing",
      r$status != 0 && has(r, "date type") && has(r, "generation time") && has(r, "incubation period") &&
        !file.exists("outputs/fit/fit.rds"))
r <- cli("fit", "--data", "clean.csv", "--date-type", "report", gt, inc, "--dry-run")
check("report dates without the onset-to-report delay are refused", r$status != 0 && has(r, "delay from onset to report"))
r <- cli("fit", "--data", "clean.csv", "--date-type", "onset", gt, inc, "--dry-run")
check("onset dates need no event delay and no week effect",
      r$status == 0 && has(r, "Event delay: +not applicable") && has(r, "Week effect: not estimated"), r$text)
r <- cli("fit", full, "--horizon", "7")
check("a full specification resolves with both delay components and EpiNow2's Rt prior, labelled",
      r$status == 0 && has(r, "Incubation: +lognormal\\(mean = 5") && has(r, "Event delay: +lognormal\\(mean = 2") &&
        has(r, "Week effect: estimated") && has(r, "Rt prior: +EpiNow2 default"), r$text)
check("a forecast carries what it assumes as a caveat", has(r, "holds Rt at its last estimate"))
check("--forecast-rt project changes that assumption", has(cli("fit", full, "--horizon", "7", "--forecast-rt", "project"), "keep varying"))
check("EpiNow2's 'estimate' option is refused: it would change the nowcast",
      cli("fit", full, "--horizon", "7", "--forecast-rt", "estimate")$status != 0)
r <- cli("fit", "--data", "clean.csv", "--date-type", "death", "--gt-dist", "weibull", "--gt-shape", "2.36", "--gt-scale", "3.18",
         "--gt-max", "8", inc, "--no-event-delay", "--dry-run")
check("a Weibull generation time and death dates resolve, with the ascertainment caveat",
      r$status == 0 && has(r, "GT: +weibull\\(shape = 2\\.360") && has(r, "No delay from onset to death") &&
        has(r, "infections leading to death"), r$text)
check("a horizon over 14 days is refused", cli("fit", full, "--horizon", "21")$status != 0)
r <- cli("fit", full, "--gp-ls", "2")
check("a GP length scale under 7 days is refused, pointing at a random walk", r$status != 0 && has(r, "--rw"))
r <- cli("fit", "--data", "cases_report.csv", "--date-type", "report", gt, inc, ed)
check("a raw file is refused, pointing at init", r$status != 0 && has(r, "missing: date") && has(r, "init"))
r <- cli("fit", "--data", "gappy.csv", "--date-type", "report", gt, inc, ed)
check("a broken series is refused", r$status != 0 && has(r, "fill-zeros"))
r <- cli("fit", "--data", "reg_cases.csv", "--date-type", "report", gt, inc, ed, "--dry-run", "--pool")
check("--pool pools strata and says so as a caveat", has(r, "3, pooled") && has(r, "pooled across 3"))
r <- cli("fit", "--data", "wk_cases.csv", "--date-type", "report", gt, inc, ed, "--dry-run")
check("weekly counts are fitted as weekly totals, with no week effect",
      r$status == 0 && has(r, "Timestep: +weekly") && has(r, "Week effect: not estimated"), r$text)

# --- fit --config ------------------------------------------------------------

cat("\nfit --config\n")
r <- cli("fit", "--config", "bare.yaml", "--dry-run")
check("a config with missing fields is refused by name", r$status != 0 && has(r, "generation time") && has(r, "incubation"))

complete <- list(
  data = list(value = "clean.csv", source = "derived"),
  date_type = list(value = "report", source = "user"),
  generation_time = list(value = list(dist = "gamma", mean = 3.6, sd = 1.6, max = 14, substituted = TRUE), source = "inferred"),
  incubation = list(value = list(dist = "lognormal", meanlog = 1.525, sdlog = 0.629, max = 20), source = "inferred"),
  # The form estimate-delay writes: uncertain parameters.
  event_delay = list(value = list(dist = "lognormal", meanlog = list(mean = 1.1, sd = 0.034),
                                  sdlog = list(mean = 0.56, sd = 0.027), max = 14L), source = "derived"),
  dynamics = list(value = list(type = "rw", step = 7), source = "inferred")
)
yaml::write_yaml(complete, "complete.yaml")
r <- cli("fit", "--config", "complete.yaml", "--dry-run")
check("a complete config resolves with no flags, keeping an estimate's uncertainty",
      r$status == 0 && has(r, "mean = 3\\.6") && has(r, "meanlog ~ Normal\\(1\\.100, 0\\.034\\)") &&
        has(r, "random walk") && has(r, "serial interval"), r$text)
check("a flag overrides the config", has(cli("fit", "--config", "complete.yaml", "--dry-run", "--gt-mean", "9.9", "--gt-sd", "2"), "mean = 9\\.9"))
r <- cli("fit", "--config", "covid.yaml", "--data", "cases_report_week2.csv", "--event-delay-mean", "2", "--event-delay-sd", "1", "--dry-run")
check("a recurring run takes new raw data with the config's choices", r$status == 0 && has(r, "Date type: +report"), r$text)
r <- cli("fit", "--config", "gap.yaml", "--date-type", "report", gt, inc, ed, "--dry-run")
check("fit refuses gaps until fill_zeros is settled", r$status != 0 && has(r, "fill_zeros"))
r <- cli("fit", "--config", "complete.yaml", "--dry-run", "--date-type", "onset")
check("correcting the date type to onset drops the week effect and the event delay",
      r$status == 0 && has(r, "Week effect: not estimated") && has(r, "Event delay: +not applicable"), r$text)

# --- Estimators: refusals -----------------------------------------------------

cat("\nEstimators\n")
dir.create("one_vintage", showWarnings = FALSE)
invisible(file.copy("clean.csv", "one_vintage/v1.csv"))
check("estimate-truncation needs two vintages", has(cli("estimate-truncation", "--vintages", "one_vintage"), "at least 2"))
write.csv(data.frame(delay = rpois(50, 3)), "ints.csv", row.names = FALSE)
check("estimate-delay refuses integer delays", has(cli("estimate-delay", "--delays", "ints.csv"), "pdate_lwr"))

# --- Sampler tests -----------------------------------------------------------

if (!run_fits) {
  cat("\nSampler tests skipped (pass --fits).\n")
} else {
  cat("\nSampler tests\n")
  spec <- c("--data", "ec.csv", "--date-type", "report", "--gt-mean", "4.7", "--gt-sd", "2.9",
            "--incubation-mean", "5.6", "--incubation-sd", "3.9", "--incubation-max", "20",
            "--event-delay-mean", "2", "--event-delay-sd", "1", "--event-delay-max", "10", "--gt-substituted", "--rw", "7")

  # 1000 warmup iterations: at 500 this fixture sat on the Rhat threshold.
  r <- cli("fit", spec, "--horizon", "7", "--warmup", "1000", "--output-dir", "out_ok")
  r <- cli("evaluate", "--fit", "out_ok/fit.rds", "--report-out", "rep/ok.md")
  check("the reference fit passes the gate", has(r, "Convergence: PASS") && r$status == 0, r$text)
  if (file.exists("rep/ok.md")) {
    rep_text <- readLines("rep/ok.md")
    check("the caveat marker is in the Rt row", any(grepl("^\\| Effective reproduction no\\. \\|.*caveats", rep_text)))
    check("the expected change is EpiNow2's label with P(Rt < 1)", any(grepl("^\\| Expected change in reports \\|.*P\\(Rt < 1\\)", rep_text)))
    check("the forecast has one row per day, under its assumption",
          sum(grepl("^\\| 2020-", rep_text)) == 7 && any(grepl("holds Rt at its last estimate", rep_text)))
    check("the report states the specification", any(grepl("Incubation:", rep_text)))
  }
  r <- cli("evaluate", "--fit", "out_ok/fit.rds", "--date", "1999-01-01", "--report-out", "rep/err.md")
  check("a date outside the fit errors and leaves no report file",
        r$status != 0 && !file.exists("rep/err.md") && !file.exists("rep/err.md.part"))

  # A starved fit: the gate withholds everything and still records the non-answer.
  r <- cli("fit", spec, "--rw", "0", "--gp-ls", "7", "--warmup", "20", "--samples", "40", "--output-dir", "out_bad")
  r <- cli("evaluate", "--fit", "out_bad/fit.rds", "--report-out", "rep/bad.md")
  check("a failed gate exits non-zero, withholds estimates and still writes its report",
        has(r, "Convergence: FAIL") && r$status != 0 && !has(r, "\\| Effective reproduction") && file.exists("rep/bad.md"), r$text)

  write.csv(rbind(data.frame(read.csv("ec.csv"), region = "east"), data.frame(read.csv("ec.csv"), region = "west")),
            "ec_regions.csv", row.names = FALSE)
  r <- cli("fit", sub("ec.csv", "ec_regions.csv", spec, fixed = TRUE), "--output-dir", "out_reg")
  r <- cli("evaluate", "--fit", "out_reg/fit.rds")
  withheld <- has(r, "\\| (FAIL|ERROR) \\|")
  check("a stratified report has a row per stratum, and its exit status agrees with them",
        has(r, "\\| east \\|") && has(r, "\\| west \\|") && (withheld == (r$status != 0)), r$text)
  if (file.exists("out_reg/fit.rds")) {
    broken <- readRDS("out_reg/fit.rds")
    broken$regional[["west"]]$fit <- NULL
    dir.create("out_broken", showWarnings = FALSE)
    saveRDS(broken, "out_broken/fit.rds")
    r <- cli("evaluate", "--fit", "out_broken/fit.rds")
    check("a stratum that did not fit is listed, withheld, and fails the run",
          has(r, "\\| west \\| ERROR") && has(r, "stratum did not fit") && r$status != 0, r$text)
  }

  # Weekly totals, with init's choice of dynamics (a GP for 126 days). The
  # forecast is read from the fit, not the report: this fit sits on the gate
  # thresholds, and a failed gate withholds the forecast.
  cli("fit", "--config", "wk.yaml", "--date-type", "report", head(tail(spec, -4), -2), "--horizon", "14",
      "--output-dir", "out_wk")
  if (file.exists("out_wk/fit.rds")) {
    suppressPackageStartupMessages(library(EpiNow2))
    fc <- as.data.frame(summary(readRDS("out_wk/fit.rds"), type = "parameters", params = "reported_cases"))
    fc <- fc[fc$type == "forecast" & !is.na(fc$median), ]
    check("a weekly fit forecasts weekly totals, one per week ending",
          nrow(fc) == 2 && all(diff(c(as.Date("2020-06-26"), as.Date(fc$date))) == 7))
  } else {
    check("the weekly fit ran", FALSE)
  }

  # The estimators write into the config only on a pass, keeping uncertainty.
  yaml::write_yaml(complete, "est.yaml")
  r <- cli("estimate-delay", "--delays", "ll1_pairs.csv", "--config", "est.yaml")
  ml <- yml("est.yaml")$event_delay$value$meanlog
  check("estimate-delay picks lognormal by AIC and recovers meanlog log(3) with its sd",
        has(r, "Family: lognormal") && has(r, "Convergence: PASS") && abs(ml$mean - log(3)) < 0.1 && !is.null(ml$sd), r$text)

  r <- cli("estimate-truncation", "--vintages", "vintages", "--config", "est.yaml")
  check("estimate-truncation passes and writes to the config",
        has(r, "Convergence: PASS") && identical(yml("est.yaml")$truncation$source, "derived"), r$text)
  check("the estimated truncation reaches the model",
        has(cli("fit", "--config", "est.yaml", "--dry-run"), "Truncation: +lognormal\\(meanlog ~"))
}

cat(sprintf("\n%d passed, %d failed\n", pass, length(failures)))
if (length(failures) > 0) {
  cat("\nFailed:\n", paste0("  ", failures, "\n"), sep = "")
  quit(status = 1)
}
