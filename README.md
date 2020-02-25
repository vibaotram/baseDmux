# BASEcalling and DeMUltipleXing
## workflow for ONT sequencing data

The workflow will be (not now) available in local computer as well as cluster environment.


### Install

```
git clone https://github.com/vibaotram/baseDmux.git
```
or
```
git clone git@github.com:vibaotram/baseDmux.git
```


### Usage

**On a laptop:**

```
snakemake --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " --report path/to/report.html
```

**On a HP-Cluster:**

```
snakemake --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " \
--cluster-config cluster.json \
--cluster "sbatch --job-name {cluster.jobname} \
-n {cluster.cores} \
-p {cluster.partition} \
--output {cluster.output} \
--error {cluster.error}"
```



### Requirements
* snakemake 5.x
* singularity >= 2.5
* conda 4.x


