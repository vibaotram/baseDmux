#!/usr/bin/env python3
import os
import sys
import re
from snakemake.utils import read_job_properties

# LOGDIR = sys.argv[-2]
# DATADIR = sys.argv[-3]
jobscript = sys.argv[-1]
# mo = re.match(r'(\S+)/snakejob\.\S+\.(\d+)\.sh', jobscript)
# assert mo
# sm_tmpdir, sm_jobid = mo.groups()
# props = read_job_properties(jobscript)

# set up job name, project name
# jobname = "{rule}-{jobid}".format(rule=props["rule"], jobid=sm_jobid)
# if props["params"].get("logid"):
#     jobname = "{rule}-{id}".format(rule=props["rule"], id=props["params"]["logid"])

# -E is a pre-exec command, that reschedules the job if the command fails
#   in this case, if the data dir is unavailable (as may be the case for a hot-mounted file path)

job_properties = read_job_properties(jobscript)

# do something useful with the threads
# threads = job_properties[threads]

# access property defined in the cluster configuration file (Snakemake >=3.6.0)
job_properties["cluster"]["time"]
jobname = job_properties["cluster"]["jobname"]
partition = job_properties["cluster"]["partition"]

cmdline = 'sbatch -j {jobname} -p {cluster.partition} {script}" '.format(jobname=jobname, partition=partition, script=jobscript)
os.system(cmdline)
