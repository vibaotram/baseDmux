#!/bin/bash
# properties = {properties}

echo -e "# Job running on node: $SLURM_JOB_NODELIST\n"
echo -e "# Number of used CPUS: $SLURM_CPUS_ON_NODE\n"
echo -e "# Memory per CPU in megabyte: $SLURM_MEM_PER_CPU\n"
echo -e "# Partition: $SLURM_JOB_PARTITION\n"

{exec_job}
