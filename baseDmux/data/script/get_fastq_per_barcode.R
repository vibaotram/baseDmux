#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

runPath = args[1]

fastq = list.files(runPath, pattern = ".fastq.gz", recursive = TRUE, full.names = TRUE)

for (file in fastq) {
  barcode = basename(file)
  barcodeName = unlist(strsplit(barcode, ".fastq.gz"))
  barcodePath = file.path(runPath, barcodeName)
  mv_cmd <- paste("mv", file, barcodePath, sep = " ")
  system(mv_cmd)
}

# runPath = "/home/baotram/tal/workflow/demultiplex/deepbinner/20190415_1209_MN25256_FAK06411_844e8015"