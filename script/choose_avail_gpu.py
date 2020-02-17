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

try:
    gpu_info = subprocess.check_output(["nvidia-smi", "--format=csv", "--query-gpu=utilization.memory,utilization.gpu,temperature.gpu"])
    gpu_df = pd.read_csv(StringIO(gpu_info.decode('UTF-8')),names=['utilization.memory', 'utilization.gpu', 'temperature.gpu'],skiprows=1)
    gpu_df.sort_values(by=['utilization.memory', 'utilization.gpu', 'temperature.gpu'], inplace=True)
    cuda = 'CUDA:' + str(gpu_df.index[0]) # take the one that has lowest values
    print(cuda)
except (PermissionError, FileNotFoundError): # in case of no GPU, "nvidia-smi" is not available
	pass
