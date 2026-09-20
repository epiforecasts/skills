# Sourced by epinow2.R. Builds the specification: distributions, data
# inspection, init, lookup-delay, estimate-delay, estimate-truncation.

# --- Distributions ----------------------------------------------------------
#
# One form, in the config and internally: list(dist, <parameters>, max). The
# parameters are what the source gave, passed to EpiNow2's constructor as
# they are, so nothing is converted between families:
#   flags          list(dist = "gamma", mean = 3, sd = 1)
#   epiparameter   list(dist = "weibull", shape = 2.36, scale = 3.18, max = 8)
#   estimators     list(dist = "lognormal", meanlog = list(mean = 1.1, sd = 0.03), ...)
#   a PMF          list(dist = "nonparametric", pmf = c(0, 0.2, 0.5, 0.3))
# A parameter written as list(mean, sd) is uncertain and becomes a Normal
# prior. An unset max is left to EpiNow2, which truncates at the 99.9th
# percentile.

DIST_CTORS <- c(lognormal = "LogNormal", gamma = "Gamma", weibull = "Weibull", exp = "Exp",
                nonparametric = "NonParametric")
DIST_PARAMS <- c("mean", "sd", "meanlog", "sdlog", "shape", "scale", "rate", "pmf")
DIST_META <- c("dist", "max", "substituted")

dist_value_from_flags <- function(params, prefix, label) {
  get <- function(s) params[[paste0(prefix, "-", s)]]
  given <- DIST_PARAMS[!vapply(DIST_PARAMS, function(s) is.null(get(s)), logical(1))]
  if (length(given) == 0 && is.null(get("dist")) && is.null(get("max"))) return(NULL)
  if (length(given) == 0) stop(label, ": give the distribution's parameters, e.g. --", prefix, "-mean and --", prefix, "-sd.")
  dn <- if (!is.null(get("dist"))) get("dist") else if ("pmf" %in% given) "nonparametric" else "lognormal"
  v <- list(dist = tolower(dn))
  for (s in c(given, if (!is.null(get("max"))) "max")) {
    x <- suppressWarnings(as.numeric(strsplit(as.character(get(s)), ",")[[1]]))
    if (length(x) == 0 || any(!is.finite(x)) || (s != "pmf" && length(x) != 1)) {
      stop(label, ": --", prefix, "-", s, " must be a number", if (s == "pmf") "s separated by commas", ".")
    }
    v[[s]] <- x
  }
  v
}

# The renewal model takes lognormal and gamma distributions as they are. A
# Weibull or an exponential goes in as EpiNow2's discretisation of it, which
# needs fixed parameters. A generation time cannot be zero days, so EpiNow2
# drops day 0 from any generation time and renormalises; a PMF passed in for
# one gets the same.
dist_from_value <- function(v, label, gt = FALSE) {
  if (!isTRUE(v$dist %in% names(DIST_CTORS))) {
    stop(label, ": family must be one of ", paste(names(DIST_CTORS), collapse = ", "), "; got '", v$dist, "'.")
  }
  if (v$dist == "nonparametric") {
    pmf <- as.numeric(unlist(v$pmf))
  } else {
    args <- lapply(v[setdiff(names(v), DIST_META)], function(p) {
      if (is.list(p)) Normal(mean = as.numeric(p$mean), sd = as.numeric(p$sd)) else as.numeric(p)
    })
    if (!is.null(v$max)) args$max <- as.numeric(v$max)
    discrete <- v$dist %in% c("weibull", "exp")
    if (discrete && is.null(v$max)) args$cdf_cutoff <- 0.001
    d <- tryCatch(do.call(DIST_CTORS[[v$dist]], args), error = function(e) stop(label, ": ", conditionMessage(e), call. = FALSE))
    if (!discrete) return(d)
    if (any(vapply(args, is.list, logical(1)))) stop(label, ": the renewal model takes a ", v$dist, " only with fixed parameters.")
    pmf <- get_pmf(discretise(d))
  }
  if (gt) pmf[1] <- 0
  NonParametric(pmf / sum(pmf))
}

# The natural mean is added where EpiNow2 can compute it (fixed parameters).
# A prior is not a delay and has no max.
describe_dist_value <- function(v, bounded = TRUE) {
  if (is.null(v) || identical(v, "none")) return("none")
  pars <- v[setdiff(names(v), DIST_META)]
  body <- paste(vapply(names(pars), function(nm) {
    p <- pars[[nm]]
    if (is.list(p)) sprintf("%s ~ Normal(%.3f, %.3f)", nm, as.numeric(p$mean), as.numeric(p$sd))
    else paste0(nm, " = ", paste(sprintf("%.3f", as.numeric(p)), collapse = "/"))
  }, character(1)), collapse = ", ")
  m <- if ("mean" %in% names(pars)) NA else tryCatch(mean(dist_from_value(v, "")), error = function(e) NA)
  mx <- if (!bounded || v$dist == "nonparametric") NULL else if (is.null(v$max)) "max = 99.9th percentile" else sprintf("max = %s", v$max)
  sprintf("%s(%s)%s", v$dist, paste(c(body, mx), collapse = ", "),
          if (isTRUE(is.finite(m))) sprintf(", mean %.2f", m) else "")
}

