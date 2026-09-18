#!/usr/bin/env Rscript

# EpiNow2 routine surveillance nowcast and Rt estimation CLI
#
# Design rule: every number this script prints is computed from the data or
# the fit it is given. Nothing about convergence, probability or model
# specification is asserted from a fixed string. Where a value cannot be
# computed, the script says so or stops, rather than printing a plausible
# default.
#
# Convergence is treated as a gate on reporting, not as a footnote: a fit
# that breaches a threshold has its estimates withheld and exits non-zero.
#
# Background: see references/.

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
      if (!("subcommand" %in% names(params))) {
        params[["subcommand"]] <- arg
      }
      i <- i + 1
    }
  }
  return(params)
}

# --- Data inspection ------------------------------------------------------
#
# What a date column is called is evidence about what it means. What the counts
# do across the week is different evidence. Neither is proof: a column called
# `date` in an aggregate series says nothing at all, and a linelist often
# carries onset, specimen and report dates with different completeness. So both
# kinds of evidence are reported, the inference they support is labelled as an
# inference, and the user settles it.

DATE_TYPE_PATTERNS <- list(
  onset     = "onset|symptom|rash",
  specimen  = "specimen|sample|swab|test",
  report    = "report|notif|confirm",
  admission = "admission|admit|hosp"
)

# Returns the date type a column name suggests, or NA when the name carries no
# signal. "date" and "count" are names, not claims.
classify_date_name <- function(nm) {
  low <- tolower(nm)
  for (type in names(DATE_TYPE_PATTERNS)) {
    if (grepl(DATE_TYPE_PATTERNS[[type]], low)) return(type)
  }
  NA_character_
}

# A column counts as a date column if a majority of its non-blank values parse
# as dates. Suppressing the warning is deliberate: failure to parse is the
# test, not an error.
parse_date_column <- function(x) {
  if (inherits(x, "Date")) return(x)
  # A numeric column is not treated as a date even though as.Date() can be made
  # to accept one: a count column of small integers would otherwise be read as
  # days since an origin nobody specified.
  if (is.numeric(x)) return(NULL)
  chr <- as.character(x)
  chr[trimws(chr) == ""] <- NA
  if (all(is.na(chr))) return(NULL)
  # as.Date() errors rather than returning NA on an unparseable string, so a
  # failure to parse has to be caught to be used as the test.
  parsed <- tryCatch(suppressWarnings(as.Date(chr)), error = function(e) NULL)
  if (is.null(parsed)) return(NULL)
  n_target <- sum(!is.na(chr))
  if (n_target == 0 || sum(!is.na(parsed)) < 0.5 * n_target) return(NULL)
  parsed
}

# Every candidate date column, with how complete it is. Completeness is the
# fact that decides which column can be fitted on, so it is always shown.
date_candidates <- function(df) {
  out <- list()
  for (nm in names(df)) {
    parsed <- parse_date_column(df[[nm]])
    if (is.null(parsed)) next
    n_ok <- sum(!is.na(parsed))
    out[[length(out) + 1]] <- data.frame(
      column = nm,
      type_guess = classify_date_name(nm),
      n_present = n_ok,
      pct_complete = 100 * n_ok / nrow(df),
      min_date = if (n_ok > 0) min(parsed, na.rm = TRUE) else as.Date(NA),
      max_date = if (n_ok > 0) max(parsed, na.rm = TRUE) else as.Date(NA),
      stringsAsFactors = FALSE
    )
  }
  if (length(out) == 0) {
    return(data.frame(column = character(0), type_guess = character(0),
                      n_present = integer(0), pct_complete = numeric(0),
                      min_date = as.Date(character(0)), max_date = as.Date(character(0)),
                      stringsAsFactors = FALSE))
  }
  res <- do.call(rbind, out)
  res[order(-res$pct_complete), , drop = FALSE]
}

# Day-of-week structure in a daily count series. An administrative reporting
# process leaves a weekly cycle; symptom onset does not. This is suggestive
# only, and the amplitude is reported so the strength of the suggestion is
# visible rather than asserted.
week_cycle_evidence <- function(dates, counts) {
  ord <- order(dates)
  dates <- dates[ord]
  counts <- as.numeric(counts[ord])
  n <- length(counts)
  if (n < 28) {
    return(list(n_days = n, amplitude = NA_real_, verdict = "inconclusive",
                reason = sprintf("series is %d days; at least 28 needed", n)))
  }
  roll <- as.numeric(stats::filter(counts, rep(1 / 7, 7), sides = 2))
  ok <- !is.na(roll) & roll > 0
  if (sum(ok) < 21) {
    return(list(n_days = n, amplitude = NA_real_, verdict = "inconclusive",
                reason = "too many zero or missing counts to compare weekdays"))
  }
  ratio <- counts[ok] / roll[ok]
  dow <- weekdays(dates[ok])
  by_day <- tapply(ratio, dow, mean)
  if (length(by_day) < 7) {
    return(list(n_days = n, amplitude = NA_real_, verdict = "inconclusive",
                reason = "not all weekdays observed"))
  }
  amp <- as.numeric(max(by_day) - min(by_day))
  verdict <- if (amp >= 0.25) "cycle" else if (amp <= 0.10) "no cycle" else "inconclusive"
  list(
    n_days = n, amplitude = amp, verdict = verdict,
    trough = names(by_day)[which.min(by_day)],
    peak = names(by_day)[which.max(by_day)],
    reason = sprintf("weekday amplitude %.2f over %d days (lowest %s, highest %s)",
                     amp, n, names(by_day)[which.min(by_day)], names(by_day)[which.max(by_day)])
  )
}

detect_region_column <- function(df) {
  hit <- names(df)[tolower(names(df)) %in% c("region", "area", "location", "geography", "la", "nhs_region")]
  if (length(hit) == 0) return(NULL)
  hit[1]
}

COUNT_NAMES <- c("confirm", "cases", "count", "counts", "new_cases", "confirmed", "n")

# One pass over the data that every other subcommand reads from, so that
# triage, init and fit agree about what the file contains.
inspect_data <- function(df) {
  cands <- date_candidates(df)
  count_hit <- names(df)[tolower(names(df)) %in% COUNT_NAMES]
  region_col <- detect_region_column(df)
  shape <- if (length(count_hit) > 0 && nrow(cands) > 0) "aggregate" else if (nrow(cands) > 0) "linelist" else "unknown"
  regions <- if (!is.null(region_col)) sort(unique(as.character(df[[region_col]]))) else character(0)
  list(
    shape = shape,
    n_rows = nrow(df),
    dates = cands,
    count_column = if (length(count_hit) > 0) count_hit[1] else NULL,
    region_column = region_col,
    regions = regions
  )
}

# --- Configuration --------------------------------------------------------
#
# Every field carries where its value came from. The four states are the whole
# point of the file: they say what the user has to look at.
#
#   derived   computed from the data, or from another field already settled
#   inferred  read off evidence that could be wrong; the evidence travels with it
#   user      supplied or confirmed by the user
#   missing   not obtainable here; `fit` refuses while a required field is missing
#
# The review surface is therefore `inferred` and `missing`. A `derived` field is
# shown but not put to the user as a question.

CONFIG_SOURCES <- c("derived", "inferred", "user", "missing")

cfg_field <- function(value, source, evidence = NULL) {
  if (!source %in% CONFIG_SOURCES) {
    stop("Unknown provenance '", source, "'; must be one of ",
         paste(CONFIG_SOURCES, collapse = ", "), ".")
  }
  list(value = value, source = source, evidence = evidence)
}

cfg_value <- function(cfg, name) {
  f <- cfg[[name]]
  if (is.null(f)) return(NULL)
  if (identical(f$source, "missing")) return(NULL)
  f$value
}

cfg_source <- function(cfg, name) {
  f <- cfg[[name]]
  if (is.null(f)) return("missing")
  f$source
}

# A week effect is a property of the reporting process, so it follows the date
# type. It is recomputed from the date type on every read rather than stored
# independently: a user who corrects the date type after `init` would otherwise
# keep a week effect chosen for the type they just rejected.
derive_week_effect <- function(cfg) {
  dt <- cfg_value(cfg, "date_type")
  if (is.null(dt)) {
    cfg$week_effect <- cfg_field(NULL, "missing", "follows date_type, which is not set")
    return(cfg)
  }
  on_admin_date <- dt %in% c("report", "specimen", "admission")
  cfg$week_effect <- cfg_field(
    on_admin_date, "derived",
    sprintf("date_type is '%s', %s an administrative reporting process", dt,
            if (on_admin_date) "which is" else "which is not")
  )
  cfg
}

CONFIG_REQUIRED <- c("data", "date_type", "generation_time", "delay")

read_config <- function(path) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required to read a config file.")
  }
  if (!file.exists(path)) stop("Config file not found: ", path)
  cfg <- yaml::read_yaml(path)
  for (nm in names(cfg)) {
    f <- cfg[[nm]]
    if (!is.list(f) || is.null(f$source)) {
      stop("Config field '", nm, "' has no 'source'. Every field must record ",
           "where its value came from (", paste(CONFIG_SOURCES, collapse = ", "), ").")
    }
    if (!f$source %in% CONFIG_SOURCES) {
      stop("Config field '", nm, "' has unknown source '", f$source, "'.")
    }
  }
  derive_week_effect(cfg)
}

write_config <- function(cfg, path) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required to write a config file.")
  }
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  yaml::write_yaml(cfg, path)
  invisible(path)
}

# Which required fields are still unset. `fit` uses this to refuse, `init` to
# tell the user what it could not work out for them.
config_gaps <- function(cfg) {
  gaps <- character(0)
  for (nm in CONFIG_REQUIRED) {
    if (is.null(cfg_value(cfg, nm))) gaps <- c(gaps, nm)
  }
  gaps
}

# Fields the user is expected to look at: anything inferred from fallible
# evidence, plus anything still missing.
config_review_items <- function(cfg) {
  names(cfg)[vapply(names(cfg), function(nm) cfg_source(cfg, nm) %in% c("inferred", "missing"), logical(1))]
}

format_config_value <- function(v) {
  if (is.null(v)) return("-")
  if (is.list(v)) {
    return(paste(sprintf("%s=%s", names(v), vapply(v, function(x) paste(as.character(x), collapse = "/"), character(1))),
                 collapse = ", "))
  }
  paste(as.character(v), collapse = ", ")
}

print_config_table <- function(cfg) {
  cat("| Field | Value | Source | Evidence |\n")
  cat("| :--- | :--- | :--- | :--- |\n")
  for (nm in names(cfg)) {
    f <- cfg[[nm]]
    cat(sprintf("| %s | %s | %s | %s |\n", nm,
                format_config_value(f$value), f$source,
                if (is.null(f$evidence)) "" else f$evidence))
  }
}

