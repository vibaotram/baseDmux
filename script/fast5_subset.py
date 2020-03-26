#!/usr/bin/env python3

'''
take all barcode folders from provided directory (non-recursively)
then input each to "fast5_subset" command
'''

import glob
import os
import sys


fast5 = sys.argv[1] # path to raw fast5 files
path = sys.argv[2] # directory containing barcode folders


summary = glob.glob(os.path.join(path, "*/sequencing_summary.txt")) # get full paths

for file in summary:
    barcode = os.path.basename(os.path.dirname(file))
    save_path = os.path.join(path, barcode, "fast5")
    os.makedirs(save_path, exist_ok=True)
    id_list = file
    fast5_subset_cmd = "fast5_subset --input {} --save_path {} --read_id_list {} --filename_base \"{}_\"".format(fast5, save_path, id_list, barcode)
    exit_code = os.system(fast5_subset_cmd)
    if exit_code == 0:
        print("multi_reads_fast5 files created and stored in /fast5 folder for {}.".format(barcode))
    else:
        sys.exit("fast5_subset error at {}".format(barcode))

print(len(summary), "/fast5 folders created for corresponding barcodes.")
