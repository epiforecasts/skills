# Sourced by epinow2.R. The convergence gate, fit and evaluate.

# --- Convergence gate -------------------------------------------------------

stan_settings <- function(params, cores_default) {
  # R's generator is seeded too: EpiNow2 draws the chains' initial values in
  # R, so a Stan seed alone does not make a fit reproducible.
  seed <- int_flag(params, "seed", 20260915L)
  set.seed(seed)
  # Warmup 500, not EpiNow2 1.9's 250: at 250, estimate_truncation() on the
  # package's own example data fails Rhat. The package's development version
  # has raised its default to 500.
  list(seed = seed, cores = int_flag(params, "cores", cores_default),
       warmup = int_flag(params, "warmup", 500L), samples = int_flag(params, "samples", 2000L))
}

# Rhat, ESS and divergences over varying quantities only. EpiNow2 monitors
# fixed inputs too: a delay PMF passed as data has sd 0 and an ESS of about 2,
# and counting it would fail every fit.
compute_diagnostics <- function(fit) {
  stanfit <- unclass(fit)[["fit"]]
  if (is.null(stanfit)) stop("The object holds no Stan fit; cannot assess convergence.")
  s <- rstan::summary(stanfit)$summary
  varying <- !is.na(s[, "Rhat"]) & !is.na(s[, "sd"]) & s[, "sd"] > 1e-10
  n_excluded <- sum(!varying)
  s <- s[varying, , drop = FALSE]
  if (nrow(s) == 0) stop("No varying parameters in the fit; cannot assess convergence.")
  sp <- rstan::get_sampler_params(stanfit, inc_warmup = FALSE)
  # An ESS that cannot be computed is not an ESS of 400.
  ess <- s[, "n_eff"]
  ess[is.na(ess)] <- 0
  list(max_rhat = max(s[, "Rhat"]), worst_rhat = rownames(s)[which.max(s[, "Rhat"])],
       min_ess = min(ess), worst_ess = rownames(s)[which.min(ess)],
       n_divergent = sum(vapply(sp, function(x) sum(x[, "divergent__"]), numeric(1))),
       n_params = nrow(s), n_excluded = n_excluded)
}

assess_diagnostics <- function(d) {
  reasons <- c(
    if (d$max_rhat > 1.01) sprintf("Rhat: max %.4f exceeds 1.01 (worst: %s)", d$max_rhat, d$worst_rhat),
    if (d$n_divergent > 0) sprintf("Divergent transitions: %d (must be 0)", d$n_divergent),
    if (d$min_ess < 400) sprintf("Effective sample size: min %.0f below 400 (worst: %s)", d$min_ess, d$worst_ess)
  )
  list(pass = length(reasons) == 0, reasons = reasons)
}

# For the estimators whose output feeds fit. Nothing is written on a failure.
gate_estimator <- function(obj, what) {
  d <- compute_diagnostics(obj)
  v <- assess_diagnostics(d)
  cat(sprintf("Diagnostics: max Rhat %.4f, min ESS %.0f, %d divergent transitions\n", d$max_rhat, d$min_ess, d$n_divergent))
  if (v$pass) {
    cat("Convergence: PASS\n\n")
    return(TRUE)
  }
  cat("Convergence: FAIL\n")
  for (r in v$reasons) cat(sprintf("  * %s\n", r))
  cat(sprintf("The %s is withheld and nothing is written. Re-run with more --warmup or\n", what))
  cat("--samples, or check the input, rather than using an unconverged estimate.\n")
  FALSE
}

# --- fit --------------------------------------------------------------------

# Past 14 days the assumption about future Rt outweighs what the data say.
MAX_HORIZON <- 14L

check_horizon <- function(h, weekly = FALSE) {
  if (h > MAX_HORIZON) {
    stop("--horizon ", h, " is beyond ", MAX_HORIZON, " days. Past that, the assumption about ",
         "future Rt outweighs what the data say.")
  }
  if (weekly && h %% 7 != 0) stop("--horizon must be 7 or 14 for weekly counts.")
  h
}

