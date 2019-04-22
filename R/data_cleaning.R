#' Import Data From NIRS Output
#'
#' Import the various CSV files necessary to conduct connectivity analysis with some quick
#' cleaning, including getting the means of the regions based on the region variable
#'
#' @param path the path to the main folder
#' @param ... the channels (a named list of numbers)
#' @param num_channels the number of channels for each of the probes
#' @param sides should the channel means be split into sides (based on the probe)
#'
#' @import fs
#' @import purrr
#' @import tibble
#' @importFrom zoo na.locf
#'
#' @export
import_nirs <- function(path = "", ..., num_channels = 24, sides = FALSE){

  path <- fs::path_tidy(path)
  regions <- list(...)
  files <- files_in_path(path)
  ## Remove any that aren't a folder
  files <- files[!grepl("\\.xlsx|\\.csv|\\.txt", files)]
  ## Load all brodExtract files for each participant
  data_brod <- extract_brod(files, path, num_channels)

  ## Load all probe1 and get the averages for the ROIs
  probe1 <- suppressWarnings(import_oxy_files(files, path, probe = 1, num_channels))
  probe2 <- suppressWarnings(import_oxy_files(files, path, probe = 2, num_channels))
  probes <- purrr::map2(probe1, probe2, ~full_join(.x, .y, by = c("time_point", "file")))
  probes <- purrr::map2(probes, data_brod, ~get_region_means(.x,
                                                             regions = regions,
                                                             channels = .y,
                                                             num_channels = num_channels,
                                                             sides = sides))
  ## Add task variable
  onsets <- extract_onset(files, path)
  probes <- purrr::map2(probes, onsets, ~{
    d = dplyr::full_join(.x, .y, by = c("time" = "start", "file"))
    d$task[1] = "None"
    d %>%
      dplyr::mutate(task = zoo::na.locf(task))
  })

  ## Return organized tibble with nested column
  ## called probe_data with all data from the probes
  df <- tibble::tibble(participant = files,
                       probe_data = probes)

  ## Little message
  msg <- paste0("\n\n", cli::col_green(cli::symbol$tick), " Data read in with ", length(files), " participants.")
  message(msg)

  ## Add regions as an attribute
  attr(df, "regions") <- names(regions)
  df
}


