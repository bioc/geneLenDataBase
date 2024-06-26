% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/supportedGenomes.R
\name{supportedGenomes}
\alias{supportedGenomes}
\title{Supported Genomes}
\usage{
supportedGenomes()
}
\value{
A data.frame containing supported genomes.
}
\description{
Lists supported genomes
}
\details{
Uses the \code{ucscGenomes()} function from the \code{rtracklayer} package
to obtain a list of genomes available from the UCSC genome browser.  The
\code{db} column lists genomes as they are provided to the \code{genome}
arguement of various functions.

The final column, headed \code{AvailableGeneIDs} lists the gene ID formats
for which there is a local copy of the length information avaible for the
genome listed in the \code{geneLenDataBase} package.
}
\examples{
supportedGenomes()

}
\author{
Matthew D. Young \email{myoung@wehi.edu.au}
}
