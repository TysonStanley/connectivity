## Testing File
library(tidyverse)

devtools::document()
usethis::use_readme_rmd()
usethis::use_vignette("overview")


## Superior Temporal Gyrus (STG),
## Inferior Parietal Lobule (made up of Supramarginal Gyrus and Angular Gyrus),
## Inferior frontal Gyrus (IFG),
## Supplementary Motor Association (SMA) and
## the Motor Cortex (M1).
regions = list(stg = 22,
               ipl = c(39, 40),
               ifg = c(44, 45),
               sma = 6,
               pmc = 4)
data = import_nirs("~/Box/Stuttering Writing Group/PhoneCallsStutter/",
                   stg = 22, ipl = c(39, 40), ifg = c(44, 45), sma = 6, pmc = 4)

d = data %>%
  unnest() %>%
  filter(time_point %% 20 == 0)

get_connectivity(d,
                 formula = stg ~ ipl + ifg + sma + pmc + lag(stg) + time_point + (1 | participant))

data %>%
  unnest()
