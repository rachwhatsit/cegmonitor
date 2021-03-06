#' get edge key: dependency for messag passing algorithm
#' @param stage.key 
#' @keywords message passing, ceg
#' @export
#' @examples
#' 
#'
get.edge.path.key <- function(stage.key) {
  cuts <- colnames(df)
  stage.key[[length(stage.key)]] -> paths
  mutate(paths, stage1 = rep(as.character(stages[1]), length(paths$n))) -> paths #initialized with first and last stages
  for (i in 2:(length(stage.key) - 1)) {
    left_join(paths, select(stage.key[[i]], cuts[1:(i - 1)], starts_with("stage")), by =
                cuts[1:(i - 1)]) -> paths
  } #this returns the paths in a wonky order, but they're there
  dplyr::select(paths, c(1:(length(cuts)), starts_with("stage"))) -> edge.path.key
  return(edge.path.key)
}



#' Message passing algorithm as outlined by Collazo 2017
#' takes a well ordered CEG and C-copmatible information I
#' outputs: an uncolored CEG with pi_hat
#' 
#' @param df data frame
#' @param stage.key 
#' @param evidence chunk of data frame representing the root to sink paths
#' @param prior Dirichlet prior with effective sample size as the largest number of outgoing edges
#' @param stages vector of stage names
#' @param struct list of observed counts in each stage
#' @keywords message passing, ceg
#' @export
#' @examples
#' 
#' 
pass.message <-
  function(df, stage.key, evidence, prior,stages,struct) {


#evidence <- df[1:5,] #how much evidencd do you have at each time?? yo ne se.
posterior <- rep(NA, length(prior))
for (i in (1:length(prior))) {
  posterior[i] <- list(unlist(prior[i]) + unlist(as.numeric(struct[[i]]$n)))
}
post.mean <- rep(NA, length(prior))
for (i in (1:length(prior))) {
  post.mean[i] <-
    list(unlist(posterior[i]) / sum(unlist(posterior[i])))
}



    cuts <- colnames(df)
    post.mean <- list()
    posterior <- list()
    for (i in (1:length(prior))) {
      posterior[i] <- list(unlist(prior[i]) + unlist(as.numeric(struct[[i]]$n)))
    }
    for (i in (1:length(prior))) {
      post.mean[[i]] <-
        list(unlist(posterior[i]) / sum(as.numeric(unlist(posterior[i]))))
    }
    #what's the most natural way to put the evidence into the system?
    #prior <- get.ref.prior(df, struct, cuts, stage.key, stages)
    tau <- c()
    for (i in 2:length(stage.key)) {
      stage.key[[i]] <- mutate(stage.key[[i]], pi = n / dim(df)[1])
    }#adds edge probabilties to each stage
    edge.path.key <-
      get.edge.path.key(stage.key) #determine what the edge path key is
    left_join(evidence, edge.path.key) -> ev.paths
    dplyr::select(ev.paths, -(1:length(cuts))) %>% as.list() %>% unlist() %>% unique() -> ev.stages
    
    
    sk.idx <- 1
    #i <- 1
    for (i in 1:(length(stages))) {
      #print(i)
      if (!(stages[[i]] %in% stage.key[[sk.idx]]$stage)) {#i+1 to skip the root node
        sk.idx <- sk.idx + 1
        #print('next stage')
      }
      tau[[i]] <- rep(-1, length(prior[[i]]))#initialize tau
      #check to see that the evidence matches this stage
      if (!(stages[[i]] %in% ev.paths[, (length(stage.key) + sk.idx+1)])) {
        next
      }#if the stages is not in the evidence, pass on it.
      subset(ev.paths, ev.paths[, (length(stage.key) + sk.idx+1)] == stages[i]) -> ev.paths.stage
      
      idx <-which(unlist(struct[[i]][, 1]) %in% ev.paths.stage[, sk.idx+1])
      tau[[i]][idx] <-
        post.mean[[i]][idx] #if the edge is in the evidence, then add the probability for each existing edge
      tau[[i]][-idx] <- 0
    }
    #print('tau')
    #print(tau)
    phi <- c()
    for (i in 1:length(tau)) {
      phi[i] <- sum(unlist(tau[[i]]))
    }
    # print('phi')
    # print(phi)
    pi.hat <- c()
    for (i in 1:length(tau)) {
      #GO BACK AND GET RID OF THESE FOR LOOPS LIKE A REAL CODER
      pi.hat[[i]] <- unlist(tau[[i]]) / phi[i]
    }
    return((pi.hat))
  }

