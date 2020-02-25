#!/usr/bin/env python3

## select a GPU based on memory, utilization and temperature (in order of priority)
## if GPU is available: output 'CUDA:x', else: output nothing

import subprocess
import sys
if sys.version_info[0] < 3:
    from StringIO import StringIO
else:
    from io import StringIO

import pandas as pd

gpus_number = int(sys.argv[1])

try:
    gpu_info = subprocess.check_output(["nvidia-smi", "--format=csv", "--query-gpu=utilization.memory,utilization.gpu,temperature.gpu"])
    gpu_df = pd.read_csv(StringIO(gpu_info.decode('UTF-8')),names=['utilization.memory', 'utilization.gpu', 'temperature.gpu'],skiprows=1)
    gpu_df.sort_values(by=['utilization.memory', 'utilization.gpu', 'temperature.gpu'], inplace=True)
    cuda = []
    for i in range(0,gpus_number):
        cuda.append(str(gpu_df.index[i])) # take the one that has lowest values
    print('CUDA:' + ','.join(cuda))
except (PermissionError, FileNotFoundError): # in case of no GPU, "nvidia-smi" is not available
	pass
