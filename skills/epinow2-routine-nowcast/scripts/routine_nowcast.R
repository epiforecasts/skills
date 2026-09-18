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

      # Infer date type from column name or explicit flag
      if (!is.null(date_type_param)) {
        date_type_inferred <- tolower(date_type_param)
      } else if (grepl("onset", date_col_name, ignore.case = TRUE)) {
        date_type_inferred <- "onset"
      } else {
        date_type_inferred <- "report"
      }

      df$date <- as.Date(df[[date_col_name]])
      df$confirm <- as.integer(df[[confirm_col_name]])
      df <- df[, c("date", "confirm")]
    } else {
      stop("Could not recognise surveillance data format. Expected either daily counts ('date', 'confirm') or linelist with onset and report dates.")
    }
  }

  # Print date-type recommendations
  if (identical(date_type_inferred, "onset")) {
    cat("Reference Date Type: Symptom Onset Date\n")
    cat("  - Delay Specification: Incubation period only (no reporting delay needed)\n")
    cat("  - Observation Model: pass --week-effect false to `fit` (biological symptom onset does not follow administrative weekly reporting cycles)\n")
    cat("  - Right-Truncation Guardrail: Recent onset counts suffer from unobserved onset lags (artificial drop at time series tail)\n")
  } else {
    cat("Reference Date Type: Notification / Report Date\n")
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
    cases <- cases[, c("date", "confirm")]
    cases$date <- as.Date(cases$date)
    cases$confirm <- as.integer(cases$confirm)
    if (any(is.na(cases$date))) stop("Some 'date' values could not be parsed as dates.")
    if (any(cases$confirm < 0, na.rm = TRUE)) stop("Data contains negative case counts.")
    gaps <- as.integer(diff(sort(cases$date)))
    if (length(gaps) > 0 && any(gaps != 1)) {
      stop("Dates are not a contiguous daily sequence. EpiNow2 requires unbroken ",
           "daily data. Fix with: triage --data <file> --fill-zeros --cases-out <clean file>.")
    }
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

  fit <- estimate_infections(
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

# Main dispatcher
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cat("EpiNow2 routine surveillance nowcast CLI\n\n")
  cat("Subcommands:\n\n")
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

if (identical(subcmd, "triage") || identical(subcmd, "describe")) {
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
