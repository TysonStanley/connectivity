.onLoad <- function(libname = find.package("connectivity"), pkgname = "connectivity"){
  if(getRversion() >= "2.15.1") {
    utils::globalVariables(c(".", "est", "rowname", "group", "number", "comb", "formula", "x", "y", "x.x", "y.x", "x.y", "y.y",
                             "x_padding", "x_perp", "xend", "xend_perp", "y_padding", "y_perp", "yend", "yend_perp",
                             "slope", "sig", "pythag", "pvalue", "inv_slope", "outcome", "probe"))
  }
  invisible()
}
