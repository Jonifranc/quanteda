#' @rdname dfm_compress
#' @note \code{fcm_compress} works only when the \link{fcm} was created with a
#' document context.
#' @return \code{fcm_compress} returns an \link{fcm} whose features have been
#' recombined by combining counts of identical features, summing their counts.
#' @export
#' @examples
#' # compress an fcm
#' myfcm <- fcm(tokens("A D a C E a d F e B A C E D"), 
#'              context = "window", window = 3)
#' ## this will produce an error:
#' # fcm_compress(myfcm)
#' 
#' txt <- c("The fox JUMPED over the dog.",
#'          "The dog jumped over the fox.")
#' toks <- tokens(txt, remove_punct = TRUE)
#' myfcm <- fcm(toks, context = "document")
#' colnames(myfcm) <- rownames(myfcm) <- tolower(colnames(myfcm))
#' colnames(myfcm)[5] <- rownames(myfcm)[5] <- "fox"
#' myfcm
#' fcm_compress(myfcm)
fcm_compress <- function(x) {
    UseMethod("fcm_compress")
}

#' @noRd
#' @export
fcm_compress.fcm <- function(x) {
    if (!is.fcm(x))
        stop("compress_fcm only works on a fcm object")
    if (x@context != "document")
        stop("compress_fcm invalid if fcm was created with a window context")
    
    uniquednames <- unique(rownames(x))
    uniquefnames <- unique(colnames(x))
    if (length(uniquednames) == nrow(x) | length(uniquefnames) == ncol(x)) 
        stop("Features in row and in column are not same.")
    
    # add 1 since stored from 0, but constructor requires indexing from 1
    new_i <- x@i + 1
    new_j <- as(x, "dgTMatrix")@j + 1
    
    allZeroFeatures <- match(names(which(colSums(x)==0)), uniquefnames)
    
    # combine row features
    if (length(uniquednames) < nrow(x))
        new_i <- match(rownames(x), uniquednames)[new_i]
    
    # combine col features
    if (length(uniquefnames) < ncol(x))
        new_j <- match(colnames(x), uniquefnames)[new_j]
    
    if (nf <- length(allZeroFeatures)) {
        new_i <- c(new_i, rep(1, nf))
        new_j <- c(new_j, allZeroFeatures)
    }
    
    new_fcm <- sparseMatrix(i = new_i, j = new_j, 
                            x = c(x@x, rep(0, length(allZeroFeatures))),
                            dimnames = list(docs = uniquednames, features = uniquefnames))
    
    if (x@tri) new_fcm <- as(Matrix::triu(new_fcm), "dgCMatrix")
    
    result <- 
        new("fcm", new_fcm,
        settings = x@settings,
        weightTf = x@weightTf,
        weightDf = x@weightDf,
        smooth = x@smooth,
        ngrams = x@ngrams,
        concatenator = x@concatenator,
        context = x@context, window = x@window, weights = x@weights, tri = x@tri)
} 

#' sort an fcm in alphabetical order of the features
#' 
#' Sorts an \link{fcm} in alphabetical order of the features.
#' 
#' @param x \link{fcm} object
#' @return A \link{fcm} object whose features have been alphabetically sorted. 
#'   Differs from \code{\link{fcm_sort}} in that this function sorts the fcm by
#'   the feature labels, not the counts of the features.
#' @export
#' @author Ken Benoit
#' @examples
#' # with tri = FALSE
#' myfcm <- fcm(tokens(c("A X Y C B A", "X Y C A B B")), tri = FALSE)
#' rownames(myfcm)[3] <- colnames(myfcm)[3] <- "Z"
#' myfcm
#' fcm_sort(myfcm)
#' 
#' # with tri = TRUE
#' myfcm <- fcm(tokens(c("A X Y C B A", "X Y C A B B")), tri = TRUE)
#' rownames(myfcm)[3] <- colnames(myfcm)[3] <- "Z"
#' myfcm
#' fcm_sort(myfcm)
fcm_sort <- function(x) {
    UseMethod("fcm_sort")    
}
    
#' @noRd
#' @export
fcm_sort.fcm <- function(x) {
    result <- x[order(rownames(x)), order(colnames(x))]
    if (x@tri) {
        # make a triplet
        result_triplet <- as(result, "dgTMatrix")
        vals_to_swap <- which(result_triplet@i > result_triplet@j)
        tempi <- result_triplet@i[vals_to_swap]
        result_triplet@i[vals_to_swap] <- result_triplet@j[vals_to_swap]
        result_triplet@j[vals_to_swap] <- tempi
        result <- new("fcm", as(result_triplet, "dgCMatrix")) 
        
        # now copy the slot values
        result <- reassign_slots(result, x)
    }
    result
}

#' @rdname dfm_select
#' @export
#' @examples 
#' toks <- tokens(c("this contains lots of stopwords",
#'                  "no if, and, or but about it: lots"),
#'                remove_punct = TRUE)
#' tmpfcm <- fcm(toks)
#' tmpfcm
#' fcm_remove(tmpfcm, stopwords("english"))
fcm_select <- function(x, pattern = NULL, selection = c("keep", "remove"), 
                       valuetype = c("glob", "regex", "fixed"),
                       case_insensitive = TRUE,
                       verbose = TRUE, ...) {
    UseMethod("fcm_select")
}