# 1. Subcommand: triage
cmd_triage <- function(params) {
  data_path <- params[["data"]]
  cases_out <- params[["cases-out"]]
  delays_out <- params[["delays-out"]]
  date_type_param <- params[["date-type"]]
  fill_zeros <- !is.null(params[["fill-zeros"]]) && !identical(params[["fill-zeros"]], FALSE)

  # An unrecognised value used to fall through to "report", silently giving
  # the user delay advice for a date type they did not ask about.
  if (!is.null(date_type_param)) {
    if (!tolower(as.character(date_type_param)) %in% c("report", "onset")) {
      stop("--date-type must be 'report' or 'onset'; got '", date_type_param, "'.")
    }
  }

  if (is.null(data_path)) {
    suppressPackageStartupMessages(library(EpiNow2))
    df <- as.data.frame(EpiNow2::example_confirmed)
    cat("Note: No --data supplied; inspecting built-in EpiNow2::example_confirmed\n")
    data_type <- "aggregate_counts"
  } else {
    if (!file.exists(data_path)) stop("Data file not found: ", data_path)
    df <- read.csv(data_path, stringsAsFactors = FALSE)
    data_type <- "unknown"
  }

  col_names <- tolower(names(df))

  # Check if linelist
  has_onset <- any(col_names %in% c("date_onset", "onset_date", "onset"))
  has_report <- any(col_names %in% c("date_report", "report_date", "report", "date_notification"))

  cat("=== Surveillance Data Triage ===\n")

  # Check for travel/imported case indicator
  has_import <- any(grepl("import|travel|source|origin", col_names))
  if (has_import) {
    cat("Structural Check: Imported/travel case column detected.\n")
    cat("  Note: EpiNow2 assumes local transmission in a closed population.\n")
    cat("  Imported cases should be separated or excluded from generating secondary cases to avoid inflating early Rt.\n")
  }

  if (has_onset && has_report) {
    data_type <- "linelist"
    onset_col <- names(df)[col_names %in% c("date_onset", "onset_date", "onset")][1]
    report_col <- names(df)[col_names %in% c("date_report", "report_date", "report", "date_notification")][1]
    cat("Detected Data Type: Linelist with onset and report dates\n")

    df$onset <- as.Date(df[[onset_col]])
    df$report <- as.Date(df[[report_col]])
    delays <- as.integer(df$report - df$onset)
    valid_delays <- delays[!is.na(delays) & delays >= 0]
    neg_delays <- sum(!is.na(delays) & delays < 0)

    cat(sprintf("Observed Delays: %d valid pairs (mean: %.2f days, median: %d days, max: %d days)\n",
                length(valid_delays), mean(valid_delays), as.integer(median(valid_delays)), max(valid_delays)))
    if (neg_delays > 0) {
      cat(sprintf("Warning: %d records have negative delay (report < onset); excluded from empirical delay extraction.\n", neg_delays))
    }

    if (!is.null(delays_out)) {
      # Write the event dates, not the differences: estimate_dist() needs the
      # dates to handle interval censoring and right truncation.
      pair_ok <- !is.na(df$onset) & !is.na(df$report) & df$report >= df$onset
      write.csv(
        data.frame(pdate_lwr = df$onset[pair_ok], sdate_lwr = df$report[pair_ok]),
        delays_out, row.names = FALSE
      )
      cat(sprintf("Event date pairs (%d rows) saved to: %s -- use with `estimate-delay --delays`\n",
                  sum(pair_ok), delays_out))
    }

    # Aggregate by report date (default) or onset date if requested
    agg_col <- if (!is.null(date_type_param) && tolower(date_type_param) == "onset") df$onset else df$report
    date_type_inferred <- if (!is.null(date_type_param) && tolower(date_type_param) == "onset") "onset" else "report"
    counts_df <- as.data.frame(table(agg_col), stringsAsFactors = FALSE)
    names(counts_df) <- c("date", "confirm")
    counts_df$date <- as.Date(counts_df$date)
    counts_df$confirm <- as.integer(counts_df$confirm)
    df <- counts_df
  } else {
    # Check for daily aggregate counts
    date_match <- which(col_names %in% c("date", "date_report", "report_date", "date_onset", "onset_date", "report", "onset"))
    confirm_match <- which(col_names %in% c("confirm", "cases", "count", "new_cases", "confirmed"))

    if (length(date_match) > 0 && length(confirm_match) > 0) {
      data_type <- "aggregate_counts"
      date_col_name <- names(df)[date_match[1]]
      confirm_col_name <- names(df)[confirm_match[1]]
      cat("Detected Data Type: Daily aggregate counts\n")

      df$date <- as.Date(df[[date_col_name]])
      df$confirm <- as.integer(df[[confirm_col_name]])
      df <- df[, c("date", "confirm")]

      # An aggregate series carries no evidence of what its dates mean. A
      # column called `date` is not a report date; it is a column called
      # `date`. This used to fall through to "report", which then drove the
      # delay structure and the week effect off an assumption nobody made.
      # Now: the column name where it says something, the weekly cycle in the
      # counts as weak corroboration, and otherwise unknown.
      name_guess <- classify_date_name(date_col_name)
      wk <- week_cycle_evidence(df$date, df$confirm)
      if (!is.null(date_type_param)) {
        date_type_inferred <- tolower(date_type_param)
        date_type_basis <- "supplied with --date-type"
      } else if (!is.na(name_guess)) {
        date_type_inferred <- name_guess
        date_type_basis <- sprintf("inferred from the column name '%s'", date_col_name)
      } else if (identical(wk$verdict, "cycle")) {
        date_type_inferred <- "report"
        date_type_basis <- sprintf("inferred from a weekly cycle in the counts (%s)", wk$reason)
      } else if (identical(wk$verdict, "no cycle")) {
        date_type_inferred <- "onset"
        date_type_basis <- sprintf("inferred from the absence of a weekly cycle (%s)", wk$reason)
      } else {
        date_type_inferred <- NA_character_
        date_type_basis <- sprintf("cannot be determined: %s", wk$reason)
      }
    } else {
      stop("Could not recognise surveillance data format. Expected either daily counts ('date', 'confirm') or linelist with onset and report dates.")
    }
  }

  # Print date-type recommendations
  if (!exists("date_type_basis", inherits = FALSE)) {
    date_type_basis <- if (!is.null(date_type_param)) "supplied with --date-type" else
      "linelist aggregated by report date; pass --date-type onset to use onset dates"
  }
  if (is.na(date_type_inferred)) {
    cat("Reference Date Type: UNKNOWN\n")
    cat(sprintf("  - Basis: %s\n", date_type_basis))
    cat("  - No delay structure or week effect is recommended, because both follow\n")
    cat("    from the date type. Set it with --date-type report|onset|specimen|admission,\n")
    cat("    or run `init`, which records the same question in the config.\n")
  } else if (identical(date_type_inferred, "onset")) {
    cat("Reference Date Type: Symptom Onset Date\n")
    cat(sprintf("  - Basis: %s\n", date_type_basis))
    cat("  - Delay Specification: Incubation period only (no reporting delay needed)\n")
    cat("  - Observation Model: pass --week-effect false to `fit` (biological symptom onset does not follow administrative weekly reporting cycles)\n")
    cat("  - Right-Truncation Guardrail: Recent onset counts suffer from unobserved onset lags (artificial drop at time series tail)\n")
  } else {
    cat(sprintf("Reference Date Type: %s\n",
                if (identical(date_type_inferred, "report")) "Notification / Report Date"
                else sprintf("%s%s Date", toupper(substring(date_type_inferred, 1, 1)),
                             substring(date_type_inferred, 2))))
    cat(sprintf("  - Basis: %s\n", date_type_basis))
    cat("  - Delay Specification: Compound delay = Incubation period + Reporting delay\n")
    cat("  - Observation Model: pass --week-effect true to `fit` (adjusts for administrative weekend dips and Monday reporting surges)\n")
  }

  df <- df[order(df$date), ]
  if (any(df$confirm < 0, na.rm = TRUE)) {
    stop("Data contains negative case counts.")
  }

  min_date <- min(df$date, na.rm = TRUE)
  max_date <- max(df$date, na.rm = TRUE)
  total_cases <- sum(df$confirm, na.rm = TRUE)
  peak_idx <- which.max(df$confirm)
  peak_date <- df$date[peak_idx]
  peak_cases <- df$confirm[peak_idx]

  full_seq <- seq(min_date, max_date, by = "day")
  missing_dates <- setdiff(as.character(full_seq), as.character(df$date))

  cat(sprintf("Rows: %d\n", nrow(df)))
  cat(sprintf("Date Range: %s to %s (%d calendar days)\n", min_date, max_date, as.integer(max_date - min_date + 1)))
  cat(sprintf("Missing Dates: %d\n", length(missing_dates)))

  if (length(missing_dates) > 0) {
    if (fill_zeros) {
      complete_df <- data.frame(date = full_seq)
      df <- merge(complete_df, df, by = "date", all.x = TRUE)
      df$confirm[is.na(df$confirm)] <- 0L
      cat("Notice: Missing calendar dates have been zero-filled (--fill-zeros applied for regular 1-day spacing).\n")
    } else {
      cat("Warning: Non-contiguous calendar dates detected. EpiNow2 Stan models require unbroken daily sequences.\n")
      cat("         Use --fill-zeros to automatically pad unobserved dates with 0 counts.\n")
    }
  }

  cat(sprintf("Total Cases: %s\n", format(total_cases, big.mark = ",")))
  cat(sprintf("Peak Cases: %s on %s\n", format(peak_cases, big.mark = ","), peak_date))

  if (!is.null(cases_out)) {
    write.csv(df, cases_out, row.names = FALSE)
    cat(sprintf("Formatted aggregate counts saved to: %s\n", cases_out))
  }
  cat("================================\n")
}

# 2. Subcommand: lookup-delay
# An epiparameter entry can exist without carrying a usable distribution.
# Measured against epiparameter 0.4.1: 11 of 125 entries have no parameters,
# and one of the three generation time entries is among them. "An entry was
# found" is therefore not the same claim as "we have a distribution", and only
# the second one licenses a fit.
has_usable_parameters <- function(ep) {
  if (is.null(ep)) return(FALSE)
  pars <- tryCatch(epiparameter::get_parameters(ep), error = function(e) NULL)
  length(pars) > 0 && !all(is.na(unlist(pars)))
}

