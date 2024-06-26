#' Download Transcript Length Data
#' 
#' Attempts to download the length of each transcript for the genome and gene
#' ID specified from the UCSC genome browser.
#' 
#' For each transcript, the UCSC genome browser is used to obtain the exon
#' boundaries.  The length of each transcript is then taken to be the sum of
#' the lengths of all its exons.  Each transcript is then associated with a
#' gene.
#' 
#' The UCSC does not contain length information for all combinations of genome
#' and gene ID listed by \code{\link{supportedGeneIDs}} and
#' \code{\link{supportedGenomes}}.  If \code{downloadLengthFromUCSC} fails
#' because your gene ID format is not supported for the genome you specified, a
#' list of possible ID formats for the specified genome will be listed.
#' 
#' @param genome A string identifying the genome that \code{genes} refer to.
#' For a list of supported organisms see \code{\link{supportedGenomes}}.
#' @param id A string identifying the gene identifier used by \code{genes}.
#' For a list of supported gene identifierst see
#' \code{\link{supportedGeneIDs}}.
#' @return A data.frame containing with three columns, the gene name,
#' transcript identifier and the length of the transcript.  Each row represents
#' one transcript.
#' @note For some genome / gene ID combinations, no gene ID will be provided by
#' UCSC.  In this case, the gene name column is set to \code{NA}.  However, the
#' transcript ID column will always be populated.
#' 
#' @author Matthew D. Young \email{myoung@@wehi.edu.au}
#' 
#' @export
#' 
#' @seealso \code{\link{supportedGenomes}}, \code{\link{supportedGeneIDs}}
#' 
#' @examples
#' \dontrun{
#'   flat_length <- downloadLengthFromUCSC('hg19', 'ensGene')
#' }
#' 
downloadLengthFromUCSC <- function(genome, id) {
  table_name <- NULL
  # We have to handle geneSymbol specially
  if (id == "geneSymbol") {
    table_name <- "refFlat"
    id <- "refGene"
  }
  # Check that genome/id are in UCSC listing
  if (!genome %in% supportedGenomes()[, "db"]) {
    stop("Length lookup is not supported for the genome ", genome, ".  You will have to obtain bias data manually.\n  Run supportedGenomes() for a list of supported genomes.")
  }
  if (!id %in% supportedGeneIDs()[, "db"]) {
    stop("Length lookup is not supported for the gene identifier ", id, ".  You will have to obtain bias data manually.\n  Run supportedGeneIDs() for a list of supported gene identifier formats.")
  }
  session <- browserSession()
  genome(session) <- genome
  # track=supportedUCSCtables()[id,"track"]
  available_tracks <- trackNames(session)
  if (!id %in% as.character(available_tracks)) {
    tmp <- supportedGeneIDs()
    tmp <- tmp[tmp$db %in% available_tracks, ]
    # We were actually looking for the gene Symbol guy...
    if (!is.null(table_name)) {
      id <- "geneSymbol"
    }
    message("The gene identifier ", id, " is unavailable for the genome ", genome, ".  Please obtain bias data manually or use on of the following gene identifiers.")
    print(tmp)
    stop("Unsupported gene identifier.")
  }
  query <- ucscTableQuery(session, track = id, table = table_name, names = NULL)
  # This table contais all the pertenant data
  message("Fetching length data for transcripts...")
  data <- unfactor(getTable(query))
  # We need to map transcripts back to some kind of gene ID
  # txname2gene_mapinfo=GenomicFeatures:::.UCSC_TXNAME2GENEID_MAPINFO[[id]]
  txname2gene_mapinfo <- txdbmaker:::.UCSC_TXNAME2GENEID_MAPDEFS[[id]]
  if (!is.null(table_name)) {
    # Gene symbol is special...
    gene_id_type <- "Gene Symbol"
    gene_id <- unfactor(data$geneName)
    tx_name <- unfactor(data$name)
  } else if (is.null(txname2gene_mapinfo)) {
    # OT OH!  Try and guess...
    gene_id_type <- "unknown gene ids"
    gene_id <- unfactor(data$name2)
    tx_name <- unfactor(data$name)
  } else {
    message("Fetching gene ID to transcript mappings...")
    tablename2 <- as.character(txname2gene_mapinfo[[1]][[1]]["tablename"])
    a <- tryCatch(
      {
        query2 <- ucscTableQuery(session, track = id, table = tablename2)
        ucsc_genetable <- unfactor(getTable(query2))
        tx_name <- ucsc_genetable[[txname2gene_mapinfo[[1]][[1]]["Lcolname"]]]
        gene_id <- ucsc_genetable[[txname2gene_mapinfo[[1]][[1]]["Rcolname"]]]
        if (is.null(tx_name) | is.null(gene_id)) {
          stop("expected cols \"", txname2gene_mapinfo[[1]][[1]]["Lcolname"], "\" or/and \"", txname2gene_mapinfo[[1]][[1]]["Rcolname"], "\" not found in table ", tablename2)
        }
        if (!is.character(tx_name)) {
          tx_name <- as.character(tx_name)
        }
        if (!is.character(gene_id)) {
          gene_id <- as.character(gene_id)
        }
        gene_id_type <- txname2gene_mapinfo[[2]]
        list(gene_id_type, gene_id, tx_name)
      },
      error = function(ex) {
        gene_id_type <- "unknown gene ids"
        gene_id <- unfactor(data$name2)
        tx_name <- unfactor(data$name)
        list(gene_id_type, gene_id, tx_name)
      }
    )
    gene_id_type <- a[[1]]
    gene_id <- a[[2]]
    tx_name <- a[[3]]
    rm(a)
    message("Using gene identifier ", gene_id_type)
  }
  if (is.null(gene_id)) {
    # There was no gene information, failure
    gene_id <- rep(NA, length(tx_name))
  }
  data$GID <- gene_id[match(unfactor(data$name), tx_name)]
  length_data <- data.frame(Gene = data$GID, Transcript = unfactor(data$name), Length = transcriptWidths(unfactor(data$exonStarts), unfactor(data$exonEnds)), stringsAsFactors = FALSE)
  # If it is possible, it would be nice to have a routine which added the downloaded data to the pool of locally available databases
  length_data
}
