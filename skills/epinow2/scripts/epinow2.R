#!/usr/bin/env Rscript

# EpiNow2 CLI: Rt estimation, nowcasting and short-term forecasting from
# surveillance counts.
#
# Design rules:
# - Every number printed is computed from the data or the fit. Where a value
#   cannot be computed, the script says so or stops, rather than printing a
#   plausible default.
# - Convergence gates reporting. A fit that breaches a threshold has its
#   estimates withheld and exits non-zero. The same gate applies to the delay
#   and truncation fits whose output feeds the main model.
#
# This file holds the command line and the config. lib/prepare.R builds the
# specification (init, lookup-delay, estimate-delay, estimate-truncation);
# lib/model.R fits and evaluates. Background: see references/.

self <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
for (f in c("prepare.R", "model.R")) source(file.path(dirname(self), "lib", f))

# --- Arguments --------------------------------------------------------------

parse_args <- function(args) {
  params <- list()
  i <- 1
  while (i <= length(args)) {
    arg <- args[i]
    if (startsWith(arg, "--")) {
      key <- substring(arg, 3)
      if (i + 1 <= length(args) && !startsWith(args[i + 1], "--")) {
        params[[key]] <- args[i + 1]
        i <- i + 2
      } else {
        params[[key]] <- TRUE
        i <- i + 1
      }
    } else {
      if (!("subcommand" %in% names(params))) params[["subcommand"]] <- arg
      i <- i + 1
    }
  }
  params
}

# An unrecognised flag is an error: a mistyped --gt-maen would otherwise drop
# out and leave the fit on a value nobody chose.
STAN_FLAGS <- c("seed", "cores", "warmup", "samples")
dist_flags <- function(prefix) paste0(prefix, "-", c("dist", "max", DIST_PARAMS))
KNOWN_FLAGS <- list(
  init = c("data", "out", "cases-out", "delays-out", "disease", "date-column", "date-type",
           "strata", "week-start", "fill-zeros", "intervention-dates", "horizon"),
  `lookup-delay` = c("disease", "param"),
  `estimate-delay` = c("delays", "dist", "config", "field", STAN_FLAGS),
  `estimate-truncation` = c("vintages", "config", STAN_FLAGS),
  fit = c("config", "data", "date-type", "pool", dist_flags("gt"), "gt-substituted",
          dist_flags("incubation"), dist_flags("event-delay"), "no-event-delay", "week-effect",
          "r-prior-mean", "r-prior-sd", "rw", "gp-ls", "horizon", "forecast-rt",
          "output-dir", "dry-run", STAN_FLAGS),
  evaluate = c("fit", "date", "report-out")
)

check_flags <- function(params, subcmd) {
  unknown <- setdiff(setdiff(names(params), "subcommand"), KNOWN_FLAGS[[subcmd]])
  if (length(unknown) > 0) {
    stop("Unknown option(s) for ", subcmd, ": ", paste0("--", unknown, collapse = ", "),
         ". Run the script with no arguments for the flag list.")
  }
}

# A bare switch parses as TRUE; `--pool false` means what it says.
flag_true <- function(params, key) {
  x <- params[[key]]
  !is.null(x) && !tolower(as.character(x)) %in% c("false", "no", "0")
}

int_flag <- function(params, key, default) {
  if (is.null(params[[key]])) return(as.integer(default))
  v <- suppressWarnings(as.integer(params[[key]]))
  if (is.na(v) || v < 0) stop("--", key, " must be a whole number, 0 or more.")
  v
}

# The date type is the event that dates each count: onset, or any later event
# (report, specimen, admission, death). Only onset versus later matters to the
# model: a later event adds the delay from onset to it.
check_date_type <- function(x) {
  x <- tolower(trimws(as.character(x)))
  if (!grepl("^[a-z_ ]+$", x)) stop("--date-type must name the dated event, e.g. onset, report, death; got '", x, "'.")
  x
}