cmd_lookup_delay <- function(params) {
  disease <- if (!is.null(params[["disease"]])) params[["disease"]] else "COVID-19"
  param <- if (!is.null(params[["param"]])) params[["param"]] else "serial interval"

  if (!requireNamespace("epiparameter", quietly = TRUE)) {
    stop("Package 'epiparameter' is required.")
  }

  # A request for a generation time is answered with one where the database has
  # it, and with the serial interval where it does not. Verified against
  # epiparameter 0.4.1: three generation time entries exist (influenza,
  # chikungunya), so a blanket redirect to the serial interval would discard a
  # directly applicable parameter for those pathogens. Everything else,
  # COVID-19 included, still substitutes.
  substituted <- FALSE
  requested <- param
  wants_gt <- grepl("generation", param, ignore.case = TRUE)

  lookup <- function(nm) {
    tryCatch(
      epiparameter::epiparameter_db(
        disease = disease, epi_name = nm, single_epiparameter = TRUE
      ),
      error = function(e) NULL
    )
  }

  ep <- lookup(param)
  # An entry with no parameters is not information. Treat it as absent so the
  # fallback runs, rather than reporting an empty distribution as a result.
  if (wants_gt && !has_usable_parameters(ep)) {
    ep_si <- lookup("serial interval")
    if (has_usable_parameters(ep_si)) {
      ep <- ep_si
      param <- "serial interval"
      substituted <- TRUE
    }
  }

  if (!has_usable_parameters(ep)) {
    if (!is.null(ep)) {
      # The database holds an entry but it carries no usable parameters. Saying
      # "no entry found" here would be false and would send the user hunting
      # for a spelling mistake that does not exist.
      cat(sprintf("An entry exists in epiparameter for disease '%s', parameter '%s',\n",
                  disease, param))
      cat("but it carries no usable distribution parameters.\n\n")
      ep <- NULL
    }
    cat(sprintf("No entry found in epiparameter for disease '%s', parameter '%s'.\n",
                disease, param))
    cat("\nNo distribution has been assumed. Options:\n")
    cat("  1. Supply parameters directly to `fit` via --gt-mean/--gt-sd/--gt-max\n")
    cat("     or --delay-mean/--delay-sd/--delay-max.\n")
    cat("  2. Estimate a delay from your own linelist with `estimate-delay`.\n")
    cat("  3. Check the disease spelling against the database, e.g. in R:\n")
    cat("     epiparameter::epiparameter_db(disease = \"<name>\")\n")
    quit(status = 1)
  }

  pars <- epiparameter::get_parameters(ep)
  # stats::family() on the distribution object; ep$prob_distribution$distribution
  # is NULL, which made sprintf return a zero-length vector that cat() dropped
  # silently, so this line used to vanish from the output entirely.
  dist_family <- tryCatch(
    as.character(stats::family(ep$prob_distribution)),
    error = function(e) "unknown"
  )

  # Report what the database returned, not what was asked for.
  # epiparameter_db(single_epiparameter = TRUE) selects one entry from many and
  # announces its choice as a message this script does not capture, so echoing
  # the request would assert something never checked against the result.
  returned_name <- tryCatch(as.character(ep$epi_name), error = function(e) NA_character_)
  returned_disease <- tryCatch(as.character(ep$disease), error = function(e) NA_character_)
  if (length(returned_name) != 1 || is.na(returned_name)) returned_name <- param
  if (length(returned_disease) != 1 || is.na(returned_disease)) returned_disease <- disease

  cat("=== epiparameter lookup ===\n")
  if (substituted) {
    cat(sprintf("Requested '%s'; epiparameter holds no usable generation time for\n", requested))
    cat(sprintf("%s, so the SERIAL INTERVAL is returned instead.\n", returned_disease))
    cat("These are not the same quantity. The serial interval measures onset-to-onset\n")
    cat("and, with pre-symptomatic transmission, is more dispersed than the generation\n")
    cat("time and can take negative values. Declare this substitution wherever the\n")
    cat("resulting Rt is reported.\n\n")
  } else if (!identical(tolower(returned_name), tolower(param))) {
    # The database answered with a different parameter than the one requested.
    cat(sprintf("Requested '%s'; the database returned '%s' instead.\n",
                param, returned_name))
    cat("These are not the same quantity. Declare this substitution wherever the\n")
    cat("resulting Rt is reported.\n\n")
  }

  citation <- tryCatch(epiparameter::get_citation(ep), error = function(e) NULL)
  if (!is.null(citation)) {
    cat(sprintf("Study: %s (%s). %s. doi: %s\n",
                citation$author[[1]]$family, citation$year, citation$title, citation$doi))
  }
  cat(sprintf("Disease: %s | Parameter: %s | Distribution: %s\n",
              returned_disease, returned_name, dist_family))
  cat("Parameters:\n")
  for (pname in names(pars)) {
    cat(sprintf("  %s: %.3f\n", pname, pars[[pname]]))
  }

  # A max bound is required by EpiNow2, but it is an imposed truncation, not a
  # property of the published estimate. Report it as a choice, and derive a
  # default from the distribution's own upper tail rather than always using 14.
  suggested_max <- tryCatch({
    q <- stats::quantile(ep$prob_distribution, 0.999)
    max(7, ceiling(as.numeric(q)))
  }, error = function(e) NA_integer_)
  max_note <- if (is.na(suggested_max)) 14L else as.integer(suggested_max)

  cat(sprintf("\nSuggested truncation: max = %d days (the 99.9th percentile of this\n", max_note))
  cat("distribution, rounded up). This is an imposed bound, not part of the published\n")
  cat("estimate. Adjust it if your setting has longer delays.\n")

  if ("meanlog" %in% names(pars) && "sdlog" %in% names(pars)) {
    cat(sprintf("EpiNow2 specification: LogNormal(meanlog = %.3f, sdlog = %.3f, max = %d)\n",
                pars[["meanlog"]], pars[["sdlog"]], max_note))
  } else if ("shape" %in% names(pars) && "rate" %in% names(pars)) {
    cat(sprintf("EpiNow2 specification: Gamma(shape = %.3f, rate = %.3f, max = %d)\n",
                pars[["shape"]], pars[["rate"]], max_note))
  } else if ("mean" %in% names(pars) && "sd" %in% names(pars)) {
    cat(sprintf("EpiNow2 specification: Gamma(mean = %.3f, sd = %.3f, max = %d)\n",
                pars[["mean"]], pars[["sd"]], max_note))
  }
  cat("===========================\n")
}

# 3. Subcommand: estimate-delay
#
# EpiNow2's estimate_dist() takes a linelist of primary and secondary event
# dates, not a vector of pre-computed delays: it accounts for double interval
# censoring and right truncation, which a vector of integer differences has
# already thrown away. `triage --delays-out` writes the matching two-column
# file.
cmd_estimate_delay <- function(params) {
  delays_path <- params[["delays"]]
  dist <- if (!is.null(params[["dist"]])) params[["dist"]] else "lognormal"
  seed <- if (!is.null(params[["seed"]])) as.integer(params[["seed"]]) else 20260915
  cores <- if (!is.null(params[["cores"]])) as.integer(params[["cores"]]) else 2

  if (is.null(delays_path) || !file.exists(delays_path)) {
    stop("Must supply an existing CSV file via --delays.")
  }
  suppressPackageStartupMessages(library(EpiNow2))

  df <- read.csv(delays_path, stringsAsFactors = FALSE)
  cols <- tolower(names(df))

  if (!all(c("pdate_lwr", "sdate_lwr") %in% cols)) {
    stop("--delays file must contain columns 'pdate_lwr' (primary event date, ",
         "e.g. onset) and 'sdate_lwr' (secondary event date, e.g. report). ",
         "Generate it with: triage --data <linelist> --delays-out <file>. ",
         "A single column of pre-computed delay integers is no longer accepted, ",
         "because censoring and truncation cannot be recovered from it.")
  }

  names(df)[cols == "pdate_lwr"] <- "pdate_lwr"
  names(df)[cols == "sdate_lwr"] <- "sdate_lwr"
  df$pdate_lwr <- as.Date(df$pdate_lwr)
  df$sdate_lwr <- as.Date(df$sdate_lwr)

  n_start <- nrow(df)
  ok <- !is.na(df$pdate_lwr) & !is.na(df$sdate_lwr) & df$sdate_lwr >= df$pdate_lwr
  df <- df[ok, c("pdate_lwr", "sdate_lwr"), drop = FALSE]
  n_dropped <- n_start - nrow(df)

  if (nrow(df) < 20) {
    stop("Only ", nrow(df), " usable event pairs; too few to estimate a delay ",
         "distribution reliably. Supply more data or set the delay from literature ",
         "via lookup-delay.")
  }

  if (n_dropped > 0) {
    cat(sprintf("Dropped %d of %d rows with missing dates or secondary before primary.\n",
                n_dropped, n_start))
  }
  cat(sprintf("Fitting %s delay distribution to %d event pairs (seed: %d)...\n",
              dist, nrow(df), seed))

  fit <- estimate_dist(
    df, dist = dist,
    stan = stan_opts(seed = seed, cores = cores)
  )

  cat("=== Fitted delay distribution ===\n")
  print(fit)
  cat("=================================\n")
  cat("\nThese are posterior estimates on the distribution's own scale\n")
  cat("(meanlog/sdlog for lognormal). Pass them to `fit` with --delay-dist,\n")
  cat("--delay-mean and --delay-sd, converting to natural scale if needed.\n")
}

# Build a delay/generation-time distribution from CLI arguments.
# Returns NULL when the user supplied nothing, so the caller can fall back.
build_dist <- function(dist_name, mean_v, sd_v, max_v, label) {
  if (is.null(mean_v) && is.null(sd_v) && is.null(dist_name)) return(NULL)
  if (is.null(mean_v) || is.null(sd_v)) {
    stop(label, ": both --", tolower(label), "-mean and --", tolower(label),
         "-sd are required when specifying this distribution.")
  }
  dn <- if (is.null(dist_name)) "lognormal" else tolower(dist_name)
  mx <- if (is.null(max_v)) 14 else as.numeric(max_v)
  m <- as.numeric(mean_v); s <- as.numeric(sd_v)
  if (!is.finite(m) || !is.finite(s) || m <= 0 || s <= 0) {
    stop(label, ": mean and sd must be positive numbers.")
  }
  if (!is.finite(mx) || mx <= 0) stop(label, ": max must be a positive number.")
  switch(dn,
    lognormal = LogNormal(mean = m, sd = s, max = mx),
    gamma     = Gamma(mean = m, sd = s, max = mx),
    stop(label, ": unsupported distribution '", dn, "'. Use lognormal or gamma.")
  )
}

