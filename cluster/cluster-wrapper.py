#!/usr/bin/env python3

'''
wrap ...
'''
import os
import sys
from snakemake.utils import read_job_properties
from snakemake import load_configfile

jobscript = sys.argv[-1]
config = 'config.yaml'

job_properties = read_job_properties(jobscript)
config_properties = load_configfile(config)



# rule = job_properties["rule"]
# jobname = job_properties["cluster"]["jobname"]
# partition = job_properties["cluster"]["partition"]
# cores = job_properties["cluster"]["cores"]
# account = job_properties["cluster"]["account"]
# output = job_properties["cluster"]["output"]
# error = job_properties["cluster"]["error"]

rule = job_properties['rule']
jobid = job_properties['jobid']
cpus_per_task = job_properties['threads']
log = job_properties['params']['log']

outdir = config_properties['OUTDIR']
logdir = os.path.join(outdir, "log/slurm")
os.makedirs(logdir, exist_ok=True)

resources = config_properties['RESOURCE']

if resources == 'GPU' and rule in ['guppy_basecalling', 'guppy_demultiplexing']:
    partition = '--partition gpu --account gpu_group'
elif rule == 'multi_to_single_fast5':
    partition = '--partition highmem --account bioinfo'
else:
    partition = '--partition normal --account bioinfo'


cmdline = f'sbatch --job-name {rule} {partition} --cpus-per-task {cpus_per_task} --output {logdir}/{log}_%j --error {logdir}/{log}_%j {jobscript}'
# sbatch --job-name {cluster.job-name} --partition {cluster.partition} --account {cluster.account} --cpus-per-task {cluster.cpus-per-task} --output {cluster.output} --error {cluster.error}

os.system(cmdline)
# print(cmdline)
