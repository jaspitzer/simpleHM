
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
#>      samples     group  patient batch      var1      var2     var3     var4
#> 1 untreated1 Untreated Patient1     1  8.885159 10.776769 50.23059 8.275746
#> 2 untreated2 Untreated Patient2     2 10.156916  9.686976 54.90836 9.144239
#> 3 untreated3 Untreated Patient3     1 11.343571  8.808912 43.25903 9.971676
#> 4 untreated4 Untreated Patient1     2 10.443823  8.971469 48.33122 9.269588
#> 5 untreated5 Untreated Patient2     1 11.294030  9.374669 45.67908 8.053775
#> 6 untreated6 Untreated Patient3     2 10.520842 10.393519 44.80469 9.319474

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
```

Dendrograms are a for to visualise hierarchical clustering, but the
branches can be rotated freely, without a change in clustering or
distance between branches. For this purpose, the `pull_top` and
`pull_side` arguments can be used to “pull” certain samples to the front
through rotation along the branches of the tree.

``` r


library(patchwork)
p1 <- simpleHM(df, excluded_vars = "batch", add_dendros = T, hide_legend = T)
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
p2 <- simpleHM(df, excluded_vars = "batch", add_dendros = T, pull_top = 7:12, hide_legend = T)
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
p3 <- simpleHM(df, excluded_vars = "batch", add_dendros = T, pull_side = 3:4, hide_legend = T)
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now
p4 <- simpleHM(df, excluded_vars = "batch", add_dendros = T, pull_side = c("var1", "var3"), hide_legend = T)
#> normalisation done
#> clustering samples done
#> clustering params done
#> plotting now

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
annotated_hm_with_dendro
```

<img src="man/figures/README-unnamed-chunk-6-1.png" width="100%" />

You can also generate the separate parts like the heatmap, the
dendrogram and the annotation seperately and later combine them in a way
you see fit.

``` r
just_dendros <- simpleDendro(df, excluded_vars = "batch")
#> normalisation done
#> clustering samples done
#> clustering params done
just_dendros
#> $top
```

<img src="man/figures/README-unnamed-chunk-7-1.png" width="100%" />

    #> 
    #> $side

<img src="man/figures/README-unnamed-chunk-7-2.png" width="100%" />

``` r
just_annotations <- simpleAnno(df, excluded_vars = "batch")
#> normalisation done
#> clustering samples done
#> clustering params done
just_annotations
#> $batch
```

<img src="man/figures/README-unnamed-chunk-8-1.png" width="100%" />

    #> 
    #> $patient

<img src="man/figures/README-unnamed-chunk-8-2.png" width="100%" />

    #> 
    #> $group

<img src="man/figures/README-unnamed-chunk-8-3.png" width="100%" /> As a
note, the `excluded_vars` argument excludes the (numeric) variable from
influence in clustering and normalisation, it does not exclude it from
the annotation columns. You can however specify the columns through the
`annotation_cols` parameter:

``` r
specific_annotations <- simpleAnno(df, anno_col = c("group", "patient"))
#> normalisation done
#> clustering samples done
#> clustering params done
specific_annotations
#> $patient
```

<img src="man/figures/README-unnamed-chunk-9-1.png" width="100%" />

    #> 
    #> $group

<img src="man/figures/README-unnamed-chunk-9-2.png" width="100%" />