# 4. Subcommand: fit
cmd_fit <- function(params) {
  suppressPackageStartupMessages(library(EpiNow2))

  # A config file supplies whatever was not passed as a flag. The refusal on a
  # missing generation time or delay is the same refusal either way: it is
  # checked below on the resolved values, so a config with a missing field
  # cannot get past a check that a bare command line would fail.
  config_path <- params[["config"]]
  if (!is.null(config_path)) {
    cfg <- read_config(config_path)
    gaps <- config_gaps(cfg)
    if (length(gaps) > 0) {
      stop("Config ", config_path, " is missing required field(s): ",
           paste(gaps, collapse = ", "), ".\n",
           "Each is recorded in the file with the reason it could not be set. ",
           "Fill them in and re-run; nothing is defaulted on your behalf.")
    }
    params <- apply_config_to_params(params, cfg)
  }

  data_path <- params[["data"]]
  out_dir <- if (!is.null(params[["output-dir"]])) params[["output-dir"]] else "outputs/fit"
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  seed <- if (!is.null(params[["seed"]])) as.integer(params[["seed"]]) else 20260915
  cores <- if (!is.null(params[["cores"]])) as.integer(params[["cores"]]) else 4

  r_mean <- if (!is.null(params[["r-prior-mean"]])) as.numeric(params[["r-prior-mean"]]) else 2.0
  r_sd <- if (!is.null(params[["r-prior-sd"]])) as.numeric(params[["r-prior-sd"]]) else 1.0
  rw_step <- if (!is.null(params[["rw"]])) as.integer(params[["rw"]]) else 0

  # NULL when unset, so "--gp-ls 21" and "--gp-ls 21.1" take the same code
  # path. The old sentinel compared against the default value itself, which
  # silently diverted one specific input to a different branch.
  gp_ls <- if (!is.null(params[["gp-ls"]])) as.numeric(params[["gp-ls"]]) else NULL

  # Gaussian processes mix poorly at short length scales. A random walk is the
  # right tool for fast or discrete changes.
  allow_short_gp <- !is.null(params[["allow-short-gp"]]) &&
    !identical(params[["allow-short-gp"]], FALSE)
  if (!is.null(gp_ls) && gp_ls < 7) {
    if (!allow_short_gp) {
      stop("--gp-ls ", gp_ls, " is below 7 days. Gaussian processes with short ",
           "length scales give poor sampler geometry and overfit. Use a random ",
           "walk instead: --rw 7 for weekly steps, or --rw 1 for daily steps. ",
           "Pass --allow-short-gp to override.")
    }
    cat("WARNING: --gp-ls ", gp_ls, " is below the recommended 7 days; ",
        "overridden by --allow-short-gp. Expect divergences and check ",
        "diagnostics carefully.\n", sep = "")
  }

  trunc_dist_name <- if (!is.null(params[["trunc-dist"]])) tolower(params[["trunc-dist"]]) else "none"
  trunc_mean <- if (!is.null(params[["trunc-mean"]])) as.numeric(params[["trunc-mean"]]) else 2.0
  trunc_sd <- if (!is.null(params[["trunc-sd"]])) as.numeric(params[["trunc-sd"]]) else 1.0
  trunc_max <- if (!is.null(params[["trunc-max"]])) as.numeric(params[["trunc-max"]]) else 10.0

  # --- Input validation -----------------------------------------------------
  # as.Date(NULL) yields a zero-length value rather than an error, so a file
  # without a 'date' column used to reach Stan and fail deep inside rbindlist
  # with a message that told the user nothing.
  if (is.null(data_path)) {
    cases <- EpiNow2::example_confirmed
    cat("No --data supplied; using EpiNow2::example_confirmed (COVID-19 example data).\n")
  } else {
    if (!file.exists(data_path)) stop("Data file not found: ", data_path)
    cases <- read.csv(data_path, stringsAsFactors = FALSE)
    missing_cols <- setdiff(c("date", "confirm"), names(cases))
    if (length(missing_cols) > 0) {
      stop("Input must have columns 'date' and 'confirm'; missing: ",
           paste(missing_cols, collapse = ", "), ". Found: ",
           paste(names(cases), collapse = ", "),
           ". Produce a correctly shaped file with: ",
           "triage --data <your file> --cases-out <clean file>.")
    }
    keep_cols <- c("date", "confirm", if ("region" %in% names(cases)) "region")
    cases <- cases[, keep_cols, drop = FALSE]
    cases$date <- as.Date(cases$date)
    cases$confirm <- as.integer(cases$confirm)
    if (any(is.na(cases$date))) stop("Some 'date' values could not be parsed as dates.")
    if (any(cases$confirm < 0, na.rm = TRUE)) stop("Data contains negative case counts.")
    # Checked within region: two regions each contiguous look like duplicate
    # dates when pooled, and a pooled check would reject a valid regional file.
    date_groups <- if ("region" %in% names(cases)) split(cases$date, cases$region) else list(cases$date)
    for (g in date_groups) {
      gaps <- as.integer(diff(sort(g)))
      if (length(gaps) > 0 && any(gaps != 1)) {
        stop("Dates are not a contiguous daily sequence. EpiNow2 requires unbroken ",
             "daily data. Fix with: triage --data <file> --fill-zeros --cases-out <clean file>.")
      }
    }
  }

  # Regions are fitted separately by default when the data carries them:
  # pooling across regions with different epidemics estimates an Rt for a
  # population that does not exist. --pool asks for that deliberately, and is
  # recorded as a caveat rather than done silently.
  pool <- !is.null(params[["pool"]]) && !identical(params[["pool"]], FALSE)
  has_region <- "region" %in% names(cases) && length(unique(cases$region)) > 1
  by_region <- has_region && !pool &&
    (is.null(params[["by-region"]]) || !identical(params[["by-region"]], "false"))
  n_pooled_regions <- if (has_region) length(unique(cases$region)) else 0L
  if (has_region && pool) {
    cases <- aggregate(confirm ~ date, data = cases, FUN = sum)
    cases <- cases[order(cases$date), ]
  } else if (!by_region && "region" %in% names(cases)) {
    cases <- cases[, c("date", "confirm"), drop = FALSE]
  }

  # --- Transmission and observation distributions ---------------------------
  gt_dist <- build_dist(params[["gt-dist"]], params[["gt-mean"]],
                        params[["gt-sd"]], params[["gt-max"]], "GT")
  delay_dist <- build_dist(params[["delay-dist"]], params[["delay-mean"]],
                           params[["delay-sd"]], params[["delay-max"]], "DELAY")

  # There is no default generation time or delay. A default here would have to
  # be some particular pathogen's biology (the package examples are COVID-19),
  # and an Rt computed on the wrong pathogen's parameters is not an estimate of
  # anything. Guarding that with a flag saying which pathogen the data is would
  # not help: nothing can check such a claim, so the guard would rest on the
  # caller's word. Requiring the numbers is the only version of this that is
  # actually verified.
  missing_dists <- character(0)
  if (is.null(gt_dist)) {
    missing_dists <- c(missing_dists, "generation time (--gt-mean, --gt-sd, --gt-max)")
  }
  if (is.null(delay_dist)) {
    missing_dists <- c(
      missing_dists,
      "infection-to-observation delay (--delay-mean, --delay-sd, --delay-max)"
    )
  }

  if (length(missing_dists) > 0) {
    stop(
      "Missing required distributions:\n",
      paste0("  - ", missing_dists, collapse = "\n"), "\n",
      "Get them in one of these ways:\n",
      "  1. lookup-delay --disease <name> --param 'generation time' for a published\n",
      "     estimate, then pass the numbers it prints.\n",
      "  2. estimate-delay on your own linelist, for the reporting delay.\n",
      "  3. Pass values you already have.\n",
      "For a COVID-19 example to try the tool on, lookup-delay --disease COVID-19\n",
      "prints numbers you can paste straight back in."
    )
  }

  # Caveats travel with the fit, not with this console output. A warning printed
  # here is gone by the time someone reads a report or copies an Rt into an
  # email, so anything that qualifies the estimate is written next to the fit
  # and re-attached to the number by `evaluate`.
  caveats <- character(0)

  if (has_region && pool) {
    caveats <- c(caveats, paste(
      "Case counts were pooled across", n_pooled_regions,
      "regions before fitting. The resulting Rt is for the pooled series, which",
      "averages over regional epidemics at different stages."
    ))
  }

  if (!is.null(params[["gt-substituted"]])) {
    caveats <- c(caveats, paste(
      "Generation time is a substituted serial interval, not a generation time.",
      "It is onset-to-onset and, under pre-symptomatic transmission, more",
      "dispersed, so Rt is biased towards 1."
    ))
  }

  # week_effect belongs on the observation model. Triage recommends a value
  # from the date type; this is the flag that carries that recommendation into
  # the model, which previously had no route in at all.
  week_effect <- TRUE
  if (!is.null(params[["week-effect"]])) {
    we <- tolower(as.character(params[["week-effect"]]))
    if (we %in% c("true", "yes", "1")) {
      week_effect <- TRUE
    } else if (we %in% c("false", "no", "0")) {
      week_effect <- FALSE
    } else {
      stop("--week-effect must be true or false; got '", we, "'.")
    }
  }
  obs_configuration <- obs_opts(week_effect = week_effect)

  rt_configuration <- if (rw_step > 0) {
    rt_opts(prior = LogNormal(mean = r_mean, sd = r_sd), rw = rw_step)
  } else {
    rt_opts(prior = LogNormal(mean = r_mean, sd = r_sd))
  }

  gp_configuration <- if (rw_step > 0) {
    NULL
  } else if (!is.null(gp_ls)) {
    gp_opts(ls = LogNormal(mean = gp_ls, sd = 7, max = 60))
  } else {
    gp_opts()
  }

  trunc_configuration <- trunc_opts()
  trunc_str <- "none (no right-truncation adjustment)"
  if (trunc_dist_name == "lognormal") {
    trunc_configuration <- trunc_opts(dist = LogNormal(mean = trunc_mean, sd = trunc_sd, max = trunc_max))
    trunc_str <- sprintf("LogNormal(mean = %.2f, sd = %.2f, max = %.0f)", trunc_mean, trunc_sd, trunc_max)
  } else if (trunc_dist_name == "gamma") {
    trunc_configuration <- trunc_opts(dist = Gamma(mean = trunc_mean, sd = trunc_sd, max = trunc_max))
    trunc_str <- sprintf("Gamma(mean = %.2f, sd = %.2f, max = %.0f)", trunc_mean, trunc_sd, trunc_max)
  } else if (trunc_dist_name != "none") {
    stop("--trunc-dist must be none, lognormal or gamma; got '", trunc_dist_name, "'.")
  }

  cat(sprintf("Fitting renewal model with EpiNow2 (seed = %d, cores = %d)...\n", seed, cores))
  cat(sprintf("  Rt prior:    LogNormal(mean = %.2f, sd = %.2f)\n", r_mean, r_sd))
  cat(sprintf("  Dynamics:    %s\n",
              if (rw_step > 0) sprintf("random walk, %d-day steps", rw_step)
              else if (!is.null(gp_ls)) sprintf("Gaussian process, length scale ~%.1f days", gp_ls)
              else "Gaussian process, package default length scale"))
  cat(sprintf("  Week effect: %s\n", if (week_effect) "estimated" else "not estimated"))
  cat(sprintf("  Truncation:  %s\n", trunc_str))

  if (by_region) {
    cat(sprintf("  Regions:     %d, fitted separately (%s)\n",
                n_pooled_regions, paste(sort(unique(cases$region)), collapse = ", ")))
  }

  # Prints the specification exactly as it will be fitted, then stops. What
  # gets resolved from a config, and what a flag overrode, is otherwise only
  # visible by waiting for a sampler run to finish.
  if (!is.null(params[["dry-run"]]) && !identical(params[["dry-run"]], FALSE)) {
    cat(sprintf("  GT:          %s(mean = %.2f, sd = %.2f, max = %s)\n",
                if (is.null(params[["gt-dist"]])) "lognormal" else params[["gt-dist"]],
                as.numeric(params[["gt-mean"]]), as.numeric(params[["gt-sd"]]),
                if (is.null(params[["gt-max"]])) "14" else params[["gt-max"]]))
    cat(sprintf("  Delay:       %s(mean = %.2f, sd = %.2f, max = %s)\n",
                if (is.null(params[["delay-dist"]])) "lognormal" else params[["delay-dist"]],
                as.numeric(params[["delay-mean"]]), as.numeric(params[["delay-sd"]]),
                if (is.null(params[["delay-max"]])) "14" else params[["delay-max"]]))
    if (length(caveats) > 0) {
      cat("  Caveats:\n")
      for (cv in caveats) cat(sprintf("    - %s\n", cv))
    }
    cat("Dry run: specification resolved, nothing fitted.\n")
    return(invisible(NULL))
  }

  fit <- if (by_region) {
    # Each region is fitted on its own and returned as a full
    # estimate_infections object, so the diagnostics and the reporting path are
    # the same code for one region as for twenty.
    regional_epinow(
      data = cases,
      generation_time = gt_opts(gt_dist),
      delays = delay_opts(delay_dist),
      truncation = trunc_configuration,
      rt = rt_configuration,
      gp = gp_configuration,
      obs = obs_configuration,
      stan = stan_opts(seed = seed, cores = cores, control = list(adapt_delta = 0.99)),
      output = c("region"),
      return_output = TRUE,
      verbose = FALSE,
      logs = NULL
    )
  } else {
    estimate_infections(
      cases,
      generation_time = gt_opts(gt_dist),
      delays = delay_opts(delay_dist),
      truncation = trunc_configuration,
      rt = rt_configuration,
      gp = gp_configuration,
      obs = obs_configuration,
      stan = stan_opts(seed = seed, cores = cores, control = list(adapt_delta = 0.99)),
      verbose = FALSE
    )
  }
  saveRDS(fit, file.path(out_dir, "fit.rds"))
  # Written even when empty, so `evaluate` can tell "no caveats" apart from
  # "caveats were never recorded because this fit predates the mechanism".
  saveRDS(
    list(caveats = caveats, fitted_at = Sys.time()),
    file.path(out_dir, "caveats.rds")
  )
  cat(sprintf("Model fit saved to: %s\n", file.path(out_dir, "fit.rds")))
  cat("Next: evaluate --fit ", file.path(out_dir, "fit.rds"),
      " (this checks convergence before reporting any estimate)\n", sep = "")
}

# 5. Subcommand: evaluate
#
# Every line this prints is computed from the supplied fit object. Nothing
# about convergence, coverage or probability is asserted from a fixed string.
#
# Convergence is a gate, not a note. If the fit breaches any threshold the
# headline estimates are withheld and the process exits non-zero, so an
# unconverged Rt cannot be lifted into a situation report.