# The fitted distribution from estimate_dist() or estimate_truncation().
dist_value_from_spec <- function(ds) {
  pars <- lapply(ds$parameters, function(p) {
    if (inherits(p, "dist_spec")) list(mean = round(as.numeric(p$parameters$mean), 4), sd = round(as.numeric(p$parameters$sd), 4))
    else round(as.numeric(p), 4)
  })
  mx <- attr(ds, "max")
  c(list(dist = ds$distribution), pars, if (!is.null(mx) && is.finite(mx)) list(max = as.integer(mx)))
}

# --- Data inspection --------------------------------------------------------
#
# What a date column is called is weak evidence about what it means, and so is
# whether the counts run on a weekly cycle. Neither is proof, so both are
# reported and the inference they support is labelled as an inference.

DATE_TYPE_PATTERNS <- c(onset = "onset|symptom", specimen = "specimen|sample|swab|test",
                        report = "report|notif|confirm", admission = "admission|admit|hosp",
                        death = "death|died|dod")

classify_date_name <- function(nm) {
  hit <- names(DATE_TYPE_PATTERNS)[vapply(DATE_TYPE_PATTERNS, grepl, logical(1), x = tolower(nm))]
  if (length(hit) > 0) hit[1] else NA_character_
}

# A column counts as dates if most non-blank values parse. Numeric columns are
# never dates: small integer counts would otherwise read as days since 1970.
parse_date_column <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (is.numeric(x)) return(NULL)
  chr <- as.character(x)
  chr[trimws(chr) == ""] <- NA
  if (all(is.na(chr))) return(NULL)
  parsed <- tryCatch(suppressWarnings(as.Date(chr)), error = function(e) NULL)
  if (is.null(parsed) || sum(!is.na(parsed)) < 0.5 * sum(!is.na(chr))) return(NULL)
  parsed
}