# What each choice of Rt over the forecast assumes about future transmission.
# EpiNow2's third option, "estimate", is not offered: it holds Rt fixed over
# the last days of the data as well as the forecast, so it changes the nowcast.
FORECAST_RT <- c(
  latest = "holds Rt at its last estimate, the least certain in the fit: transmission stays at its current level",
  project = paste("lets Rt keep varying as the fitted Rt model allows: no trend beyond what the model has seen,",
                  "with uncertainty widening over the horizon")
)

# One specification from the config, with any flag taking precedence.
resolve_spec <- function(cfg, params) {
  pick <- function(flag, field) if (!is.null(params[[flag]])) params[[flag]] else cfg_value(cfg, field)
  dist <- function(prefix, field, label) {
    v <- dist_value_from_flags(params, prefix, label)
    if (!is.null(v)) v else cfg_value(cfg, field)
  }
  date_type <- pick("date-type", "date_type")
  if (!is.null(date_type)) date_type <- check_date_type(date_type)

  # A "none" derived from an onset date type is not a choice to model no
  # delay; only a user's "none", or --no-event-delay, is.
  ed <- dist_value_from_flags(params, "event-delay", "Event delay")
  if (flag_true(params, "no-event-delay")) {
    if (!is.null(ed)) stop("--no-event-delay contradicts the --event-delay-* flags.")
    ed <- "none"
  } else if (is.null(ed) && !identical(date_type, "onset") && !is.null(cfg$event_delay$value) &&
             !identical(cfg$event_delay$source, "missing") &&
             !(identical(cfg$event_delay$source, "derived") && identical(cfg$event_delay$value, "none"))) {
    ed <- cfg$event_delay$value
  }

  dyn <- cfg_value(cfg, "dynamics")
  if (!is.null(params[["rw"]]) || !is.null(params[["gp-ls"]])) dyn <- NULL
  rt_prior <- if (!is.null(params[["r-prior-mean"]]) || !is.null(params[["r-prior-sd"]])) {
    if (is.null(params[["r-prior-mean"]]) || is.null(params[["r-prior-sd"]])) stop("--r-prior-mean and --r-prior-sd go together.")
    list(mean = as.numeric(params[["r-prior-mean"]]), sd = as.numeric(params[["r-prior-sd"]]))
  } else cfg_value(cfg, "rt_prior")

  gt <- dist("gt", "generation_time", "Generation time")
  list(
    data = pick("data", "data"),
    date_type = date_type,
    gt = gt,
    gt_substituted = flag_true(params, "gt-substituted") || (is.null(dist_value_from_flags(params, "gt", "")) && isTRUE(gt$substituted)),
    inc = dist("incubation", "incubation", "Incubation period"),
    event_delay = ed,
    truncation = dist("trunc", "truncation", "Truncation"),
    rw = if (identical(dyn$type, "rw")) as.integer(dyn$step) else int_flag(params, "rw", 0),
    gp_ls = if (identical(dyn$type, "gp")) as.numeric(dyn$ls) else if (!is.null(params[["gp-ls"]])) as.numeric(params[["gp-ls"]]),
    rt_prior = if (is.list(rt_prior)) rt_prior else NULL,
    horizon = if (!is.null(params[["horizon"]])) int_flag(params, "horizon", 0) else as.integer(c(cfg_value(cfg, "horizon"), 0)[1]),
    forecast_rt = { f <- pick("forecast-rt", "forecast_rt"); if (is.null(f)) "latest" else f },
    week_effect = if (!is.null(params[["week-effect"]])) flag_true(params, "week-effect"),
    pool = flag_true(params, "pool")
  )
}

