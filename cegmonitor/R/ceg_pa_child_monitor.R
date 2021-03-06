#' A function to compute the node monitors of the BN
#'
#' @param df data in question
#' @param target.stage child stage
#' @param target.cut which cut is the child stage in 
#' @param stages list of stages
#' @param stage.key ceg stage.key
#' @param struct ceg structure
#' @param n number of iterations
#' @param learn binary to control learning 
#' @keywords bn node monitor
#' @export
#' @examples chds.expect.pach <- ceg.child.parent.monitor(df=chds.df,
#'target.stage = "u1",
#'target.cut = 2, 
#'condtnl.stage = "u0",
#'struct = chds.struct,
#'stage.key = chds.sk.nocol, 
#'stages=chds.stages,
#'prior=chds.prior.expert,
#'n = 860,
#'learn = F)

ceg.child.parent.monitor <-
  function(df,
           target.stage,
           target.cut,
           condtnl.stage,
           stage.key,
           struct,
           stages,
           prior,
           n = 50,
           learn = FALSE) {
    #dataframes should also be added for the counts
    #add checks to make sure that prior has same number of items as counts in dataframe
    #target.cut is the cut that the target.stage is in
    colnames(df) -> cuts
    Zm <- rep(NA, n)
    Sm <- rep(NA, n)
    Em <- rep(NA, n)
    Vm <- rep(NA, n)
    p <- rep(NA, n)
    
    target.stage.idx <-
      as.numeric(substr(target.stage, nchar(target.stage), nchar(target.stage))) +
      1
    condtnl.stage.idx <-
      as.numeric(substr(condtnl.stage, nchar(condtnl.stage), nchar(condtnl.stage))) +
      1
    target.prior <- unlist(prior[target.stage.idx])
    if (learn == FALSE) {
      for (i in 2:n) {
        df_cut <- df[2:i, ]
        #figure out what stages we're watching for the target (child) stage
        in.paths <-
          stage.key[[target.cut]][which(stage.key[[target.cut]]$stage == target.stage), ]#id the incoming pathways
        stages.of.interest <-
          merge(in.paths[, 1:(target.cut - 1)], stage.key[[(target.cut - 1)]][, c(1:(target.cut -
                                                                                       1), dim(stage.key[[(target.cut - 1)]])[2])])$stage
        ref.prior.idx <-
          unlist(lapply(stages.of.interest, function(x) {
            as.numeric(substr(x, nchar(x), nchar(x))) + 1
          }))#gives the stage number, because of weird indexing, want
        in.path.idx <-
          which(stage.key[[target.cut]]$stage == target.stage)
        #figure out what stages we're watching for the condtnl (parent) stage
        cnd.in.paths <-
          stage.key[[target.cut - 1]][which(stage.key[[target.cut - 1]]$stage == condtnl.stage), ]
        cnd.in.path.idx <-
          which(stage.key[[target.cut - 1]]$stage == condtnl.stage)
        
        
        
        #filter out along conditional stage requirements
        df_cuts <- list()
        if (target.cut == 2) {
          #this is not doing what it should. regrettably.
          for (j in 1:length(cnd.in.path.idx)) {
            df_cuts[[j]] <- df_cut
            df_cuts[[j]] <- filter(df_cuts[[j]], Social=="High")#filter according to the matching indices
            # df_cuts[[j]] <-
            #   filter(df_cuts[[j]], UQ(sym(colnames(df_cut)[1])) == as.character(unlist(stage.key[[target.cut -
            #                                                                                         1]][cnd.in.path.idx[j], 1])))#filter according to the matching indices
          }
        }else{
          for (j in 1:length(cnd.in.path.idx)) {
            df_cuts[[j]] <- df_cut
            for (k in 1:(length(colnames(stage.key[[target.cut - 1]])) - 2)) {
              df_cuts[[j]] <-
                filter(df_cuts[[j]], UQ(sym(colnames(df_cut)[k])) == as.character(unlist(stage.key[[target.cut -
                                                                                                      1]][cnd.in.path.idx[j], k])))#filter according to the matching indices
            }
          }
        }
        df_paths.cnd <- do.call(rbind, df_cuts)
        
        df_cuts <- list()
        for (j in 1:length(in.path.idx)) {
          df_cuts[[j]] <- df_paths.cnd
          for (k in (length(colnames(stage.key[[target.cut - 1]])) - 1):(length(colnames(stage.key[[target.cut]])) -
                                                                         2)) {
            df_cuts[[j]] <-
              filter(df_cuts[[j]], UQ(sym(colnames(df_cut)[k])) == as.character(unlist(stage.key[[target.cut]][in.path.idx[j], k])))#filter according to the matching indices
          }
        }
        df_paths <- do.call(rbind, df_cuts)
        # df_paths <- filter(df_paths,Economic==cndtnl.stage.val)
        obsv.stage.count <-
          count(df_paths, UQ(sym(colnames(
            as.data.frame(struct[target.stage.idx])
          )[1])))#how many counts we observe in each stage
        counts <- rep(0, length(target.prior))
        counts[as.numeric(rownames(obsv.stage.count))] <-
          obsv.stage.count$n
        target.prior.vec <- unlist(target.prior)
        p[i] = (lgamma(sum(target.prior.vec)) + sum(lgamma(target.prior.vec +
                                                             counts)) - (sum(lgamma(
                                                               target.prior.vec
                                                             )) + lgamma(
                                                               sum(target.prior.vec) + sum(counts)
                                                             )))#logprobability
        #compute the z statistics
        Sm[i] = -p[i]
        Em[i] = sum((target.prior.vec / sum(target.prior.vec)) * sum(counts))
        Vm[i] = sum(target.prior.vec * (sum(target.prior.vec) - target.prior.vec)) /
          (sum(target.prior.vec) ^ 2 * (sum(target.prior.vec) + 1))
        Zm[i] = sum(na.omit(Sm)) - sum(na.omit(Em)) / sqrt(sum(na.omit(Vm)))
      }
    }
    else{
      for (i in 2:n) {
        df_cut <- df[2:i, ]
        #figure out what stages we're watching for the target (child) stage
        in.paths <-
          stage.key[[target.cut]][which(stage.key[[target.cut]]$stage == target.stage), ]#id the incoming pathways
        stages.of.interest <-
          merge(in.paths[, 1:(target.cut - 1)], stage.key[[(target.cut - 1)]][, c(1:(target.cut -
                                                                                       1), dim(stage.key[[(target.cut - 1)]])[2])])$stage
        ref.prior.idx <-
          unlist(lapply(stages.of.interest, function(x) {
            as.numeric(substr(x, nchar(x), nchar(x))) + 1
          }))#gives the stage number, because of weird indexing, want
        in.path.idx <-
          which(stage.key[[target.cut]]$stage == target.stage)
        #figure out what stages we're watching for the condtnl (parent) stage
        cnd.in.paths <-
          stage.key[[target.cut - 1]][which(stage.key[[target.cut - 1]]$stage == condtnl.stage), ]
        cnd.in.path.idx <-
          which(stage.key[[target.cut - 1]]$stage == condtnl.stage)
        
        
        
        #filter out along conditional stage requirements
        df_cuts <- list()
        if (target.cut == 2) {
          #this is not doing what it should. regrettably.
          for (j in 1:length(cnd.in.path.idx)) {
            df_cuts[[j]] <- df_cut
            df_cuts[[j]] <- filter(df_cuts[[j]], Social=="High")#filter according to the matching indices
          }
        }else{
          for (j in 1:length(cnd.in.path.idx)) {
            df_cuts[[j]] <- df_cut
            for (k in 1:(length(colnames(stage.key[[target.cut - 1]])) - 2)) {
              df_cuts[[j]] <-
                filter(df_cuts[[j]], UQ(sym(colnames(df_cut)[k])) == as.character(unlist(stage.key[[target.cut -
                                                                                                      1]][cnd.in.path.idx[j], k])))#filter according to the matching indices
            }
          }
        }
        df_paths.cnd <- do.call(rbind, df_cuts)
        
        df_cuts <- list()
        for (j in 1:length(in.path.idx)) {
          df_cuts[[j]] <- df_paths.cnd
          for (k in (length(colnames(stage.key[[target.cut - 1]])) - 1):(length(colnames(stage.key[[target.cut]])) -
                                                                         2)) {
            df_cuts[[j]] <-
              filter(df_cuts[[j]], UQ(sym(colnames(df_cut)[k])) == as.character(unlist(stage.key[[target.cut]][in.path.idx[j], k])))#filter according to the matching indices
          }
        }
        df_paths <- do.call(rbind, df_cuts)
        # df_paths <- filter(df_paths,Economic==cndtnl.stage.val)
        obsv.stage.count <-
          count(df_paths, UQ(sym(colnames(
            as.data.frame(struct[target.stage.idx])
          )[1])))#how many counts we observe in each stage
        counts <- rep(0, length(target.prior))
        counts[as.numeric(rownames(obsv.stage.count))] <-
          obsv.stage.count$n
        target.prior.vec <- unlist(target.prior)
        p[i] = (lgamma(sum(target.prior.vec)) + sum(lgamma(target.prior.vec +
                                                             counts)) - (sum(lgamma(
                                                               target.prior.vec
                                                             )) + lgamma(
                                                               sum(target.prior.vec) + sum(counts)
                                                             )))#logprobability
        #compute the z statistics
        Sm[i] = -p[i]
        Em[i] = sum((target.prior.vec / sum(target.prior.vec)) * sum(counts))
        Vm[i] = sum(target.prior.vec * (sum(target.prior.vec) - target.prior.vec)) /
          (sum(target.prior.vec) ^ 2 * (sum(target.prior.vec) + 1))
        Zm[i] = sum(na.omit(Sm)) - sum(na.omit(Em)) / sqrt(sum(na.omit(Vm)))
        unlist(target.prior) + counts -> target.prior
      }
    }
    results <- data.frame(cbind(Sm, Zm, Em, Vm))
    colnames(results) <- c("Sm", "Zm", "Em", "Vm")
    return((results))
  }
