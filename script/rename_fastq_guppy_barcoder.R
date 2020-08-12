#!/usr/bin/env Rscript

## rename fastq file created by guppy_barcoder

args <- commandArgs(trailingOnly = TRUE)

folder = args[1]

# folder = "/home/baotram/tal/workflow/test/demultiplex/guppy/20190411_1245_MN25256_FAH93041_8a9c834e"

fastq = list.files(folder, pattern = ".fastq", full.names = TRUE, recursive = T)

barcode_path = dirname(fastq)

for (p in unique(barcode_path)) {
  barcode = basename(p)
  newfile = paste0(p, "/", barcode, ".fastq")
  concat = paste0("cat ", p, "/*.fastq", " > ", newfile)
  gzip = paste0("gzip -f -9", newfile)
  rm = paste0("rm ", p, "/*.fastq")
  print(paste("Concatenating fastq files for", barcode))
  system(paste(concat, gzip, rm, sep = " && "))
}

# for (file in fastq) {
#   barcode_path = dirname(file)
#   barcode = basename(barcode_path)
#   filename = basename(file)
#   newfilename = sub("([^_]*_){3}", paste0(barcode, "_"), filename)
#   fastq_path = paste0(barcode_path, "/fastq")
#   mkdir_cmd = paste0("mkdir ", fastq_path)
#   system(mkdir_cmd)
#   newfile = paste(fastq_path, newfilename, sep = "/")
#   mv_cmd = paste("mv", file, newfile, sep = " ")
#   system(mv_cmd)
# }


message(paste(length(fastq), "fastq files concatenated and compressed into", length(unique(barcode_path)), "fastq.gz files named as barcode id in each barcode folder"), sep = " ")
