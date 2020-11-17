#!/usr/bin/env python3

'''
Create snakemake report
'''

import os
from snakemake import load_configfile
import argparse

parser = argparse.ArgumentParser(description = 'Create snakemake report and output it to \'report\' folder under \'OUTDIR\' specified in the configfile.')

parser.add_argument('-c', '--configfile', dest = 'configfile', nargs = 1, default = argparse.SUPPRESS,
                    help = 'path to config file, default: \'config.yaml\'')
parser.add_argument('-r', '--reportname', dest = 'reportname', nargs = 1, default = argparse.SUPPRESS,
                    help = 'report file name, default: \'snakemake_report.html\'')
args = parser.parse_args()

if 'configfile' in args:
    configfile = args.configfile[0]
else:
    configfile = 'config.yaml'

outdir = load_configfile(configfile)['OUTDIR']
report_dir = os.path.join(outdir, "report")
os.makedirs(report_dir, exist_ok=True)

if 'reportname' in args:
    reportname = args.reportname[0]
else:
    reportname = "snakemake_report.html"
reportfile = os.path.join(report_dir, reportname)

cmd = f'snakemake --configfile {configfile} --report {reportfile}'
print("Executing: " + cmd)
os.system(cmd)