# Compute sampler diagnostics from the Stan object inside an EpiNow2 fit.
#
# Quantities that do not vary across draws are excluded. EpiNow2 monitors
# fixed inputs alongside sampled parameters -- a non-parametric delay PMF
# passed in as data appears in the Stan summary with sd exactly 0, Rhat near
# 1 and an effective sample size of ~2. Those are constants, not badly mixed
# parameters, and including them makes every fit look like it failed on ESS.
# Rows with an undefined Rhat are excluded for the same reason.
compute_diagnostics <- function(fit) {
  stanfit <- fit$fit
  s <- rstan::summary(stanfit)$summary

  varying <- !is.na(s[, "Rhat"]) & !is.na(s[, "sd"]) & s[, "sd"] > 1e-10
  n_excluded <- sum(!varying)
  s <- s[varying, , drop = FALSE]

  if (nrow(s) == 0) {
    stop("No varying parameters found in the fit; cannot assess convergence.")
  }

  rhat <- s[, "Rhat"]
  ess <- s[, "n_eff"]
  sp <- rstan::get_sampler_params(stanfit, inc_warmup = FALSE)
  n_div <- sum(vapply(sp, function(x) sum(x[, "divergent__"]), numeric(1)))

  list(
    max_rhat = max(rhat, na.rm = TRUE),
    n_rhat_bad = sum(rhat > 1.01, na.rm = TRUE),
    worst_rhat_param = rownames(s)[which.max(rhat)],
    min_ess = min(ess, na.rm = TRUE),
    n_ess_bad = sum(ess < 400, na.rm = TRUE),
    worst_ess_param = rownames(s)[which.min(ess)],
    n_divergent = n_div,
    n_params = nrow(s),
    n_excluded = n_excluded
  )
}

# Apply thresholds. Returns pass/fail plus the specific reasons for failure.
assess_diagnostics <- function(d) {
  reasons <- character(0)
  if (!is.finite(d$max_rhat) || d$max_rhat > 1.01) {
    reasons <- c(reasons, sprintf(
      "Rhat: max %.4f exceeds 1.01 (%d of %d varying parameters above threshold; worst: %s)",
      d$max_rhat, d$n_rhat_bad, d$n_params, d$worst_rhat_param))
  }
  if (d$n_divergent > 0) {
    reasons <- c(reasons, sprintf(
      "Divergent transitions: %d (must be 0)", d$n_divergent))
  }
  if (!is.finite(d$min_ess) || d$min_ess < 400) {
    reasons <- c(reasons, sprintf(
      "Effective sample size: min %.0f below 400 (%d of %d varying parameters below threshold; worst: %s)",
      d$min_ess, d$n_ess_bad, d$n_params, d$worst_ess_param))
  }
  list(pass = length(reasons) == 0, reasons = reasons)
}

# Posterior P(Rt > 1) on a given date, taken from the draws rather than from
# any summary column. Returns NA if the date cannot be located in the draws.
prob_rt_above_one <- function(fit, rt_all, report_date) {
  idx <- which(rt_all$date == report_date)
  if (length(idx) != 1) return(NA_real_)
  draws <- tryCatch(rstan::extract(fit$fit, pars = "R")$R, error = function(e) NULL)
  if (is.null(draws) || idx > ncol(draws)) return(NA_real_)
  mean(draws[, idx] > 1)
}

# Describe the delay/observation assumptions actually used, read from the
# arguments stored on the fit rather than from a hardcoded description.
describe_assumptions <- function(fit) {
  a <- fit$args
  out <- character(0)
  # EpiNow2 stores week_effect as a period length: 7 means a weekly effect
  # is estimated, 1 means none.
  if (!is.null(a$week_effect)) {
    out <- c(out, sprintf("  - Day-of-week effect: %s",
                          if (isTRUE(a$week_effect > 1)) {
                            sprintf("estimated, period %d days", as.integer(a$week_effect))
                          } else {
                            "not estimated"
                          }))
  }
  # EpiNow2 stores distributions two ways. An uncertain (parametric) delay
  # keeps mean/sd parameters and a max. A fixed delay is discretised to a
  # probability mass function, so delay_max and the parameter vectors are
  # empty and the length of the PMF is the only record of its support.
  if (!is.null(a$delay_max) && length(a$delay_max) > 0) {
    out <- c(out, sprintf("  - Delay distribution max bounds (days): %s",
                          paste(a$delay_max, collapse = ", ")))
  } else if (!is.null(a$delay_np_pmf) && length(a$delay_np_pmf) > 0) {
    out <- c(out, sprintf("  - Delays supplied as fixed distributions, discretised to %d PMF bins",
                          length(a$delay_np_pmf)))
  }
  if (!is.null(a$delay_n)) {
    out <- c(out, sprintf("  - Delay components: %d", as.integer(a$delay_n)))
  }
  if (!is.null(a$seeding_time)) {
    out <- c(out, sprintf("  - Seeding time: %d days", as.integer(a$seeding_time)))
  }
  if (!is.null(a$horizon)) {
    out <- c(out, sprintf("  - Forecast horizon: %d days", as.integer(a$horizon)))
  }
  if (!is.null(a$gp_type) || !is.null(a$fixed)) {
    dyn <- if (isTRUE(a$fixed == 1)) "fixed Rt" else "Gaussian process / random walk (see fit call)"
    out <- c(out, sprintf("  - Rt dynamics: %s", dyn))
  }
  if (length(out) == 0) out <- "  - (No stored arguments available on this fit object)"
  out
}

cmd_evaluate <- function(params) {
  fit_path <- params[["fit"]]
  compare_path <- params[["compare"]]
  date_str <- params[["date"]]

  if (is.null(fit_path) || !file.exists(fit_path)) {
    stop("Valid --fit path must be supplied.")
  }
  suppressPackageStartupMessages(library(EpiNow2))
  fit <- readRDS(fit_path)

  # --report-out captures this report to a file as well as the console. A
  # caveat that exists only in a terminal does not survive the number being
  # copied out of it, so an unsupervised report needs the qualification to live
  # in the same artefact as the estimate.
  # Written to a temporary path and moved into place only once the report is
  # complete. An error partway through (an out-of-range --date, say) would
  # otherwise leave a truncated or empty file on disk looking like a report.
  # A withheld-estimate report is a valid report and is kept; a half-written
  # one is not.
  report_out <- params[["report-out"]]
  if (!is.null(report_out)) {
    dir.create(dirname(report_out), showWarnings = FALSE, recursive = TRUE)
    report_tmp <- paste0(report_out, ".part")
    con <- file(report_tmp, open = "wt")
    report_complete <- FALSE
    sink(con, split = TRUE)
    on.exit({
      sink()
      close(con)
      if (report_complete) {
        file.rename(report_tmp, report_out)
        cat(sprintf("\nReport written to: %s\n", report_out))
      } else {
        unlink(report_tmp)
        cat("\nReport not written: the run did not complete.\n")
      }
    }, add = TRUE)
  }
  # Marks the report finished. Assigned in the enclosing frame so the on.exit
  # handler above sees it.
  finish_report <- function() {
    if (!is.null(report_out)) report_complete <<- TRUE
  }

  # Caveats recorded by `fit` next to the fit object. Absent for a fit made
  # before this existed, which is reported as unknown rather than as none:
  # silently showing no caveats for a fit that was never checked would be the
  # same failure this mechanism exists to prevent.
  caveat_path <- file.path(dirname(fit_path), "caveats.rds")
  caveat_info <- if (file.exists(caveat_path)) {
    tryCatch(readRDS(caveat_path), error = function(e) NULL)
  } else {
    NULL
  }
  caveats <- if (is.null(caveat_info)) NA_character_ else caveat_info$caveats

  # A regional fit holds one estimate_infections object per region. It is
  # reported as a table with its own per-region gate rather than as one
  # headline, because there is no single Rt to headline.
  if (is.list(fit) && !is.null(fit$regional)) {
    result <- report_regional(fit, caveats, date_str)
    finish_report()
    return(invisible(result))
  }

  rt_all <- summary(fit, type = "parameters", params = "R")
  available <- sort(unique(as.Date(rt_all$date)))

  if (!is.null(date_str)) {
    report_date <- as.Date(date_str)
    if (is.na(report_date)) {
      stop("Could not parse --date '", date_str, "'. Use YYYY-MM-DD.")
    }
    # No silent fallback: a date outside the estimated period is an error,
    # because reporting the last row under the requested date's header
    # misattributes the estimate.
    if (!(report_date %in% available)) {
      stop("Requested --date ", format(report_date),
           " is not in the estimated period (",
           format(min(available)), " to ", format(max(available)), ").")
    }
  } else {
    report_date <- max(fit$observations$date)
    if (!(report_date %in% available)) report_date <- max(available)
  }

  # --- Convergence gate -----------------------------------------------------
  diag <- compute_diagnostics(fit)
  verdict <- assess_diagnostics(diag)

  cat("\n# Routine Surveillance Transmission & Nowcast Summary\n")
  cat(sprintf("**Reference date:** %s | **Engine:** EpiNow2 %s\n\n",
              format(report_date), as.character(utils::packageVersion("EpiNow2"))))

  cat("## Sampler diagnostics\n\n")
  cat("| Diagnostic | Value | Threshold |\n")
  cat("| :--- | ---: | :--- |\n")
  cat(sprintf("| Max Rhat | %.4f | <= 1.01 |\n", diag$max_rhat))
  cat(sprintf("| Min effective sample size | %.0f | >= 400 |\n", diag$min_ess))
  cat(sprintf("| Divergent transitions | %d | 0 |\n", diag$n_divergent))
  cat(sprintf("| Varying parameters assessed | %d | |\n\n", diag$n_params))
  if (diag$n_excluded > 0) {
    cat(sprintf("%d fixed quantities (sd = 0, e.g. delay PMFs supplied as data) were excluded from these diagnostics.\n\n",
                diag$n_excluded))
  }

  if (!verdict$pass) {
    cat("**Convergence: FAIL**\n\n")
    for (r in verdict$reasons) cat(sprintf("* %s\n", r))
    cat("\n## Estimates withheld\n\n")
    cat("No Rt, growth rate or nowcast is reported from this fit. The sampler did\n")
    cat("not converge, so the posterior it explored is not the model's posterior.\n")
    cat("This is a recorded non-answer, not a missing report: the question was\n")
    cat("asked and could not be answered on this fit.\n\n")
    cat("Reconsider the model rather than refitting unchanged. Simplify the Rt\n")
    cat("dynamics (a random walk in place of a Gaussian process), tighten priors,\n")
    cat("or check for non-identifiability from estimating too many delay\n")
    cat("components at once.\n")
    # A withheld-estimate report is complete: it says what was asked and why it
    # could not be answered. quit() here would skip the on.exit handler and
    # leave the file unfinished, so unwind normally and let the dispatcher set
    # the exit status.
    finish_report()
    return(invisible(list(pass = FALSE)))
  }

  cat("**Convergence: PASS** (all thresholds met)\n\n")

  # --- Headline estimates ---------------------------------------------------
  rt_row <- rt_all[rt_all$date == report_date, ]

  growth_all <- summary(fit, type = "parameters", params = "growth_rate")
  growth_row <- growth_all[growth_all$date == report_date, ]

  inf_all <- summary(fit, type = "parameters", params = "infections")
  inf_row <- inf_all[inf_all$date == report_date, ]

  obs_row <- fit$observations[fit$observations$date == report_date, ]
  obs_cases <- if (nrow(obs_row) > 0) format(obs_row$confirm, big.mark = ",") else "not observed"

  p_growth <- prob_rt_above_one(fit, rt_all, report_date)

  cat("## Transmission and nowcast estimates\n\n")
  cat("| Metric | Median (90% CrI) | Interpretation |\n")
  cat("| :--- | :--- | :--- |\n")

  if (is.na(p_growth)) {
    rt_interp <- "P(Rt > 1) could not be computed from draws"
  } else {
    direction <- if (p_growth > 0.5) "growing" else "declining"
    rt_interp <- sprintf("P(Rt > 1) = %.2f (%s)", p_growth, direction)
  }

  # The qualifier goes in the Rt row, not in a section below the table. A
  # caveat under its own heading is separated from the number by the first
  # person who copies the number out.
  rt_flag <- if (identical(caveats, NA_character_)) {
    " [parameter provenance not recorded for this fit]"
  } else if (length(caveats) > 0) {
    " [see caveats below; this Rt is conditional on them]"
  } else {
    ""
  }
  cat(sprintf("| Rt | %.2f (%.2f to %.2f) | %s%s |\n",
              rt_row$median, rt_row$lower_90, rt_row$upper_90, rt_interp, rt_flag))

  if (nrow(growth_row) == 1) {
    time_type <- if (growth_row$median >= 0) "Doubling time" else "Halving time"
    dt <- if (abs(growth_row$median) < 1e-8) {
      "not estimable (growth rate ~ 0)"
    } else {
      sprintf("~%.1f days", log(2) / abs(growth_row$median))
    }
    cat(sprintf("| Growth rate (r) | %.3f (%.3f to %.3f) | %s: %s |\n",
                growth_row$median, growth_row$lower_90, growth_row$upper_90,
                time_type, dt))
  }

  if (nrow(inf_row) == 1) {
    cat(sprintf("| New infections per day | %s (%s to %s) | Estimated infections, not reports |\n",
                format(round(inf_row$median), big.mark = ","),
                format(round(inf_row$lower_90), big.mark = ","),
                format(round(inf_row$upper_90), big.mark = ",")))
  }
  cat(sprintf("| Observed cases | %s | Raw reported count on reference date |\n\n", obs_cases))

  # --- Caveats --------------------------------------------------------------
  if (identical(caveats, NA_character_)) {
    cat("## Caveats\n\n")
    cat("Parameter provenance was not recorded for this fit, so whether published,\n")
    cat("substituted or default distributions were used cannot be determined from\n")
    cat("the fit object. Treat the estimates above as unattributed until the fit is\n")
    cat("reproduced with a version of `fit` that records it.\n\n")
  } else if (length(caveats) > 0) {
    cat("## Caveats\n\n")
    cat("These qualify every estimate above. Carry them with any number taken from\n")
    cat("this report.\n\n")
    for (cv in caveats) cat(sprintf("* %s\n", cv))
    cat("\n")
  }

  # --- Model specification as actually fitted -------------------------------
  cat("## Model specification (read from the fit)\n\n")
  cat(paste(describe_assumptions(fit), collapse = "\n"))
  cat("\n\n")

  # --- Sensitivity ----------------------------------------------------------
  if (!is.null(compare_path) && file.exists(compare_path)) {
    fit_comp <- readRDS(compare_path)
    comp_diag <- compute_diagnostics(fit_comp)
    comp_verdict <- assess_diagnostics(comp_diag)
    rt_comp <- summary(fit_comp, type = "parameters", params = "R")
    rt_comp_row <- rt_comp[rt_comp$date == report_date, ]

    cat("## Sensitivity comparison\n\n")
    if (!comp_verdict$pass) {
      cat("Comparison fit did not converge; its estimates are not shown.\n\n")
    } else if (nrow(rt_comp_row) == 1) {
      cat(sprintf("Alternate fit Rt = %.2f (%.2f to %.2f). Difference vs primary: %+.2f.\n\n",
                  rt_comp_row$median, rt_comp_row$lower_90, rt_comp_row$upper_90,
                  rt_comp_row$median - rt_row$median))
    } else {
      cat("Comparison fit does not cover the reference date.\n\n")
    }
  } else {
    cat("## Suggested sensitivity checks (not performed)\n\n")
    cat("These are suggestions for the user. This run tested none of them.\n")
    cat("Re-run `fit` with altered settings and pass the result via `--compare`.\n\n")
    cat("1. Generation time: vary the mean by +/- 1 day, or change the distribution shape.\n")
    cat("2. Rt prior: compare a weakly informative prior against a literature-informed one.\n")
    cat("3. Rt dynamics: test a weekly random walk (`--rw 7`) against the Gaussian process.\n")
    cat("4. Right truncation: if recent counts are incomplete, add `--trunc-dist`.\n")
    cat("5. Reporting delay: vary the delay mean to test nowcast stability at the tail.\n\n")
  }

  finish_report()
  invisible(list(pass = TRUE))
}


