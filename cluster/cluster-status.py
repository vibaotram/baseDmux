#!/usr/bin/env python3

import subprocess
import sys

'''
modified from :
https://snakemake.readthedocs.io/en/stable/tutorial/additional_features.html#using-cluster-status
and
https://github.com/Snakemake-Profiles/slurm/blob/master/%7B%7Bcookiecutter.profile_name%7D%7D/slurm-status.py
'''

jobid = sys.argv[-1]

status = str(subprocess.check_output("sacct -j %s --format State --noheader | head -1 | awk '{print $1}'" % jobid, shell=True).strip())

failed = ["BOOT_FAIL", "CANCELLED", "DEADLINE", " FAILED", " NODE_FAIL", "OUT_OF_MEMORY", " PREEMPTED", " STOPPED", " SUSPENDED", " TIMEOUT"]

if status == "COMPLETED":
  print("success")
elif any(status.startswith(s) for s in failed):
  print("failed")
else:
  print("running")
