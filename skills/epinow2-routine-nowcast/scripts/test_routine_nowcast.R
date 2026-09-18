#!/usr/bin/env Rscript

# Mechanical tests for routine_nowcast.R.
#
# These assert the script's contract: what it rejects, what it prints, what it
# exits with. No agent is involved, so they are deterministic and worth running
# after any change to the script. The tests that need an agent live in TEST.md.
#
# Usage:
#   Rscript scripts/test_routine_nowcast.R          # fast tests only
#   Rscript scripts/test_routine_nowcast.R --fits   # also the sampler tests
#
# The sampler tests are excluded by default because they take minutes. Run them
# before releasing a change to fitting, diagnostics or reporting.

# Locate the script under test relative to this file, so the tests run from any
# working directory. --file= is how Rscript reports its own path.
self <- sub("^--file=", "",
            grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))
candidates <- c(
  if (length(self) == 1L) file.path(dirname(self), "routine_nowcast.R"),
  file.path("scripts", "routine_nowcast.R"),
  "routine_nowcast.R"
)
script <- candidates[file.exists(candidates)][1]
if (is.na(script)) {
  stop("Cannot locate routine_nowcast.R next to this test script.")
}
script <- normalizePath(script)

run_fits <- "--fits" %in% commandArgs(trailingOnly = TRUE)

pass <- 0L
fail <- 0L
failures <- character(0)

# Run the script and capture stdout, stderr and exit status together. Every
# assertion below is made against what a caller would actually observe.
cli <- function(...) {
  args <- c(script, as.character(unlist(list(...))))
  out <- suppressWarnings(
    system2("Rscript", args, stdout = TRUE, stderr = TRUE)
  )
  status <- attr(out, "status")
  list(
    text = paste(out, collapse = "\n"),
    status = if (is.null(status)) 0L else as.integer(status)
  )
}

check <- function(label, condition, detail = "") {
  if (isTRUE(condition)) {
    pass <<- pass + 1L
    cat(sprintf("  ok   %s\n", label))
  } else {
    fail <<- fail + 1L
    failures <<- c(failures, label)
    cat(sprintf("  FAIL %s%s\n", label, if (nzchar(detail)) paste0(": ", detail) else ""))
  }
}

has <- function(res, pattern) grepl(pattern, res$text, ignore.case = TRUE)

# --- Fixtures ---------------------------------------------------------------
# Same generative parameters as the TEST.md fixture block, so a number measured
# under one is comparable under the other.

work <- file.path(tempdir(), "routine_nowcast_tests")
dir.create(work, showWarnings = FALSE, recursive = TRUE)
old_wd <- setwd(work)
on.exit(setwd(old_wd), add = TRUE)

set.seed(42)
n <- 300
onset <- as.Date("2024-01-01") + sample(0:60, n, replace = TRUE)
report <- onset + round(rlnorm(n, log(3), 0.6))
ll <- data.frame(id = seq_len(n), date_onset = onset, date_report = report)
ll$date_report[1:3] <- ll$date_onset[1:3] - 2   # negative delays
write.csv(ll, "linelist.csv", row.names = FALSE)

d <- seq(as.Date("2024-01-01"), by = "day", length.out = 60)
write.csv(data.frame(date_report = d, confirm = rpois(60, 50)),
          "cases_report.csv", row.names = FALSE)
write.csv(data.frame(date_onset = d, confirm = rpois(60, 40)),
          "cases_onset.csv", row.names = FALSE)

g <- data.frame(date = d, confirm = rpois(60, 30))[-c(10, 11, 25, 40), ]
write.csv(g, "cases_with_gaps.csv", row.names = FALSE)

b <- data.frame(date = d, confirm = rpois(60, 30))
b$confirm[5] <- -4
write.csv(b, "bad_cases.csv", row.names = FALSE)

clean <- data.frame(date = d, confirm = rpois(60, 50))
write.csv(clean, "clean_cases.csv", row.names = FALSE)

# --- Usage ------------------------------------------------------------------

