#!/bin/bash
#SBATCH --job-name bd_for_Medaka
#SBATCH --output slurm-%x_%j.log
#SBATCH --error slurm-%x_%j.log

## "$1" = hac or hac_mod

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


# snakemake --nolock --use-singularity --singularity-args "--nv " --use-conda --cores -p --verbose \
# --latency-wait 60 --keep-going --restart-times 2 --rerun-incomplete \
# --cluster "python3 cluster/slurm_wrapper.py {dependencies}" \
# --cluster-status "python3 cluster//slurm_status.py" \
# --immediate-submit --notemp

#snakemake -s snakefile_master --nolock --use-singularity --singularity-args "--nv " --use-conda --cores -p --verbose -n

snakemake -s snakefile_master --nolock --use-singularity --singularity-args "--nv " --use-conda --cores -p --verbose \
--latency-wait 60 --keep-going --restart-times 1 --rerun-incomplete \
--cluster "python3 cluster/slurm_wrapper.py" --cluster-config cluster/cluster.json && \
echo -e "## [$(date) - baseDmux]\t Snakemake workflow finished"  && \
echo -e "## [$(date) - baseDmux]\t Creating snakemake report"  && \
snakemake --report $(python3 script/report_dir.py)/snakemake_report.html && \
echo -e "## [$(date) - baseDmux]\t Finished!"

