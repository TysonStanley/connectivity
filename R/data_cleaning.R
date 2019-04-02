#' Import Data From NIRS Output
#'
#' Import the various CSV files necessary to conduct connectivity analysis with some quick
#' cleaning, including getting the means of the regions based on the region variable
#'
#' @param path the path to the main folder
#' @param ... the channels (a named list of numbers)
#'
#' @import fs
#' @import purrr
#' @import tibble
#' @import rlang
#'
#' @export
import_nirs <- function(path = "", ...){

  keep <- rlang::quo(keep)
  path <- fs::path_tidy(path)
  regions <- list(...)
  files <- files_in_path(path)
  ## Load all brodExtract files for each participant
  data_brod <- extract_brod(files, path)

  ## Load all probe1 and get the averages for the ROIs
  probe1 <- import_oxy_files(files, path, probe = 1)
  probe2 <- import_oxy_files(files, path, probe = 2)
  probes <- purrr::map2(probe1, probe2, ~full_join(.x, .y, by = c("time_point", "file")))
  probes <- purrr::map2(probes, data_brod, ~get_region_means(.x, regions = regions, channels = .y))

  ## Return organized tibble with nested column
  ## called probe_data with all data from the probes
  tibble::tibble(participant = files,
                 probe_data = probes)
}