cat("\nUsage\n")
r <- cli()
check("lists every subcommand",
      all(vapply(c("init", "triage", "lookup-delay", "estimate-delay",
                   "estimate-truncation", "fit", "evaluate"),
                 function(s) has(r, s), logical(1))))
check("documents the convergence exit behaviour", has(r, "non-zero"))

# --- Triage -----------------------------------------------------------------

cat("\nTriage\n")
r <- cli("triage", "--data", "linelist.csv",
         "--delays-out", "pairs.csv", "--cases-out", "ll_cases.csv")
check("identifies a linelist", has(r, "linelist"))
check("reports 297 valid pairs", has(r, "297"))
check("warns about 3 negative delays", has(r, "3") && has(r, "negative"))
pairs <- read.csv("pairs.csv")
check("delays-out has the event-pair columns estimate-delay needs",
      all(c("pdate_lwr", "sdate_lwr") %in% names(pairs)),
      paste("got:", paste(names(pairs), collapse = ", ")))
check("delays-out excludes the negative-delay records", nrow(pairs) == 297L,
      paste("got", nrow(pairs), "rows"))
check("cases-out has date and confirm",
      all(c("date", "confirm") %in% names(read.csv("ll_cases.csv"))))

r <- cli("triage", "--data", "cases_report.csv")
check("report dates imply a compound delay", has(r, "report|notification"))
check("report dates recommend --week-effect true", has(r, "week-effect true"))

r <- cli("triage", "--data", "cases_onset.csv")
check("onset dates are identified as onset", has(r, "onset"))
check("onset dates recommend --week-effect false", has(r, "week-effect false"))

r <- cli("triage", "--data", "cases_with_gaps.csv")
check("reports the 4 missing calendar dates", has(r, "4"))
check("names --fill-zeros as the fix", has(r, "fill-zeros"))

r <- cli("triage", "--data", "cases_with_gaps.csv",
         "--fill-zeros", "--cases-out", "filled.csv")
filled <- read.csv("filled.csv")
check("--fill-zeros writes a contiguous 60-day series", nrow(filled) == 60L,
      paste("got", nrow(filled), "rows"))
check("--fill-zeros pads with zeros, not NA", sum(filled$confirm == 0) == 4L,
      paste("got", sum(filled$confirm == 0), "zero rows"))

# A silent fallback to report dates would be worse than the error: it would
# produce a plausible fit under a date type the user did not choose.
r <- cli("triage", "--data", "cases_report.csv", "--date-type", "banana")
check("rejects an invalid --date-type", r$status != 0L)
check("names the permitted date types", has(r, "report") && has(r, "onset"))

r <- cli("triage", "--data", "bad_cases.csv")
check("halts on negative counts", r$status != 0L)
check("names the problem rather than showing a stack trace",
      has(r, "negative") && !has(r, "rbindlist"))

# --- Parameter lookup -------------------------------------------------------

cat("\nParameter lookup\n")

r <- cli("lookup-delay", "--disease", "COVID-19", "--param", "serial interval")
check("COVID-19 serial interval cites Nishiura", has(r, "Nishiura"))
check("reports meanlog 1.386", has(r, "1\\.386"))
check("reports sdlog 0.568", has(r, "0\\.568"))
# This line vanished silently in an earlier version: family() returned NULL and
# sprintf produced a zero-length vector that cat() dropped.
check("prints a non-empty Distribution line", has(r, "Distribution: lognormal"))
check("declares the max as an imposed bound", has(r, "imposed"))

# Where the database has a generation time, using the serial interval instead
# would discard the better parameter, and a spurious caveat teaches the user to
# ignore real ones.
r <- cli("lookup-delay", "--disease", "Influenza", "--param", "generation time")
check("influenza returns a real generation time",
      has(r, "Parameter: generation time"))
check("influenza reports the weibull family", has(r, "weibull"))
check("influenza announces no substitution", !has(r, "SERIAL INTERVAL is returned"))

r <- cli("lookup-delay", "--disease", "COVID-19", "--param", "generation time")
check("COVID-19 substitutes the serial interval",
      has(r, "SERIAL INTERVAL is returned"))