#' @noRd
#' @export
fcm_select.fcm <- function(x, pattern = NULL, selection = c("keep", "remove"), 
                           valuetype = c("glob", "regex", "fixed"),
                           case_insensitive = TRUE,
                           verbose = TRUE, ...) {
        
        selection <- match.arg(selection)
    valuetype <- match.arg(valuetype)
    features_from_dfm <- FALSE
    
    # select features based on character length
    featIndex <- 1:nfeature(x)
   
    if (!is.null(pattern)) {
        if (!(is.character(pattern) | is.dfm(pattern) | is(pattern, "dictionary")))
            stop("pattern must be of type character, dictionary, or dfm")
        if (is.dfm(pattern)) {
            if (selection == "keep") {
                features_dfm <- pattern <- featnames(pattern)
                features_from_dfm <- TRUE
            } else {
                pattern <- featnames(pattern)
            }
        }
        
        pattern <- unique(unlist(pattern))  # to convert any dictionaries
        
        originalvaluetype <- valuetype
        # convert glob to fixed if no actual glob characters (since fixed is much faster)
        if (valuetype == "glob") {
            # treat as fixed if no glob characters detected
            if (!sum(stringi::stri_detect_charclass(pattern, c("[*?]"))))
                valuetype <- "fixed"
            else {
                pattern <- sapply(pattern, utils::glob2rx, USE.NAMES = FALSE)
                valuetype <- "regex"
            }
        }
        
        features_x <- featnames(x)
        if (case_insensitive & valuetype == "fixed") {
            features_x <- char_tolower(features_x)
            pattern <- char_tolower(pattern)
        }
        # split pattern on concatenator if exists
        if (x@concatenator != "")
            features_x <- strsplit(features_x, x@concatenator)
        
        if (valuetype == "regex") {
            if (all.equal(x@ngrams, 1L)==TRUE) {
                featIndex <- which(stringi::stri_detect_regex(features_x, paste0(pattern, collapse = "|"), 
                                                              case_insensitive = case_insensitive, ...))
            } else {
                ####
                ####
                matchPattern <- paste0(pattern, collapse = "|")
                featIndex <- which(sapply(features_x, 
                                          function(x) any(stringi::stri_detect_regex(x, matchPattern, 
                                                                                     case_insensitive = case_insensitive, ...))))
            }
        } else {
            if (all.equal(x@ngrams, 1L)==TRUE)
                featIndex <- which(features_x %in% pattern)  # unigrams
            else
                featIndex <- which(sapply(features_x, function(f) any(f %in% pattern), USE.NAMES = FALSE)) # ngrams
        }
        
        if (verbose & !features_from_dfm) 
            catm(if (selection == "keep") "kept" else "removed", " ", 
                 format(length(featIndex), big.mark=","),
                 " feature", if (length(featIndex) > 1L || length(featIndex) == 0L) "s" else "",
                 ", from ", length(pattern), " supplied (", originalvaluetype, ") feature type",
                 if (length(pattern) > 1L || length(featIndex) == 0L) "s" else "",
                 "\n", sep = "")
        
        # pad the zeros if pattern was a dfm, return in same feature order as original dfm
        # for selection = "keep" only
        if (features_from_dfm) {
            
            if (verbose)
                catm(ifelse(selection=="keep", "found", "zeroed"), " ", 
                     format(length(featIndex), big.mark=","),
                     " feature", ifelse(length(featIndex) > 1 | length(featIndex)==0, "s", ""), 
                     " from ", length(pattern), " supplied type",
                     ifelse(length(pattern) > 0 | length(featIndex)==0, "s", ""),
                     " in a dfm,", sep = "")
            
            
            # remove features in x that are not in features (from supplied dfm)
            x2 <- x[featIndex, featIndex]
            # now add zero-valued features to x that are not in x but are in pattern
            origDfmFeatureIndex <- which(!(char_tolower(pattern) %in% char_tolower(featnames(x2))))
            xOriginalFeatureLength <- nfeature(x2)
            xOriginalFeatures <- featnames(x2)
            if (verbose) catm(" padding 0s for another", length(origDfmFeatureIndex), "\n")
#             x <- new("fcm", Matrix::cbind2(x2, sparseMatrix(i = NULL, j = NULL, 
#                                                             dims = c(length(origDfmFeatureIndex), length(origDfmFeatureIndex)), 
#                                                             dimnames = list(pattern[origDfmFeatureIndex], pattern[origDfmFeatureIndex]))))
            x <- new("dfmSparse", Matrix::cbind2(x2,
                                                 sparseMatrix(i = NULL, j = NULL, dims = c(ndoc(x2), length(origDfmFeatureIndex)), 
                                                              dimnames = list(docnames(x2), pattern[origDfmFeatureIndex]))))
            if (case_insensitive & valuetype == "fixed") {
                features_x_ori <- char_tolower(featnames(x))
                features_dfm <- char_tolower(features_dfm)
            }
            featIndex <- match(features_dfm, features_x_ori)
            # x <- x2 #[, features_dfm]
        }
    }
    ##
    ## MIGHT NEED TO ADD BACK ORIGINAL ATTRIBUTES HERE
    ##
    if (!length(featIndex)) {
        if (selection == "keep")
            return(NULL)
        else 
            return(x)
    } else {
        if (selection == "keep")
            return(x[featIndex, featIndex])
        else 
            return(x[-featIndex, -featIndex])
    }
}
    

#' @rdname dfm_select
#' @export
fcm_remove <- function(x, pattern, ...) {
    UseMethod("fcm_select")
}

#' @noRd
#' @export
fcm_remove.fcm <- function(x, pattern, ...) {
    fcm_select(x, pattern, selection = "remove", ...)
}
