#!/usr/bin/env python3
import os
from snakemake.utils import read_job_properties


jobscript = sys.argv[-1]


job_properties = read_job_properties(jobscript)


job_properties["cluster"]["time"]
jobname = job_properties["cluster"]["jobname"]
partition = job_properties["cluster"]["partition"]
cores = job_properties["cluster"]["cores"]
account = job_properties["cluster"]["account"]

cmdline = 'sbatch -j {jobname} -p {partition} -A {account} -c {cores} {script}" '.format(jobname=jobname, partition=partition, account=account, cores=cores, script=jobscript)
os.system(cmdline)
