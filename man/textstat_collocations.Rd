% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/textstat_collocations.R
\name{textstat_collocations}
\alias{textstat_collocations}
\alias{is.collocations}
\title{calculate collocation statistics}
\usage{
textstat_collocations(x, method = c("lambda", "lambda1", "lr", "chi2", "pmi",
  "dice"), size = 2, min_count = 2, ...)

is.collocations(x)
}
\arguments{
\item{x}{a \link{tokens} object whose collocations will be scored}

\item{method}{association measure for detecting collocations.
Let \eqn{i} index documents, and \eqn{j} index features, \eqn{n_{ij}} refers to 
observed counts, and \eqn{m_{ij}} the expected counts in a collocations 
frequency table of dimensions \eqn{(J - size + 1)^2}. 

Available measures are computed as: 

\describe{\item{\code{"lr"}}{The likelihood ratio 
statistic \eqn{G^2}, computed as: \deqn{2 * \sum_i \sum_j ( n_{ij} * log 
\frac{n_{ij}}{m_{ij}} )} } 
\item{\code{"chi2"}}{Pearson's \eqn{\chi^2} statistic, computed as: 
\deqn{\sum_i \sum_j \frac{(n_{ij} - m_{ij})^2}{m_{ij}}} } 
\item{\code{"pmi"}}{point-wise mutual information 
score, computed as log \eqn{n_{11}/m_{11}}} 
\item{\code{"dice"}}{the Dice coefficient, computed as \eqn{n_{11}/n_{1.} + n_{.1}}} 
\item{\code{"lambda1"}}{unigram subtuples, Blaheta and Johnson's method (called through 
\code{\link{sequences}})}  
\item{\code{"lambda"}}{all subtuples algorithm, Blaheta and Johnson's method 
(called through \code{\link{sequences}})} }}

\item{size}{numeric argument representing the length of the collocations
to be scored.  The maximum size is currently 3 for all
methods except \code{"lambda"} and \code{"lambda1"}, which has a maximum size of 5.
Use c(2,n) or 2:n to return collocations of bigram to n-gram collocations.}

\item{min_count}{minimum frequency of collocations that will be scored}

\item{...}{additional arguments passed to \code{\link{collocations2}} for the
first four methods, or to  \code{\link{sequences}} for \code{method = "bj_*"}}
}
\value{
\code{textstat_collocations} returns a data.frame of collocations and their
  scores and statistsics.

\code{is.collocation} returns \code{TRUE} if the object is of class
  \code{collocations}, \code{FALSE} otherwise.
}
\description{
Identify and score collocations from a tokenized text.
}
\note{
This function is under active development, and we aim to improve both its operation and 
efficiency in the next release of \pkg{quanteda}.
}
\examples{
txts <- c("quanteda is a package for quantitative text analysis", 
          "quantitative text analysis is a rapidly growing field", 
          "The population is rapidly growing")
toks <- tokens(txts)
textstat_collocations(toks, method = "lr")
textstat_collocations(toks, method = "lr", min_count = 1)
textstat_collocations(toks, method = "lr", size = 2:3, min_count = 1)
(cols <- textstat_collocations(toks, method = "lr", size = 2:3, min_count = 2))

# extracting multi-part proper nouns (capitalized terms)
toks2 <- tokens(corpus_segment(data_corpus_inaugural, what = "sentence"))
toks2 <- tokens_select(toks2, stopwords("english"), "remove", padding = TRUE)
toks2 <- tokens_select(toks2, "^([A-Z][a-z\\\\-]{2,})", valuetype="regex", 
                     case_insensitive = FALSE, padding = TRUE)
seqs <- textstat_collocations(toks2, method = "lambda")
head(seqs, 10)

# compounding tokens is more efficient when applied to the same tokens object 
toks_comp <- tokens_compound(toks2, seqs)
}
\references{
Blaheta, D., & Johnson, M. (2001). 
  \href{http://web.science.mq.edu.au/~mjohnson/papers/2001/dpb-colloc01.pdf}{Unsupervised
   learning of multi-word verbs}. Presented at the ACLEACL Workshop on the 
  Computational Extraction, Analysis and Exploitation of Collocations.
  
  McInnes, B T. 2004. "Extending the Log Likelihood Measure to Improve 
  Collocation Identification."  M.Sc. Thesis, University of Minnesota.
}
\keyword{collocations}
\keyword{experimental}
\keyword{textstat}
