normalise.params <- function(.df, 
                             .norm_method, 
                             .excluded_vars){
  df_input <- .df %>%
    {if(.norm_method == "zscore")
      dplyr::mutate(., dplyr::across(.cols = dplyr::where(is.numeric) & !.excluded_vars, scale))
      else .} %>%
    {if(.norm_method == "max")
      dplyr::mutate(., dplyr::across(.cols = dplyr::where(is.numeric) & !.excluded_vars,
                                     function(x){(x-min(x))/(max(x)-min(x))}))
      else .}
  return(df_input)
}

normalise.samples <- function(.df,
                              .norm_method, 
                              .excluded_vars){
  df_input <- .df %>%
    tidyr::pivot_longer(cols = dplyr::where(is.numeric) & !.excluded_vars,
                        names_to = "params",
                        values_to = "val") %>%
    tidyr::pivot_wider(names_from = "SAMPLE",
                       values_from = "val") %>%
    {if(.norm_method == "zscore")
      dplyr::mutate(., dplyr::across(.cols = dplyr::where(is.numeric) & !.excluded_vars, scale))
      else .} %>%
    {if(.norm_method == "max")
      dplyr::mutate(., dplyr::across(.cols = dplyr::where(is.numeric) & !.excluded_vars,
                                     function(x){(x-min(x))/(max(x)-min(x))}))
      else .} %>%
    tidyr::pivot_longer(cols = dplyr::where(is.numeric) & !.excluded_vars,
                        names_to = "SAMPLE",
                        values_to = "val") %>%
    tidyr::pivot_wider(names_from = "params", values_from = "val")
  
  return(df_input)
}


clust.samples <- function(.df,
                          .excluded_vars){
  samples_clust <- .df %>% 
    {if(length(.excluded_vars) >0)
      dplyr::select(., -tidyselect::any_of(.excluded_vars))
      else .} %>% 
    tibble::column_to_rownames("SAMPLE") %>% 
    dplyr::select(tidyselect::where(base::is.numeric)) %>% 
    stats::dist() %>% 
    stats::hclust()
  
  return(samples_clust)
}

clust.params <- function(.df, 
                         .excluded_vars){
  params_clust <- .df %>% 
    {if(length(.excluded_vars) >0)
      dplyr::select(., -tidyselect::any_of(.excluded_vars))
      else .} %>% 
    tibble::column_to_rownames("SAMPLE") %>% 
    dplyr::select(tidyselect::where(is.numeric)) %>% 
    t() %>% 
    stats::dist() %>% 
    stats::hclust()
  
  return(params_clust)
}