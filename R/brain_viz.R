#' Brain Visual
#'
#' Provides a `ggplot2` figure of the connections of regions of the brain.
#'
#' @param obj from `get_connectivity()`
#' @param jitter_val control how far away the overlapping lines are (default is .04)
#' @param view the view of the brain diagram (available options are "side", "top", "right", "left"). If the image argument is given a path, then that image will be used instead of the built-in ones.
#' @param image If NULL then the default images (based on `view`); otherwise the path to the figure should be supplied here
#' @param regs Alternate locations for the regions of interest (needs to have x, y, and region as the variables)
#' @param ratio For comparison brain viz's, this is the ratio of the largest effect size of one to the other (current sample / comparison sample).
#'
#' @import ggplot2
#' @import dplyr
#' @importFrom png readPNG
#'
#' @export
brain_viz <- function(obj, jitter_val = .04, view = "side", image = NULL, regs = NULL, ratio = 1){

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
    dplyr::mutate(sig = dplyr::case_when(pvalue <= .05 ~ 1,
                                         pvalue > .05 ~ 0)) %>%
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

  if (all(fig_data$sig == 1)){
    alphas <- .95
  } else if (all(fig_data$sig == 0)){
    alphas <- .2
  } else {
    alphas <- c(.2, .95)
  }

  ## standardize the size of arrows based on ratio of effect sizes across groups (if applicable)
  ratio <- 3*ratio

  ggplot2::ggplot(fig_data, ggplot2::aes(x, y)) +
    ggplot2::annotation_custom(grid::rasterGrob(brain,
                                                width = ggplot2::unit(1,"npc"),
                                                height = ggplot2::unit(1,"npc"))) +
    ggplot2::geom_point(size = 15, shape = 21, fill = "white",
                        ggplot2::aes(color = outcome)) +
    ggplot2::geom_text(ggplot2::aes(label = toupper(outcome),
                                    color = outcome)) +
    ggplot2::geom_curve(ggplot2::aes(xend = x_perp - x_padding,
                                     yend = y_perp - y_padding,
                                     x = xend_perp + x_padding,
                                     y = yend_perp + y_padding,
                                     alpha = sig,
                                     size = abs(est),
                                     color = outcome),
                        arrow = ggplot2::arrow(length = ggplot2::unit(0.02, "npc")),
                        curvature = 0) +
    ggplot2::coord_cartesian(xlim = c(0,10),
                             ylim = c(0,10)) +
    ggplot2::theme_void() +
    ggplot2::scale_alpha_manual(values = alphas) +
    ggplot2::theme(legend.position = "none") +
    ggplot2::scale_size(range = c(0.3, ratio))

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

