# BASEcalling and DeMUltipleXing
## Snakemake workflow for ONT sequencing data

The workflow will be (not now) available in local computer as well as cluster environment.

### Full Workflow
![Full workflow: BASEcalling by GUPPY + DeMUltipleXing by both GUPPY and Deepbinner.](./dag/full_dag.svg)


### Requirements
* snakemake 5.x
* singularity >= 2.5
* conda 4.x
* [singularity images](https://github.com/vibaotram/singularity-container.git)
* conda environment (already provided by the workflow)


### Installation

```
git clone https://github.com/vibaotram/baseDmux.git
```
or
```
git clone git@github.com:vibaotram/baseDmux.git
```


### Usage

#### 1. Edit [config.yaml](.config.yaml) file


#### 2. Run the workflow

**Locally:** (local computer, local node on cluster)

```
snakemake --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv "
```

**On cluster:** (slurm)

```
snakemake --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " \
--cluster-config cluster.json \
--cluster "sbatch --job-name {cluster.jobname} \
-p {cluster.partition} -A {cluster.account}\
--output {cluster.output} \
--error {cluster.error}"
```


#### 3. Create reports

**Snakemake report including basecall results**

```
snakemake --use-singularity --use-conda  --report path/to/report_basecall.html
```

**Demultiplexing report**
```
snakemake --use-singularity --use-conda  report_ demultiplex
```
