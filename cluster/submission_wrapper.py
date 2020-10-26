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

job_properties = read_job_properties(jobscript)

submit_params = ''
for k in job_properties['cluster'].values():
    submit_params += k + ' '

dep_jobid = sys.argv[1:-1]
if not any(re.match('\d+', j) for j in dep_jobid): # "normal"-submit
    dependencies = ''
else: # if immediate-submit, for slurm only
    dependencies = ' --dependency=afterok:' + ':'.join(dep_jobid)

submit_params += dependencies

cmdline = " ".join([submit_params, jobscript])

# jobscript.replace("\n", "\necho -e\"sbatch parameters:\n\"{}\"\"".format(sbatch), 1)
with open(jobscript, "r") as j:
    scripts = j.readlines()
scripts.insert(1, "echo -e \"# Submit command-line: \"{}\"\"\n".format(cmdline))
scripts.insert(2, "echo -e \"# Job running on node: $(hostname -a)\"\n")
scripts.insert(3, "echo -e \"\n\"")
with open(jobscript, "w") as j:
    j.writelines(scripts)

os.system(cmdline)
# print(cmdline)
# sbatch --job-name {cluster.job-name} --partition {cluster.partition} --account {cluster.account} --cpus-per-task {cluster.cpus-per-task} --output {cluster.output} --error {cluster.error} snakejob.sh
