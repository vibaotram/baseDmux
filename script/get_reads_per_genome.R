#!/usr/bin/env Rscript

# input: output directory of baseDmux, table annotating demultiplex, runid, barcodeid of genomes/strains
# output: folders for each genome containing corresponding fast5 and fastq

#### Loading required packages #####
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager", repos = "https://cloud.r-project.org")

BiocManager::install("Biostrings", update = F, ask = F)

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("Biostrings"))

#### COMMAND LINE ARGUMENTS PARSING ######
option_list <- list(
  make_option(c("-b", "--baseDmux_outdir"),
              type = "character",
              help = "Path to the output folder of baseDmux"),
  make_option(c("-o", "--outdir"),
              type = "character",
              help = "Output directory"),
  make_option(c("-d", "--barcodeByGenome"),
              type = "character",
              help = "File storing demultiplexer, run_id, barcode_id for each genome_id in csv/tsv format"),
  make_option(c("-R", "--copy"),
              action = "store_true",
              default = FALSE,
              help = "Copy files"),
  make_option(c("-M", "--move"),
              action = "store_true",
              default = FALSE,
              help = "Move files"),
  make_option(c("-S", "--symlink"),
              action = "store_true",
              default = FALSE,
              help = "Symlink files")
)

myArgs <- parse_args(
  OptionParser(usage = "%prog [-b baseDmux output] [-o Outdir] [-d barcodeByGenome] [-transfering option R/M/S]\n", option_list = option_list,
               description = "Description: Create 1 folder for each genome containing corresponding fast5 and fastq from baseDmux output and a 'barcodeByGenome' table annotating demultiplex, runid, barcodeid of genomes/strains.\n\tData table must contain the following columns: \"Demultiplexer\", \"Run_ID\", \"ONT_Barcode\", \"Genome_ID\".\n\tYou can choose only ONE transfering option (copy/move/symlink).")
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

# check transfer mode
copy = myArgs$copy
move = myArgs$move
symlink = myArgs$symlink

transfer <- c(copy, move, symlink)
check = length(transfer[transfer == FALSE])
if (check == 3) {
  stop("Oups... Transfer mode is not specified.\n")
} else if (check <= 1) {
  stop("More than 1 transfer modes are specified.\n")
}

if (myArgs$copy == TRUE) {
  cmd = "rsync -avrP"
  transfer_mode = "copied"
} else if (myArgs$move == TRUE) {
  cmd = "mv"
  transfer_mode = "moved"
} else {
  cmd = "ln -s"
  transfer_mode = "symlinked"
}

# check data table
barcodeByGenome = myArgs$barcodeByGenome
if (is.null(barcodeByGenome)) {
  stop("Missing barcodeByGenome file.\n")
} else if (!file.exists(barcodeByGenome)) {
  stop("barcodeByGenome table does not exist.\n")
}
dict <- read.csv(barcodeByGenome, header = T, sep = "\t")
stdColnames <- c("Demultiplexer", "Run_ID", "ONT_Barcode", "Genome_ID")
if (!all(stdColnames %in% colnames(dict))) {
  stop("Cannot find at least 1 of following columns on barcodeByGenome table: \"Demultiplexer\", \"Run_ID\", \"ONT_Barcode\", \"Genome_ID\".")
}

# search for original file paths
barcode_folder <- file.path(baseDmux_outdir, "demultiplex", dict$Demultiplexer, dict$Run_ID, dict$ONT_Barcode)
dict$ori_fast5 <- file.path(barcode_folder, "fast5")
fastq <- list.files(barcode_folder, pattern = "barcode\\d*.fastq.gz", full.names = T, recursive = T)
dict$ori_fastq <- file.path(barcode_folder, paste0(dict$ONT_Barcode, ".fastq.gz"))

# create destination folders
# strain_dir <- sapply(dict$Genome_ID, function(x) file.path(outdir, x))
dict$dest_fast5 <- sapply(dict$Genome_ID, function(x) file.path(outdir, "fast5", x))

dest_fastq_dir <- file.path(outdir, "fastq")
dest_fastq_name <- paste0(dict$Genome_ID, ".fastq.gz")
dict$dest_fastq <- file.path(dest_fastq_dir, dest_fastq_name)

for (i in unique(c(dict$dest_fast5, dest_fastq_dir))) {
  dir.create(i, recursive = T, showWarnings = F)
}

write.csv(as.matrix(dict), file.path(outdir, "reads_per_genome.csv"), quote = F, row.names = F)
# dict <- data.frame(dict, ori_fast5, ori_fastq, dest_fast5_dir, dest_fastq_dir)


for (i in unique(dict$Genome_ID)) {
  ori_dir = dict[dict$Genome_ID == i, "ori_fast5"]
  for (o in ori_dir) {
    ori_files <- list.files(as.character(o), pattern = ".*\\.fast5", full.names = T, recursive = T)
    for (os in ori_files) {
      dest_name <- lapply(os, function(x) paste(dict[dict$ori_fast5 == o, "Demultiplexer"], dict[dict$ori_fast5 == o, "Run_ID"], basename(x), sep = "_"))
      dest_file <- paste(dict[dict$ori_fast5 == o, "dest_fast5"], dest_name, sep = "/")
      transfer_file <- paste(cmd, os, dest_file, sep = " ")
      system(transfer_file)
    }
    message(paste("\n# [", date(), "]\t", length(ori_files), "fast5 files", transfer_mode, "to", unique(dict[dict$Genome_ID == i, "dest_fast5"]), "\n"))
  }
  }


# transfer fastq files

for (i in unique(dict$Genome_ID)) {
  ori_file = dict[dict$Genome_ID == i, "ori_fastq"]
  ## save info in fastq name
  for (f in ori_file) {
    splitted_path <- unlist(strsplit(dirname(f), "/", fixed = T))
    marked <- do.call(paste, as.list(c(splitted_path[(length(splitted_path) - 2):length(splitted_path)], sep = "|")))
    fq <- readDNAStringSet(f, seek.first.rec = T, with.qualities = T, format = "fastq")
    names(fq) <- marked
    writeXStringSet(fq, f, compress = T, format = "fastq")
  }
  
  dest_file = file.path(dest_fastq_dir, paste0(i, ".fastq.gz"))
  if (length(ori_file) == 1) {
    transfer_file = paste(cmd, ori_file, dest_file, sep = " ")
  } else {
    transfer_file = paste("zcat", do.call(paste, as.list(ori_file)), "| gzip >", dest_file)
  }
  message(paste("\n# [", date(), "]\t Preparing compressed fastq file for", i))
  system(transfer_file)
  message(paste("\n#", length(ori_file), "fastq file(s) copied to", dest_file, "\n"))
}


# Rscript /home/baotram/tal/workflow/script/get_reads_per_genome.R \
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
