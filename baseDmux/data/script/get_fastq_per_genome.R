#!/usr/bin/env Rscript

# input: output directory of baseDmux, table annotating demultiplex, runid, barcodeid of genomes/strains
# output: folders for each genome containing corresponding fast5 and fastq

#### Loading required packages #####
suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("Biostrings"))
suppressPackageStartupMessages(library("dplyr"))

#### COMMAND LINE ARGUMENTS PARSING ######
option_list <- list(
  make_option(c("-b", "--baseDmux_outdir"),
              type = "character",
              default = NULL,
              help = "Path to the output folder of baseDmux"),
  make_option(c("-o", "--outdir"),
              type = "character",
              default = NULL,
              help = "Output directory"),
  make_option(c("-g", "--genome"),
              type = "character",
              help = "genome ID"),
  make_option(c("-d", "--barcodeByGenome"),
              type = "character",
              help = "File listing demultiplexer, Run_ID, ONT_Barcode for each Genome_ID in csv/tsv format"),
  # make_option(c("-R", "--copy"),
  #             action = "store_true",
  #             default = FALSE,
  #             help = "Copy files"),
  # make_option(c("-M", "--move"),
  #             action = "store_true",
  #             default = FALSE,
  #             help = "Move files"),
  # make_option(c("-S", "--symlink"),
  #             action = "store_true",
  #             default = FALSE,
  #             help = "Symlink files")
)

myArgs <- parse_args(
  OptionParser(usage = "%prog [-b baseDmux output] [-o Outdir] [-d barcodeByGenome] [-transfering option R/M/S]\n", option_list = option_list,
               description = "Description: Create 1 folder for each genome and create a fastq file with corresponding reads from baseDmux output and a 'barcodeByGenome' table annotating demultiplex, runid, barcodeid of genomes/strains.\n\tData table must contain the following columns: \"Demultiplexer\", \"Run_ID\", \"ONT_Barcode\", \"Genome_ID\".")
)


# check baseDmux outdir
baseDmux_outdir = myArgs$baseDmux_outdir
if (is.null(baseDmux_outdir)) {
  stop("Missing output directory of baseDmux.\n")
} else if (!dir.exists(baseDmux_outdir)) {
  stop("Output directory of baseDmux does not exist.\n")
}

# check outdir argument
outdir = myArgs$outdir
if (is.null(outdir)) {
  stop("Missing output directory.\n")
}

# check barcodeByGenome table
barcodeByGenome = myArgs$barcodeByGenome
if (is.null(barcodeByGenome)) {
  stop("Missing barcodeByGenome file.\n")
} else if (!file.exists(barcodeByGenome)) {
  stop("barcodeByGenome table does not exist.\n")
}

# Load barcodeByGenome table
dict <- read.csv(barcodeByGenome, header = T, sep = "\t")
stdColnames <- c("Demultiplexer", "Run_ID", "ONT_Barcode", "Genome_ID")
if (!all(stdColnames %in% colnames(dict))) {
  stop("Cannot find at least 1 of following columns on barcodeByGenome table: \"Demultiplexer\", \"Run_ID\", \"ONT_Barcode\", \"Genome_ID\".")
}

# search for original file paths
barcode_folder <- file.path(baseDmux_outdir, "demultiplex", dict$Demultiplexer, dict$Run_ID, dict$ONT_Barcode)

fastq <- list.files(barcode_folder, pattern = "barcode\\d*.fastq.gz", full.names = T, recursive = T)
dict$ori_fastq <- file.path(barcode_folder, paste0(dict$ONT_Barcode, ".fastq.gz"))

# create destination folders
# strain_dir <- sapply(dict$Genome_ID, function(x) file.path(outdir, x))
# dict$dest_fast5 <- sapply(dict$Genome_ID, function(x) file.path(outdir, "fast5", x))

dest_fastq_dir <- file.path(outdir, "fastq")
dest_fastq_name <- paste0(dict$Genome_ID, ".fastq.gz")
dict$dest_fastq <- file.path(dest_fastq_dir, dest_fastq_name)

dict_csv <- file.path(outdir, "reads_per_genome.csv")
if (!file.exists(dict_csv)) {
  write.table(dict, dict_csv, quote = F, row.names = F, sep = "\t")
} 


# transfer fastq files

ori_file = dict[dict$Genome_ID == myArgs$genome, "ori_fastq"]
dir.create(dest_fastq_dir, mode = "0770")
dest_file = file.path(dest_fastq_dir, paste0(myArgs$genome, ".fastq.gz"))
if (length(ori_file) == 1) {
  transfer_file = paste(cmd, ori_file, dest_file, sep = " ")
} else {
  transfer_file = paste("zcat", do.call(paste, as.list(ori_file)), "| gzip >", dest_file)
}
message(paste("\n# [", date(), "]\t Preparing compressed fastq file for", myArgs$genome))
system(transfer_file)
message(paste("\n#", length(ori_file), "fastq file(s) copied to", dest_file, "\n"))

# Create read ids list

fqPath <- dest_file
fqCon <- XVector::open_input_files(fqPath)
idsFilePath <- file.path(dest_fastq_dir, "read_id_list.txt")
idsFileCon <- file(idsFilePath, open = "w")
while (TRUE) {
  titles <- names(Biostrings::readDNAStringSet(fqCon, format = "fastq", nrec = 10000))
  if (length(titles) == 0L) break
  writeLines(gsub("^(.*)[ ]runid=.*$", "\\1", titles), con = idsFileCon)
}
close(idsFileCon)

quit(save = "no", status = 0, runLast = FALSE)



# Rscript /home/baotram/tal/workflow/script/.get_reads_per_genome.R \
# -b /home/baotram/tal/workflow/test \
# -o /home/baotram/tal/workflow/test/Cul_input1 \
# -d /home/baotram/tal/workflow/test/reads/barcodeByGenome_sample.tsv \
# -R

# baseDmux_outdir = "/home/baotram/tal/workflow/test"
# barcodeByGenome = "/home/baotram/tal/workflow/test/reads/barcodeByGenome_sample.tsv"
# outdir = "/home/baotram/tal/workflow/test/Cul_input"
# copy = FALSE
# move = FALSE
# symlink = TRUE
