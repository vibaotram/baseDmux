#!/usr/bin/env python3
import os
import sys
from snakemake.utils import read_job_properties


jobscript = sys.argv[-1]


job_properties = read_job_properties(jobscript)

rule = job_properties["rule"]
jobname = job_properties["cluster"]["jobname"]
partition = job_properties["cluster"]["partition"]
cores = job_properties["cluster"]["cores"]
account = job_properties["cluster"]["account"]
output = job_properties["cluster"]["output"]
error = job_properties["cluster"]["error"]

if rule == "guppy_basecalling":
    cmdline = 'sbatch -J {jobname} -p {partition} -A {account} -c {cores} {script}'.format(jobname=jobname, partition=partition, account=account, cores=cores, script=jobscript)
else:
    cmdline = 'sbatch -J {jobname} -p {partition} {script}'.format(jobname=jobname, partition=partition, script=jobscript)
os.system(cmdline)
