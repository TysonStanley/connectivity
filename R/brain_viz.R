#' Brain Visual
#'
#' Provides a `ggplot2` figure of the connections of regions of the brain.
#'
#' @param obj from `get_connectivity()`
#' @param jitter_val control how far away the overlapping lines are (default is .04)
#' @param view the view of the brain diagram (available options are "side", "top", "right", "left"). If the image argument is given a path, then that image will be used instead of the built-in ones.
#' @param image If NULL then the default images (based on `view`); otherwise the path to the figure should be supplied here
#' @param regs Alternate locations for the regions of interest (needs to have x, y, and region as the variables)
#' @param diff For comparison brain viz's, this is the difference between the largest effect size of one to the other (current sample - comparison sample). Adjusts the size of the arrows to be more comparable across samples.
#' @param colors If NULL, then it colored based on outcome region. Otherwise can define based on the `get_connectivity()` object.
#' @param alpha the alpha level for significance
#'
#' @import ggplot2
#' @import dplyr
#' @importFrom png readPNG
#'
#' @export
brain_viz <- function(obj, jitter_val = .04, view = "side", image = NULL, regs = NULL, diff = 0, colors = NULL, alpha = .001){

  if (is.null(regs)){

    regions <-
      switch(view,
             side  = connectivity::regions_side,
             top   = connectivity::regions_top,
             right = connectivity::regions_right,
             left  = connectivity::regions_left)

  } else {
    regions <- regs
  }

  if (is.null(image)){

    brain <-
      switch(view,
             side  = png::readPNG(find_file("brain_side.png")),
             top   = png::readPNG(find_file("brain_top.png")),
             right = png::readPNG(find_file("brain_rightangle.png")),
             left  = png::readPNG(find_file("brain_leftangle.png")))

  } else {
    brain <- png::readPNG(image)
  }

  fig_data <- obj %>%
    dplyr::inner_join(regions, by = c("outcome" = "region")) %>%
    dplyr::inner_join(regions, by = c("rowname" = "region")) %>%
    dplyr::rename(x = x.x,
                  y = y.x,
                  xend = x.y,
                  yend = y.y) %>%
    dplyr::filter(rowname != "lag") %>%
    dplyr::mutate(sig = dplyr::case_when(pvalue <= alpha ~ 1,
                                         pvalue > alpha ~ 0)) %>%
    dplyr::mutate(sig = factor(sig, levels = c(0,1))) %>%
    dplyr::mutate(x_padding = x - xend,
                  y_padding = y - yend,
                  pythag = sqrt(x_padding^2 + y_padding^2)) %>%
    ## Standardize the padding using pythagorean theorem
    dplyr::mutate(x_padding = x_padding / pythag*.6,
                  y_padding = y_padding / pythag*.6) %>%
    ## Slope of line and inverse of slope
    dplyr::mutate(slope = (y - yend) / (x - xend),
                  inv_slope = - 1 / slope) %>%
    ## Jitter (for each region pair, we need a positive jitter for one and negative jitter for the other)
    ## First, create unique indicator for each pair (comb)
    dplyr::mutate(comb = purrr::map2(outcome, rowname, ~c(.x, .y) %>% sort())) %>%
    dplyr::mutate(comb = purrr::map_chr(comb, ~paste(.x[1], .x[2]))) %>%
    dplyr::mutate(inv_slope = dplyr::case_when(is.infinite(inv_slope) ~ 10,
                                               TRUE ~ inv_slope)) %>%
    dplyr::mutate(inv_slope = scale(inv_slope)) %>%
    dplyr::group_by(comb) %>%
    dplyr::mutate(y_perp = dplyr::case_when(row_number() == 1 ~ y - inv_slope*jitter_val,
                                            row_number() == 2 ~ y + inv_slope*jitter_val),
                  x_perp = dplyr::case_when(row_number() == 1 ~ x - jitter_val,
                                            row_number() == 2 ~ x + jitter_val),
                  yend_perp = dplyr::case_when(row_number() == 1 ~ yend - inv_slope*jitter_val,
                                               row_number() == 2 ~ yend + inv_slope*jitter_val),
                  xend_perp = dplyr::case_when(row_number() == 1 ~ xend - jitter_val,
                                               row_number() == 2 ~ xend + jitter_val)) %>%
    dplyr::ungroup() %>%
    ## Get rid of intermediate variables
    dplyr::select(outcome, rowname, est, pvalue, x, y, xend, yend, x_perp, y_perp, xend_perp, yend_perp,
                  sig, x_padding, y_padding)

  if (is.null(colors)){
    fig_data <- fig_data %>%
      dplyr::mutate(coloring = outcome) %>%
      dplyr::mutate(outcome = stringr::str_remove_all(outcome, "_right$|_left$"))
  } else {
    ## If `est` in colors use that one
    nams <- names(colors)
    if (isTRUE("est" %in% nams)){
      fig_data <- fig_data %>%
        select(-est) %>%
        dplyr::inner_join(colors) %>%
        dplyr::mutate(outcome = stringr::str_remove_all(outcome, "_right$|_left$"))
    } else {
      fig_data <- fig_data %>%
        dplyr::inner_join(colors) %>%
        dplyr::mutate(outcome = stringr::str_remove_all(outcome, "_right$|_left$"))
    }
  }

  if (all(fig_data$sig == 1)){
    alphas <- .95
  } else if (all(fig_data$sig == 0)){
    alphas <- .1
  } else {
    alphas <- c(.1, .95)
  }

  ## adjusts the size of arrows based on difference of effect sizes across groups (if applicable)
  diff <- 3 + diff

  ## Brain Viz
  p <- ggplot2::ggplot(fig_data, ggplot2::aes(x, y)) +
    ggplot2::annotation_custom(grid::rasterGrob(brain,
                                                width = ggplot2::unit(1,"npc"),
                                                height = ggplot2::unit(1,"npc")))
  ## Add circles and text based on colors object (if colors != NULL, then black for both, otherwise color by outcome)
  if (!is.null(colors)) p <- p + ggplot2::geom_point(size = 15, shape = 21, fill = "white", color = "black") + ggplot2::geom_text(ggplot2::aes(label = toupper(outcome)), color = "black")
  if (is.null(colors)) p <- p + ggplot2::geom_point(size = 15, shape = 21, fill = "white", ggplot2::aes(color = coloring)) + ggplot2::geom_text(ggplot2::aes(label = toupper(outcome), color = coloring))
  p +
    ggplot2::geom_curve(ggplot2::aes(xend = x_perp - x_padding,
                                     yend = y_perp - y_padding,
                                     x = xend_perp + x_padding,
                                     y = yend_perp + y_padding,
                                     alpha = sig,
                                     size = abs(est),
                                     color = coloring,
                                     linetype = factor(ifelse(est >= 0, 1, 0))),
                        arrow = ggplot2::arrow(length = ggplot2::unit(0.02, "npc")),
                        curvature = 0) +
    ggplot2::coord_cartesian(xlim = c(0,10),
                             ylim = c(0,10)) +
    ggplot2::theme_void() +
    ggplot2::scale_alpha_manual(values = alphas) +
    ggplot2::scale_size(range = c(0.2, diff)) +
    ggplot2::scale_linetype_manual(values = c("dashed", "solid"))

}