# Every candidate date column with its completeness, most complete first.
date_candidates <- function(df) {
  out <- lapply(names(df), function(nm) {
    parsed <- parse_date_column(df[[nm]])
    if (is.null(parsed) || all(is.na(parsed))) return(NULL)
    data.frame(column = nm, type_guess = classify_date_name(nm), pct_complete = 100 * mean(!is.na(parsed)),
               min_date = min(parsed, na.rm = TRUE), max_date = max(parsed, na.rm = TRUE), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, out[!vapply(out, is.null, logical(1))])
  if (is.null(out)) return(data.frame(column = character(0)))
  out[order(-out$pct_complete), , drop = FALSE]
}

# Day-of-week structure in a daily series: the spread of weekday means of
# counts relative to a centred 7-day average.
week_cycle_evidence <- function(dates, counts) {
  ord <- order(dates)
  dates <- dates[ord]
  counts <- as.numeric(counts[ord])
  n <- length(counts)
  if (n < 28) return(list(verdict = "inconclusive", reason = sprintf("series is %d days; at least 28 needed", n)))
  roll <- as.numeric(stats::filter(counts, rep(1 / 7, 7), sides = 2))
  ok <- !is.na(roll) & roll > 0
  if (sum(ok) < 21) return(list(verdict = "inconclusive", reason = "too many zero or missing counts to compare weekdays"))
  by_day <- tapply(counts[ok] / roll[ok], weekdays(dates[ok]), mean)
  if (length(by_day) < 7) return(list(verdict = "inconclusive", reason = "not all weekdays observed"))
  amp <- as.numeric(max(by_day) - min(by_day))
  list(verdict = if (amp >= 0.25) "cycle" else if (amp <= 0.10) "no cycle" else "inconclusive",
       reason = sprintf("weekday amplitude %.2f over %d days (lowest %s, highest %s)", amp, n,
                        names(by_day)[which.min(by_day)], names(by_day)[which.max(by_day)]))
}

COUNT_NAMES <- c("confirm", "cases", "count", "counts", "new_cases", "confirmed", "n")

inspect_data <- function(df) {
  cands <- date_candidates(df)
  count_hit <- names(df)[tolower(names(df)) %in% COUNT_NAMES]
  list(shape = if (nrow(cands) == 0) "unknown" else if (length(count_hit) > 0) "aggregate" else "linelist",
       dates = cands, count_column = if (length(count_hit) > 0) count_hit[1] else NULL)
}

# Columns that could split the series into strata: not a date or the count,
# not numeric, 2 to 50 distinct values. In aggregate counts a stratum column
# must also separate the rows that share a date.
strata_candidates <- function(df, exclude, dates = NULL) {
  Filter(function(nm) {
    x <- df[[nm]]
    k <- length(unique(x[!is.na(x)]))
    !is.numeric(x) && k >= 2 && k <= 50 && (is.null(dates) || !anyDuplicated(data.frame(dates, x)))
  }, setdiff(names(df), exclude))
}

# The series EpiNow2 fits, built from the user's file with the choices in the
# config, so init and fit build it the same way. A linelist is counted by day,
# split by stratum in the same step: tabulating first and attaching strata
# afterwards mismatches the rows. Aggregate rows that share a date with no
# stratum column are summed. Aggregate counts dated 7 days apart are weekly:
# EpiNow2 takes each as the total of the 7 days ending on its date. Dates with
# no row are zeros in a linelist, so they are filled; in aggregate counts they
# may be zeros or unreported, so they are filled only when fill_zeros is set.
build_series <- function(df, date_col, count_col, strata_col = NULL, week_start = FALSE, fill_zeros = FALSE) {
  dates <- parse_date_column(df[[date_col]])
  if (is.null(dates)) stop("Column '", date_col, "' is missing or does not hold dates.")
  if (!is.null(strata_col) && !strata_col %in% names(df)) stop("Stratum column '", strata_col, "' is missing.")
  keep <- !is.na(dates)
  strata <- if (is.null(strata_col)) NULL else as.character(df[[strata_col]][keep])
  summed <- FALSE
  if (!is.null(count_col)) {
    series <- data.frame(date = dates[keep], confirm = as.integer(df[[count_col]][keep]))
    if (!is.null(strata)) series$region <- strata
    else if (anyDuplicated(series$date) > 0) {
      series <- aggregate(confirm ~ date, data = series, FUN = sum)
      summed <- TRUE
    }
  } else {
    tab <- if (is.null(strata)) table(dates[keep]) else table(dates[keep], strata)
    series <- as.data.frame(tab, stringsAsFactors = FALSE)
    names(series) <- c("date", if (!is.null(strata)) "region", "confirm")
    series$date <- as.Date(series$date)
    series$confirm <- as.integer(series$confirm)
  }
  groups <- if (is.null(strata)) list(series) else split(series, series$region)
  weekly <- !is.null(count_col) && all(vapply(groups, function(g) {
    d <- as.integer(diff(sort(g$date)))
    length(d) > 0 && all(d %% 7 == 0)
  }, logical(1)))
  step <- if (weekly) 7L else 1L
  if (weekly && week_start) groups <- lapply(groups, function(g) transform(g, date = date + 6L))
  n_gap <- sum(vapply(groups, function(g) as.integer(diff(range(g$date))) %/% step + 1L - nrow(g), integer(1)))
  filled <- n_gap > 0 && (is.null(count_col) || fill_zeros)
  if (filled) {
    groups <- lapply(groups, function(g) {
      full <- data.frame(date = seq(min(g$date), max(g$date), by = step))
      g <- merge(full, g, by = "date", all.x = TRUE)
      g$confirm[is.na(g$confirm)] <- 0L
      if ("region" %in% names(g)) g$region <- g$region[!is.na(g$region)][1]
      g
    })
  }
  series <- do.call(rbind, groups)
  series <- series[order(if (is.null(strata)) series$date else paste(series$region, series$date)),
                   intersect(c("date", "confirm", "region"), names(series))]
  list(series = series, weekly = weekly, step = step, n_gap = n_gap, filled = filled, summed = summed)
}

# --- epiparameter -----------------------------------------------------------
#
# An entry can exist without a usable distribution: 11 of 125 in epiparameter
# 0.4.1 carry no parameters, one of the three generation times among them. A
# generation time request falls back to the serial interval only where no
# usable generation time exists.

has_usable_parameters <- function(ep) {
  if (is.null(ep)) return(FALSE)
  pars <- tryCatch(epiparameter::get_parameters(ep), error = function(e) NULL)
  length(pars) > 0 && !all(is.na(unlist(pars)))
}

# Returns list(status = "ok" | "empty" | "none" | "unsupported", ...).
epiparameter_lookup <- function(disease, param) {
  lookup <- function(nm) {
    tryCatch(epiparameter::epiparameter_db(disease = disease, epi_name = nm, single_epiparameter = TRUE),
             error = function(e) NULL)
  }
  ep <- lookup(param)
  substituted <- FALSE
  if (grepl("generation", param, ignore.case = TRUE) && !has_usable_parameters(ep)) {
    ep_si <- lookup("serial interval")
    if (has_usable_parameters(ep_si)) {
      ep <- ep_si
      substituted <- TRUE
    }
  }
  if (!has_usable_parameters(ep)) return(list(status = if (is.null(ep)) "none" else "empty"))
  family <- tryCatch(as.character(stats::family(ep$prob_distribution)), error = function(e) NA_character_)
  if (!isTRUE(family %in% names(DIST_CTORS))) return(list(status = "unsupported", family = family))

  pars <- lapply(as.list(epiparameter::get_parameters(ep)), function(x) round(as.numeric(x), 4))
  max_v <- tryCatch(max(7L, as.integer(ceiling(stats::quantile(ep$prob_distribution, 0.999)))), error = function(e) NULL)
  one <- function(x, fallback) if (length(x) == 1 && !is.na(x)) as.character(x) else fallback
  list(status = "ok", ep = ep, value = c(list(dist = family), pars, list(max = max_v)), substituted = substituted,
       name = one(tryCatch(ep$epi_name, error = function(e) NA), param),
       disease = one(tryCatch(ep$disease, error = function(e) NA), disease))
}

cmd_lookup_delay <- function(params) {
  disease <- params[["disease"]]
  param <- params[["param"]]
  if (!is.character(disease) || !is.character(param)) {
    stop("lookup-delay requires --disease <name> and --param <name>, e.g. ",
         "--disease COVID-19 --param 'incubation period'.")
  }
  res <- epiparameter_lookup(disease, param)
  if (res$status != "ok") {
    cat(switch(res$status,
      empty = sprintf("An entry exists in epiparameter for '%s', '%s', but it carries no parameters.\n", disease, param),
      unsupported = sprintf("epiparameter's entry is a %s distribution, which EpiNow2 delays do not take.\n", res$family),
      sprintf("No entry found in epiparameter for '%s', '%s'.\n", disease, param)))
    cat("No distribution has been assumed. Options: supply values you have to `fit`,\n")
    cat("estimate a delay from your own linelist with `estimate-delay`, or check the\n")
    cat("spelling with epiparameter::epiparameter_db(disease = \"<name>\").\n")
    return(invisible(list(pass = FALSE)))
  }
  suppressPackageStartupMessages(library(EpiNow2))
  cat("=== epiparameter lookup ===\n")
  if (res$substituted) {
    cat(sprintf("No usable generation time for %s, so the SERIAL INTERVAL is returned instead.\n", res$disease))
    cat("It is onset-to-onset and, with pre-symptomatic transmission, more dispersed\n")
    cat("than the generation time, which biases Rt towards 1. Declare the substitution\n")
    cat("wherever the resulting Rt is reported.\n\n")
  }
  citation <- tryCatch(epiparameter::get_citation(res$ep), error = function(e) NULL)
  if (!is.null(citation)) {
    cat(sprintf("Study: %s (%s). %s. doi: %s\n", citation$author[[1]]$family, citation$year, citation$title, citation$doi))
  }
  cat(sprintf("Disease: %s | Parameter: %s\n", res$disease, res$name))
  cat("Distribution:", describe_dist_value(res$value), "\n")
  cat("The max is the 99.9th percentile: an imposed bound, not part of the published estimate.\n")
  prefix <- if (grepl("generation|serial", param, ignore.case = TRUE)) "gt"
            else if (grepl("incubation", param, ignore.case = TRUE)) "incubation" else "event-delay"
  v <- res$value[setdiff(names(res$value), "dist")]
  cat(sprintf("As fit flags: --%s-dist %s %s%s\n", prefix, res$value$dist,
              paste(sprintf("--%s-%s %s", prefix, names(v), unlist(v)), collapse = " "),
              if (res$substituted) " --gt-substituted" else ""))
  invisible(list(pass = TRUE))
}

# --- init -------------------------------------------------------------------
#
# Works out everything that can be worked out, records where each value came
# from, and writes the config. The user then reviews.

# A GP needs enough series to estimate a length scale; a short series or known
# step changes are a random walk's job.
choose_dynamics <- function(n_days, has_steps) {
  if (has_steps) return(cfg_field(list(type = "rw", step = 7), "inferred", "intervention dates given, so change is stepwise"))
  if (n_days < 42) {
    return(cfg_field(list(type = "rw", step = 7), "inferred",
                     sprintf("series is %d days; too short to estimate a GP length scale", n_days)))
  }
  ls <- if (n_days >= 90) 21 else 14
  cfg_field(list(type = "gp", ls = ls), "inferred",
            sprintf("series is %d days with no step changes given; GP length scale %d days", n_days, ls))
}

lookup_dist_field <- function(disease, param) {
  if (is.null(disease)) return(cfg_field(NULL, "missing", "no --disease given; use lookup-delay or supply the numbers"))
  res <- epiparameter_lookup(disease, param)
  if (res$status != "ok") return(cfg_field(NULL, "missing", sprintf("epiparameter has no usable %s for '%s'", param, disease)))
  cfg_field(c(res$value, if (res$substituted) list(substituted = TRUE)), "inferred",
            sprintf("epiparameter: %s, %s%s", res$disease, res$name,
                    if (res$substituted) " (SUBSTITUTED for a generation time)" else ""))
}

cmd_init <- function(params) {
  data_path <- params[["data"]]
  out_path <- if (!is.null(params[["out"]])) params[["out"]] else "nowcast.yaml"
  cases_out <- if (!is.null(params[["cases-out"]])) params[["cases-out"]] else "outputs/cases.csv"
  delays_out <- if (!is.null(params[["delays-out"]])) params[["delays-out"]] else "outputs/delay_pairs.csv"
  disease <- params[["disease"]]

  if (is.null(data_path)) stop("init requires --data <path>.")
  if (!file.exists(data_path)) stop("Data file not found: ", data_path)
  df <- read.csv(data_path, stringsAsFactors = FALSE)
  info <- inspect_data(df)
  if (nrow(info$dates) == 0) stop("No column in ", data_path, " parses as dates.")
  aggregate_counts <- identical(info$shape, "aggregate")
  if (aggregate_counts && any(df[[info$count_column]] < 0, na.rm = TRUE)) {
    stop("Data contains negative case counts in '", info$count_column, "'. Fix the source data.")
  }

  cat("=== Data inspection ===\n")
  cat(sprintf("Rows: %d | Shape: %s\n\n", nrow(df), info$shape))
  cat("| Date column | Name suggests | Complete | Range |\n| :--- | :--- | ---: | :--- |\n")
  for (i in seq_len(nrow(info$dates))) {
    r <- info$dates[i, ]
    cat(sprintf("| %s | %s | %.1f%% | %s to %s |\n", r$column, if (is.na(r$type_guess)) "nothing" else r$type_guess,
                r$pct_complete, format(r$min_date), format(r$max_date)))
  }
  if (any(grepl("import|travel", tolower(names(df))))) {
    cat("\nAn imported/travel column is present. EpiNow2 assumes a closed population:\n")
    cat("imported cases inflate early Rt, so separate or exclude them.\n")
  }

  # Date column: completeness decides, and the rows it costs are reported.
  if (!is.null(params[["date-column"]])) {
    chosen <- params[["date-column"]]
    if (!chosen %in% info$dates$column) {
      stop("--date-column '", chosen, "' is not a date column. Found: ", paste(info$dates$column, collapse = ", "), ".")
    }
    date_col_field <- cfg_field(chosen, "user", "supplied with --date-column")
  } else {
    chosen <- info$dates$column[1]
    date_col_field <- if (nrow(info$dates) == 1) {
      cfg_field(chosen, "derived", sprintf("only date column, %.1f%% complete", info$dates$pct_complete[1]))
    } else {
      cfg_field(chosen, "inferred", sprintf("most complete of %d date columns (%.1f%%, next is %s at %.1f%%)",
        nrow(info$dates), info$dates$pct_complete[1], info$dates$column[2], info$dates$pct_complete[2]))
    }
  }
  dates_all <- parse_date_column(df[[chosen]])
  keep <- !is.na(dates_all)
  if (any(!keep)) {
    cat(sprintf("\nNote: %d of %d rows (%.1f%%) have no %s and will be excluded.\n",
                sum(!keep), nrow(df), 100 * mean(!keep), chosen))
  }

  # Strata. In aggregate counts, rows sharing a date must be told apart by
  # some column, and the data says which. In a linelist every row is an
  # event, so nothing in the data calls for a split: one series is the
  # default and the columns that could split it are listed.
  dup <- aggregate_counts && anyDuplicated(dates_all[keep]) > 0
  cands <- strata_candidates(df[keep, , drop = FALSE], c(info$dates$column, info$count_column), if (dup) dates_all[keep])
  describe_cands <- function(cs) paste(sprintf("%s (%d values)", cs, vapply(cs, function(c) length(unique(df[[c]])), 1L)), collapse = ", ")
  strata_col <- NULL
  if (!is.null(params[["strata"]]) && !identical(params[["strata"]], "none")) {
    strata_col <- params[["strata"]]
    if (!strata_col %in% names(df)) stop("--strata '", strata_col, "' is not a column.")
    if (dup && anyDuplicated(data.frame(dates_all[keep], df[[strata_col]][keep]))) {
      stop("--strata '", strata_col, "' does not separate the rows that share a date.")
    }
    strata_field <- cfg_field(strata_col, "user", "supplied with --strata")
  } else if (!is.null(params[["strata"]])) {
    strata_field <- cfg_field("none", "user", if (dup) "supplied with --strata none; rows sharing a date are summed" else "supplied with --strata none")
  } else if (dup && length(cands) == 0) {
    stop("Dates repeat, and no single column separates the rows that share one. Aggregate the file to one ",
         "row per date, or per date and stratum, or name the column with --strata.")
  } else if (dup) {
    strata_col <- cands[1]
    strata_field <- cfg_field(strata_col, "inferred", sprintf(
      "dates repeat once per value of %s; each value is fitted separately%s. Set none to fit the total",
      describe_cands(strata_col), if (length(cands) > 1) paste0("; also separating: ", describe_cands(cands[-1])) else ""))
  } else if (length(cands) > 0 && !aggregate_counts) {
    strata_field <- cfg_field("none", "inferred", sprintf(
      "fitted as one series; could be split by %s. Set a column name to fit each value separately", describe_cands(cands)))
  } else {
    strata_field <- cfg_field("none", "derived", "one row per date")
  }

  b <- build_series(df, chosen, info$count_column, strata_col, flag_true(params, "week-start"), flag_true(params, "fill-zeros"))
  series <- b$series
  weekly <- b$weekly
  step <- b$step
  timestep_field <- if (!weekly) {
    cfg_field("day", "derived", if (aggregate_counts) "dates are days" else "linelist events are counted by day")
  } else if (flag_true(params, "week-start")) {
    cfg_field("week_starting", "user", "supplied with --week-start: each count is the 7 days starting on its date")
  } else {
    cfg_field("week_ending", "inferred", sprintf(paste(
      "dates are 7 days apart, all on a %s; each count is taken as the 7 days ending on its date.",
      "Set week_starting if the dates mark the start of the week"), weekdays(min(dates_all, na.rm = TRUE))))
  }
  if (!is.null(params[["horizon"]])) check_horizon(int_flag(params, "horizon", 0), weekly)

  unit <- if (weekly) "weeks" else "calendar days"
  fill_field <- if (!aggregate_counts) {
    cfg_field(TRUE, "derived", "a linelist day with no row had no cases")
  } else if (flag_true(params, "fill-zeros")) {
    cfg_field(TRUE, "user", "supplied with --fill-zeros")
  } else if (b$n_gap > 0) {
    cfg_field(FALSE, "inferred", sprintf(paste(
      "%d %s have no row, and EpiNow2 needs an unbroken series. Set true if they are zeros. If they are",
      "unreported, trim the series instead: filling would invent observations"), b$n_gap, unit))
  } else {
    cfg_field(FALSE, "derived", "no dates without a row")
  }
  if (b$filled) cat(sprintf("\n%d %s with no row were filled with zero counts.\n", b$n_gap, unit))
  else if (b$n_gap > 0) cat(sprintf("\nWarning: %d %s have no row; see fill_zeros below.\n", b$n_gap, unit))
  pooled <- aggregate(confirm ~ date, data = series, FUN = sum)
  n_days <- as.integer(diff(range(pooled$date))) + step

  # Date type: two weak signals, neither allowed to settle it alone.
  wk <- if (weekly) list(verdict = "inconclusive", reason = "weekly counts carry no weekday signal")
        else week_cycle_evidence(pooled$date, pooled$confirm)
  name_guess <- classify_date_name(chosen)
  date_type_field <- if (!is.null(params[["date-type"]])) {
    cfg_field(check_date_type(params[["date-type"]]), "user", "supplied with --date-type")
  } else if (!is.na(name_guess)) {
    cfg_field(name_guess, "inferred", sprintf("column name '%s' suggests %s; %s", chosen, name_guess, wk$reason))
  } else if (identical(wk$verdict, "cycle")) {
    cfg_field("report", "inferred", sprintf(
      "column name carries no signal; a weekly cycle in the counts (%s) is consistent with an administrative date", wk$reason))
  } else if (identical(wk$verdict, "no cycle")) {
    cfg_field("onset", "inferred", sprintf(
      "column name carries no signal; no weekly cycle in the counts (%s) is consistent with symptom onset", wk$reason))
  } else {
    cfg_field(NULL, "missing", sprintf("column name carries no signal and %s. Set --date-type.", wk$reason))
  }

  # A linelist with an onset column and another date column holds the delay
  # from onset to that date. For a later-event date type it is the event
  # delay; for onset dates it is the right truncation of recent onsets.
  ed_evidence <- "needed for any date type but onset; supply it, or estimate it from a linelist with estimate-delay"
  trunc_evidence <- "optional; estimate it from earlier snapshots with estimate-truncation, or leave unset if recent counts are complete"
  onset_col <- info$dates$column[which(info$dates$type_guess == "onset")[1]]
  to_col <- if (is.na(onset_col)) NA else if (onset_col != chosen) chosen else setdiff(info$dates$column, onset_col)[1]
  if (!aggregate_counts && !is.na(to_col)) {
    p_on <- parse_date_column(df[[onset_col]])
    p_to <- parse_date_column(df[[to_col]])
    ok <- !is.na(p_on) & !is.na(p_to) & p_to >= p_on
    if (any(ok)) {
      dir.create(dirname(delays_out), showWarnings = FALSE, recursive = TRUE)
      write.csv(data.frame(pdate_lwr = p_on[ok], sdate_lwr = p_to[ok]), delays_out, row.names = FALSE)
      cat(sprintf("\nEvent pairs %s -> %s: %d written to %s.\n", onset_col, to_col, sum(ok), delays_out))
      how <- sprintf("%d %s -> %s pairs are in %s; run estimate-delay --delays %s --config %s",
                     sum(ok), onset_col, to_col, delays_out, delays_out, out_path)
      if (onset_col == chosen) trunc_evidence <- paste("optional, but recent onsets are incomplete until reported.", how)
      else ed_evidence <- how
    }
  }

  cfg <- list(
    data = cfg_field(data_path, "user", sprintf("the %s series fit builds from it is in %s", if (weekly) "weekly" else "daily", cases_out)),
    date_column = date_col_field,
    date_type = date_type_field,
    timestep = timestep_field,
    strata = strata_field,
    fill_zeros = fill_field,
    generation_time = lookup_dist_field(disease, "generation time"),
    incubation = lookup_dist_field(disease, "incubation period"),
    event_delay = cfg_field(NULL, "missing", ed_evidence),
    truncation = cfg_field(NULL, "missing", trunc_evidence),
    dynamics = choose_dynamics(n_days, !is.null(params[["intervention-dates"]])),
    rt_prior = cfg_field("default", "inferred", paste(
      "EpiNow2's default prior on Rt at the start of the series. Replace with",
      "{mean, sd} for a lognormal prior from prior knowledge"))
  )
  if (!is.null(params[["horizon"]])) {
    cfg$horizon <- cfg_field(int_flag(params, "horizon", 0), "user", "supplied with --horizon")
    cfg$forecast_rt <- cfg_field("latest", "inferred", paste(
      "Rt over the forecast. latest: held at its last estimate, so transmission stays at its",
      "current level. project: keeps varying as the fitted Rt model allows, with widening uncertainty"))
  }
  cfg <- derive_dependent(cfg)

  # Sparse strata are named here, not left to fail inside the sampler.
  if ("region" %in% names(series)) {
    sparse <- names(Filter(function(g) as.integer(diff(range(g$date))) + step < 21 || sum(g$confirm) < 50,
                           split(series, series$region)))
    if (length(sparse) > 0) {
      cat(sprintf("\nWarning: under 21 days or under 50 total cases in: %s. Fitting these\n", paste(sparse, collapse = ", ")))
      cat("separately is unlikely to converge. Drop them, or pool with fit --pool.\n")
    }
  }

  dir.create(dirname(cases_out), showWarnings = FALSE, recursive = TRUE)
  write.csv(series, cases_out, row.names = FALSE)
  write_config(cfg, out_path)

  cat("\n=== Specification ===\n\n| Field | Value | Source | Evidence |\n| :--- | :--- | :--- | :--- |\n")
  for (nm in names(cfg)) {
    f <- cfg[[nm]]
    cat(sprintf("| %s | %s | %s | %s |\n", nm, format_config_value(f$value), f$source, if (is.null(f$evidence)) "" else f$evidence))
  }
  cat(sprintf("\nSeries: %s\nConfig: %s\n\n", cases_out, out_path))
  review <- names(cfg)[vapply(cfg, function(f) f$source %in% c("inferred", "missing"), logical(1))]
  if (length(review) > 0) {
    cat("Check these before fitting; the rest was derived from the data:\n")
    for (nm in review) cat(sprintf("  - %s (%s): %s\n", nm, cfg[[nm]]$source, cfg[[nm]]$evidence))
  }
  gaps <- config_gaps(cfg)
  if (length(gaps) > 0) cat(sprintf("\nfit will refuse until these are set: %s\n", paste(gaps, collapse = ", ")))
  else cat(sprintf("\nNo required field is missing. Next: fit --config %s\n", out_path))
  invisible(cfg)
}

# --- estimate-delay ---------------------------------------------------------
#
# estimate_dist() takes event date pairs, not integer delays, to account for
# double interval censoring and right truncation.

# The family is chosen before the Stan fit: maximum likelihood on the
# whole-day delays, each counted as the interval [d, d + 1), compared by AIC.
# The screen ignores truncation; it only ranks families. Only lognormal and
# gamma are candidates, because only they carry the posterior uncertainty into
# the renewal model.
screen_families <- function(delay) {
  m <- mean(delay) + 0.5
  cdf <- list(lognormal = function(x, p) plnorm(x, p[1], exp(p[2])),
              gamma = function(x, p) pgamma(x, exp(p[1]), exp(p[2])))
  start <- list(lognormal = c(log(m), -0.5), gamma = c(0, -log(m)))
  sort(vapply(names(cdf), function(f) {
    nll <- function(p) -sum(log(pmax(cdf[[f]](delay + 1, p) - cdf[[f]](delay, p), 1e-300)))
    2 * optim(start[[f]], nll, method = "BFGS")$value + 4
  }, numeric(1)))
}

cmd_estimate_delay <- function(params) {
  delays_path <- params[["delays"]]
  if (is.null(delays_path) || !file.exists(delays_path)) stop("Must supply an existing CSV file via --delays.")
  st <- stan_settings(params, cores_default = 2L)
  df <- read.csv(delays_path, stringsAsFactors = FALSE)
  if (!all(c("pdate_lwr", "sdate_lwr") %in% names(df))) {
    stop("--delays needs columns 'pdate_lwr' (e.g. onset) and 'sdate_lwr' (e.g. report), as init ",
         "writes them. Integer delays are not accepted: censoring cannot be recovered from them.")
  }
  df$pdate_lwr <- as.Date(df$pdate_lwr)
  df$sdate_lwr <- as.Date(df$sdate_lwr)
  df <- df[!is.na(df$pdate_lwr) & !is.na(df$sdate_lwr) & df$sdate_lwr >= df$pdate_lwr, c("pdate_lwr", "sdate_lwr")]
  if (nrow(df) < 20) stop("Only ", nrow(df), " usable event pairs; too few to estimate a delay.")

  aic <- screen_families(as.integer(df$sdate_lwr - df$pdate_lwr))
  cat("| Family | AIC | Difference |\n| :--- | ---: | ---: |\n")
  for (f in names(aic)) cat(sprintf("| %s | %.1f | %.1f |\n", f, aic[[f]], aic[[f]] - aic[[1]]))
  dist <- if (!is.null(params[["dist"]])) tolower(params[["dist"]]) else names(aic)[1]
  if (!dist %in% names(aic)) stop("--dist must be lognormal or gamma, the families the model takes with uncertainty.")
  basis <- if (!is.null(params[["dist"]])) "chosen with --dist" else sprintf(
    "lowest AIC%s", if (aic[[2]] - aic[[1]] < 2) sprintf("; %s is within 2, so the data barely separate them", names(aic)[2]) else "")
  cat(sprintf("Family: %s (%s)\n\n", dist, basis))

  suppressPackageStartupMessages(library(EpiNow2))
  cat(sprintf("Fitting %s delay to %d event pairs (seed %d, warmup %d)...\n", dist, nrow(df), st$seed, st$warmup))
  fit <- estimate_dist(df, dist = dist, verbose = FALSE,
                       stan = stan_opts(seed = st$seed, cores = st$cores, warmup = st$warmup, samples = st$samples))
  if (!gate_estimator(fit, "delay distribution")) return(invisible(list(pass = FALSE)))
  v <- dist_value_from_spec(get_parameters(fit)[["delay"]])
  cat("Fitted: ", describe_dist_value(v), "\n", sep = "")

  if (!is.null(params[["config"]])) {
    cfg <- read_config(params[["config"]])
    # For onset-dated counts the delay from onset to a later event is the
    # truncation of recent onsets, not part of the delay from infection.
    field <- params[["field"]]
    if (is.null(field)) field <- if (identical(cfg_value(cfg, "date_type"), "onset")) "truncation" else "event_delay"
    if (!field %in% c("event_delay", "truncation")) stop("--field must be event_delay or truncation.")
    cfg[[field]] <- cfg_field(v, "derived", sprintf("estimate_dist() on %d event pairs from %s; family %s (%s); posterior uncertainty kept",
                                                    nrow(df), basename(delays_path), dist, basis))
    write_config(cfg, params[["config"]])
    cat(sprintf("Written to %s as '%s' (date_type is %s).\n", params[["config"]], field,
                format_config_value(cfg_value(cfg, "date_type"))))
  }
  invisible(list(pass = TRUE))
}

# --- estimate-truncation ----------------------------------------------------
#
# Right truncation from earlier snapshots of the same series.

cmd_estimate_truncation <- function(params) {
  vintages <- params[["vintages"]]
  if (!is.character(vintages)) stop("--vintages <dir> is required: CSV snapshots of the same series, each with 'date' and 'confirm'.")
  files <- if (dir.exists(vintages)) sort(list.files(vintages, "\\.csv$", full.names = TRUE)) else sort(Sys.glob(vintages))
  if (length(files) < 2) {
    stop("Found ", length(files), " vintage(s); at least 2 are needed, since truncation is estimated ",
         "from how later vintages revise earlier ones.")
  }
  st <- stan_settings(params, cores_default = 2L)
  vin <- lapply(files, function(f) {
    d <- read.csv(f, stringsAsFactors = FALSE)
    if (!all(c("date", "confirm") %in% names(d))) stop("Vintage ", basename(f), " needs 'date' and 'confirm'.")
    d$date <- as.Date(d$date)
    d <- d[order(d$date), c("date", "confirm")]
    if (any(diff(d$date) != 1)) stop("Vintage ", basename(f), " is not an unbroken daily series; truncation is estimated from daily snapshots.")
    d
  })
  # estimate_truncation() treats the last vintage as the most complete.
  if (is.unsorted(vapply(vin, function(d) as.numeric(max(d$date)), numeric(1)))) {
    stop("Vintage files sorted by name must end on increasing dates. Name them in the order taken.")
  }

  suppressPackageStartupMessages(library(EpiNow2))
  cat(sprintf("Estimating truncation from %d vintages (seed %d, warmup %d)...\n", length(vin), st$seed, st$warmup))
  est <- estimate_truncation(vin, verbose = FALSE,
                             stan = stan_opts(seed = st$seed, cores = st$cores, warmup = st$warmup, samples = st$samples))
  if (!gate_estimator(est, "truncation distribution")) return(invisible(list(pass = FALSE)))
  v <- dist_value_from_spec(get_parameters(est)[["truncation"]])
  cat("Fitted: ", describe_dist_value(v), "\n", sep = "")
  if (!is.null(params[["config"]])) {
    cfg <- read_config(params[["config"]])
    cfg$truncation <- cfg_field(v, "derived", sprintf("estimate_truncation() over %d vintages; posterior uncertainty kept", length(vin)))
    write_config(cfg, params[["config"]])
    cat(sprintf("Written to %s as 'truncation'.\n", params[["config"]]))
  }
  invisible(list(pass = TRUE))
}
