#!/bin/bash
# properties = {properties}
# this is identical to the default jobscript with the exception of the exit code

{exec_job}

# if the job succeeds, snakemake
# touches jobfinished, thus if it exists cat succeeds. if cat fails, the error code indicates job failure
# see https://groups.google.com/forum/#!searchin/snakemake/immediate$20submit%7Csort:relevance/snakemake/1QelazgzilY/mz0KfAzJAgAJ
#cat $1

# properties = {"type": "single", "rule": "multi_to_single_fast5", "local": false, "input": ["/scratch/baotram/test/reads/20190411_1245_MN25256_FAH93041_8a9c834e/fast5"], "output": ["/scratch/baotram-snakemake/test/results/demultiplex/deepbinner/20190411_1245_MN25256_FAH93041_8a9c834e/singlefast5"], "wildcards": {"run": "20190411_1245_MN25256_FAH93041_8a9c834e"}, "params": {}, "log": [], "threads": 12, "resources": {}, "jobid": 29, "cluster": {"account": "bioinfo", "cores": 12, "partition": "short", "jobname": "multi_to_single_fast5_run=20190411_1245_MN25256_FAH93041_8a9c834e", "output": "/scratch/baotram/log/multi_to_single_fast5_run=20190411_1245_MN25256_FAH93041_8a9c834e.out", "error": "/scratch/baotram/log/multi_to_single_fast5_run=20190411_1245_MN25256_FAH93041_8a9c834e.err", "mail-user": "", "mail-type": "ALL"}}
