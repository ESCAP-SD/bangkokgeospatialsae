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


# getting variance with the "direct" function
df <- read_dta("rastersdata/ihs5_consumption_aggregate.dta")
direct <- direct(y = "rexpaggpc", # the variable
           smp_data = df, # the sample data
           smp_domains = "TA", # the domain (area) name in the sample data
           weights = "hh_wgt", # sample weights
           var = TRUE,
           HT = TRUE)

direct$MSE

direct <- as_tibble(direct$MSE)
direct <- direct |>
  select(TA = Domain, var = Mean) |>
  mutate(TA = as.character(TA))





temp$zila <- temp$zl
temp$upazila <- temp$upz

temp$new <- paste(temp$dvn, temp$zila, temp$upazila, sep = "-")

temp$ADM1_PCODE <- temp$div

temp$zila[str_length(temp$zila)==1] <- paste0("0", temp$zila[str_length(temp$zila)==1])
temp$ADM2_PCODE <- paste0(temp$ADM1_PCODE, temp$zila)

temp$upazila[str_length(temp$upazila)==1] <- paste0("0", temp$upazila[str_length(temp$upazila)==1])
temp$ADM3_PCODE <- paste0(temp$ADM2_PCODE, temp$upazila)

temp$source <- gsub("div_", "", temp$source)
temp$source <- gsub("_sample_all.dta", "", temp$source)
temp$ADM4_PCODE <- paste0(temp$ADM3_PCODE, temp$source)





