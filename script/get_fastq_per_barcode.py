#!/usr/bin/env python3

# move all fastq.gz files to corresponding folders from provided path based on barcode id

import glob
import os
import sys

# provide path containing fastq.gz files as the first argument
runPath = sys.argv[1]

fastq = glob.glob(os.path.join(runPath, "*.fastq.gz")) # get full paths of all fastq.gz file

for file in fastq:
    filename = os.path.basename(file)
    barcode = filename.split(".fastq.gz")[0]
    barcodePath = os.path.join(runPath, barcode)
    mkdir_cmd = "mkdir -p {}".format(barcodePath)
    os.system(mkdir_cmd)
    mv_cmd = "mv -f {} {}".format(file, barcodePath)
    exit_code = os.system(mv_cmd)
    if exit_code == 0:
        pass
    else:
        sys.exit(1)
        
print(len(fastq), "fastq files moved to corresponding barcode folders")
