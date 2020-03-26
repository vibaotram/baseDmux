#!/bin/bash
#SBATCH --job-name bD-sample
#SBATCH --output slurm-%x_%j.log
#SBATCH --error slurm-%x_%j.log

echo -e "## [$(date) - baseDmux]\t Starting full workflow"

echo -e "## [$(date) - baseDmux]\t Creating working environment"

module load system/Miniconda3/1.0

env=/home/$(whoami)/.conda/envs/snakemake

[ ! -d $env ] && echo -e "## [$(date) - baseDmux]\t Creating conda environment for baseDmux" && conda env create -f environment.yaml -n snakemake
# [ -d $env ] && echo "Updating conda environment for baseDmux" && conda env update -f environment.yaml -n snakemake

source activate snakemake

# module load bioinfo/snakemake/5.9.1-conda
module load system/singularity/3.3.0

snakemake --unlock

echo -e "## [$(date) - baseDmux]\t Ready to execute snakemake workflow"

# snakemake --nolock --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " --latency-wait 60 \
# --cluster-config cluster/cluster.json \
# --cluster "sbatch --job-name {cluster.job-name} \
# -p {cluster.partition} -A {cluster.account} --cpus-per-task {cluster.cpus-per-task} --output={cluster.output} --error={cluster.error}"

snakemake --nolock --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " --latency-wait 60 \
--cluster "python3 cluster/cluster-wrapper.py" && \
echo -e "## [$(date) - baseDmux]\t Snakemake workflow finished"  && \
echo -e "## [$(date) - baseDmux]\t Creating report for demultiplexing report"  && \
snakemake --use-singularity --use-conda -p --verbose report_demultiplex && \
echo -e "## [$(date) - baseDmux]\t Creating snakemake report"  && \
snakemake --report $(python3 script/report_dir.py)/snakemake_report.html && \
echo -e "## [$(date) - baseDmux]\t Creating folder containing fastq and fast5 for each genome" && \
snakemake --use-singularity --use-conda -p --verbose get_reads_per_genome && \
echo -e "## [$(date) - baseDmux]\t Finished!"
