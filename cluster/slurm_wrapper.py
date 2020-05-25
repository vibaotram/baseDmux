#!/usr/bin/env python3

'''
wrap ...
'''
import os
import sys
from snakemake.utils import read_job_properties
from snakemake import load_configfile
import re
# import subprocess

jobscript = sys.argv[-1]
config = sys.argv[1]

job_properties = read_job_properties(jobscript)

if len(job_properties['cluster']) > 0: # if using cluster config
    sbatch_params = ''
    for k in job_properties['cluster'].values():
        sbatch_params += k + ' '
else: # if not
    config_properties = load_configfile(config)

    rule = job_properties['rule']
    job_name = '--job-name ' + rule

    # jobid = job_properties['jobid']
    threads = job_properties['threads']
    cpus_per_task = '--cpus-per-task ' + str(threads)

    ntasks = '--ntasks 1'

    outdir = config_properties['OUTDIR']
    logdir = os.path.join(outdir, 'log/slurm')
    os.makedirs(logdir, exist_ok=True)
    try:
        log = job_properties['params']['log']
        # log = os.path.splitext(log)[0]
    except IndexError:
        log = rule
    output = f'--output {logdir}/{log}_%j'
    error = f'--error {logdir}/{log}_%j'


    # resources = config_properties['RESOURCE']
    # indir = config_properties['INDIR']
    # fast5 = glob.glob(os.path.join(indir, '*', 'fast5/'), recursive = True)
    #
    # mem = 0
    # for f in fast5:
    #     fmem = subprocess.check_output(["du", "-sh", "-B", "G", f])
    #     mem += int(fmem.decode('UTF-8').split('G')[0])
    # mem

    resources = config_properties['RESOURCE']
    if resources == 'GPU' and rule in ['guppy_basecalling', 'guppy_demultiplexing', 'deepbinner_classification']:
        partition = '--partition gpu --account gpu_group'
    elif rule == 'multi_to_single_fast5':
        partition = '--partition highmem --account bioinfo'
    else:
        partition = '--partition normal --account bioinfo'

    sbatch_params = ' '.join([job_name, partition, cpus_per_task, ntasks, output, error])

dep_jobid = sys.argv[1:-1]
if not any(re.match('\d+', j) for j in dep_jobid): # "normal"-submit
    dependencies = ''
else: # if immediate-submit
    dependencies = ' --dependency=afterok:' + ':'.join(dep_jobid)
# sbatch = f'sbatch --parsable --job-name {rule} {partition} --cpus-per-task {cpus_per_task} --ntasks 1 --output {logdir}/{log}_%j --error {logdir}/{log}_%j'

sbatch = 'sbatch --parsable ' + sbatch_params + dependencies

# jobscript.replace("\n", "\necho -e\"sbatch parameters:\n\"{}\"\"".format(sbatch), 1)
with open(jobscript, "r") as j:
    scripts = j.readlines()

scripts.insert(1, "echo -e \"# sbatch parameters: \"{}\"\"\n".format(sbatch))
scripts.insert(2, "echo -e \"# Job running on node: $SLURM_JOB_NODELIST\"\n")


with open(jobscript, "w") as j:
    j.writelines(scripts)



cmdline = " ".join([sbatch, jobscript])
# sbatch --job-name {cluster.job-name} --partition {cluster.partition} --account {cluster.account} --cpus-per-task {cluster.cpus-per-task} --output {cluster.output} --error {cluster.error}

os.system(cmdline)
# print(cmdline)