# Look up a distribution and return it as numbers, rather than as printed text.
# The substitution rule lives here so that `lookup-delay` and `init` cannot
# drift apart about when a serial interval stands in for a generation time.
#
# Returns NULL when nothing usable exists. An entry with no parameters counts
# as nothing usable: see has_usable_parameters.
epiparameter_lookup <- function(disease, param) {
  if (!requireNamespace("epiparameter", quietly = TRUE)) return(NULL)
  wants_gt <- grepl("generation", param, ignore.case = TRUE)
  substituted <- FALSE

  lookup <- function(nm) {
    tryCatch(
      epiparameter::epiparameter_db(
        disease = disease, epi_name = nm, single_epiparameter = TRUE
      ),
      error = function(e) NULL
    )
  }

  ep <- lookup(param)
  if (wants_gt && !has_usable_parameters(ep)) {
    ep_si <- lookup("serial interval")
    if (has_usable_parameters(ep_si)) {
      ep <- ep_si
      param <- "serial interval"
      substituted <- TRUE
    }
  }
  if (!has_usable_parameters(ep)) return(NULL)

  pars <- epiparameter::get_parameters(ep)
  family <- tryCatch(as.character(stats::family(ep$prob_distribution)),
                     error = function(e) NA_character_)

  # EpiNow2's LogNormal() and Gamma() take natural-scale mean and sd, so a
  # published meanlog/sdlog or shape/rate is converted here rather than being
  # passed through to mean something different.
  if (all(c("meanlog", "sdlog") %in% names(pars))) {
    ml <- pars[["meanlog"]]; sl <- pars[["sdlog"]]
    mean_v <- exp(ml + sl^2 / 2)
    sd_v <- mean_v * sqrt(exp(sl^2) - 1)
    dist <- "lognormal"
  } else if (all(c("shape", "rate") %in% names(pars))) {
    mean_v <- pars[["shape"]] / pars[["rate"]]
    sd_v <- sqrt(pars[["shape"]]) / pars[["rate"]]
    dist <- "gamma"
  } else if (all(c("shape", "scale") %in% names(pars))) {
    mean_v <- pars[["shape"]] * pars[["scale"]]
    sd_v <- sqrt(pars[["shape"]]) * pars[["scale"]]
    dist <- "gamma"
  } else if (all(c("mean", "sd") %in% names(pars))) {
    mean_v <- pars[["mean"]]; sd_v <- pars[["sd"]]
    dist <- if (identical(family, "lnorm")) "lognormal" else "gamma"
  } else {
    return(NULL)
  }

  max_v <- tryCatch({
    q <- stats::quantile(ep$prob_distribution, 0.999)
    max(7, ceiling(as.numeric(q)))
  }, error = function(e) NA_real_)
  if (!is.finite(max_v)) max_v <- 14

  returned_name <- tryCatch(as.character(ep$epi_name), error = function(e) NA_character_)
  returned_disease <- tryCatch(as.character(ep$disease), error = function(e) NA_character_)
  if (length(returned_name) != 1 || is.na(returned_name)) returned_name <- param
  if (length(returned_disease) != 1 || is.na(returned_disease)) returned_disease <- disease

  list(
    dist = dist, mean = round(as.numeric(mean_v), 3), sd = round(as.numeric(sd_v), 3),
    max = as.integer(max_v), substituted = substituted,
    name = returned_name, disease = returned_disease, ep = ep
  )
}

# --- Subcommand: estimate-truncation --------------------------------------
#
# Right truncation is a question the user is usually asked and usually cannot
# answer. If they hold earlier vintages of the same series, the data answers it
# instead: how much each vintage's recent counts were later revised upwards is
# exactly the truncation distribution.
cmd_estimate_truncation <- function(params) {
  vintages <- params[["vintages"]]
  config_path <- params[["config"]]
  seed <- if (!is.null(params[["seed"]])) as.integer(params[["seed"]]) else 20260915
  cores <- if (!is.null(params[["cores"]])) as.integer(params[["cores"]]) else 2

  if (is.null(vintages)) {
    stop("--vintages <dir> is required: a directory of CSV snapshots of the same ",
         "series taken on different days, each with 'date' and 'confirm'. ",
         "Without at least two vintages there is nothing to estimate from.")
  }
  files <- if (dir.exists(vintages)) {
    sort(list.files(vintages, pattern = "\\.csv$", full.names = TRUE))
  } else {
    sort(Sys.glob(vintages))
  }
  if (length(files) < 2) {
    stop("Found ", length(files), " vintage file(s) in '", vintages, "'. ",
         "At least 2 are needed: truncation is estimated from how later ",
         "vintages revise earlier ones.")
  }

  suppressPackageStartupMessages(library(EpiNow2))
  vin <- lapply(files, function(f) {
    d <- read.csv(f, stringsAsFactors = FALSE)
    missing_cols <- setdiff(c("date", "confirm"), names(d))
    if (length(missing_cols) > 0) {
      stop("Vintage ", basename(f), " is missing column(s): ",
           paste(missing_cols, collapse = ", "), ".")
    }
    d$date <- as.Date(d$date)
    d$confirm <- as.integer(d$confirm)
    d[order(d$date), c("date", "confirm")]
  })

  cat(sprintf("Estimating right truncation from %d vintages (%s to %s)...\n",
              length(vin), basename(files[1]), basename(files[length(files)])))
  est <- estimate_truncation(vin, stan = stan_opts(seed = seed, cores = cores), verbose = FALSE)

  cat("=== Estimated truncation distribution ===\n")
  print(est$dist)
  cat("=========================================\n")

  if (!is.null(config_path)) {
    cfg <- read_config(config_path)
    pars <- tryCatch(as.list(est$dist), error = function(e) NULL)
    mean_v <- tryCatch(as.numeric(mean(est$dist)), error = function(e) NA_real_)
    sd_v <- tryCatch(as.numeric(sd(est$dist)), error = function(e) NA_real_)
    max_v <- tryCatch(as.integer(max(est$dist)), error = function(e) NA_integer_)
    if (!is.finite(mean_v) || !is.finite(sd_v)) {
      cat("Could not reduce the fitted truncation to mean and sd; config not updated.\n")
    } else {
      cfg$truncation <- cfg_field(
        list(dist = "lognormal", mean = round(mean_v, 3), sd = round(sd_v, 3),
             max = if (is.finite(max_v)) max_v else 10L),
        "derived",
        sprintf("estimate_truncation() over %d vintages", length(vin))
      )
      write_config(cfg, config_path)
      cat(sprintf("Truncation written to %s.\n", config_path))
    }
  } else {
    cat("Pass --config <file> to write this into a config file.\n")
  }
  invisible(est)
}