check("explains the substitution is onset-to-onset", has(r, "onset-to-onset"))
check("requires the substitution to be declared", has(r, "[Dd]eclare"))

r <- cli("lookup-delay", "--disease", "Disease XYZ", "--param", "incubation period")
check("unknown disease exits non-zero", r$status != 0L)
check("unknown disease invents no distribution", !has(r, "EpiNow2 specification"))
check("unknown disease offers next steps", has(r, "estimate-delay"))

# --- Fit validation ---------------------------------------------------------

cat("\nFit validation\n")

# The old failure was an rbindlist error from deep inside EpiNow2, which told
# the user nothing about their file.
# Fully specified apart from the defect under test, so each failure is
# attributable to the input rather than to missing parameters.
dists <- c("--gt-mean", "3.6", "--gt-sd", "3.1", "--gt-max", "14",
           "--delay-mean", "4", "--delay-sd", "2", "--delay-max", "14")

r <- cli("fit", "--data", "cases_report.csv", dists)
check("names the missing date column", has(r, "date"))
check("points at triage --cases-out", has(r, "cases-out"))
check("does not surface an internal rbindlist error", !has(r, "rbindlist"))

r <- cli("fit", "--data", "cases_with_gaps.csv", dists)
check("rejects a non-contiguous series", r$status != 0L)
check("names --fill-zeros as the fix", has(r, "fill-zeros"))

r <- cli("fit", "--data", "clean_cases.csv", dists, "--gp-ls", "2")
check("refuses a GP length scale below 7 days", r$status != 0L)
check("recommends a random walk instead", has(r, "--rw"))

# There is no default generation time or delay: a default would be some
# particular pathogen's biology, and nothing can verify a caller's claim about
# which pathogen the data is. Requiring the numbers is the only check that is
# actually checked.
r <- cli("fit", "--data", "clean_cases.csv")
check("refuses a fit with no distributions", r$status != 0L)
check("names the missing generation time", has(r, "generation time"))
check("names the missing delay", has(r, "delay"))
check("names the routes to real parameters",
      has(r, "lookup-delay") && has(r, "estimate-delay"))
check("writes no fit when refused", !file.exists("outputs/fit/fit.rds"))

# Half-specified is still refused: a supplied generation time does not license
# defaulting the delay.
r <- cli("fit", "--data", "clean_cases.csv",
         "--gt-mean", "3.6", "--gt-sd", "3.1", "--gt-max", "14")
check("refuses a fit with only the generation time", r$status != 0L)
check("names the delay as the missing piece", has(r, "delay-mean"))

# No pathogen name can unlock the defaults, because there are none.
r <- cli("fit", "--data", "clean_cases.csv", "--disease", "COVID-19")
check("a disease name does not substitute for parameters", r$status != 0L)

# --- Sampler tests ----------------------------------------------------------
# Excluded unless --fits: each of these fits a model and takes minutes.

