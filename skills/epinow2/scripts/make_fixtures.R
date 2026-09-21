#!/usr/bin/env Rscript

# Test fixtures for test_epinow2.R and TEST.md, written to one directory:
#
#   Rscript scripts/make_fixtures.R <dir>

make_fixtures <- function(dir) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  w <- function(df, name) write.csv(df, file.path(dir, name), row.names = FALSE)

  # A linelist with onset and report dates; delay lognormal(log 3, 0.6).
  set.seed(42)
  onset <- as.Date("2024-01-01") + sample(0:60, 300, replace = TRUE)
  ll <- data.frame(id = 1:300, date_onset = onset, date_report = onset + round(rlnorm(300, log(3), 0.6)))
  ll$date_report[1:3] <- ll$date_onset[1:3] - 2   # negative delays
  w(ll, "linelist.csv")

  d <- seq(as.Date("2024-01-01"), by = "day", length.out = 60)
  w(data.frame(date_report = d, confirm = rpois(60, 50)), "cases_report.csv")
  w(data.frame(date_report = d + 60, confirm = rpois(60, 50)), "cases_report_week2.csv")
  w(data.frame(date = d, confirm = rpois(60, 50)), "measles.csv")
  clean <- data.frame(date = d, confirm = rpois(60, 50))
  w(clean, "clean.csv")
  w(clean[-c(10, 11, 25), ], "gappy.csv")
  bad <- clean
  bad$confirm[5] <- -4
  w(bad, "negative.csv")

  # Strata under a column name nothing looks for, one of them too sparse.
  set.seed(11)
  w(rbind(data.frame(date = d, confirm = rpois(60, 60), district = "north"),
          data.frame(date = d, confirm = rpois(60, 35), district = "south"),
          data.frame(date = d[1:10], confirm = rpois(10, 3), district = "island")), "regions.csv")
  # Dates repeat, and no column tells the rows apart.
  w(data.frame(date = rep(d[1:30], 2), confirm = rpois(60, 20)), "dup_dates.csv")

  # A bare date/count series: nothing says what the date is.
  set.seed(7)
  w(data.frame(date = seq(as.Date("2024-01-01"), by = "day", length.out = 120), count = rpois(120, 40)), "bare.csv")

  # Three date columns, onset 61% complete, and a column that could split it.
  set.seed(8)
  on <- as.Date("2024-03-01") + sample(0:90, 400, replace = TRUE)
  ll3 <- data.frame(id = 1:400, onset_date = as.character(on), specimen_date = as.character(on + rpois(400, 2)),
                    report_date = as.character(on + rpois(400, 4)))
  ll3$onset_date[sample(400, 156)] <- NA
  ll3$sex <- sample(c("f", "m"), 400, replace = TRUE)
  w(ll3, "linelist3.csv")

  # Five cases over 21 days: the days between are zeros, not gaps.
  w(data.frame(id = 1:5, onset_date = as.character(as.Date("2024-01-01") + c(0, 3, 4, 9, 20))), "sparse_ll.csv")

  # From EpiNow2: a reference series, the same epidemic as weekly totals
  # dated by the last day of each week, and snapshots of a truncated series.
  ec <- EpiNow2::example_confirmed
  w(ec[1:60, c("date", "confirm")], "ec.csv")
  w(data.frame(week_ending = ec$date[7 * (1:18)], cases = colSums(matrix(ec$confirm[1:126], 7))), "weekly.csv")
  dir.create(file.path(dir, "vintages"), showWarnings = FALSE)
  v <- EpiNow2::example_truncated
  for (i in seq_along(v)) w(as.data.frame(v[[i]])[, c("date", "confirm")], sprintf("vintages/v%02d.csv", i))
  invisible(dir)
}

if (sys.nframe() == 0) {
  dir <- commandArgs(trailingOnly = TRUE)[1]
  if (is.na(dir)) stop("Usage: Rscript make_fixtures.R <dir>")
  make_fixtures(dir)
  cat("Fixtures written to", dir, "\n")
}
