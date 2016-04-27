#' Retrieve one item at a time from the ccRecord, NOTE: items with meta data,
#' i.e. three columns case is not valide for this function, should be improved
#' in the future.
#' @param record ccRecord
#' @param item_id NHIC code
#' @export readOneItem
readOneItem <- function(record, item_id, convert_type=NULL, as.POSIX=FALSE,
                        unlist=TRUE) {
    StdId(item_id)
    short_name <- ccdata.env$ITEM_REF[['item_id']]$shortName
    if (is.null(short_name))
        short_name <- "NULL"
    env <- new.env()
    # to store 1d data, in the 2d data case, this list will keep empty
    env$tb_1 <- list() 
    env$tb_2 <- list() 

    lapply(record@patients, 
           function(x) {
               lapply(x@episodes, 
                      function(x) {
                          if (as.POSIX != FALSE) {
                              x@data[[item_id]]$time <-
                                  xmlTime2POSIX(x@data[[item_id]]$time)
                          }
                          if (!is.null(convert_type)) {
                              if (length(x@data[[item_id]]) == 1) {
                                  x@data[[item_id]] <-
                                      convert_type(as.character((x@data[[item_id]])))
                              }
                              else {
                                  x@data[[item_id]]$item2d <-
                                      convert_type(as.character(x@data[[item_id]]$item2d))
                              }
                          }

                          if (length(x@data[[item_id]]) == 1) {
                              pos <- length(env$tb_1) + 1
                              env$tb_1[[pos]] <- data.table(nhs_number=x@nhs_number, 
                                                          pas_number=x@pas_number,
                                                          episode_id=x@episode_id, 
                                                          site_id=x@site_id,
                                                          item=item_id,
                                                          short_name=short_name,
                                                          time=NA,
                                                          val=x@data[[item_id]])
                          }
                          else if (length(x@data[[item_id]]) == 2) {
                              pos <- length(env$tb_2) + 1
                              nr <- nrow(x@data[[item_id]])
                              env$tb_2[[pos]] <-
                                  data.table(nhs_number = rep(x@nhs_number, nr), 
                                             pas_number = rep(x@pas_number, nr),  
                                             episode_id = rep(x@episode_id, nr),
                                             site_id    = rep(x@site_id, nr),
                                             item       = rep(item_id, nr),
                                             short_name = rep(short_name, nr),
                                             time       = x@data[[item_id]]$time,
                                             val        = x@data[[item_id]]$item2d)
                          }
                      })
           })
    
    if (unlist == TRUE) 
        return(list(data1d=rbindlist(env$tb_1), data2d=rbindlist(env$tb_2)))
    else
        return(list(data1d=env$tb_1, data2d=env$tb_2))
}

#' @export readItems
readItems <- function(record, item_ids, split=TRUE, ...) {
    if (any(duplicated(item_ids)))
        stop("item ids should not be duplicated.")
    tt1d <- list()
    tt2d <- list()
    for (id in item_ids) {
        tt <- readOneItem(record, id, unlist=TRUE)
        if (nrow(tt$data1d) != 0 )
            tt1d[[id]] <- tt$data1d
        else 
            tt2d[[id]] <- tt$data2d
    }
    return(list(data1d=rbindlist(tt1d), data2d=rbindlist(tt2d)))
}