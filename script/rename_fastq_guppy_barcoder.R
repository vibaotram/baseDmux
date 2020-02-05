#!/usr/bin/env Rscript

## rename fastq file created by guppy_barcoder

args <- commandArgs(trailingOnly = TRUE)

folder = args[1]

# folder = "/home/baotram/tal/workflow/test/demultiplex/guppy/20190411_1245_MN25256_FAH93041_8a9c834e"

fastq = list.files(folder, pattern = ".fastq.gz", full.names = TRUE, recursive = T)

for (file in fastq) {
  barcode_path = dirname(file)
  barcode = basename(barcode_path)
  newfile = paste0(barcode_path, "/", barcode,".fastq.gz")
  mv_cmd = paste("mv", file, newfile, sep = " ")
  system(mv_cmd)
}

print(paste(length(fastq), "fastq files renamed as barcode id"))
