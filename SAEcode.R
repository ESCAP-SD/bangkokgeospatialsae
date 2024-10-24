# small area estimation code

library(tidyverse)
library(povmap) 
library(survey)
library(haven)


# ebp is used for sub-area models and household(unit)-level models
ebp <- ebp(fixed = ebpformula, # the formula
           pop_data = predictors, # the population data
           pop_domains = "TA_CODE", # the domain (area) name in the population data
           smp_data = data, # the sample data
           smp_domains = "TA_CODE", # the domain (area) name in the sample data
           transformation = "arcsin", # I'm going to use the arcsin transformation
           weights = "total_weights", # sample weights
           weights_type = "nlme", # weights type
           MSE = TRUE, # variance? yes please
           L = 0) # this is a new thing in povmap: "analytical" point estimates. much faster!


# fh is used for area-level models

fh <- fh(
  fixed,
  vardir, # big difference is that we must give it variance estimates!
  combined_data,
  domains = NULL,
  method = "reml",
  interval = NULL,
  k = 1.345,
  mult_constant = 1,
  transformation = "no",
  backtransformation = NULL,
  eff_smpsize = NULL,
  correlation = "no",
  corMatrix = NULL,
  Ci = NULL,
  tol = 1e-04,
  maxit = 100,
  MSE = FALSE,
  mse_type = "analytical",
  B = c(50, 0),
  seed = 123
)


df <- read_dta("rastersdata/ihs5_consumption_aggregate.dta")

# create design object
designobj <- svydesign(id = ~ea_id, 
          weights = ~hh_wgt,
          strata = ~region, 
          nest = TRUE, 
          survey.lonely.psu = "adjust", 
          data = df)
# calculate total variance
svyvar(~rexpaggpc, design = designobj, na = TRUE)

# calculate BY TA (which is what we will need)
vars <- svyby(~rexpaggpc, by = ~TA, design = designobj, FUN = svyvar)
colnames(vars) <- c("TA", "var", "var.se")
df <- df |>
  left_join(vars, by = "TA")




