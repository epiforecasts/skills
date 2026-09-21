# What EpiNow2 offers beyond this skill

The skill takes one route through EpiNow2 where the package allows several.
Each row is a simplification, what the package also offers, and why the skill
does not. Checked against EpiNow2 1.9.0. Name the rows that bear on a user's
analysis in the review; the package documentation covers each option.

| Area | The skill | EpiNow2 also offers | Why not here |
| :--- | :--- | :--- | :--- |
| Delay families | Lognormal and gamma as they are; Weibull and exponential as EpiNow2's discretisation, with fixed parameters; a PMF | The renewal model takes lognormal, gamma, fixed and nonparametric delays and nothing else | Nothing is left out |
| Estimated delays | `estimate-delay` fits lognormal or gamma | `estimate_dist()` also fits Weibull, exponential and normal | The model takes those only with fixed parameters, which would drop the posterior uncertainty |
| Delays the user states | A mean and sd, or the family's parameters, taken as fixed | Parameters with their own uncertainty, e.g. `LogNormal(meanlog = Normal(1.6, 0.1), ...)` | Flags carry point values; the estimators keep their uncertainty in the config |
| Rt prior | EpiNow2's default, or a lognormal with a chosen mean and sd | Gamma or normal priors on initial Rt | Lognormal suits a positive, right-skewed quantity |
| Rt dynamics | Random walk, or a Gaussian process with the default kernel | Other kernels (`gp_opts(kernel = )`), breakpoints, `gp_on = "R0"`, Rt-free back-calculation (`rt = NULL`) | The two choices cover step changes and smooth change |
| Rt over the forecast | `latest` or `project` | `estimate`, or a fixed number of days back | `estimate` also holds Rt fixed over the last days of the data (24 on the England window), which changes the nowcast; on England it failed the gate |
| Observation model | Negative binomial; week effect on or off | Poisson; an ascertainment `scale`; other periodicities (`week_length`) | Defaults suit routine counts; ascertainment is not identifiable from counts alone |
| Population | Not modelled | Susceptible depletion (`rt_opts(pop = )`) | Matters over long windows or high attack rates, where a 14-day forecast is already out of scope |
| Strata | Fitted separately with one specification, or pooled | Per-stratum settings in `regional_epinow()` | One review covers every stratum |
| Secondary outcomes | Not covered | `estimate_secondary()`, `forecast_secondary()` | Two series and a chained forecast; see the package vignette |
| Sampler | Full MCMC, gated on Rhat, ESS and divergences | Variational inference, Laplace, pathfinder; `cmdstanr` | The gate needs MCMC diagnostics |
