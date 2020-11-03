#!/usr/bin/env python3

'''
move all fastq.gz files to corresponding folders from provided path based on barcode id
'''

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
    os.makedirs(barcodePath, exist_ok=True) # create barcode folders
    # move fastq files to corresponding barcode folders
    newfile = os.path.join(barcodePath, filename)
    os.renames(file, newfile)

print(len(fastq), "fastq files moved to corresponding barcode folders")
