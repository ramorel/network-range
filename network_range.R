## Function to find network range for each node in a network
## Arguments:
##  net = adjacency matrix, igraph graph, or network object
##  attr = Vector of attributes associated with each node in net
##  directed = boolean indicated if the network is directed or not

netrange <- function(network, attr, directed = TRUE) {
    require(reshape2)
    if (class(network) == "igraph") {
        network <- as_adjacency_matrix(network, sparse = F)
    }
    if (class(network) == "network") {
        network <- as.matrix.network(network)
    }
    if (class(network) == "matrix" & is.null(rownames(network))) {
        rownames(network) <- 1:nrow(network)
    }
    if (class(network) == "matrix" & is.null(colnames(network))) {
        colnames(network) <- 1:ncol(network)
    }
    if (nrow(network) != length(attr)) {
        stop("Number of nodes must match length of attributes vector")
    }
    
    if (directed == TRUE) {
        ns <- colnames(network)
        el <- melt(network, varnames = c("ego", "alter"), value.name = "weight")
        df <- cbind(rownames(network), attr)
        el$ego_grp <- df[match(el[, 1], df[, 1]), 2]
        el$alter_grp <- df[match(el[, 2], df[, 1]), 2]
        
        # FINDING p_k, the strength of ties within each group z_iq = sum of strength of ties
        # from nodes in group _k_ to all other alters z_ij = sum of strength of ties from
        # nodes in group _k_ to alters in group _k_
        
        z_iq <- sapply(unique(attr), function(x) {
            sum(el[which(el$ego_grp == x), "weight"])
        })
        z_ij <- sapply(unique(attr), function(x) {
            sum(el[which(el$ego_grp == x & el$alter_grp == x), "weight"])
        })
        p_k <- z_ij/z_iq
        p_k[is.na(p_k)] <- 0
        
        # FINDING p_ik, the strength of connection from person i to group k x_iq = sum of
        # strength of ties for _i_ to alters in group _k_ x_ij = sum of strength of ties for
        # _i_ to all alters
        
        x_ij <- sapply(colnames(network), function(x) {
            sum(el[which(el$ego == x), "weight"])
        })
        x_iq <- list(NULL)
        for (i in colnames(network)) {
            x_iq[[i]] <- sapply(unique(attr), function(x) {
                sum(el[which(el$ego == i & el$alter_grp == x), "weight"])
            })
        }
        x_iq <- x_iq[-c(1)]  #x_iq is now a list where each elements is a vector of node _i_ summed strength of tie to group _k_
        
        p_ik <- lapply(1:length(x_iq), function(x) x_iq[[x]]/x_ij[x])
        
        # FINDING nd_i, the network diversity score for node _i_
        
        nd_i <- sapply(1:length(p_ik), function(x) 1 - sum(p_k * p_ik[[x]]^2, na.rm = F))
    } else {
        ns <- colnames(network)
        el <- melt(network, varnames = c("ego", "alter"), value.name = "weight")
        dup <- data.frame(t(apply(el[, 1:2], 1, sort)))
        el <- el[!duplicated(dup), ]
        df <- cbind(rownames(network), attr)
        el$ego_grp <- df[match(el[, 1], df[, 1]), 2]
        el$alter_grp <- df[match(el[, 2], df[, 1]), 2]
        
        # FINDING p_k, the strength of ties within each group z_iq = sum of strength of ties
        # from nodes in group _k_ to all other alters z_ij = sum of strength of ties from
        # nodes in group _k_ to alters in group _k_
        
        z_iq <- sapply(unique(attr), function(x) {
            sum(el[which(el$ego_grp == x | el$alter_grp == x), "weight"])
        })
        z_ij <- sapply(unique(attr), function(x) {
            sum(el[which(el$ego_grp == x & el$alter_grp == x), "weight"])
        })
        p_k <- z_ij/z_iq
        p_k[is.na(p_k)] <- 0
        
        # FINDING p_ik, the strength of connection from person i to group k x_iq = sum of
        # strength of ties for _i_ to alters in group _k_ x_ij = sum of strength of ties for
        # _i_ to all alters
        
        x_ij <- sapply(colnames(network), function(x) {
            sum(el[which(el$ego == x | el$alter == x), "weight"])
        })
        x_iq <- list(NULL)
        for (i in colnames(network)) {
            x_iq[[i]] <- sapply(unique(attr), function(x) {
                sum(el[which(el$ego == i & el$alter_grp == x), "weight"], el[which(el$alter == 
                  i & el$ego_grp == x), "weight"])
            })
        }
        x_iq <- x_iq[-c(1)]  #x_iq is now a list where each elements is a vector of node _i_ summed strength of tie to group _k_
        
        p_ik <- lapply(1:length(x_iq), function(x) x_iq[[x]]/x_ij[x])
        
        
        # FINDING nd_i, the network diversity score for node _i_
        
        nd_i <- sapply(1:length(p_ik), function(x) 1 - sum(p_k * p_ik[[x]]^2, na.rm = F))
    }
    return(nd_i)
}
