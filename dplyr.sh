#!/usr/bin/Rscript

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  dplyr - cli    [mikefc@coolbutuseless.com]
#
# Run chains of dplyr commands in the terminal (using {littler})
#
# * run any dplyr command of the form "dplyr::verb(.data, code)"
# * can set input file to be a CSV or RDS file
# * if reading data from stdin (the default), assume that it is CSV format
#
# History
#   v0.1.0  2020-04-20 Initial release
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

suppressMessages({
    library(docopt)
    library(dplyr)
})



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# configuration for docopt
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
doc <- "dplyr-cli

Usage:
    dplyr.sh <command> [--file=fn] [--csv | -c] [--verbose | -v] [<code>...]
    dplyr.sh -h | --help

Options:
    -h --help            show this help text
    -f FILE --file=FILE  input CSV or RDS filename. If reading from stdin, assumes CSV [default: stdin]
    -c --csv             write output to stdout in CSV format (instead of default RDS file)
    -v --verbose         be verbose"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Print help if requested
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
opt <- docopt(doc)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# What did the user pass in to stdin?
# Two cases handled:
#   - if stdin is only a single element, assume it's a filename
#       - only reading of RDS and CSV files currently supported.
#         (easy to add more)
#   - otherwise assume that the user has echoed the contents of
#     a CSV file and piped it into this command
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (opt$verbose) message("------------------------------------------")
input <- readLines(opt$file)

if (length(input) == 1) {
    input <- trimws(input)
    if (file.exists(input)) {
        if (opt$verbose) message("[input] looks like an existing file: ", input)
        ext <- tolower(tools::file_ext(input))
        .data <- switch(
            ext,
            csv = readr::read_csv(input),
            rds = readRDS(input),
            stop("Unknown file extension: ", ext)
        )
    } else {
        stop("[input]: not found: ", input)
    }
} else {
    if (opt$verbose) message("[input] reading CSV from stdin")
    .data <- readr::read_csv(input)
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Collapse the code string
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
code <- paste(opt$code, collapse=" ")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Run the command + code
# If the user is demanding CSV or kable output, then
# set the result to be the initial data and print it out
# later
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (opt$command %in% c('csv', 'kable')) {
    opt$csv <- TRUE
    res <- .data
} else {
    command <- glue::glue("dplyr::{opt$command}(.data, {code})")
    if (opt$verbose) message("command: ", command)

    res <- eval(parse(text = command))
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Output options:
#  - if command == 'kable' then use knitr::kable to output
#  - if command == 'csv' or opt$csv is true, then dump
#    CSV strings to the terminal. User can redirect how
#    they want
#  - otherwise save to an RDS file and echo to stdout such
#    that another command can use it.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (opt$command == 'kable') {
    cat(knitr::kable(.data), sep = "\n")
} else if (opt$csv) {
    if (opt$verbose) message(">>>> output CSV to stdout")
    write.csv(res, row.names = FALSE)
} else {
    tmp <- tempfile(fileext = ".rds")
    saveRDS(res, tmp)
    if (opt$verbose) message(">>>> output to RDS", tmp)
    cat(tmp, "\n")
}


