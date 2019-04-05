## Testing File

## The Areas for the Lab
# ipl  : Inferior parietal lobule (angular and supramarginal)
# stg  : Superior Temporal Gyrus
# ifg  : Inferior frontal gyrus
# dpcl : Dorsolateral prefrontal cortex left and right (frontal lobe)
# dpcr : Dorsolateral prefrontal cortex left and right (frontal lobe)
# mpc  : Medial prefrontal cortex (frontal lobe)
# smc  : Supplementary Motor Cortex
# mc   : Motor Cortex

library(tidyverse)
devtools::document()
devtools::check()

## Data Import
d1 <- import_nirs("~/Box/Stuttering Writing Group/PhoneCallsStutter/",
                  stg = 22, ipl = c(39, 40), ifg = c(44, 45), sma = 6, mc = 4)
d2 <- import_nirs("~/Box/Stuttering Writing Group/PhoneCallsControl/",
                  stg = 22, ipl = c(39, 40), ifg = c(44, 45), sma = 6, mc = 4)

## Group variable
d1$group <- "stutter"
d2$group <- "control"
data <- rbind(d1, d2)
attr(data, "regions")

## Both Groups
full_analysis <- get_connectivity(data, group = "group", covariates = c("(1 | participant)"))
full_analysis
effectsize_viz(full_analysis)
## Stutter
stutter <- get_connectivity(d1, covariates = c("(1 | participant)"))
stutter
effectsize_viz(stutter)
## Control
control <- get_connectivity(d2, covariates = c("(1 | participant)"))
control
effectsize_viz(control)

## Comparison between the two groups
stutter$group <- "stutter"
control$group <- "control"
effectsize_comp_viz(stutter, control)

brain <- png::readPNG("inst/brain.png")

## Adjust regions
regions_side <- tibble::tibble(
  x = c(5.0, 7, 3.0, 4.0, 4.9, 1.0, 0.0, 0.0),
  y = c(4.5, 7, 6.0, 9.7, 8.0, 8.6, 6.8, 9.3),
  region = c("stg", "ipl", "ifg", "sma", "m1", "mpc", "dpcl", "dpcr")
)
regions_top <- tibble::tibble(
  x = c(4.0, 6.0, 4.3, 5.7, 4.0, 6.0, 4.2, 5.8),
  y = c(8.7, 8.7, 8.0, 8.0, 6.7, 6.7, 5.5, 5.5),
  region = c("ldlpfc", "rdlpfc", "lmpfc", "rmpfc", "lsma", "rmsa", "lm1", "rm1")
)
regions_right <- tibble::tibble(
  x = c(9.8, 7.0, 1.5, 1.0, 8.9),
  y = c(5.5, 5.0, 6.0, 5.0, 4.0),
  region = c("ldlpfc", "rdlpfc", "smg", "ang", "mpfc")
)
regions_left <- tibble::tibble(
  x = c(2.0, 0.5, 8.5, 6.0, 0.5),
  y = c(5.0, 5.5, 5.0, 4.0, 3.0),
  region = c("ldlpfc", "rdlpfc", "ipl", "ifg", "mpfc")
)

usethis::use_data(regions_side, overwrite = TRUE)
usethis::use_data(regions_top, overwrite = TRUE)
usethis::use_data(regions_right, overwrite = TRUE)
usethis::use_data(regions_left, overwrite = TRUE)

d1 <- import_nirs("~/Box/Stuttering Writing Group/PhoneCallsStutter/",
                  ldlpfc = 22, rdlpfc = c(39, 40), mpfc = c(44, 45), smg = 6, ang = 4)
stutter <- get_connectivity(d1, covariates = c("(1 | participant)"))
brain_viz(stutter, view = "right", regs = regions_right, jitter_val = .05) + labs(title = "Stutter")
brain_viz(control) + labs(title = "Control")


