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
check("lists all five subcommands",
      all(vapply(c("triage", "lookup-delay", "estimate-delay", "fit", "evaluate"),
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

# --- Summary ----------------------------------------------------------------

cat(sprintf("\n%d passed, %d failed\n", pass, fail))
if (fail > 0L) {
  cat("\nFailed:\n")
  for (f in failures) cat(sprintf("  %s\n", f))
  quit(status = 1)
}