# --- Configuration ----------------------------------------------------------
#
# Every field records where its value came from:
#   derived   computed from the data, or from another field already settled
#   inferred  read off evidence or a package default that could be wrong for
#             this analysis; the evidence travels with it
#   user      supplied or confirmed by the user
#   missing   not obtainable here; fit refuses while a required field is missing
# The user is asked about `inferred` and `missing` fields only.

CONFIG_SOURCES <- c("derived", "inferred", "user", "missing")
CONFIG_REQUIRED <- c("data", "date_type", "generation_time", "incubation", "event_delay")

cfg_field <- function(value, source, evidence = NULL) {
  list(value = value, source = source, evidence = evidence)
}

cfg_value <- function(cfg, name) {
  f <- cfg[[name]]
  if (is.null(f) || identical(f$source, "missing")) NULL else f$value
}

# Fields that follow from the date type are recomputed on every read, so
# correcting the date type cannot leave a week effect or a delay chosen for
# the type the user rejected.
derive_dependent <- function(cfg) {
  dt <- cfg_value(cfg, "date_type")
  ed <- cfg$event_delay
  cfg$week_effect <- if (startsWith(c(cfg_value(cfg, "timestep"), "")[1], "week")) {
    cfg_field(FALSE, "derived", "weekly counts carry no day-of-week pattern")
  } else if (is.null(dt)) {
    cfg_field(NULL, "missing", "follows date_type, which is not set")
  } else if (dt == "onset") {
    cfg_field(FALSE, "derived", "onset dates do not follow a working week")
  } else {
    cfg_field(TRUE, "derived", sprintf("%s dates can follow a working week", dt))
  }
  if (is.null(dt)) {
    if (is.null(ed) || identical(ed$source, "derived")) {
      cfg$event_delay <- cfg_field(NULL, "missing", "follows date_type, which is not set")
    }
  } else if (dt == "onset" && (is.null(ed) || ed$source %in% c("derived", "missing"))) {
    cfg$event_delay <- cfg_field("none", "derived", "onset dates: the incubation period is the whole delay")
  } else if (dt != "onset" && (is.null(ed) || (identical(ed$source, "derived") && identical(ed$value, "none")))) {
    cfg$event_delay <- cfg_field(NULL, "missing", sprintf(
      "the delay from onset to %s is needed on top of the incubation period", dt))
  }
  cfg
}

read_config <- function(path) {
  if (!file.exists(path)) stop("Config file not found: ", path)
  cfg <- yaml::read_yaml(path)
  for (nm in names(cfg)) {
    if (!is.list(cfg[[nm]]) || !isTRUE(cfg[[nm]]$source %in% CONFIG_SOURCES)) {
      stop("Config field '", nm, "' needs a 'source', one of ", paste(CONFIG_SOURCES, collapse = ", "), ".")
    }
  }
  derive_dependent(cfg)
}

write_config <- function(cfg, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  yaml::write_yaml(cfg, path)
}

config_gaps <- function(cfg) {
  CONFIG_REQUIRED[vapply(CONFIG_REQUIRED, function(nm) is.null(cfg_value(cfg, nm)), logical(1))]
}

format_config_value <- function(v) {
  if (is.null(v) || length(v) == 0) return("-")
  if (!is.list(v)) return(paste(as.character(v), collapse = ", "))
  nm <- names(v)
  paste(vapply(seq_along(v), function(i) {
    s <- if (is.list(v[[i]])) paste0("{", format_config_value(v[[i]]), "}") else paste(v[[i]], collapse = "/")
    if (is.null(nm) || !nzchar(nm[i])) s else paste0(nm[i], "=", s)
  }, character(1)), collapse = ", ")
}

# --- Dispatcher -------------------------------------------------------------

