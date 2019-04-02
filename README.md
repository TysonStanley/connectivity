
<!-- README.md is generated from README.Rmd. Please edit that file -->

# connectivity

The goal of connectivity is to make the importing, cleaning, and
analyzing of NIRS data recipe based. That is, piping three main
functions will lead from import to analysis with minimal effort of the
user.

## Installation

You can install the GitHub version of `connectivity` with:

``` r
remotes::install_github("tysonstanley/connectivity")
```

## Example

The receipe is as follows:

1.  Import and Clean
2.  Analyze
3.  Visualize

The `import_nirs()` function depends on a files structure that looks
something like:

    -- P07
       |__P07_brodExtract.csv
       |__P07_HBA_Probe1_Deoxy.csv
       |__P07_HBA_Probe1_Oxy.csv
       |__P07_HBA_Probe1_Total.csv
       |__P07_HBA_Probe2_Deoxy.csv
       |__P07_HBA_Probe2_Oxy.csv
       |__P07_HBA_Probe2_Total.csv
    -- P08
       |__P08_brodExtract.csv
       |__P08_HBA_Probe1_Deoxy.csv
       |__P08_HBA_Probe1_Oxy.csv
       |__P08_HBA_Probe1_Total.csv
       |__P08_HBA_Probe2_Deoxy.csv
       |__P08_HBA_Probe2_Oxy.csv
       |__P08_HBA_Probe2_Total.csv
    -- P09
       |__P09_brodExtract.csv
       |__P09_HBA_Probe1_Deoxy.csv
       |__P09_HBA_Probe1_Oxy.csv
       |__P09_HBA_Probe1_Total.csv
       |__...

where each participant has its own folder with the data within that
folder.

In our data (not currently provided), we have 5 regions that we are
interested in that are mapped out in the `*brod.csv` files. To inform on
what region goes with which channel from the Probe files, we use the
import function like so:

``` r
## Superior Temporal Gyrus (STG),
## Inferior Parietal Lobule (made up of Supramarginal Gyrus and Angular Gyrus),
## Inferior frontal Gyrus (IFG),
## Supplementary Motor Association (SMA) and
## the Motor Cortex (M1)
path <- "~/Box/Stuttering Writing Group/PhoneCallsStutter/"
data <- import_nirs(path,
                    stg = 22, ipl = c(39, 40), ifg = c(44, 45), sma = 6, pmc = 4)
```

The `stg = 22, ipl = c(30, 40), ...` correspond to regions (the name)
and their number in the `*brod.csv` file. This creates a nested tibble
called `data` that looks like this:

``` r
data
```