cmd_fit <- function(params) {
  suppressPackageStartupMessages(library(EpiNow2))
  cfg <- if (!is.null(params[["config"]])) read_config(params[["config"]]) else list()
  s <- resolve_spec(cfg, params)

  missing_parts <- c(
    if (is.null(s$data)) "data (--data, or a config that names it)",
    if (is.null(s$date_type)) "date type (--date-type): onset, or the later event that dates each count",
    if (is.null(s$gt)) "generation time (--gt-*)",
    if (is.null(s$inc)) "incubation period (--incubation-*)",
    if (!is.null(s$date_type) && s$date_type != "onset" && is.null(s$event_delay)) sprintf(
      "delay from onset to %s (--event-delay-*), or --no-event-delay, recorded as a caveat", s$date_type)
  )
  if (length(missing_parts) > 0) {
    stop("Missing required specification:\n", paste0("  - ", missing_parts, collapse = "\n"),
         "\nNothing is defaulted. Get distributions from lookup-delay (published), estimate-delay (your ",
         "linelist), or values you have. Or run init, which fills what it can and names the rest.")
  }
  if (s$date_type == "onset" && is.list(s$event_delay)) {
    stop("Date type is onset, so the incubation period is the whole delay. Drop the event delay.")
  }
  if (!s$forecast_rt %in% names(FORECAST_RT)) stop("--forecast-rt must be one of ", paste(names(FORECAST_RT), collapse = ", "), ".")
  if (!is.null(s$gp_ls) && s$gp_ls < 7) {
    stop("--gp-ls ", s$gp_ls, " is below 7 days. Gaussian processes with short length scales ",
         "sample poorly and overfit. Use a random walk: --rw 7 for weekly steps, --rw 1 for daily.")
  }

  # --- Data ---
  # With a config, the series is rebuilt from the raw file with the config's
  # choices, so a corrected field takes effect and new data in the same layout
  # needs no new init. Without one, the file must already be a series.
  if (!file.exists(s$data)) stop("Data file not found: ", s$data)
  df <- read.csv(s$data, stringsAsFactors = FALSE)
  b <- if (!is.null(cfg_value(cfg, "date_column"))) {
    strata <- cfg_value(cfg, "strata")
    build_series(df, cfg_value(cfg, "date_column"), inspect_data(df)$count_column,
                 if (!is.null(strata) && strata != "none") strata,
                 identical(cfg_value(cfg, "timestep"), "week_starting"), isTRUE(cfg_value(cfg, "fill_zeros")))
  } else {
    missing_cols <- setdiff(c("date", "confirm"), names(df))
    if (length(missing_cols) > 0) {
      stop("Input needs columns 'date' and 'confirm'; missing: ", paste(missing_cols, collapse = ", "),
           ". Produce one with: init --data <your file>.")
    }
    if (!"region" %in% names(df) && anyDuplicated(df$date)) stop("Dates repeat. Run init, which finds the stratum column.")
    build_series(df, "date", "confirm", if ("region" %in% names(df)) "region")
  }
  cases <- b$series
  if (any(cases$confirm < 0, na.rm = TRUE)) stop("Data contains negative case counts.")
  if (b$n_gap > 0 && !b$filled) {
    stop(b$n_gap, " dates have no row, and EpiNow2 needs an unbroken series. If they are zeros, set ",
         "fill_zeros to true in the config (or init --fill-zeros). If they are unreported, trim the series.")
  }
  weekly <- b$weekly
  horizon <- check_horizon(s$horizon, weekly)

  # Strata are fitted separately: pooling estimates an Rt for a population
  # that does not exist, so it happens only on request and becomes a caveat.
  has_strata <- "region" %in% names(cases) && length(unique(cases$region)) > 1
  pool <- has_strata && s$pool
  by_stratum <- has_strata && !pool
  n_strata <- if (has_strata) length(unique(cases$region)) else 0L
  if (pool) cases <- aggregate(confirm ~ date, data = cases, FUN = sum)
  if (!has_strata) cases <- cases[, c("date", "confirm")]
  if (by_stratum && horizon > 0) stop("Forecasts are reported for single-series fits only. Fit a stratum on its own, or --pool.")
  # A weekly count is the total over the 7 days ending on its date.
  if (weekly) cases <- fill_missing(cases, missing_dates = "accumulate", initial_accumulate = 7, by = if (by_stratum) "region")

  # --- Specification ---
  gt_conf <- suppressMessages(gt_opts(dist_from_value(s$gt, "Generation time", gt = TRUE)))
  inc_dist <- dist_from_value(s$inc, "Incubation period")
  has_ed <- s$date_type != "onset" && is.list(s$event_delay)
  delay_conf <- suppressMessages(delay_opts(if (has_ed) inc_dist + dist_from_value(s$event_delay, "Event delay") else inc_dist))
  trunc_conf <- if (is.null(s$truncation)) trunc_opts() else suppressMessages(trunc_opts(dist_from_value(s$truncation, "Truncation")))
  week_effect <- if (!is.null(s$week_effect)) s$week_effect else !weekly && s$date_type != "onset"
  # No prior is passed unless one was chosen, so EpiNow2 applies its own.
  rt_args <- list(rw = s$rw, future = s$forecast_rt)
  if (!is.null(s$rt_prior)) rt_args$prior <- LogNormal(mean = s$rt_prior$mean, sd = s$rt_prior$sd)
  rt_conf <- do.call(rt_opts, rt_args)
  gp_conf <- if (s$rw > 0) NULL else if (!is.null(s$gp_ls)) gp_opts(ls = LogNormal(mean = s$gp_ls, sd = 7, max = 60)) else gp_opts()

  # Caveats travel with the fit, and evaluate binds them to the Rt row.
  caveats <- c(
    if (pool) sprintf("Counts were pooled across %d strata. The Rt is for the pooled series, which averages over their epidemics.", n_strata),
    if (b$summed) "Rows sharing a date were summed. The Rt is for the total series, which averages over the epidemics within it.",
    if (s$gt_substituted) paste("Generation time is a substituted serial interval. It is onset-to-onset and, under",
                                "pre-symptomatic transmission, more dispersed, so Rt is biased towards 1."),
    if (s$date_type != "onset" && identical(s$event_delay, "none")) sprintf(paste(
      "No delay from onset to %s was modelled. Infections are placed later than they",
      "occurred by the omitted delay, so Rt and the nowcast lag the epidemic."), s$date_type),
    if (s$date_type %in% c("admission", "death")) sprintf(
      "Rt from %s counts assumes the fraction of infections leading to %s is constant over the window.", s$date_type, s$date_type),
    if (horizon > 0) sprintf("The %d-day forecast %s.", horizon, FORECAST_RT[[s$forecast_rt]])
  )

  spec <- c(
    sprintf("Date type:   %s", s$date_type),
    sprintf("Timestep:    %s", if (weekly) "weekly counts, each the total of the 7 days ending on its date" else "daily"),
    sprintf("GT:          %s", describe_dist_value(s$gt)),
    sprintf("Incubation:  %s", describe_dist_value(s$inc)),
    sprintf("Event delay: %s", if (has_ed) describe_dist_value(s$event_delay)
            else if (s$date_type == "onset") "not applicable (onset dates)" else "none (--no-event-delay)"),
    sprintf("Truncation:  %s", describe_dist_value(s$truncation)),
    sprintf("Rt prior:    %s", if (is.null(s$rt_prior)) paste("EpiNow2 default,", describe_dist_value(dist_value_from_spec(rt_opts()$prior), bounded = FALSE))
            else sprintf("lognormal(mean = %.2f, sd = %.2f)", s$rt_prior$mean, s$rt_prior$sd)),
    sprintf("Dynamics:    %s", if (s$rw > 0) sprintf("random walk, %d-day steps", s$rw)
            else if (!is.null(s$gp_ls)) sprintf("Gaussian process, length scale ~%.1f days", s$gp_ls)
            else "Gaussian process, package default length scale"),
    sprintf("Week effect: %s", if (week_effect) "estimated" else "not estimated"),
    sprintf("Forecast:    %s", if (horizon > 0) sprintf("%d days, Rt %s", horizon, s$forecast_rt) else "none"),
    if (has_strata) sprintf("Strata:      %d, %s", n_strata, if (pool) "pooled" else "fitted separately")
  )
  st <- stan_settings(params, cores_default = 4L)
  cat(sprintf("Fitting with EpiNow2 (seed %d, cores %d, warmup %d)\n", st$seed, st$cores, st$warmup))
  for (line in c(spec, if (length(caveats) > 0) paste("Caveat:", caveats))) cat("  ", line, "\n", sep = "")
  if (flag_true(params, "dry-run")) {
    cat("Dry run: specification resolved, nothing fitted.\n")
    return(invisible(NULL))
  }

  args <- list(generation_time = gt_conf, delays = delay_conf, truncation = trunc_conf, rt = rt_conf,
               gp = gp_conf, obs = obs_opts(week_effect = week_effect), forecast = forecast_opts(horizon = horizon),
               stan = stan_opts(seed = st$seed, cores = st$cores, warmup = st$warmup, samples = st$samples,
                                control = list(adapt_delta = 0.99)),
               verbose = FALSE)
  # regional_epinow() returns each stratum as a full estimate_infections fit,
  # so diagnostics and reporting are the same code for one stratum or twenty.
  fit <- if (by_stratum) {
    do.call(regional_epinow, c(list(data = cases, output = "region", return_output = TRUE, logs = NULL), args))
  } else {
    do.call(estimate_infections, c(list(data = cases), args))
  }
  out_dir <- if (!is.null(params[["output-dir"]])) params[["output-dir"]] else "outputs/fit"
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  saveRDS(fit, file.path(out_dir, "fit.rds"))
  # Written even when empty, so evaluate can tell "no caveats" from "not recorded".
  saveRDS(list(caveats = caveats, spec = spec, weekly = weekly), file.path(out_dir, "caveats.rds"))
  cat(sprintf("Saved %s. Next: evaluate --fit %s\n", file.path(out_dir, "fit.rds"), file.path(out_dir, "fit.rds")))
}

