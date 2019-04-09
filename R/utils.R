## Utils

files_in_path <- function(path){
  split_path <- unlist(fs::path_split(path))
  folder <- split_path[length(split_path)]

  files <- list.files(path) %>%
    .[!grepl(folder, .)]
  files
}

extract_brod <- function(files, path){
  purrr::map(files, ~{

    file = paste0(.x, "_brodExtract.csv")
    path_parts = c(path, .x, file)
    data = readr::read_csv(fs::path_join(path_parts),
                    col_names = FALSE) %>%
      dplyr::mutate(file = .x)

    if (NCOL(data) == 5){
      data %>%
        purrr::set_names(c("channel", "number", "name", "coverage", "file")) %>%
        dplyr::mutate(coverage = dplyr::case_when(stringr::str_detect(coverage, "[a-zA-Z]") ~ NA_character_,
                                                  TRUE ~ coverage))
    } else if (NCOL(data) == 6){
      data %>%
        set_names(c("channel", "number", "name", "coverage", "coverage2", "file")) %>%
        dplyr::mutate(coverage = dplyr::case_when(!is.na(coverage2) ~ as.character(coverage2),
                                                  TRUE ~ coverage)) %>%
        dplyr::select(-coverage2)
    }
  })
}

extract_onset <- function(files, path){
  purrr::map(files, ~{

    path_parts = c(path, .x, "ons.txt")
    data = readr::read_delim(fs::path_join(path_parts),
                             delim = "\t",
                             col_names = FALSE) %>%
      tidyr::gather("nothing", "start", 2:ncol(.)) %>%
      dplyr::select(X1, start) %>%
      dplyr::rename(task = X1) %>%
      dplyr::mutate(file = .x) %>%
      dplyr::arrange(start) %>%
      dplyr::filter(complete.cases(start))

  })
}



import_oxy_files <- function(files, path, probe){
  if (probe == 1){
    purrr::map2(files, seq_along(files), ~{

      oxy_files = list.files(paste0(path, "/", .x), pattern = "Oxy\\.csv$")
      file = oxy_files[grepl("Probe1", oxy_files)]
      readr::read_csv(paste0(path, "/", .x, "/", file),
               skip = 40) %>%
        dplyr::rename("time_point" = `Probe1(Oxy)`,
                       "CH01" = "CH1",
                       "CH02" = "CH2",
                       "CH03" = "CH3",
                       "CH04" = "CH4",
                       "CH05" = "CH5",
                       "CH06" = "CH6",
                       "CH07" = "CH7",
                       "CH08" = "CH8",
                       "CH09" = "CH9") %>%
        dplyr::select(time_point:PreScan) %>%
        dplyr::mutate(file = .x,
                      time = seq(0.1, nrow(.)/10, by = .1))
    })
  } else if (probe == 2) {
    purrr::map2(files, seq_along(files), ~{

    oxy_files = list.files(paste0(path, "/", .x), pattern = "Oxy\\.csv$")
    file = oxy_files[grepl("Probe2", oxy_files)]
    readr::read_csv(paste0(path, "/", .x, "/", file),
             skip = 40) %>%
      dplyr::mutate(file = .x) %>%
      dplyr::select(1:30, file) %>%
      purrr::set_names(c("time_point", paste0("CH", 25:48),
                         "Mark", "Time", "BodyMovement", "RemovalMark", "PreScan", "file"))
    })
  } else {
    stop("Only probe == 1 or probe == 2 allowed", call. = FALSE)
  }
}

get_region_means <- function(data, regions, channels, weighted = FALSE){

  for (i in seq_along(regions)){
    channel = channels %>% filter(number %in% regions[[i]])

    if (all(channel$channel %in% names(data))){
      data[, paste0(names(regions)[i])] <- rowMeans(data[, channel$channel])
    } else {
      stop(paste("Couldn't find", paste(unique(channel$channel), collapse = ", "), "in the imported data"), call. = FALSE)
    }

  }
  data
}


all_formulas <- function(data, group, covariates){

  regions <- attr(data, "regions")
  form    <- vector("list", length = length(regions))
  group   <- if (!is.null(group)) paste("*", group)

  for (i in seq_along(regions)){

    main_int <- ifelse(!is.null(group),
                       paste(regions[!grepl(regions[i], regions)], group, collapse = " + "),
                       paste(regions[!grepl(regions[i], regions)], collapse = " + "))
    cov <- ifelse(!is.null(covariates), paste(" + ", paste(covariates, collapse = " + ")), "")

    form[[i]] <- paste(regions[[i]], "~", main_int, "+ lag(", regions[i], ", 1)", cov) %>%
      formula()

  }

  form
}


`%>%` <- dplyr::`%>%`

