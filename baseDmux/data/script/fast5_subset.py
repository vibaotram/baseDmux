#!/usr/bin/env python3

'''
take all barcode folders from provided directory (non-recursively)
then input each to "fast5_subset" command
'''

import glob
import os
import sys
from multiprocessing import Pool


def fast5_subset(summary_file):
    barcode = os.path.basename(os.path.dirname(summary_file))
    save_path = os.path.join(path, barcode, "fast5")
    os.makedirs(save_path, exist_ok=True)
    id_list = summary_file
    fast5_subset_cmd = "fast5_subset --input {} --save_path {} --read_id_list {} --filename_base \"{}_\"".format(fast5, save_path, id_list, barcode)
    try:
        os.system(fast5_subset_cmd)
        print("multi_reads_fast5 files created and stored in /fast5 folder for {}.".format(barcode))
        return 1
    except ValueError:
        sys.exit("fast5_subset error at {}".format(barcode))
        return 0


if __name__ == '__main__':
    fast5 = sys.argv[1] # path to raw fast5 files
    path = sys.argv[2] # directory containing barcode folders
    threads = sys.arg[3] # number of threads

    summary = glob.glob(os.path.join(path, "*/sequencing_summary.txt")) # get full paths

    with Pool(threads) as p:
        times = p.starmap(fast5_subset, summary)
    print("{} /fast5 folders created for corresponding barcodes.". format(times))print("{} /fast5 folders created for corresponding barcodes.". format(times))