if (!run_fits) {
  cat("\nSampler tests skipped (pass --fits to run them).\n")
} else {
  cat("\nSampler tests\n")

  ec <- EpiNow2::example_confirmed[seq_len(60), c("date", "confirm")]
  write.csv(ec, "ec.csv", row.names = FALSE)

  # COVID-19 serial interval from epiparameter, used as a generation time, plus
  # a plausible reporting delay: the substitution is the caveat under test.
  r <- cli("fit", "--data", "ec.csv",
           "--gt-mean", "4.7", "--gt-sd", "2.9", "--gt-max", "14",
           "--delay-mean", "4", "--delay-sd", "2", "--delay-max", "14",
           "--gt-substituted", "--rw", "7", "--cores", "4",
           "--output-dir", "out_ok")
  check("a fully specified fit completes", r$status == 0L)
  check("records caveats next to the fit", file.exists("out_ok/caveats.rds"))
  cav <- readRDS("out_ok/caveats.rds")
  check("records the substitution caveat",
        length(cav$caveats) == 1L && grepl("serial interval", cav$caveats[1]),
        paste("got", length(cav$caveats)))

  # --- Regions ---------------------------------------------------------------
  # One fit over two regions, then the same fit with one region broken, so the
  # per-region gate is exercised without waiting for a pathological sampler run.

  set.seed(12)
  ec2 <- rbind(
    data.frame(date = ec$date, confirm = ec$confirm, region = "east"),
    data.frame(date = ec$date, confirm = ec$confirm, region = "west")
  )
  write.csv(ec2, "ec_regions.csv", row.names = FALSE)

  r <- cli("fit", "--data", "ec_regions.csv",
           "--gt-mean", "4.7", "--gt-sd", "2.9", "--gt-max", "14",
           "--delay-mean", "4", "--delay-sd", "2", "--delay-max", "14",
           "--gt-substituted", "--rw", "7", "--cores", "4",
           "--output-dir", "out_reg")
  check("a regional fit completes", r$status == 0L, r$text)
  check("the fit says the regions were fitted separately",
        has(r, "fitted separately"))

  if (file.exists("out_reg/fit.rds")) {
    r <- cli("evaluate", "--fit", "out_reg/fit.rds", "--report-out", "rep/reg.md")
    check("a regional report has one row per region",
          has(r, "\\| east \\|") && has(r, "\\| west \\|"))
    check("a regional report gives per-region diagnostics", has(r, "Max Rhat"))
    # Whether these particular regions converge is a property of the fixture,
    # not of the script. What the script must guarantee is that the exit status
    # agrees with the table: clean only when every region passed.
    any_withheld <- has(r, "\\| (FAIL|ERROR) \\|") || has(r, "withheld")
    check("the exit status agrees with the per-region verdicts",
          (any_withheld && r$status != 0L) || (!any_withheld && r$status == 0L),
          sprintf("withheld=%s status=%d", any_withheld, r$status))
    check("the substitution caveat covers every region",
          has(r, "serial interval"))

    # Break one region and re-evaluate: a region that did not fit must not be
    # quietly dropped from the table, and must not leave the exit status clean.
    broken <- readRDS("out_reg/fit.rds")
    broken$regional[[2]]$fit <- NULL
    dir.create("out_broken", showWarnings = FALSE)
    saveRDS(broken, "out_broken/fit.rds")
    if (file.exists("out_reg/caveats.rds")) {
      file.copy("out_reg/caveats.rds", "out_broken/caveats.rds", overwrite = TRUE)
    }
    r <- cli("evaluate", "--fit", "out_broken/fit.rds", "--report-out", "rep/broken.md")
    check("a failed region is still listed", has(r, "ERROR|FAIL"))
    check("a failed region has its estimates withheld", has(r, "withheld"))
    check("one failed region makes the whole run exit non-zero", r$status != 0L)
    check("the passing region is still reported", has(r, "\\| east \\| PASS"))
    check("the report names why the region has no estimate",
          has(r, "did not fit|diagnostics unavailable|Rhat|effective sample size"))
  }


  r <- cli("evaluate", "--fit", "out_ok/fit.rds", "--report-out", "rep/ok.md")
  check("a converged fit evaluates cleanly", r$status == 0L)
  check("reports PASS", has(r, "Convergence: PASS"))
  check("writes the report file", file.exists("rep/ok.md"))
  report <- paste(readLines("rep/ok.md"), collapse = "\n")
  # The caveat has to sit in the Rt row: the number is what gets copied out,
  # and a qualification in a later section does not travel with it.
  rt_line <- grep("^\\| Rt \\|", strsplit(report, "\n")[[1]], value = TRUE)
  check("the Rt row carries a caveat marker",
        length(rt_line) == 1L && grepl("caveat", rt_line, ignore.case = TRUE),
        rt_line)
  check("a Caveats section spells them out", grepl("## Caveats", report))
  check("P(Rt > 1) is reported as a probability", grepl("P\\(Rt > 1\\)", report))

  # Absent provenance and no caveats are different claims, and only one of
  # them licenses reporting the number unqualified.
  dir.create("out_nocav", showWarnings = FALSE)
  file.copy("out_ok/fit.rds", "out_nocav/fit.rds", overwrite = TRUE)
  r <- cli("evaluate", "--fit", "out_nocav/fit.rds", "--report-out", "rep/nocav.md")
  check("a fit with no recorded provenance says so", has(r, "not recorded"))

  r <- cli("evaluate", "--fit", "out_ok/fit.rds", "--date", "1999-01-01")
  check("a date outside the fitted period errors", r$status != 0L)
  check("names the available range", has(r, "estimated period"))

  # An error partway through must leave no file: an empty report on disk looks
  # like a report.
  r <- cli("evaluate", "--fit", "out_ok/fit.rds", "--date", "1999-01-01",
           "--report-out", "rep/err.md")
  check("a failed run writes no report file", !file.exists("rep/err.md"))
  check("a failed run leaves no partial file", !file.exists("rep/err.md.part"))

  # A deliberately unconverged fit: the gate must withhold estimates, and the
  # report must still exist to record the non-answer.
  r <- cli("fit", "--data", "ec.csv",
           "--gt-mean", "4.7", "--gt-sd", "2.9", "--gt-max", "14",
           "--delay-mean", "4", "--delay-sd", "2", "--delay-max", "14",
           "--gp-ls", "7", "--cores", "2", "--output-dir", "out_bad")
  if (file.exists("out_bad/fit.rds")) {
    r <- cli("evaluate", "--fit", "out_bad/fit.rds", "--report-out", "rep/bad.md")
    if (has(r, "Convergence: FAIL")) {
      check("a failed gate exits non-zero", r$status != 0L)
      check("a failed gate withholds the estimates", !has(r, "\\| Rt \\|"))
      check("a failed gate still writes its report", file.exists("rep/bad.md"))
      bad <- paste(readLines("rep/bad.md"), collapse = "\n")
      check("the withheld report records the non-answer",
            grepl("Estimates withheld", bad))
      check("the withheld report names the breached thresholds",
            grepl("Rhat|effective sample size|[Dd]ivergent", bad))
    } else {
      cat("  note this fit converged; convergence-failure assertions skipped\n")
    }
  }
}


