# BASEcalling and DeMUltipleXing
## Snakemake workflow for ONT sequencing data

Basecalling by GUPPY + Demultiplexing by GUPPY and/or DEEPBINNER + MinIONQC/Multiqc + external report

<p align="center">
  <img src="./dag/full_dag.svg" width="500" height="500">
</p>

### Requirements
- snakemake 5.x
- singularity >= 2.5
- conda 4.x


### Installation

```
git clone https://github.com/vibaotram/baseDmux.git
```
or
```
git clone git@github.com:vibaotram/baseDmux.git
```


### Usage

#### 1. Edit [config.yaml](./config.yaml) file


#### 2. Run the workflow

**Locally:** (local computer, local node on cluster)

```
snakemake --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv "
```

**On cluster mode:** (slurm)

Modify [cluster.json](./cluster.json) if needed (partition, log, mail, ...) before running this command:

```
snakemake --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " --latency-wait 60 \
--cluster-config cluster.json \
--cluster "sbatch {cluster.job-name} {cluster.partition} {cluster.account} \
{cluster.gpus} {cluster.ntasks} {cluster.cpus-per-task} {cluster.output} {cluster.error}"
```

**Note**:
- If you don't run the workflow on a GPU-support machine, it is not necessary to include `--singularity-args "--nv "` on the command line.
- `--cores` allows using as many cores as decided in the [config.yaml](./config.yaml) and not more than number of environment available cores.
- More information of snakemake usage --> https://snakemake.readthedocs.io

#### 3. An alternative way to run the workflow on cluster:
Use a wrapper script (`slurm_wrapper.py`) to parse job submission to cluster, instead of using cluster config.

An additional script (`slurm_status.py`) can be used to pass job status properly to snakemake (snakemake does not interpret correctly some slurm job signals).

```
snakemake --nolock --use-singularity --use-conda --cores -p --verbose --singularity-args "--nv " --latency-wait 60 \
--cluster "python3 cluster/slurm_wrapper.py" \
--cluster-status "python3 cluster/slurm_status.py"
```

**Note for future**: A snakemake profile can be added to the workflow to simplify the command-line, e.g. `snakemake --profile baseDmux`.

#### 4. Other widgets:

`snakemake help`: print README

`snakemake clean`: delete output directory

`script/snakemake_report.py`: create snakemake report

****
### Verbose (to be continued...)


#### Rules
- **Guppy basecalling**
Run `guppy_basecaller` with filtering reads, then subset fast5 reads from passed reads list (`passed_sequencing_summary.txt`).

- **Guppy demultiplexing**
Run `guppy_barcoder` with passed fastq, then subset fastq to classified barcode folders based on `barcoding_summary.txt`. **Barcode sequences are removed after demultiplexing.**

- **Multi to single fast5**
Convert passed multi-read fast5 files to single-read fast5 file, preparing for deepbinner.

- **Deepbinner classification**
Run `deepbinner classify` with pass single-read fast5, output classification file.

- **Deepbinner bin**
Classify passed fastq based on classification file, then subset fastq to barcode folders.

- **Get sequencing summary per barcode**
Subset `passed_sequencing_summary.txt` according to barcode ids, preparing for minionqc/multiqc of each barcode and subseting fast5 reads per barcode (get multi fast5 per barcode).

- **Get multi fast5 per barcode**
Filter fast5 for each corresponding barcode by the `sequencing_summary.txt` per barcode.

- **MinIONQC and Multiqc**
After basecalling, MinIONQC is performed for each run, and Multiqc reports all run collectively.
On the other hand, after demultiplexing, MinIONQC runs for each barcode separately then Multiqc aggregates MinIONQC results of all barcodes.

- **Demultiplex report (optional)**
Compare demultiplexing results from different runs, and from different demultiplexers (guppy and/or deepbinner) by analyzing information of `multiqc_minionqc.txt`.

- **Get reads per genome (optional)**
Combine and concatenate fast5 and fastq from designed barcodes for genomes individually, according to `barcodeByGenome_sample.tsv`, preparing for further genome assembly.


#### Tools

- Guppy 4.0.14 GPU and 3.6.0 CPU version
- Deepbinner 0.2.0
- MinIONQC
- Multiqc

You can decide guppy and deepbinner running on GPU or CPU by specifying 'RESOURCE' in the [config.yaml](./config.yaml) file.

#### Singularity containers

The whole workflow runs inside [singularity images](https://github.com/vibaotram/singularity-container.git) (already implemented on the workflow). Depending on type of 'RESOURCE' (CPU/GPU), corresponding containers will be automatically selected and pulled.

#### conda environment
- minionqc
- multiqc
- rmarkdown

#### Input and Output
Input directory **must** follow the structure as below. 'fast5' directory containing fast5 files in each run is a MANDATORY for baseDmux to mark 'runid'.

```
indir/
├── run_id1
│   └── fast5
│       ├── file_1.fast5
│       ├── ...
│       └── file_n.fast5
├── ...
└── run_idx

```

Output directory will be:

```
outdir/
├── basecall
│   ├── run_id1
│   │   ├── sequencing_summary.txt
│   │   └── {MinIONQC results}
│   ├── ...
│   ├── run_idx
│   └── multiqc
│       ├── multiqc_data
│       └── multiqc_report.html
├── demultiplex
│   ├── deepbinner
│   │   ├── run_id1
│   │   │   ├── barcode01
│   │   │   │   ├── barcode01.fastq.gz
│   │   │   │   ├── fast5
│   │   │   │   ├── sequencing_summary.txt
│   │   │   │   └── {MinIONQC results}
│   │   │   ├── ...
│   │   │   ├── barcodexxx
│   │   |   ├── classification
│   │   |   ├── fast5_per_barcode.done
│   │   |   ├── multiqc
│   │   |   └── unclassified
│   │   ├── ...
│   │   └── run_idx
│   └── guppy
│       ├── run_id1
│       │   ├── barcode01
│       │   │   ├── barcode01.fastq.gz
│       │   │   ├── fast5
│       │   │   ├── sequencing_summary.txt
│       │   │   └── {MinIONQC results}
│       │   ├── ...
│       │   ├── barcodexxx
│       |   ├── barcoding_summary.txt
│       |   ├── fast5_per_barcode.done
│       |   ├── multiqc
│       |   └── unclassified
│       ├── ...
│       └── run_idx
├── log
│   ├── slurm
│   └── snakemake
└── report
   ├── slurm
   └── snakemake

```
