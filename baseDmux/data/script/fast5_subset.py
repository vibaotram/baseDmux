#!/usr/bin/env python3

'''
run "fast5_subset" command
in parallel for each "fast5/{run}" as input folder
'''

import glob
import os
import sys
from multiprocessing import Pool
import itertools

def fast5_subset(input, save_path, read_id_list):
    run_id = os.path.basename(os.path.dirname(input))
    barcode_id = os.path.basename(save_path)
    filename_base = "{barcode_id}_{run_id}_".format(barcode_id = barcode_id, run_id = run_id)
    os.makedirs(save_path, exist_ok = True)
    fast5_subset_cmd = "fast5_subset --input {} --save_path {} --read_id_list {} --filename_base {}".format(input, save_path, read_id_list, filename_base)
    print(fast5_subset_cmd, '\n')
    try:
        os.system(fast5_subset_cmd)
        genome = os.path.basename(save_path)
        return("{}: done".format(fast5_subset_cmd), '\n')
    except ValueError:
        return("{}: failed".format(fast5_subset_cmd), '\n')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input_fast5', nargs = '+', dest = 'inputs')
    parser.add_argument('-s', '--save_path', nargs = '1', dest = 'save_path')
    parser.add_argument('-l', '--read_id_list', nargs = '1', dest = 'read_id_list')
    parser.add_argument('-t', '--threads', nargs = '1', dest = 'threads')

    args = parser.parse_args()

    with Pool(args.threads) as p:
        save_paths = itertools.repeat(args.save_path, len(args.inputs))
        read_id_lists = itertools.repeat(args.read_id_list, len(args.inputs))
        out = p.map(fast5_subset, zip(args.inputs, save_paths, read_id_lists))
    print(out)

if __name__ == '__main__':
    main()
