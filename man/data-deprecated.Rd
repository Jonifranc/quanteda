% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data-deprecated.R
\docType{data}
\name{data-deprecated}
\alias{data-deprecated}
\alias{ukimmigTexts}
\alias{ie2010Corpus}
\alias{inaugTexts}
\alias{data_char_inaugural}
\alias{inaugCorpus}
\alias{LBGexample}
\alias{exampleString}
\alias{data_char_inaugural}
\alias{data_char_mobydick}
\title{datasets with deprecated or defunct names}
\format{See the specific object documentation for the renamed objects.}
\usage{
inaugTexts
}
\description{
These are datasets that have been renamed but that have been
  temporarily retained for backward compatibility, or that have been renamed
  and the old names removed. Please change your code to use the new names, as
  the deprecated functions will become defunct in future versions.
}
\details{
\code{ukimmigTexts} is defunct; please use 
  \code{data_char_ukimmigration} instead.

\code{ie2010Corpus} is defunct; please use 
  \code{data_corpus_irishbudget2010}

\code{inaugTexts} is deprecated; please use
  \code{data_char_inaugural} instead.

\code{data_char_inaugural} is defunct; please use
  \code{data_corpus_inaugural} instead.

\code{inaugCorpus} is defunct; please use 
  \code{data_corpus_inaugural} instead.

\code{LBGexample} is defunct; please use 
  \code{data_dfm_LBGexample} instead.

\code{exampleString} is defunct; please use 
  \code{data_char_sampletext} instead.

\code{data_char_inaugural} is defunct; please use
  \code{data_corpus_inaugural} instead.

\code{data_char_mobydick} is defunct; please use
  \code{data(mobydick, package = "tokenizers")} instead.
}
\keyword{datasets}
\keyword{deprecated}
\keyword{internal}