#' Calculate Difference of Effect Sizes for Brain Viz
#'
#' @param obj1 from `get_connectivity()`
#' @param obj2 from `get_connectivity()`
#' @param pattern the regular expression to grab the variables not to be included (e.g., the lag or time variables)
#'
#' @import stringr
#' @import dplyr
#'
#' @export
calc_diff <- function(obj1, obj2, pattern = "lag|time"){

  obj1 <- filter(obj1, !stringr::str_detect(rowname, pattern) %>% pull(est))
  obj2 <- filter(obj2, !stringr::str_detect(rowname, pattern) %>% pull(est))

  (max(obj1) - max(obj1)) / mean(c(max(obj1), max(obj2)))

}



#' Effect Size Visual
#'
#' Provides a `ggplot2` line graph of the connections of regions of the brain.
#'
#' @param obj from `get_connectivity()`
#'
#' @import ggplot2
#' @import dplyr
#'
#' @export
effectsize_viz <- function(obj){

  obj <- obj %>%
    filter(rowname != "lag")

  ggplot2::ggplot(obj, ggplot2::aes(rowname, est)) +
    ggplot2::geom_point(alpha = .9) +
    ggplot2::geom_segment(ggplot2::aes(xend = rowname, yend = 0),
                          alpha = .9) +
    ggplot2::facet_wrap(~outcome, scales = "free")

}

#' Effect Size Comparison Visual
#'
#' Provides a `ggplot2` line graph of the connections of regions of the brain.
#'
#' @param obj1 from `get_connectivity()` with a grouping variable called `group`
#' @param obj2 from `get_connectivity()` with a grouping variable called `group`
#'
#' @export
effectsize_comp_viz <- function(obj1, obj2){

  d <- rbind(obj1, obj2)
  d <- d %>%
    filter(rowname != "lag")

  ggplot2::ggplot(d, ggplot2::aes(rowname, est, color = group, linetype = group)) +
    ggplot2::geom_point(alpha = .9) +
    ggplot2::geom_segment(ggplot2::aes(xend = rowname, yend = 0),
                          alpha = .9) +
    ggplot2::facet_wrap(~outcome, scales = "free")

}

