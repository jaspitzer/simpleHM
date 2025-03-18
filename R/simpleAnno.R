#' Return the annotation bars for the heatmap
#'
#' @param df a dataframe to containing the data to be plotted. Required
#' @param clust_samples  should the samples be clustered? T/F
#' @param clust_params should the variables be clustered? T/F
#' @param param_order can be used to suplly a vector containg a custom order for the variables. Ignored if clust_params = TRUE
#' @param linkage which linkage method to use. defaults
#' @param pull_top should the dendrogram be rotated? if yes, what levels should be pulled to the front? Accepts numeric values (current order) and variable names
#' @param pull_side should the dendrogram be rotated? if yes, what levels should be pulled to the front? Accepts numeric values (current order) and variable names
#' @param normalise_params should the variables be normalized? defaults to T
#' @param normalise_samples should normalisation be applied to samples? defaults to F
#' @param norm_method which method should be applied to normalise? can be min/max scaling or z-score; T/F
#' @param excluded_vars character vector of variabels to be excluded
#' @param id_col a character with id column clearly identifying each sample
#' @param anno_col which columns is the data contain annotation? can be a character vector.
#' @param annotation_colors a list containing the vectors with colors for every annotation column
#'
#' @returns return a list of ggplot object, each corresponding to one element of anno_col
#' @export
#'
#' @examples df <- data.frame(samples = c(paste0("untreated", 1:6), paste0("treated", 7:12)),
#'                            group = c(rep("Untreated",6), rep("Treated",6)),
#'                            patient = c(rep(paste0("Patient", 1:3), 4)),
#'                            var1 = c(rnorm(6, 10, 1),  rnorm(6, 7, .7)),
#'                            var2 = c(rnorm(6, 10, 1),  rnorm(6, 200, 10)),
#'                            var3 = c(rnorm(6, 50, 5),  rnorm(6, 10, 1)),
#'                            var4 = c(rnorm(6, 10, 1),  rnorm(6, 60, .7)))
#'
#' heatmap_anno <- simpleAnno(df)
#' heatmap_anno
simpleAnno <- function(df, 
                    clust_samples = T, # should the samples (columns)  be clustered
                    clust_params = T, # should the parameters (rows) be clustered
                    param_order = NULL, # if the parameters are not clustered, you can supply a custom order
                    linkage = "complete", #what linkage method for clustering
                    pull_top = NULL,
                    pull_side = NULL,
                    
                    normalise_params = T,  # normalisation across parameters (z-score)
                    normalise_samples = F, # normalisation across samples
                    norm_method = "zscore", # which normmilastion to use, zscore or max
                    
                    excluded_vars = c(), # numeric variables included as columns which are not to be included in the heatmap(i.e. batch 1,2,3)
                    id_col = "", # column identifying each sample, defaults to first colum if empty)
                    anno_col = "", # which columns contains annotations, defaults to everything but the identifier or the not excluded numeric columns
                    annotation_colors = list()){
  df_input <- df %>% 
    {if(nchar(id_col) > 0) dplyr::rename(.,"SAMPLE" = id_col)  else dplyr::rename(.,"SAMPLE" = 1)}
  
  if(normalise_params) { #normalise params
    df_input <- normalise.params(df_input, norm_method, excluded_vars)
  }
  
  if(normalise_samples){ #normalize samples
    df_input <- normalise.samples(df_input, norm_method, excluded_vars)
  }
  
  if(clust_samples){
    samples_clust <- clust.samples(df_input, excluded_vars)
    
    order_samples <- samples_clust$labels[samples_clust$order]
    if(!is.null(pull_top)){
      if(is.numeric(pull_top)){
        order_samples <- samples_clust$labels[samples_clust$order] %>% forcats::fct_inorder() %>% forcats::fct_relevel(samples_clust$labels[samples_clust$order[pull_top]]) %>% levels()
        samples_clust <- dendextend::rotate(samples_clust, order_samples)
      }
      if(is.character(pull_top)){
        order_samples <- samples_clust$labels[samples_clust$order] %>% forcats::fct_inorder() %>% forcats::fct_relevel(pull_top) %>% levels()
        samples_clust <- dendextend::rotate(samples_clust, order_samples)
      }
    }
  }
  
  if(clust_params){
    params_clust <- clust.params(df_input, excluded_vars)
    order_params <- params_clust$labels[params_clust$order]
    
    if(!is.null(pull_side)){
      if(is.numeric(pull_side)){
        order_params <- params_clust$labels[params_clust$order] %>% forcats::fct_inorder() %>% forcats::fct_relevel(params_clust$labels[params_clust$order[pull_side]]) %>% levels()
        params_clust <- dendextend::rotate(params_clust, order_params)
      }
      if(is.character(pull_side)){
        order_params <- params_clust$labels[params_clust$order] %>% forcats::fct_inorder() %>% forcats::fct_relevel(pull_side) %>% levels()
        params_clust <- dendextend::rotate(params_clust, order_params)
      }
    }
  }
  
  
  df_plot <- df_input %>%
    tidyr::pivot_longer(cols = dplyr::where(is.numeric) & !excluded_vars,
                        names_to = "params",
                        values_to = "val")
  df_plot <- df_plot %>%
    {if(nchar(id_col) > 0) dplyr::rename(.,"SAMPLE" = id_col)  else dplyr::rename(.,"SAMPLE" = 1)}
  df_plot <- df_plot %>%
    dplyr::mutate(SAMPLE = forcats::as_factor(SAMPLE),
                  params = forcats::as_factor(params)) %>%
    {if (clust_params) dplyr::mutate(., params = forcats::fct_relevel(params, order_params)) else . } %>%
    {if (clust_samples) dplyr::mutate(., SAMPLE = forcats::fct_relevel(SAMPLE, order_samples)) else . } %>%
    {if (!clust_params & !is.null(param_order)) dplyr::mutate(., params = forcats::fct_relevel(params, param_order)) else . }
  
  
  if(length(anno_col) > 1){
    if(!all(anno_col %in% colnames(df_plot))){
      stop("not all supplied columns are in the data frame")
    }
    anno_cols <- anno_col
  }else{
    anno_cols <- df_plot %>%
      dplyr::select(-c(SAMPLE, params, val)) %>% names()
  }
  
  anno_list <- list()
  for(col in 1:length(anno_cols)){
    anno <- df_plot %>%
      dplyr::mutate(dplyr::across(anno_cols, forcats::as_factor)) %>% 
      ggplot2::ggplot(ggplot2::aes_string(y = 1, x = "SAMPLE", fill = anno_cols[col])) +
      ggplot2::geom_tile()+
      ggplot2::scale_y_discrete(breaks = seq(from = 0, to = 1, by = 0.25), labels = rep("", 5))+
      {if(length(annotation_colors) >= col && is.character(annotation_colors[[col]]))
        ggplot2::scale_fill_manual(values = annotation_colors[[col]])}+
      ggplot2::theme_void()+
      ggplot2::theme(legend.position = "bottom")
    anno_list <- purrr::prepend(anno_list, list(anno)) 
  }
  anno_list <- purrr::set_names(anno_list, rev(anno_cols))
  return(anno_list)
}