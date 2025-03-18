#' Function to generate the clustering and dendrogram plots for the simpleHM function
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
#' @param return_clustering  should the clustering be returned? defaults to F
#'
#' @returns returns a list of ggplot dendrogram plots. If return_clustering is set, returns the hclust objects instead
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
#' heatmap_dendro <- simpleDendro(df)
#' heatmap_dendro
simpleDendro <- function(df,
                     
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
                     id_col = "", # column identifying each sample, defaults to first colum if empty
                     return_clustering = F # should the hclust be returned? or the dendrograms as plots
){
  df_input <- df
  
  if(normalise_params) { #normalise params
    df_input <- df_input %>%
      {if(norm_method == "zscore")
        dplyr::mutate(., dplyr::across(.cols = dplyr::where(is.numeric) & !excluded_vars, scale))
        else .} %>%
      {if(norm_method == "max")
        dplyr::mutate(., dplyr::across(.cols = dplyr::where(is.numeric) & !excluded_vars,
                                       function(x){(x-min(x))/(max(x)-min(x))}))
        else .}
    
    
  }
  if(normalise_samples){ #normalize samples
    df_input <- df_input %>%
      tidyr::pivot_longer(cols = dplyr::where(is.numeric) & !excluded_vars,
                          names_to = "params",
                          values_to = "val") %>%
      tidyr::pivot_wider(names_from = ifelse(nchar(id_col) > 0, id_col, names(df)[1]),
                         values_from = "val") %>%
      {if(norm_method == "zscore")
        dplyr::mutate(., dplyr::across(.cols = dplyr::where(is.numeric) & !excluded_vars, scale))
        else .} %>%
      {if(norm_method == "max")
        dplyr::mutate(., dplyr::across(.cols = dplyr::where(is.numeric) & !excluded_vars,
                                       function(x){(x-min(x))/(max(x)-min(x))}))
        else .} %>%
      tidyr::pivot_longer(cols = dplyr::where(is.numeric) & !excluded_vars,
                          names_to = ifelse(nchar(id_col) > 0, id_col, names(df)[1]),
                          values_to = "val") %>%
      tidyr::pivot_wider(names_from = "params", values_from = "val")
  }
  message("normalisation done")
  if(clust_samples){
    samples_clust <- df_input %>% 
      {if(length(excluded_vars) >0)
        dplyr::select(., -tidyselect::any_of(excluded_vars))
        else .} %>% 
      tibble::column_to_rownames(ifelse(nchar(id_col) > 0, id_col, names(df)[1])) %>% 
      dplyr::select(tidyselect::where(base::is.numeric)) %>% 
      stats::dist() %>% 
      stats::hclust()
    
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
    
    message("clustering samples done")
  }
  
  
  if(clust_params){
    params_clust <- df_input %>% 
      {if(length(excluded_vars) >0)
        dplyr::select(., -tidyselect::any_of(excluded_vars))
        else .} %>% 
      tibble::column_to_rownames(ifelse(nchar(id_col) > 0, id_col, names(df)[1])) %>% 
      dplyr::select(tidyselect::where(is.numeric)) %>% 
      t() %>% 
      stats::dist() %>% 
      stats::hclust()
    
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
    message("clustering params done")
  }
  
  if(return_clustering){
    clust_list <- list("samples" = samples_clust, 
                       "parameters" = params_clust)
    return(clust_list)
  }
  suppressMessages(p_top_denro <- ggdendro::ggdendrogram(samples_clust)+
                     ggplot2::theme_void())
  suppressMessages(p_side_denro <- ggdendro::ggdendrogram(params_clust, rotate = T)+
                     ggplot2::scale_y_reverse()+
                     ggplot2::scale_x_discrete(breaks = seq(from = 0, to = 1, length.out = length(order_params)), labels = rep("", length(order_params)))+
                     ggplot2::theme_void())
  plot_list <- list("top" = p_top_denro,
                    "side" = p_side_denro)
  
  return(plot_list)
  
}