# --- Regional reporting ---------------------------------------------------
#
# regional_epinow() returns one object per region that is itself an
# estimate_infections fit, so the diagnostics and the Rt extraction above apply
# unchanged. What changes is the gate: each region is judged on its own, and a
# run where any region failed cannot exit clean, because a table with a hole in
# it is easy to read as a table.
report_regional <- function(obj, caveats, date_str) {
  regions <- names(obj$regional)
  rows <- list()
  any_fail <- FALSE

  for (rg in regions) {
    est <- obj$regional[[rg]]
    if (is.null(est) || is.null(est$fit)) {
      rows[[rg]] <- list(region = rg, status = "ERROR", note = "region did not fit")
      any_fail <- TRUE
      next
    }
    diag <- tryCatch(compute_diagnostics(est), error = function(e) NULL)
    if (is.null(diag)) {
      rows[[rg]] <- list(region = rg, status = "ERROR", note = "diagnostics unavailable")
      any_fail <- TRUE
      next
    }
    verdict <- assess_diagnostics(diag)
    rt_all <- summary(est, type = "parameters", params = "R")
    available <- sort(unique(as.Date(rt_all$date)))
    report_date <- if (!is.null(date_str)) as.Date(date_str) else max(est$observations$date)
    if (!(report_date %in% available)) report_date <- max(available)

    row <- list(region = rg, status = if (verdict$pass) "PASS" else "FAIL",
                date = report_date, diag = diag, reasons = verdict$reasons)
    if (verdict$pass) {
      rt_row <- rt_all[rt_all$date == report_date, ]
      row$rt <- rt_row$median
      row$lo <- rt_row$lower_90
      row$hi <- rt_row$upper_90
      row$p <- prob_rt_above_one(est, rt_all, report_date)
    } else {
      any_fail <- TRUE
    }
    rows[[rg]] <- row
  }

  cat("\n# Routine Surveillance Transmission & Nowcast Summary (by region)\n")
  cat(sprintf("**Regions:** %d | **Engine:** EpiNow2 %s\n\n", length(regions),
              as.character(utils::packageVersion("EpiNow2"))))

  cat("## Estimates and diagnostics by region\n\n")
  cat("| Region | Convergence | Rt (90% CrI) | P(Rt > 1) | Max Rhat | Min ESS | Divergences |\n")
  cat("| :--- | :--- | :--- | ---: | ---: | ---: | ---: |\n")
  for (rg in regions) {
    r <- rows[[rg]]
    if (identical(r$status, "ERROR")) {
      cat(sprintf("| %s | ERROR | withheld | - | - | - | - |\n", rg))
    } else if (identical(r$status, "FAIL")) {
      cat(sprintf("| %s | FAIL | withheld | - | %.4f | %.0f | %d |\n",
                  rg, r$diag$max_rhat, r$diag$min_ess, r$diag$n_divergent))
    } else {
      cat(sprintf("| %s | PASS | %.2f (%.2f to %.2f) | %s | %.4f | %.0f | %d |\n",
                  rg, r$rt, r$lo, r$hi,
                  if (is.na(r$p)) "-" else sprintf("%.2f", r$p),
                  r$diag$max_rhat, r$diag$min_ess, r$diag$n_divergent))
    }
  }
  cat("\n")

  failed <- regions[vapply(regions, function(rg) !identical(rows[[rg]]$status, "PASS"), logical(1))]
  if (length(failed) > 0) {
    cat("## Regions with estimates withheld\n\n")
    cat("No Rt is reported for these. Either the region did not fit at all, or the\n")
    cat("sampler did not converge and the posterior it explored is not the model's\n")
    cat("posterior. The reason is given per region below. This run exits non-zero:\n")
    cat("a partial table is not a successful report.\n\n")
    for (rg in failed) {
      r <- rows[[rg]]
      cat(sprintf("* %s: %s\n", rg,
                  if (identical(r$status, "ERROR")) r$note else paste(r$reasons, collapse = "; ")))
    }
    cat("\nReconsider the model for these regions rather than refitting unchanged.\n")
    cat("A sparse region is often the cause: check its case counts before\n")
    cat("changing the model for every region.\n\n")
  }

  if (identical(caveats, NA_character_)) {
    cat("## Caveats\n\n")
    cat("Parameter provenance was not recorded for this fit, so whether published,\n")
    cat("substituted or default distributions were used cannot be determined from\n")
    cat("the fit object. Treat every estimate above as unattributed.\n\n")
  } else if (length(caveats) > 0) {
    cat("## Caveats\n\n")
    cat("These qualify every estimate above, in every region. Carry them with any\n")
    cat("number taken from this report.\n\n")
    for (cv in caveats) cat(sprintf("* %s\n", cv))
    cat("\n")
  }

  invisible(list(pass = !any_fail, rows = rows))
}

# --- Config into flags ----------------------------------------------------
#
# The config supplies anything the caller did not. Doing it this way, rather
# than threading a config object through `fit`, keeps one code path: a value
# from the file is indistinguishable downstream from the same value typed as a
# flag, and an explicit flag always wins because it is already set.
apply_config_to_params <- function(params, cfg) {
  set <- function(p, key, val) {
    if (is.null(p[[key]]) && !is.null(val)) p[[key]] <- val
    p
  }
  params <- set(params, "data", cfg_value(cfg, "data"))

  gt <- cfg_value(cfg, "generation_time")
  if (!is.null(gt)) {
    params <- set(params, "gt-dist", gt$dist)
    params <- set(params, "gt-mean", gt$mean)
    params <- set(params, "gt-sd", gt$sd)
    params <- set(params, "gt-max", gt$max)
    if (isTRUE(gt$substituted)) params <- set(params, "gt-substituted", TRUE)
  }
  dl <- cfg_value(cfg, "delay")
  if (!is.null(dl)) {
    params <- set(params, "delay-dist", dl$dist)
    params <- set(params, "delay-mean", dl$mean)
    params <- set(params, "delay-sd", dl$sd)
    params <- set(params, "delay-max", dl$max)
  }
  tr <- cfg_value(cfg, "truncation")
  if (!is.null(tr)) {
    params <- set(params, "trunc-dist", tr$dist)
    params <- set(params, "trunc-mean", tr$mean)
    params <- set(params, "trunc-sd", tr$sd)
    params <- set(params, "trunc-max", tr$max)
  }
  dyn <- cfg_value(cfg, "dynamics")
  if (!is.null(dyn)) {
    if (identical(dyn$type, "rw")) {
      params <- set(params, "rw", dyn$step)
    } else if (identical(dyn$type, "gp") && !is.null(dyn$ls)) {
      params <- set(params, "gp-ls", dyn$ls)
    }
  }
  we <- cfg_value(cfg, "week_effect")
  if (!is.null(we)) params <- set(params, "week-effect", if (isTRUE(we)) "true" else "false")
  rp <- cfg_value(cfg, "rt_prior")
  if (!is.null(rp)) {
    params <- set(params, "r-prior-mean", rp$mean)
    params <- set(params, "r-prior-sd", rp$sd)
  }
  st <- cfg_value(cfg, "stan")
  if (!is.null(st)) {
    params <- set(params, "seed", st$seed)
    params <- set(params, "cores", st$cores)
  }
  br <- cfg_value(cfg, "by_region")
  if (isTRUE(br)) params <- set(params, "by-region", TRUE)
  params
}

# --- Subcommand: init -----------------------------------------------------
#
# Works out everything about the fit that can be worked out, records where each
# value came from, and writes the result as a config file. What it cannot
# determine is written as missing rather than guessed, and what it inferred from
# fallible evidence is labelled so the user knows to check it.
#
# The point is the order of operations: the user reviews a specification that
# already exists instead of answering a sequence of questions that builds one.

# Dynamics are chosen by a stated rule so that the choice is reproducible and
# testable. A Gaussian process needs enough series to estimate a length scale;
# a short series or known step changes are a random walk's job.
choose_dynamics <- function(n_days, has_steps) {
  if (has_steps) {
    return(cfg_field(list(type = "rw", step = 7), "inferred",
                     "intervention dates supplied, so change is treated as stepwise"))
  }
  if (n_days < 42) {
    return(cfg_field(list(type = "rw", step = 7), "inferred",
                     sprintf("series is %d days; too short to estimate a GP length scale", n_days)))
  }
  ls <- if (n_days >= 90) 21 else 14
  cfg_field(list(type = "gp", ls = ls), "inferred",
            sprintf("series is %d days with no step changes given; GP length scale %d days", n_days, ls))
}

# A published distribution, as a config block. Returns NULL when epiparameter
# has nothing usable, which is written into the config as missing.
lookup_dist_field <- function(disease, param) {
  if (!requireNamespace("epiparameter", quietly = TRUE)) return(NULL)
  res <- epiparameter_lookup(disease, param)
  if (is.null(res)) return(NULL)
  value <- list(
    dist = res$dist, mean = res$mean, sd = res$sd, max = res$max,
    substituted = res$substituted
  )
  evidence <- sprintf("epiparameter: %s, %s%s", res$disease, res$name,
                      if (res$substituted) " (SUBSTITUTED for a generation time)" else "")
  cfg_field(value, "inferred", evidence)
}