# --- init: the specification is built, not asked for -------------------------
#
# The point of these is the provenance. A field the script worked out must not
# come back as a question, and a field it could not work out must not come back
# as a value.

cat("\ninit\n")

if (!requireNamespace("yaml", quietly = TRUE)) {
  cat("  note yaml not installed; init and config tests skipped\n")
} else {

# An aggregate series whose date column is called `date` and nothing else. The
# file carries no evidence of what the date means.
set.seed(7)
bare_dates <- seq(as.Date("2024-01-01"), by = "day", length.out = 120)
write.csv(data.frame(date = bare_dates, count = rpois(120, 40)),
          "bare_agg.csv", row.names = FALSE)

r <- cli("init", "--data", "bare_agg.csv", "--out", "bare.yaml",
         "--cases-out", "bare_cases.csv")
check("init writes a config", file.exists("bare.yaml"))
cfg <- yaml::read_yaml("bare.yaml")

check("every field records a source",
      all(vapply(cfg, function(f) !is.null(f$source), logical(1))),
      paste("missing on:", paste(names(cfg)[!vapply(cfg, function(f) !is.null(f$source), logical(1))], collapse = ", ")))
check("every source is one of the four states",
      all(vapply(cfg, function(f) f$source %in% c("derived", "inferred", "user", "missing"), logical(1))))
check("date type is never derived from an aggregate series",
      cfg$date_type$source %in% c("inferred", "missing"),
      paste("got:", cfg$date_type$source))
check("date type carries its evidence",
      !is.null(cfg$date_type$evidence) && nzchar(cfg$date_type$evidence))
check("generation time is missing, not guessed",
      cfg$generation_time$source == "missing" && is.null(cfg$generation_time$value))
check("delay is missing, not guessed",
      cfg$delay$source == "missing" && is.null(cfg$delay$value))
check("init says which fields will block a fit",
      has(r, "fit will refuse until these are set"))
check("init names the fields to review", has(r, "Check these before fitting"))
check("a single-series file yields no regions",
      length(cfg$regions$value) == 0)
check("week effect follows the date type, not the data",
      !is.null(cfg$week_effect$evidence) && grepl("date_type", cfg$week_effect$evidence))

# A linelist with three date columns at different completeness. Completeness is
# the deciding fact and has to be visible.
set.seed(8)
m <- 400
on <- as.Date("2024-03-01") + sample(0:90, m, replace = TRUE)
ll3 <- data.frame(
  id = seq_len(m),
  onset_date = as.character(on),
  specimen_date = as.character(on + rpois(m, 2)),
  report_date = as.character(on + rpois(m, 4))
)
ll3$onset_date[sample(m, round(0.39 * m))] <- NA
write.csv(ll3, "linelist3.csv", row.names = FALSE)

r <- cli("init", "--data", "linelist3.csv", "--out", "ll3.yaml",
         "--cases-out", "ll3_cases.csv")
check("init lists every candidate date column",
      has(r, "onset_date") && has(r, "specimen_date") && has(r, "report_date"))
check("init reports completeness per date column", has(r, "61.0%|61%"))
ll3cfg <- yaml::read_yaml("ll3.yaml")
check("init picks the most complete date column",
      ll3cfg$date_column$value %in% c("report_date", "specimen_date"),
      paste("got:", ll3cfg$date_column$value))
check("the date column choice is inferred, not derived",
      ll3cfg$date_column$source == "inferred")

r <- cli("init", "--data", "linelist3.csv", "--out", "ll3b.yaml",
         "--cases-out", "ll3b_cases.csv", "--date-column", "onset_date")
check("an explicit date column is recorded as the user's",
      yaml::read_yaml("ll3b.yaml")$date_column$source == "user")
check("excluded rows are reported when a sparse column is chosen",
      has(r, "will be excluded"))

# Regions.
set.seed(9)
rd <- seq(as.Date("2024-01-01"), by = "day", length.out = 60)
regional <- rbind(
  data.frame(date = rd, confirm = rpois(60, 40), region = "north"),
  data.frame(date = rd, confirm = rpois(60, 30), region = "south"),
  data.frame(date = rd[1:10], confirm = rep(1L, 10), region = "tiny")
)
write.csv(regional, "regional.csv", row.names = FALSE)
r <- cli("init", "--data", "regional.csv", "--out", "reg.yaml",
         "--cases-out", "reg_cases.csv")
regcfg <- yaml::read_yaml("reg.yaml")
check("init detects every region",
      setequal(unlist(regcfg$regions$value), c("north", "south", "tiny")))
check("by_region is set when there is more than one region",
      isTRUE(regcfg$by_region$value))
check("a sparse region is named before it reaches the sampler",
      has(r, "tiny") && has(r, "under 21 days|under 50 total"))

# A linelist that also carries regions. Counting and splitting have to happen
# together: tabulating dates first and attaching regions afterwards mismatches
# the row counts, which is a real bug this asserts against.
set.seed(10)
k <- 300
lon <- as.Date("2024-01-01") + sample(0:60, k, replace = TRUE)
write.csv(data.frame(id = seq_len(k),
                     onset_date = as.character(lon),
                     report_date = as.character(lon + rpois(k, 3)),
                     region = sample(c("a", "b"), k, replace = TRUE)),
          "ll_region.csv", row.names = FALSE)
r <- cli("init", "--data", "ll_region.csv", "--out", "llr.yaml",
         "--cases-out", "llr_cases.csv")
check("a linelist with regions is counted per region", r$status == 0L, r$text)
llr <- read.csv("llr_cases.csv")
check("the per-region series has date, confirm and region",
      all(c("date", "confirm", "region") %in% names(llr)))
check("both regions survive aggregation",
      setequal(unique(llr$region), c("a", "b")))
check("counts are split by region, not duplicated",
      sum(llr$confirm) == k, paste("got", sum(llr$confirm), "of", k))

# Gaps are reported rather than filled: a date with no row may be a genuine
# zero or an unreported day, and only the user knows which.
gap_dates <- seq(as.Date("2024-01-01"), by = "day", length.out = 40)[-c(5, 6, 20)]
write.csv(data.frame(date = gap_dates, confirm = rpois(37, 20)),
          "gappy.csv", row.names = FALSE)
r <- cli("init", "--data", "gappy.csv", "--out", "gappy.yaml",
         "--cases-out", "gappy_cases.csv")
check("init reports calendar gaps without filling them",
      has(r, "no row") && has(r, "fill-zeros"))

# --- Config consumption ------------------------------------------------------

cat("\nfit --config\n")

r <- cli("fit", "--config", "bare.yaml", "--dry-run")
check("fit refuses a config with missing required fields", r$status != 0L)
check("the refusal names the missing fields",
      has(r, "generation_time") && has(r, "delay"))
check("the refusal does not fit anything", !has(r, "Fitting renewal model"))

# A complete config, written by hand in the same shape init writes.
complete <- list(
  data = list(value = "clean_cases.csv", source = "derived", evidence = "test fixture"),
  date_column = list(value = "date", source = "derived", evidence = "only date column"),
  date_type = list(value = "report", source = "user", evidence = "set by the test"),
  regions = list(value = list(), source = "derived", evidence = "none"),
  by_region = list(value = FALSE, source = "derived", evidence = "0 regions"),
  generation_time = list(
    value = list(dist = "gamma", mean = 3.6, sd = 1.6, max = 14, substituted = TRUE),
    source = "inferred", evidence = "epiparameter, substituted"),
  delay = list(
    value = list(dist = "lognormal", mean = 4.4, sd = 2.1, max = 20, substituted = FALSE),
    source = "inferred", evidence = "epiparameter"),
  truncation = list(value = NULL, source = "missing", evidence = "no vintages"),
  dynamics = list(value = list(type = "rw", step = 7), source = "inferred", evidence = "short series"),
  rt_prior = list(value = list(mean = 2.0, sd = 1.0), source = "derived", evidence = "default"),
  stan = list(value = list(seed = 1234, cores = 2), source = "derived", evidence = "default")
)
yaml::write_yaml(complete, "complete.yaml")

r <- cli("fit", "--config", "complete.yaml", "--dry-run")
check("a complete config resolves without any flags", r$status == 0L, r$text)
check("config values reach the model", has(r, "3.60") && has(r, "4.40"))
check("config dynamics reach the model", has(r, "random walk"))
check("a substituted generation time in the config becomes a caveat",
      has(r, "serial interval"))
check("the week effect is derived from the date type, not stored",
      has(r, "Week effect: +estimated"))

# Precedence: an explicit flag beats the file.
r <- cli("fit", "--config", "complete.yaml", "--dry-run", "--gt-mean", "9.9", "--gt-sd", "2.2")
check("an explicit flag overrides the config", has(r, "9.90"))

r <- cli("fit", "--config", "complete.yaml", "--dry-run", "--rw", "0", "--gp-ls", "21")
check("an explicit dynamics flag overrides the config",
      has(r, "Gaussian process"), r$text)

# Correcting the date type flips the week effect on the next read, rather than
# leaving the value chosen for the type the user rejected.
onset_cfg <- complete
onset_cfg$date_type$value <- "onset"
yaml::write_yaml(onset_cfg, "onset.yaml")
r <- cli("fit", "--config", "onset.yaml", "--dry-run")
check("correcting the date type to onset removes the week effect",
      has(r, "Week effect: +not estimated"), r$text)

# --- estimate-truncation -----------------------------------------------------

cat("\nestimate-truncation\n")

r <- cli("estimate-truncation")
check("estimate-truncation requires vintages", r$status != 0L && has(r, "vintages"))

dir.create("vint_one", showWarnings = FALSE)
write.csv(clean, "vint_one/v1.csv", row.names = FALSE)
r <- cli("estimate-truncation", "--vintages", "vint_one")
check("one vintage is refused with the reason", r$status != 0L && has(r, "at least 2"))

}

# --- Summary ----------------------------------------------------------------

cat(sprintf("\n%d passed, %d failed\n", pass, fail))
if (fail > 0L) {
  cat("\nFailed:\n")
  for (f in failures) cat(sprintf("  %s\n", f))
  quit(status = 1)
}
