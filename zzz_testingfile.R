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
regions <- tibble::tibble(
  x = c(5.0, 7, 3.0, 4.0, 4.9, 1.0, 0.0, 0.0),
  y = c(4.5, 7, 6.0, 9.7, 8.0, 8.6, 6.8, 9.3),
  region = c("stg", "ipl", "ifg", "sma", "m1", "mpc", "dpcl", "dpcr")
)

usethis::use_data(regions, overwrite = TRUE)

brain_viz(stutter, regions = regions, jitter_val = .05) + labs(title = "Stutter")
brain_viz(control) + labs(title = "Control")


