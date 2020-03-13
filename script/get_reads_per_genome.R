#!/usr/bin/env Rscript

# input: output directory of baseDmux, table annotating demultiplex, runid, barcodeid of genomes/strains
# output: folders for each genome containing corresponding fast5 and fastq 

#### Loading required packages #####
suppressPackageStartupMessages(library("optparse"))

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
ori_fast5 <- file.path(barcode_folder, "fast5")
# fastq <- list.files(barcode_folder, pattern = "barcode\\d*.fastq.gz", full.names = T, recursive = T)
ori_fastq <- file.path(barcode_folder, paste0(dict$ONT_Barcode, ".fastq.gz"))

# create destination folders
strain_dir <- sapply(dict$Genome_ID, function(x) file.path(outdir, x))
dest_fast5_dir <- file.path(strain_dir, "fast5")
dest_fastq_dir <- file.path(strain_dir, "fastq")

for (i in unique(c(dest_fast5_dir, dest_fastq_dir))) {
  dir.create(i, recursive = T, showWarnings = F)
}

# transfer files
dict <- data.frame(dict, ori_fast5, ori_fastq, dest_fast5_dir, dest_fastq_dir)


file_to_cmd <- function(file, demultiplexer, runID, filedir) {
  filename <- basename(file)
  dest_file_name <- paste(demultiplexer, runID, filename, sep = "_")
  dest_file <- file.path(filedir, dest_file_name)
  transfer_file <- paste(cmd, file, dest_file)
  exit_code = system(transfer_file)
  return(exit_code)
}

n_fast5 = 0
n_fastq = 0
for (i in 1:nrow(dict)) {
  fast5_files <- list.files(as.character(dict$ori_fast5[i]), pattern = ".*.fast5", full.names = T, recursive = T)
  exit_fast5 <- file_to_cmd(fast5_files, dict$Demultiplexer[i], dict$Run_ID[i], dict$dest_fast5_dir[i])
  if (exit_fast5 == 0) {
    n_fast5 <- n_fast5 + 1
  }
  fastq_files <- as.character(dict$ori_fastq[i])
  exit_fastq <- file_to_cmd(fastq_files, dict$Demultiplexer[i], dict$Run_ID[i], dict$dest_fastq_dir[i])
  if (exit_fastq == 0) {
    n_fastq <- n_fastq + 1
  }

    }

# report number of files transfered
message(paste("\n#", n_fast5, "fast5 files", transfer_mode, "to", outdir))
message(paste("\n#", n_fastq, "fastq files", transfer_mode, "to", outdir, "\n"))

# Rscript /home/baotram/tal/workflow/script/get_reads_per_genome.R \
# -b /home/baotram/tal/workflow/test/ \
# -o /home/baotram/tal/workflow/test/Cul_input \
# -d /home/baotram/tal/workflow/test/reads/seqdataByGenome.tsv \
# -R

# baseDmux_outdir = "/home/baotram/tal/workflow/test"
# barcodeByGenome = "/home/baotram/tal/workflow/test/reads/seqdataByGenome.tsv"
# outdir = "/home/baotram/tal/workflow/test/Cul_input"
# copy = FALSE
# move = FALSE
# symlink = TRUE