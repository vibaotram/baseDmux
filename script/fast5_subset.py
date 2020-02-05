#!/usr/bin/env python3

import glob
import os
import sys


fast5 = sys.argv[1] # path to raw fast5 files
path = sys.argv[2] # path to barcode folders


summary = glob.glob(os.path.join(path, "*/sequencing_summary.txt")) # get full paths

for file in summary:
    barcode = os.path.basename(os.path.dirname(file))
    save_path = os.path.join(path, barcode, "fast5")
#    mkdir_cmd = "mkdir {}".format(save_path)
#    os.system(mkdir_cmd)
    id_list = file
    fast5_subset_cmd = "fast5_subset --input {} --save_path {} --read_id_list {} --filename_base \"{}_\"".format(fast5, save_path, id_list, barcode)
    os.system(fast5_subset_cmd)
#    cat_cmd = "cat {save_path}/{barcode}_*.fast5 > {save_path}/{barcode}.fast5".format(save_path=save_path, barcode=barcode)
#    os.system(cat_cmd)
#    rm_cmd = "rm {}/{}_*.fast5".format(save_path, barcode)
#    os.system(rm_cmd)

print(len(summary), "multi_reads_fast5 files created for each barcode")