cmd_init <- function(params) {
  data_path <- params[["data"]]
  out_path <- if (!is.null(params[["out"]])) params[["out"]] else "nowcast.yaml"
  cases_out <- if (!is.null(params[["cases-out"]])) params[["cases-out"]] else "outputs/cases.csv"
  disease <- params[["disease"]]
  date_col_param <- params[["date-column"]]
  date_type_param <- params[["date-type"]]
  has_steps <- !is.null(params[["intervention-dates"]])

  if (is.null(data_path)) stop("init requires --data <path>.")
  if (!file.exists(data_path)) stop("Data file not found: ", data_path)
  df <- read.csv(data_path, stringsAsFactors = FALSE)
  info <- inspect_data(df)

  if (nrow(info$dates) == 0) {
    stop("No date column found in ", data_path, ". Expected at least one column ",
         "whose values parse as dates.")
  }

  cat("=== Data inspection ===\n")
  cat(sprintf("Rows: %d | Shape: %s\n", info$n_rows, info$shape))
  cat("\nCandidate date columns:\n")
  cat("| Column | Name suggests | Complete | Range |\n")
  cat("| :--- | :--- | ---: | :--- |\n")
  for (i in seq_len(nrow(info$dates))) {
    r <- info$dates[i, ]
    cat(sprintf("| %s | %s | %.1f%% | %s to %s |\n", r$column,
                if (is.na(r$type_guess)) "nothing" else r$type_guess,
                r$pct_complete, format(r$min_date), format(r$max_date)))
  }
  cat("\n")

  # --- Date column ---------------------------------------------------------
  # Completeness decides what can be fitted, so it is the rule here, and the
  # cost of the choice (rows that will be dropped) is always reported.
  if (!is.null(date_col_param)) {
    if (!date_col_param %in% info$dates$column) {
      stop("--date-column '", date_col_param, "' is not a date column in this file. ",
           "Found: ", paste(info$dates$column, collapse = ", "), ".")
    }
    chosen <- date_col_param
    date_col_field <- cfg_field(chosen, "user", "supplied with --date-column")
  } else {
    chosen <- info$dates$column[1]
    pct <- info$dates$pct_complete[1]
    ev <- if (nrow(info$dates) == 1) {
      sprintf("only date column in the file, %.1f%% complete", pct)
    } else {
      sprintf("most complete of %d date columns (%.1f%%, next is %s at %.1f%%)",
              nrow(info$dates), pct, info$dates$column[2], info$dates$pct_complete[2])
    }
    date_col_field <- cfg_field(chosen, if (nrow(info$dates) == 1) "derived" else "inferred", ev)
  }

  dates_all <- parse_date_column(df[[chosen]])
  n_missing_date <- sum(is.na(dates_all))
  if (n_missing_date > 0) {
    cat(sprintf("Note: %d of %d rows (%.1f%%) have no %s and will be excluded.\n",
                n_missing_date, nrow(df), 100 * n_missing_date / nrow(df), chosen))
  }

  # --- Daily series --------------------------------------------------------
  # An aggregate file already has one row per date (per region); a linelist has
  # one row per case and has to be counted. Doing the region split inside each
  # branch keeps the row counts aligned: tabulating first and attaching regions
  # afterwards mismatches, because tabulation changes the number of rows.
  keep <- !is.na(dates_all)
  region_vals <- if (!is.null(info$region_column)) {
    as.character(df[[info$region_column]][keep])
  } else {
    NULL
  }
  if (identical(info$shape, "aggregate")) {
    series <- data.frame(date = dates_all[keep],
                         confirm = as.integer(df[[info$count_column]][keep]),
                         stringsAsFactors = FALSE)
    if (!is.null(region_vals)) series$region <- region_vals
  } else if (is.null(region_vals)) {
    series <- as.data.frame(table(dates_all[keep]), stringsAsFactors = FALSE)
    names(series) <- c("date", "confirm")
    series$date <- as.Date(series$date)
    series$confirm <- as.integer(series$confirm)
  } else {
    series <- as.data.frame(table(dates_all[keep], region_vals), stringsAsFactors = FALSE)
    names(series) <- c("date", "region", "confirm")
    series$date <- as.Date(series$date)
    series$confirm <- as.integer(series$confirm)
  }
  if (!is.null(region_vals)) {
    series <- series[order(series$region, series$date), c("date", "confirm", "region")]
  } else {
    series <- series[order(series$date), ]
  }

  pooled <- if (is.null(info$region_column)) series else {
    agg <- aggregate(confirm ~ date, data = series, FUN = sum)
    agg[order(agg$date), ]
  }
  n_days <- as.integer(max(pooled$date) - min(pooled$date) + 1)

  # EpiNow2 needs an unbroken daily sequence. Whether a date with no row means
  # no cases or no report is the user's call, so the gap is reported rather
  # than filled: zero-filling an unreported day invents an observation.
  if (nrow(pooled) < n_days) {
    cat(sprintf("\nWarning: %d of %d calendar days have no row. EpiNow2 requires an\n",
                n_days - nrow(pooled), n_days))
    cat("unbroken daily series. If the missing days are genuine zeros, fill them with:\n")
    cat(sprintf("  triage --data %s --fill-zeros --cases-out %s\n", data_path, cases_out))
    cat("If they are unreported days, they are missing data and zero-filling would\n")
    cat("invent observations; trim the series to the reported period instead.\n")
  }

  # --- Date type -----------------------------------------------------------
  # Two weak signals, neither of which is allowed to settle the question on its
  # own: what the column is called, and whether the counts run on a weekly
  # administrative cycle. An aggregate series called `date` gives neither.
  wk <- week_cycle_evidence(pooled$date, pooled$confirm)
  name_guess <- classify_date_name(chosen)

  date_type_field <- if (!is.null(date_type_param)) {
    if (!date_type_param %in% c("report", "onset", "specimen", "admission")) {
      stop("--date-type must be one of report, onset, specimen, admission; got '",
           date_type_param, "'.")
    }
    cfg_field(date_type_param, "user", "supplied with --date-type")
  } else if (!is.na(name_guess)) {
    cfg_field(name_guess, "inferred",
              sprintf("column name '%s' suggests %s; %s", chosen, name_guess, wk$reason))
  } else if (identical(wk$verdict, "cycle")) {
    cfg_field("report", "inferred",
              sprintf("column name carries no signal; counts show a weekly cycle (%s), consistent with an administrative reporting date", wk$reason))
  } else if (identical(wk$verdict, "no cycle")) {
    cfg_field("onset", "inferred",
              sprintf("column name carries no signal; counts show no weekly cycle (%s), consistent with symptom onset", wk$reason))
  } else {
    cfg_field(NULL, "missing",
              sprintf("column name carries no signal and the counts are %s. Set --date-type.", wk$reason))
  }

  # --- Distributions -------------------------------------------------------
  gt_field <- if (!is.null(disease)) lookup_dist_field(disease, "generation time") else NULL
  if (is.null(gt_field)) {
    gt_field <- cfg_field(NULL, "missing", if (is.null(disease)) {
      "no --disease given; look one up with lookup-delay or supply the numbers"
    } else {
      sprintf("epiparameter has no usable generation time or serial interval for '%s'", disease)
    })
  }
  delay_field <- if (!is.null(disease)) lookup_dist_field(disease, "incubation period") else NULL
  if (is.null(delay_field)) {
    delay_field <- cfg_field(NULL, "missing",
      "estimate it from your own linelist with estimate-delay, or supply the numbers")
  }

  trunc_field <- cfg_field(NULL, "missing",
    "no data vintages supplied; run estimate-truncation with --vintages to estimate it, or leave unset if recent counts are complete")

  # --- Assemble ------------------------------------------------------------
  cfg <- list(
    data = cfg_field(cases_out, "derived", sprintf("cleaned daily series written from %s", data_path)),
    date_column = date_col_field,
    date_type = date_type_field,
    regions = cfg_field(info$regions, if (is.null(info$region_column)) "derived" else "derived",
                        if (is.null(info$region_column)) "no region column in the data"
                        else sprintf("from column '%s'", info$region_column)),
    by_region = cfg_field(length(info$regions) > 1, "derived",
                          sprintf("%d region(s) detected", length(info$regions))),
    generation_time = gt_field,
    delay = delay_field,
    truncation = trunc_field,
    dynamics = choose_dynamics(n_days, has_steps),
    rt_prior = cfg_field(list(mean = 2.0, sd = 1.0), "derived", "package-conventional weakly informative prior"),
    stan = cfg_field(list(seed = 20260915, cores = 4), "derived", "defaults")
  )
  cfg <- derive_week_effect(cfg)

  # --- Sparse regions ------------------------------------------------------
  # Named here rather than left to fail inside the sampler, where the message
  # would be about Stan rather than about the data.
  if (length(info$regions) > 1) {
    per_region <- tapply(series$confirm, series$region, function(x) c(n = length(x), total = sum(x)))
    sparse <- names(per_region)[vapply(per_region, function(x) x[["n"]] < 21 || x[["total"]] < 50, logical(1))]
    if (length(sparse) > 0) {
      cat(sprintf("\nWarning: %d region(s) have under 21 days or under 50 total cases: %s\n",
                  length(sparse), paste(sparse, collapse = ", ")))
      cat("Fitting these separately is unlikely to converge. Drop them, or pool with --pool.\n")
    }
  }

  dir.create(dirname(cases_out), showWarnings = FALSE, recursive = TRUE)
  write.csv(series, cases_out, row.names = FALSE)
  write_config(cfg, out_path)

  cat("\n=== Proposed specification ===\n\n")
  print_config_table(cfg)

  review <- config_review_items(cfg)
  gaps <- config_gaps(cfg)
  cat(sprintf("\nDaily series written to: %s\n", cases_out))
  cat(sprintf("Config written to:       %s\n\n", out_path))
  if (length(review) > 0) {
    cat("Check these before fitting. Everything else was computed from the data:\n")
    for (nm in review) {
      cat(sprintf("  - %s (%s): %s\n", nm, cfg[[nm]]$source,
                  if (is.null(cfg[[nm]]$evidence)) "" else cfg[[nm]]$evidence))
    }
    cat("\n")
  }
  if (length(gaps) > 0) {
    cat(sprintf("fit will refuse until these are set: %s\n", paste(gaps, collapse = ", ")))
  } else {
    cat("No required field is missing. Next: fit --config ", out_path, "\n", sep = "")
  }
  cat("==============================\n")
  invisible(cfg)
}

# Main dispatcher
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cat("EpiNow2 routine surveillance nowcast CLI\n\n")
  cat("Subcommands:\n\n")
  cat("  init           Inspect data, work out what can be worked out, and write a\n")
  cat("                 config file recording where every value came from.\n")
  cat("    --data <path>            Input CSV (linelist or daily counts).\n")
  cat("    --out <path>             Config to write (default nowcast.yaml).\n")
  cat("    --cases-out <path>       Cleaned daily series (default outputs/cases.csv).\n")
  cat("    --disease <str>          Look up published parameters for this disease.\n")
  cat("    --date-column <col>      Use this date column instead of the most complete.\n")
  cat("    --date-type <report|onset|specimen|admission>  Settle the date type.\n")
  cat("    --intervention-dates <str>  Known step changes; selects a random walk.\n\n")
  cat("  estimate-truncation  Estimate right truncation from data vintages.\n")
  cat("    --vintages <dir|glob>    Two or more CSV snapshots of the same series.\n")
  cat("    --config <path>          Write the fitted distribution into this config.\n")
  cat("    --seed <int>  --cores <int>\n\n")
  cat("  triage         Inspect surveillance data and recommend a delay structure.\n")
  cat("    --data <path>            Input CSV (linelist or daily counts).\n")
  cat("    --cases-out <path>       Write cleaned daily counts (date, confirm).\n")
  cat("    --delays-out <path>      Write event date pairs for estimate-delay.\n")
  cat("    --date-type <report|onset>  Override the inferred reference date type.\n")
  cat("    --fill-zeros             Pad missing calendar dates with zero counts.\n\n")
  cat("  lookup-delay   Retrieve a published distribution from epiparameter.\n")
  cat("    --disease <str>          Disease name as spelled in the database.\n")
  cat("    --param <str>            e.g. 'serial interval', 'incubation period'.\n")
  cat("                             'generation time' returns the serial interval,\n")
  cat("                             flagged as a substitution.\n\n")
  cat("  estimate-delay Fit a delay distribution to observed event pairs.\n")
  cat("    --delays <csv>           CSV with pdate_lwr and sdate_lwr date columns.\n")
  cat("    --dist <lognormal|gamma> Distribution family (default lognormal).\n")
  cat("    --seed <int>  --cores <int>\n\n")
  cat("  fit            Fit the renewal model.\n")
  cat("    --config <path>          Read the specification from a config file.\n")
  cat("                             Explicit flags below override it.\n")
  cat("    --pool                   Sum regions into one series before fitting.\n")
  cat("    --data <path>            Daily counts with 'date' and 'confirm'.\n")
  cat("    --gt-substituted         Record that the generation time is a serial\n")
  cat("                             interval, carried into the report's caveats.\n")
  cat("    --gt-mean/-sd/-max <num> Generation time. Required, no default.\n")
  cat("    --gt-dist <lognormal|gamma>\n")
  cat("    --delay-mean/-sd/-max <num>  Infection-to-observation delay. Required.\n")
  cat("    --delay-dist <lognormal|gamma>\n")
  cat("    --week-effect <true|false>   Day-of-week reporting effect (default true).\n")
  cat("    --r-prior-mean/-sd <num>     Rt prior (default 2.0 / 1.0).\n")
  cat("    --rw <int>               Random walk step in days (overrides GP).\n")
  cat("    --gp-ls <num>            GP length scale in days; must be >= 7.\n")
  cat("    --allow-short-gp         Override the length scale guard.\n")
  cat("    --dry-run                Print the resolved specification, fit nothing.\n")
  cat("    --trunc-dist <none|lognormal|gamma>  Right-truncation adjustment.\n")
  cat("    --trunc-mean/-sd/-max <num>\n")
  cat("    --seed <int>  --cores <int>  --output-dir <dir>\n\n")
  cat("  evaluate       Check convergence, then report estimates.\n")
  cat("    --fit <fit.rds>          Fit to evaluate.\n")
  cat("    --compare <fit.rds>      Second fit for sensitivity comparison.\n")
  cat("    --date YYYY-MM-DD        Reference date (must be in the fitted period).\n")
  cat("    --report-out <path>      Also write the report to this file.\n")
  cat("    Exits non-zero and withholds estimates if convergence fails. A failed\n")
  cat("    run still writes its report, recording that no estimate was produced.\n")
  quit(status = 0)
}

params <- parse_args(args)
subcmd <- params[["subcommand"]]

if (identical(subcmd, "init")) {
  cmd_init(params)
} else if (identical(subcmd, "estimate-truncation")) {
  cmd_estimate_truncation(params)
} else if (identical(subcmd, "triage") || identical(subcmd, "describe")) {
  cmd_triage(params)
} else if (identical(subcmd, "lookup-delay")) {
  cmd_lookup_delay(params)
} else if (identical(subcmd, "estimate-delay")) {
  cmd_estimate_delay(params)
} else if (identical(subcmd, "fit")) {
  cmd_fit(params)
} else if (identical(subcmd, "evaluate") || identical(subcmd, "report")) {
  # A failed convergence gate must still exit non-zero, so a calling script or
  # workflow cannot treat a withheld estimate as a successful report.
  result <- cmd_evaluate(params)
  if (is.list(result) && isFALSE(result$pass)) quit(status = 1)
} else {
  cat("Unknown subcommand:", subcmd, "\n")
  quit(status = 1)
}
