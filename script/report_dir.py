#!/usr/bin/env python3

'''
print report directory
'''

import os
from snakemake import load_configfile

outdir = load_configfile('config.yaml')['OUTDIR']
report_dir = os.path.join(outdir, "report")
os.makedirs(report_dir, exist_ok=True)
print(report_dir)
