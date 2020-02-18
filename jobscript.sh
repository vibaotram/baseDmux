#!/bin/bash
# properties = {properties}
# this is identical to the default jobscript with the exception of the exit code
mkdir -p /scratch/baotram

module load bioinfo/snakemake/5.9.1-conda
module load system/singularity/3.3.0

cd /scratch/baotram
rsync -vaur --progress nas:/home/baotram/test .

{exec_job}

rsync -vaur --progress * nas:/home/baotram/test

rm -rf /scratch/baotram
# if the job succeeds, snakemake
# touches jobfinished, thus if it exists cat succeeds. if cat fails, the error code indicates job failure
# see https://groups.google.com/forum/#!searchin/snakemake/immediate$20submit%7Csort:relevance/snakemake/1QelazgzilY/mz0KfAzJAgAJ
#cat $1