# --- evaluate ---------------------------------------------------------------
#
# Estimates are reported in EpiNow2's own terms: summary()'s snapshot table,
# including its label for the expected change in reports, which maps
# P(Rt < 1) as below 0.05 Increasing, 0.05 to 0.4 Likely increasing, 0.4 to
# 0.6 Stable, 0.6 to 0.95 Likely decreasing, 0.95 or more Decreasing.

prob_rt_below_one <- function(fit, date) {
  smp <- tryCatch(get_samples(fit), error = function(e) NULL)
  if (is.null(smp)) return(NA_real_)
  r <- smp$value[smp$variable == "R" & smp$date == date]
  if (length(r) == 0) NA_real_ else mean(r < 1)
}

fmt_n <- function(x) format(round(x), big.mark = ",")
# A proportion of draws is not exactly 0 or 1, only beyond what the draws resolve.
fmt_p <- function(p) if (is.na(p)) "-" else if (p > 0.99) "above 0.99" else if (p < 0.01) "below 0.01" else sprintf("%.2f", p)

print_caveats <- function(caveats, spec) {
  if (identical(caveats, NA_character_)) {
    cat("## Caveats\n\nParameter provenance was not recorded for this fit, so whether published,\n")
    cat("substituted or default distributions were used cannot be told. Treat the\n")
    cat("estimates as unattributed.\n\n")
  } else if (length(caveats) > 0) {
    cat("## Caveats\n\nThese qualify every estimate above. Carry them with any number taken from here.\n\n")
    for (cv in caveats) cat(sprintf("* %s\n", cv))
    cat("\n")
  }
  if (!is.null(spec)) {
    cat("## Model specification\n\n")
    for (line in spec) cat(sprintf("  - %s\n", line))
    cat("\n")
  }
}

