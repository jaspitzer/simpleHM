
<!-- README.md is generated from README.Rmd. Please edit that file -->

# simpleHM

<!-- badges: start -->
<!-- badges: end -->

The goal of simpleHM is to …

## Installation

You can install the development version of simpleHM from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("jaspitzer/simpleHM")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(simpleHM)

df <- data.frame(samples = c(paste0("untreated", 1:6), paste0("treated", 7:12)),
                 group = c(rep("Untreated",6), rep("Treated",6)),
                 patient = c(rep(paste0("Patient", 1:3), 4)),
                 batch = rep(1:2, 6),
                 var1 = c(rnorm(6, 10, 1),  rnorm(6, 7, .7)),
                 var2 = c(rnorm(6, 10, 1),  rnorm(6, 200, 10)),
                 var3 = c(rnorm(6, 50, 5),  rnorm(6, 10, 1)),
                 var4 = c(rnorm(6, 10, 1),  rnorm(6, 60, .7)))

head(df)
#>      samples     group  patient batch      var1      var2     var3      var4
#> 1 untreated1 Untreated Patient1     1  8.891739  9.220799 57.41239 10.088072
#> 2 untreated2 Untreated Patient2     2 10.737352  8.458915 57.92662 10.885514
#> 3 untreated3 Untreated Patient3     1 11.001549 10.176619 49.35026  9.854329
#> 4 untreated4 Untreated Patient1     2  9.719786 11.301982 42.28681 10.444724
#> 5 untreated5 Untreated Patient2     1  9.721286  9.080322 51.96233  9.700775
#> 6 untreated6 Untreated Patient3     2 10.996322 10.454314 48.94407 10.340856

heatmap_plot <- simpleHM(df, excluded_vars = "batch")    
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
heatmap_plot
```

<img src="man/figures/README-example-1.png" width="100%" />

By default the sample names for \<50 samples or \>100 params are hidden.
You can also hide them by using the `show_sample_names` and
`show_param_names` arguments.

``` r
heatmap_plot_no_sample_names <- simpleHM(df, excluded_vars = "batch", show_sample_names = F)    
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
heatmap_plot_no_sample_names
```

<img src="man/figures/README-unnamed-chunk-2-1.png" width="100%" />

``` r
heatmap_plot_no_param_names <- simpleHM(df, excluded_vars = "batch", show_param_names = F)    
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
heatmap_plot_no_param_names
```

<img src="man/figures/README-unnamed-chunk-2-2.png" width="100%" />

You can also add Annotation bars for several of the conditions by using
the `add_annotation` parameter:

``` r
hm_with_anno <- simpleHM(df, add_annotation = T, anno_col = c("group", "patient"), excluded_vars = "batch")
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
#> adding annotation
#> wrapping plots up
hm_with_anno
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />

By default, the samples and parameters are clustered. To display the
dendrograms, set `add_dendros=T`.

``` r
hm_with_dendro <- simpleHM(df, excluded_vars = "batch", add_dendros = T)
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
#> Scale for y is already present.
#> Adding another scale for y, which will replace the existing scale.
#> Scale for x is already present.
#> Adding another scale for x, which will replace the existing scale.
```

Dendrograms are a for to visualise hierarchical clustering, but the
branches can be rotated freely, without a change in clustering or
distance between branches. For this purpose, the `pull_top` and
`pull_side` arguments can be used to “pull” certain samples to the front
through rotation along the branches of the tree.

``` r


library(patchwork)
p1 <- simpleHM(df, excluded_vars = "batch", add_dendros = T )
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
#> Scale for y is already present.
#> Adding another scale for y, which will replace the existing scale.
#> Scale for x is already present.
#> Adding another scale for x, which will replace the existing scale.
p2 <- simpleHM(df, excluded_vars = "batch", add_dendros = T, pull_top = 7:12)
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
#> Scale for y is already present.
#> Adding another scale for y, which will replace the existing scale.Scale for x is already present.
#> Adding another scale for x, which will replace the existing scale.
p3 <- simpleHM(df, excluded_vars = "batch", add_dendros = T, pull_side = 3:4)
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
#> Scale for y is already present.
#> Adding another scale for y, which will replace the existing scale.Scale for x is already present.
#> Adding another scale for x, which will replace the existing scale.
p4 <- simpleHM(df, excluded_vars = "batch", add_dendros = T, pull_side = c("var1", "var3"))
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
#> Scale for y is already present.
#> Adding another scale for y, which will replace the existing scale.Scale for x is already present.
#> Adding another scale for x, which will replace the existing scale.

combined_plots1 <- wrap_plots(list(p1, p2), ncol = 2)
combined_plots2 <- wrap_plots(list(p3, p4), ncol = 2)

combined_plots1
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />

``` r
combined_plots2
```

<img src="man/figures/README-unnamed-chunk-5-2.png" width="100%" />

These options can also be combined:

``` r
annotated_hm_with_dendro <- simpleHM(df, excluded_vars = "batch", add_annotation = T, anno_col = c("group", "patient"), add_dendros = T)
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
#> adding annotation
#> wrapping plots up
#> Scale for y is already present.
#> Adding another scale for y, which will replace the existing scale.
#> Scale for x is already present.
#> Adding another scale for x, which will replace the existing scale.
annotated_hm_with_dendro
```

<img src="man/figures/README-unnamed-chunk-6-1.png" width="100%" />
