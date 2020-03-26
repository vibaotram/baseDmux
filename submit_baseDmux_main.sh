#!/bin/bash
#SBATCH --job-name baseDmux
#SBATCH --output slurm-%x_%j.log
#SBATCH --error slurm-%s_%j.log


module load bioinfo/snakemake/5.9.1-conda
module load system/singularity/3.3.0

# snakemake --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " --latency-wait 60 \
# --cluster-config cluster/cluster.json \
# --cluster "sbatch --job-name {cluster.job-name} \
# -p {cluster.partition} -A {cluster.account} --cpus-per-task {cluster.cpus-per-task} --output {cluster.output} --error {cluster.error}"

snakemake --nolock --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " --latency-wait 60 \
--cluster "python3 cluster/cluster-wrapper.py"