cmd_evaluate <- function(params) {
  fit_path <- params[["fit"]]
  if (!is.character(fit_path) || !file.exists(fit_path)) stop("Valid --fit path must be supplied.")
  suppressPackageStartupMessages(library(EpiNow2))
  fit <- readRDS(fit_path)

  # --report-out writes the report to a temporary file, moved into place only
  # once complete: a half-written file on disk looks like a report. A
  # withheld-estimate report is complete and is kept.
  report_out <- params[["report-out"]]
  report_complete <- FALSE
  if (!is.null(report_out)) {
    dir.create(dirname(report_out), showWarnings = FALSE, recursive = TRUE)
    tmp <- paste0(report_out, ".part")
    con <- file(tmp, open = "wt")
    sink(con, split = TRUE)
    on.exit({
      sink(); close(con)
      if (report_complete) file.rename(tmp, report_out) else unlink(tmp)
      cat(if (report_complete) sprintf("\nReport written to: %s\n", report_out) else "\nReport not written.\n")
    }, add = TRUE)
  }

  # Absent caveats (a fit not made by this script) are reported as unknown,
  # not as none.
  caveat_path <- file.path(dirname(fit_path), "caveats.rds")
  info <- if (file.exists(caveat_path)) readRDS(caveat_path) else NULL
  caveats <- if (is.null(info)) NA_character_ else info$caveats
  flag <- if (identical(caveats, NA_character_)) " [provenance not recorded]"
          else if (length(caveats) > 0) " [conditional on the caveats below]" else ""

  requested <- NULL
  if (!is.null(params[["date"]])) {
    requested <- tryCatch(as.Date(params[["date"]]), error = function(e) as.Date(NA))
    if (is.na(requested)) stop("Could not parse --date '", params[["date"]], "'. Use YYYY-MM-DD.")
  }

  result <- if (is.list(fit) && !is.null(fit$regional)) {
    report_strata(fit, requested, flag)
  } else {
    report_single(fit, requested, flag, isTRUE(info$weekly))
  }
  print_caveats(caveats, info$spec)
  report_complete <- TRUE
  invisible(result)
}

