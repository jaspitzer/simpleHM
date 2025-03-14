#' Create a heatmap
#'
#' @param df a dataframe to containing the data to be plotted. Required
#' @param clust_samples  should the samples be clustered? T/F
#' @param clust_params should the variables be clustered? T/F
#' @param param_order can be used to suplly a vector containg a custom order for the variables. Ignored if clust_params = TRUE
#' @param linkage which linkage method to use. defaults
#' @param pull_top should the dendrogram be rotated? if yes, what levels should be pulled to the front? Accepts numeric values (current order) and variable names
#' @param pull_side should the dendrogram be rotated? if yes, what levels should be pulled to the front? Accepts numeric values (current order) and variable names
#' @param show_sample_names should the sample names be shown in the heatmap?
#' @param show_param_names should the parameter names be shown in the heatmap?
#' @param hide_legend Should the legend be hidden? Default is FALSE
#' @param normalise_params should the variables be normalized? defaults to T
#' @param normalise_samples should normalisation be applied to samples? defaults to F
#' @param norm_method which method should be applied to normalise? can be min/max scaling or z-score; T/F
#' @param excluded_vars character vector of variabels to be excluded
#' @param id_col a character with id column clearly identifying each sample
#' @param color_code color code for the fill aestethic. default is "#FF1c00" for high values and "darkblue" for low values
#' @param custom_threshold custom threshold for the scale; defaults to NULL
#' @param outlier.removal should outlier be removed? i.e. single values which drive the normalized values; default is T
#' @param outlier.threshold threshold for outlier.removal. currently is set to the 95th percentile (0.95)
#' @param add_annotation should annotation be added to the heatmap? default = F
#' @param anno_col which columns is the data contain annotation? can be a character vector.
#' @param annotation_colors a list containing the vectors with colors for every annotation column
#' @param add_dendros should dendros be added
#' @param .plot should the plot be created and returned? default is T, if F just returns the data
#' @param return_list when adding annotation, should the assembled plot be returned? or should the components be returned as a list? defaults to F
#'
#' @return returns a heatmap as a ggplot object. If annotation is added, a patchwork assembled plot is returned.
#' @export
#'
#' @importFrom magrittr %>%
#' @examples df <- data.frame(samples = c(paste0("untreated", 1:6), paste0("treated", 7:12)),
#'                            group = c(rep("Untreated",6), rep("Treated",6)),
#'                            patient = c(rep(paste0("Patient", 1:3), 4)),
#'                            var1 = c(rnorm(6, 10, 1),  rnorm(6, 7, .7)),
#'                            var2 = c(rnorm(6, 10, 1),  rnorm(6, 200, 10)),
#'                            var3 = c(rnorm(6, 50, 5),  rnorm(6, 10, 1)),
#'                            var4 = c(rnorm(6, 10, 1),  rnorm(6, 60, .7)))
#'
#' heatmap_plot <- simpleHM(df)
#'
#' anno_added <- simpleHM(df, add_annotation = TRUE)
#'
simpleHM <- function(df,

                  clust_samples = T, # should the samples (columns)  be clustered
                  clust_params = T, # should the parameters (rows) be clustered
                  param_order = NULL, # if the parameters are not clustered, you can supply a custom order
                  linkage = "complete", #what linkage method for clustering
                  pull_top = NULL,
                  pull_side = NULL,
                  
                  show_sample_names = T, #show the sample names
                  show_param_names = T, #show the sample names
                  hide_legend = F,

                  normalise_params = T,  # normalisation across parameters (z-score)
                  normalise_samples = F, # normalisation across samples
                  norm_method = "zscore", # which normmilastion to use, zscore or max

                  excluded_vars = c(), # numeric variables included as columns which are not to be included in the heatmap(i.e. batch 1,2,3)
                  id_col = "", # column identifying each sample, defaults to first colum if empty

                  color_code = c(high = "#FF1c00", low = "darkblue"), # color code for the heatmap
                  custom_threshold = NULL, #custom threshold for z-score
                  outlier.removal = T, # should the zscore be cleared of outliers (outliers are set to the percentile detailed below)
                  outlier.threshold = 0.95, # want percentile of z-scores should be trimmed

                  add_annotation = F, # should color bar annotation be included?
                  anno_col = "", # which columns contains annotations, defaults to everything but the identifier or the not excluded numeric columns
                  annotation_colors = list(), # list of color vectors, expects one for every anno col
                  
                  add_dendros = F, # should dendrograms be added? T/F

                  .plot = T, # should a plot be generated or only the data frame be returned
                  return_list = F # if a plot is generated, should it be returned as a plot or as a list of subplots
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
  
  


  if(is.numeric(custom_threshold) & norm_method == "zscore"){
    df_plot <- df_input %>%
      tidyr::pivot_longer(cols = dplyr::where(is.numeric) & !excluded_vars,
                   names_to = "params",
                   values_to = "val")

    df_plot <- df_plot %>%
      dplyr::mutate(val = dplyr::case_when(
        val > custom_threshold ~ custom_threshold,
        val < -custom_threshold ~ -custom_threshold,
        T ~ val))

    fill_labels =  round(seq(-custom_threshold, custom_threshold, length.out = 5),2) %>% as.numeric()
    fill_names = c(paste0("< -", custom_threshold),
                   paste0("- ", custom_threshold/2 %>% round(2)),
                   "0",
                   paste0(custom_threshold/2 %>% round(2)),
                   paste0("> ", custom_threshold))
  }else if(outlier.removal & norm_method == "zscore"){
    df_plot <- df_input %>%
      tidyr::pivot_longer(cols = dplyr::where(is.numeric) & !excluded_vars,
                   names_to = "params",
                   values_to = "val")

    thres <- df_plot$val %>% stats::quantile(probs = outlier.threshold) %>% round(2)
    df_plot <- df_plot %>%
      dplyr::mutate(val = dplyr::case_when(
        val > thres ~ thres,
        val < -thres ~ -thres,
        T ~ val))

    fill_labels =  round(seq(-thres, thres, length.out = 5),2) %>% as.numeric()
    fill_names = c(paste0("< -", thres),
                   paste0("- ", thres/2 %>% round(2)),
                   "0",
                   paste0(thres/2 %>% round(2)),
                   paste0("> ", thres))

  }else{
    df_plot <- df_input %>%
      tidyr::pivot_longer(cols = dplyr::where(is.numeric) & !excluded_vars,
                   names_to = "params",
                   values_to = "val")
  }


  df_plot <- df_plot %>%
    {if(nchar(id_col) > 0) dplyr::rename(.,"SAMPLE" = id_col)  else dplyr::rename(.,"SAMPLE" = 1)}

  df_plot <- df_plot %>%
    dplyr::mutate(SAMPLE = forcats::as_factor(SAMPLE),
           params = forcats::as_factor(params)) %>%
    {if (clust_params) dplyr::mutate(., params = forcats::fct_relevel(params, order_params)) else . } %>%
    {if (clust_samples) dplyr::mutate(., SAMPLE = forcats::fct_relevel(SAMPLE, order_samples)) else . } %>%
    {if (!clust_params & !is.null(param_order)) dplyr::mutate(., params = forcats::fct_relevel(params, param_order)) else . }

  if(.plot){
    message("plotting now")


    hm <- df_plot %>%
      ggplot2::ggplot(ggplot2::aes(x = SAMPLE,
                 y = params,
                 fill = val))+
      ggplot2::geom_tile()+
      {if(outlier.removal | (is.numeric(custom_threshold) & norm_method == "zscore"))
        ggplot2::scale_fill_gradient2(high = color_code[1], low = color_code[2],
                             breaks = fill_labels,
                             labels = fill_names)
        else
          ggplot2::scale_fill_gradient2(high = color_code[1], low = color_code[2])}+
      ggplot2::scale_x_discrete(position = "top")+
      ggplot2::theme_void()+
      ggplot2::theme(axis.title.x = ggplot2::element_blank(),
            axis.title.y = ggplot2::element_blank(),
            axis.ticks.y = ggplot2::element_blank(),
            axis.text.x = ggplot2::element_text(hjust = 1, angle = 90),
            axis.text.y = ggplot2::element_text(),
            legend.position = "right")+
      {if(length(unique(df_plot$params)) > 100)
        ggplot2::theme(axis.text.y = ggplot2::element_blank())}+
      {if(!show_param_names)
        ggplot2::theme(axis.text.y = ggplot2::element_blank())}+
      {if(!show_sample_names)
        ggplot2::theme(axis.text.x = ggplot2::element_blank(),
              axis.ticks.x = ggplot2::element_blank())
        else if(length(unique(df_plot$SAMPLE)) > 50)
          ggplot2::theme(axis.text.x = ggplot2::element_blank())}+
      {if(norm_method == "zscore") ggplot2::labs(fill = "z-score norm.\nmRNA expression")}+
      {if(norm_method == "max") ggplot2::labs(fill = "Maximum scaled\nmRNA expression")}+
      {if(hide_legend) ggplot2::theme(legend.position = "none")}



    if(add_annotation){
      message("adding annotation")

      hm <- hm +
        ggplot2::theme(axis.text.x = ggplot2::element_blank(),
              axis.ticks.x = ggplot2::element_blank())
      plot_list <- list(hm)


      if(length(anno_col) > 1){
        if(!all(anno_col %in% colnames(df_plot))){
          stop("not all supplied columns are in the data frame")
        }
        anno_cols <- anno_col
      }else{
        anno_cols <- df_plot %>%
          dplyr::select(-c(SAMPLE, params, val)) %>% names()
      }

      for(col in 1:length(anno_cols)){
        anno <- df_plot %>%
          ggplot2::ggplot(ggplot2::aes_string(y = 1, x = "SAMPLE", fill = anno_cols[col])) +
          ggplot2::geom_tile()+
          ggplot2::scale_y_discrete(breaks = seq(from = 0, to = 1, by = 0.25), labels = rep("", 5))+
          {if(length(annotation_colors) >= col && is.character(annotation_colors[[col]]))
            ggplot2::scale_fill_manual(values = annotation_colors[[col]])}+
          ggplot2::theme_void()+
          ggplot2::theme(legend.position = "bottom")
        plot_list <- purrr::prepend(plot_list, list(anno))
      }
      
      
      
      if(return_list) {
        return(plot_list)
      }
      
      message("wrapping plots up")
      plot <- patchwork::wrap_plots(plot_list, heights = c(rep(0.05, length(anno_cols)), 1), ncol = 1, guides = "collect")
      
      if(add_dendros){
        p_top_denro <- ggdendro::ggdendrogram(samples_clust)+
          ggplot2::theme_void()
        p_side_denro <- ggdendro::ggdendrogram(params_clust, rotate = T)+
          ggplot2::scale_y_reverse()+
          ggplot2::scale_x_discrete(breaks = seq(from = 0, to = 1, length.out = length(order_params)), labels = rep("", length(order_params)))+
          ggplot2::theme_void()
        
        plot_list <- purrr::prepend(plot_list, list(p_top_denro))
        plot_list <- purrr::prepend(plot_list, list(p_side_denro))
        
        for(col in 1:(length(anno_cols)+1)){
          p_space <- patchwork::plot_spacer()
          plot_list <- purrr::prepend(plot_list, list(p_space))
        }
        plot <- patchwork::wrap_plots(plot_list, 
                                      heights = c(0.5, rep(0.05, length(anno_cols)), 1),
                                      widths = c(0.5, 1), ncol = 2, byrow = F, guides = "collect")
        
        return(plot)
        ##stuff
      }
      
      
      return(plot)
    }else{
      if(add_dendros){
        plot_list <- list(hm)
        p_top_denro <- ggdendro::ggdendrogram(samples_clust)+
          ggplot2::theme_void()
        p_side_denro <- ggdendro::ggdendrogram(params_clust, rotate = T)+
          ggplot2::scale_y_reverse()+
          ggplot2::scale_x_discrete(breaks = seq(from = 0, to = 1, length.out = length(order_params)), labels = rep("", length(order_params)))+
          ggplot2::theme_void()
        
        plot_list <- purrr::prepend(plot_list, list(p_top_denro))
        plot_list <- purrr::prepend(plot_list, list(p_side_denro))
        
        p_space <- patchwork::plot_spacer()
        plot_list <- purrr::prepend(plot_list, list(p_space))
        
        plot <- patchwork::wrap_plots(plot_list, 
                                      heights = c(0.5, 1),
                                      widths = c(0.5, 1), ncol = 2, byrow = F, guides = "collect")
        
        return(plot)
        ##stuff
      }
      
      
      return(hm)
    }
    
    
  }else{
    return(df_plot)
  }
}
