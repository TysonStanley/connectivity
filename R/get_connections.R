#' Get Brain Connectivity Measures
#'
#' Provides measures of connectivity between brain regions from a nested tibble returned from `import_nirs()`. It
#' fits the data to a multilevel model with a specified number of lags. It returns a tibble with effect size measures
#' to and from each region.
#'
#' @param data object from a nested tibble returned from `import_nirs()`
#' @param covariates variables to include in the model in addition to the regions of interest and the random effects
#' @param ... arguments passed to `lme4::lmer()`
#'
#' @importFrom tidyr unnest
#' @import purrr
#' @import tibble
#' @import stringr
#'
#' @export
get_connectivity <- function(data, group = NULL, covariates = NULL, ...){

  regions <- attr(data, "regions")
  forms <- all_formulas(data, group, covariates)

  d <- data %>%
    tidyr::unnest(.)

  mods <- purrr::map(seq_along(regions), ~lme4::lmer(forms[[.x]], data = d))
  summ <- purrr::map(mods, ~jtools::summ(.x, scale = TRUE, digits = 4))
  outcomes <- purrr::map(seq_along(mods), ~names(summ[[.x]]$model@frame)[[1]])
  outs <- purrr::map_df(seq_along(outcomes), ~{
    summ[[.x]]$coeftable %>%
      data.frame(.) %>%
      tibble::rownames_to_column(.) %>%
      mutate(outcome = outcomes[[.x]]) %>%
      select(outcome, rowname, `Est.`, p) %>%
      setNames(c("outcome", "rowname", "est", "pvalue")) %>%
      mutate(rowname = case_when(stringr::str_detect(rowname, pattern = "lag") ~ "lag",
                                 TRUE ~ rowname)) %>%
      filter(rowname != "(Intercept)")
    })
  outs

}