# The estimates on one date of one fit, or the reason there are none.
estimates_on <- function(fit, requested) {
  rt_all <- as.data.frame(summary(fit, type = "parameters", params = "R"))
  available <- sort(unique(as.Date(rt_all$date[rt_all$type != "forecast"])))
  # No silent fallback: reporting another date's row under the requested date
  # misattributes the estimate.
  if (!is.null(requested) && !(requested %in% available)) {
    return(list(error = sprintf("--date %s is not in the estimated period (%s to %s)",
                                format(requested), format(min(available)), format(max(available)))))
  }
  date <- if (!is.null(requested)) requested else max(as.Date(fit$observations$date))
  rt <- rt_all[rt_all$date == date, ][1, ]
  snap <- as.data.frame(summary(fit, type = "snapshot", target_date = date))
  # summary() rounds to 2 significant figures, which can hide whether the
  # interval crosses 1; Rt is given to 2 decimal places instead.
  snap$estimate[snap$measure == "Effective reproduction no."] <-
    sprintf("%.2f (%.2f -- %.2f)", rt$median, rt$lower_90, rt$upper_90)
  list(date = date, type = rt$type, snapshot = snap, p_below = prob_rt_below_one(fit, date))
}

report_single <- function(fit, requested, flag, weekly) {
  e <- estimates_on(fit, requested)
  if (!is.null(e$error)) stop("Requested ", e$error, ".")
  d <- compute_diagnostics(fit)
  v <- assess_diagnostics(d)
  cat(sprintf("\n# EpiNow2 estimates\n\nReference date: %s (%s) | EpiNow2 %s\n\n", format(e$date), e$type,
              as.character(utils::packageVersion("EpiNow2"))))
  cat("## Sampler diagnostics\n\n| Diagnostic | Value | Threshold |\n| :--- | ---: | :--- |\n")
  cat(sprintf("| Max Rhat | %.4f | <= 1.01 |\n| Min effective sample size | %.0f | >= 400 |\n", d$max_rhat, d$min_ess))
  cat(sprintf("| Divergent transitions | %d | 0 |\n\n", d$n_divergent))
  cat(sprintf("%d varying parameters assessed; %d fixed quantities (sd = 0) excluded.\n\n", d$n_params, d$n_excluded))

  if (!v$pass) {
    cat("Convergence: FAIL\n\n")
    for (r in v$reasons) cat(sprintf("* %s\n", r))
    cat("\n## Estimates withheld\n\n")
    cat("No Rt, growth rate, nowcast or forecast is reported from this fit: the sampler did\n")
    cat("not converge, so the posterior it explored is not the model's posterior. This is a\n")
    cat("recorded non-answer. Change the model before refitting: simplify the dynamics (a\n")
    cat("random walk in place of a Gaussian process), tighten priors, run more warmup, or\n")
    cat("estimate fewer delay components at once.\n\n")
    return(list(pass = FALSE))
  }
  cat("Convergence: PASS\n\n")

  # The qualifier sits in the Rt row: the number is what gets copied out.
  cat("## Estimates\n\n| Measure | Median (90% CrI) |\n| :--- | :--- |\n")
  for (i in seq_len(nrow(e$snapshot))) {
    m <- e$snapshot$measure[i]
    cat(sprintf("| %s | %s%s |\n", m, e$snapshot$estimate[i],
                if (m == "Effective reproduction no.") flag
                else if (m == "Expected change in reports") sprintf(" (P(Rt < 1) %s)", sub("^([0-9])", "= \\1", fmt_p(e$p_below))) else ""))
  }
  cat("\n")

  # Weekly data gives weekly forecast totals: EpiNow2 accumulates forecasts at
  # the frequency of the data it was fitted to.
  fc <- as.data.frame(summary(fit, type = "parameters", params = "reported_cases"))
  fc <- fc[!is.na(fc$type) & fc$type == "forecast" & !is.na(fc$median), ]
  if (nrow(fc) > 0) {
    cat("## Forecast of reported cases\n\n")
    cat(sprintf("| %s | Reported cases, median (90%% CrI) |\n| :--- | :--- |\n", if (weekly) "Week ending" else "Date"))
    for (i in order(fc$date)) {
      cat(sprintf("| %s | %s (%s to %s) |\n", format(fc$date[i]), fmt_n(fc$median[i]), fmt_n(fc$lower_90[i]), fmt_n(fc$upper_90[i])))
    }
    cat("\n")
  }
  list(pass = TRUE)
}

