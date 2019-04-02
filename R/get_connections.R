#' Get Brain Connectivity Measures
#'
#' Provides measures of connectivity between brain regions from a nested tibble returned from `import_nirs()`. It
#' fits the data to a multilevel model with a specified number of lags. It returns a tibble with effect size measures
#' to and from each region.
#'
#' @param data object from a nested tibble returned from `import_nirs()`
#' @param formula the model formula passed to `lme4::lmer()`
#' @param regions the variable names of the regions of interest
#' @param ... arguments passed to `lme4::lmer()`
#'
#' @export

get_connectivity <- function(data, formula, regions, ...){

  fit <- lme4::lmer(formula, data = d, ...)
  jtools::summ(fit,
               scale = TRUE,
               digits = 4)

}

`!!` <- rlang::`!!`

## http://www.scholarpedia.org/article/Brain_connectivity to read more on this stuff
