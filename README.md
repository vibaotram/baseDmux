# BASEcalling and DeMUltipleXing
## Snakemake workflow for ONT sequencing data

The workflow will be (not now) available in local computer as well as cluster environment.


### Requirements
* snakemake 5.x
* singularity >= 2.5
* conda 4.x
* [singularity images](https://github.com/vibaotram/singularity-container.git)
* conda environment (already provided by the workflow)


### Install

```
git clone https://github.com/vibaotram/baseDmux.git
```
or
```
git clone git@github.com:vibaotram/baseDmux.git
```


### Usage

***Edit config.yaml file before running snakemake***

**Locally:**

```
snakemake --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " --report path/to/report.html
```

**On cluster:**

```
snakemake --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " \
--cluster-config cluster.json \
--cluster "sbatch --job-name {cluster.jobname} \
-p {cluster.partition} -A {cluster.account}\
--output {cluster.output} \
--error {cluster.error}"
```