HELP <- "EpiNow2 CLI: Rt, nowcasts and short-term forecasts from surveillance counts

  init                 Inspect data and write a config recording where every value came from.
    --data <path>        Linelist, or daily or weekly counts. Required.
    --disease <str>      Look up the generation time and incubation period in epiparameter.
    --date-column <col>  Use this column instead of the most complete.
    --date-type <event>  onset, or the later event that dates each count (report, death, ...).
    --strata <col|none>  Fit each value of this column separately; none fits one series.
    --week-start         Weekly dates mark the start of each week, not the end.
    --fill-zeros         Dates with no row are zeros.
    --horizon <days>     Forecast horizon, up to 14.
    --intervention-dates <str>  Known step changes; selects a random walk.
    --out <path> (nowcast.yaml)  --cases-out <path>  --delays-out <path>

  lookup-delay         Published distribution from epiparameter, printed as fit flags.
    --disease <str> --param <str>   Both required. 'generation time' falls back to the
                                    serial interval, flagged as a substitution.

  estimate-delay       Fit the onset-to-event delay to event pairs from init.
    --delays <csv>       Columns pdate_lwr and sdate_lwr.
    --config <path>      Write it in: as event_delay, or as truncation for onset dates.
    --field <name>       Override where it is written.
    --dist <lognormal|gamma>  Default: the lower AIC on the pairs.
    --seed --cores --warmup --samples

  estimate-truncation  Estimate right truncation from two or more daily snapshots.
    --vintages <dir>  --config <path>  --seed --cores --warmup --samples

  fit                  Fit the renewal model. Flags override the config.
    --config <path>      The series is built from the config's data file with its choices.
    --data <path>        With --config, new data in the same layout. Without, a date,
                         confirm (and region) file, as init writes.
    --date-type <event>
    --gt-*, --incubation-*, --event-delay-*
                         Distributions: -dist (lognormal, gamma, weibull, exp or
                         nonparametric), -max, and the family's parameters: -mean -sd,
                         or -meanlog -sdlog, -shape -scale, -shape -rate, -rate, or
                         -pmf 0,0.2,0.5,0.3. Weibull and exp need fixed parameters.
    --gt-substituted     The generation time is a serial interval; becomes a caveat.
    --no-event-delay     Model no delay from onset to a later event; becomes a caveat.
    --week-effect <true|false>   Override the week effect the date type implies.
    --r-prior-mean/-sd   Lognormal prior on initial Rt. Default: EpiNow2's.
    --rw <days> | --gp-ls <days>  Random walk step, or GP length scale (>= 7).
    --horizon <days>     Forecast, up to 14; a multiple of 7 for weekly data.
    --forecast-rt <latest|project>  Rt over the forecast: held at its last estimate
                         (default), or varying as the fitted Rt model allows.
    --pool               Sum strata before fitting; becomes a caveat.
    --dry-run  --output-dir <dir>  --seed --cores --warmup --samples

  evaluate             Check convergence, then report estimates and any forecast.
    --fit <fit.rds>  --date YYYY-MM-DD  --report-out <path>
    Exits non-zero and withholds every estimate if convergence fails. A failed run
    still writes its report. estimate-delay and estimate-truncation apply the same
    gate and write nothing on a failure.
"

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cat(HELP)
  quit(status = 0)
}
params <- parse_args(args)
subcmd <- params[["subcommand"]]
if (is.null(subcmd) || !subcmd %in% names(KNOWN_FLAGS)) {
  cat("Unknown subcommand:", if (is.null(subcmd)) "(none)" else subcmd, "\nRun with no arguments for help.\n")
  quit(status = 1)
}
check_flags(params, subcmd)
result <- switch(subcmd,
  init = cmd_init(params),
  `lookup-delay` = cmd_lookup_delay(params),
  `estimate-delay` = cmd_estimate_delay(params),
  `estimate-truncation` = cmd_estimate_truncation(params),
  fit = cmd_fit(params),
  evaluate = cmd_evaluate(params)
)
if (is.list(result) && isFALSE(result$pass)) quit(status = 1)