# Each stratum is gated on its own diagnostics. A run where any stratum failed
# exits non-zero, because a table with a hole in it reads as a table.
report_strata <- function(obj, requested, flag) {
  strata <- names(obj$regional)
  rows <- lapply(strata, function(nm) {
    est <- obj$regional[[nm]]
    if (is.null(est) || is.null(unclass(est)[["fit"]])) return(list(status = "ERROR", note = "stratum did not fit"))
    d <- tryCatch(compute_diagnostics(est), error = function(e) NULL)
    if (is.null(d)) return(list(status = "ERROR", note = "diagnostics unavailable"))
    e <- estimates_on(est, requested)
    if (!is.null(e$error)) return(list(status = "ERROR", note = e$error, d = d))
    v <- assess_diagnostics(d)
    list(status = if (v$pass) "PASS" else "FAIL", d = d, note = paste(v$reasons, collapse = "; "), e = e)
  })
  names(rows) <- strata

  cat(sprintf("\n# EpiNow2 estimates by stratum\n\nStrata: %d | EpiNow2 %s\n\n", length(strata),
              as.character(utils::packageVersion("EpiNow2"))))
  cat(sprintf("| Stratum | Convergence | Rt, median (90%% CrI)%s | Expected change in reports | P(Rt < 1) | Max Rhat | Min ESS | Divergences |\n", flag))
  cat("| :--- | :--- | :--- | :--- | ---: | ---: | ---: | ---: |\n")
  for (nm in strata) {
    r <- rows[[nm]]
    diag_cells <- if (is.null(r$d)) "- | - | -" else sprintf("%.4f | %.0f | %d", r$d$max_rhat, r$d$min_ess, r$d$n_divergent)
    est_cells <- if (r$status == "PASS") {
      snap <- r$e$snapshot
      sprintf("%s | %s | %s", snap$estimate[snap$measure == "Effective reproduction no."],
              snap$estimate[snap$measure == "Expected change in reports"],
              fmt_p(r$e$p_below))
    } else "withheld | - | -"
    cat(sprintf("| %s | %s | %s | %s |\n", nm, r$status, est_cells, diag_cells))
  }
  failed <- strata[vapply(rows, function(r) r$status != "PASS", logical(1))]
  if (length(failed) > 0) {
    cat("\n## Strata with estimates withheld\n\n")
    for (nm in failed) cat(sprintf("* %s: %s\n", nm, rows[[nm]]$note))
    cat("\nThis run exits non-zero: a partial table is not a successful report. A sparse stratum\n")
    cat("is the usual cause; check its counts before changing the model for every stratum.\n")
  }
  cat("\n")
  list(pass = length(failed) == 0)
}
