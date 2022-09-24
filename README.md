# BASEcalling and DeMUltipleXing for ONT sequencing data
## A Snakemake workflow for basecalling and gathering ONT reads originating from disparate runs and barcodes

Basecalling by GUPPY + Demultiplexing by GUPPY and/or DEEPBINNER + MinIONQC/Multiqc + QC reports + reads aggregation into bins + fastq reads trimming + filtering

<p align="center">
  <img src="./dag/full_dag.svg" width="500" height="500">
</p>


### Requirements
- singularity >= 2.5
- conda >=4.3 + Mamba

### Implemented tools
- Snakemake
- Guppy
- Deepbinner
- MinIONQC
- Multiqc
- Porechop
- Filtlong  

We try to update the tools regularly. See versions in the [folder](`baseDmux/data/containers`) containning conda
 environment and singularity container recipie files.



### More details about individual snakemake Rules
- **Guppy basecalling**\
Run `guppy_basecaller` with filtering reads, then subset fast5 reads from passed reads list (`passed_sequencing_summary.txt`).

- **Guppy demultiplexing**\
Run `guppy_barcoder` with passed fastq, then subset fastq to classified barcode folders based on `barcoding_summary.txt`.

- **Multi to single fast5**\
Convert passed multi-read fast5 files to single-read fast5 file, preparing for deepbinner.

- **Deepbinner classification**\
Run `deepbinner classify` with pass single-read fast5, output classification file.

- **Deepbinner bin**\
Classify passed fastq based on classification file, then subset fastq to barcode folders.

- **Get sequencing summary per barcode**\
Subset `passed_sequencing_summary.txt` according to barcode ids, preparing for minionqc/multiqc of each barcode and subseting fast5 reads per barcode (get multi fast5 per barcode).

- **MinIONQC and Multiqc**\
After basecalling, MinIONQC is performed for each run, and Multiqc reports all run collectively.
On the other hand, after demultiplexing, MinIONQC runs for each barcode separately then Multiqc aggregates MinIONQC results of all barcodes.

- **Demultiplex report (optional)**\
Compare demultiplexing results from different runs, and from different demultiplexers (guppy and/or deepbinner) by analyzing information of `multiqc_minionqc.txt`. It is only available when demultiplexing rules are executed.

- **Get reads per genome (optional)**\
Combine and concatenate fast5 and fastq barcodes for genomes individually based on the demultiplexer program, preparing
 for
 further genome assembly
, following the information in the `barcodeByGenome_sample.tsv` tabulated file (column names of this table should not be
 modified).  
 **Caution**: if guppy or deepbinner is on Demultiplexer of the barcodeByGenome table, it will be
  executed even it is not specified in config['DEMULTIPLEXER'].

- **Porechop (optional)**\
Find and remove adapters from reads. See [here](https://github.com/rrwick/Porechop) for more information.

- **Filtlong (optional)**\
Filter reads by length and by quality. More details is [here](https://github.com/rrwick/Filtlong). Several filtlong runs at the same time are enabled.


### Singularity containers

The whole workflow runs inside Singularity images (see [our Singularity Recipe files](`baseDmux/data/containers`). Depending on type of 'RESOURCE' (CPU/GPU), corresponding containers will be selected and pulled.

The latest containers will be automatically downloaded and intalled in the baseDmux environement installation
 directory. They can anyhow be manually downloaded from [IRD Drive](https://drive.ird.fr/s/nTsw45jnW67tCw7).

Custom Singularity images can be specified by editing the [`./baseDmux/data/singularity.yaml`](baseDmux/data/singularity.yaml) file right after clonning the github repository or directly in your baseDmux installation (see below) location.


### Conda environments

Inside of the Singularity images, individual Snakemake rules use dedicated conda
environments yaml files that are located in `./baseDmux/data/conda`

- minionqc
- multiqc
- rmarkdown
- porechop
- filtlong

### Installation
Download the package:
```
git clone https://github.com/vibaotram/baseDmux.git
cd ./baseDmux
```

And then, install in a virtualenv...
```
make install
source venv/bin/activate
```

... or install in a conda environment
```
conda env create -n baseDmux -f environment.yaml
conda activate baseDmux
pip install .
``` 

It is recommended to first run the local test below with the toy dataset to make sure everything works well. On the
 first invokation, this will download and install the Singularity images and setup the Conda environment. This
  process takes time, so be patient. Note also that in the end, this setup amounts to a total of about 12GB of files
  , so you need some room on the installation disk.
  



### Usage
```
Run baseDmux version 1.1.0 ... See https://github.com/vibaotram/baseDmux/blob/master/README.md for more
details

positional arguments:
  {configure,run,dryrun,version_tools}
    configure           edit config file and profile
    run                 run baseDmux
    dryrun              dryrun baseDmux
    version_tools       check version for the tools of baseDmux

options:
  -h, --help            show this help message and exit
  -v, --version         show program's version number and exit
```

### baseDmux configuration

Because configuring snakemake workflows can be a bit intimidating, we try to clarify below the main principles of baseDmux configuration:

- **Configuring a specific 'flavor' of the workflow**

This is done primarilly by adjusting the parameters listed in the workflow config file `profile/workflow_parameters.yaml` or the [config.yaml](baseDmux/data/config.yaml) which corresponds to the typical Snakemake 'config.yaml' file. It enables to setup input reads, output folder, parameters for the tools, reports generation, etc... It is suggested to refer to the comments in this file for further details on individual parameters.

Note however, that Deepbinner is not longer maintained and that [Deepbinner models](https://github.com/rrwick
/Deepbinner/tree/master/models) are limited to specific 'earlier' flow cells and barcoding kits. One should therefore
 ensure that that Deepbinner is a adequate for the data at hand.  

baseDmux takes as input a folder with internal ONT 'run' folders that each contain a 'fast5' folder. This is the typical file hierarchy when sequencing with a MinION. baseDmux can therefore process a virtually unlimited number of (multiplexed) sequencing runs.

You can decide whether guppy and deepbinner should run on GPU or CPU by specifying 'RESOURCE' in the [config.yaml](baseDmux/data/config.yaml) file depending on the available computing hardware.


A typical usage case for baseDmux is to prepare filtered sequencing reads in individual fastq files for genome assembly (or transcripts analysis) when users have a number of genomic DNA (or RNA) preparations sequenced with the same library preparation protocol and flowcell typoe but over several runs with various sets of multiplex barcodes. For this, it is necessary to run the complete workflow.

To this end, users need to prepare a [`Barcode by genome`](/baseDmux/data/barcodeByGenome_sample.tsv) file. This is a roadmap table for subseting fastq and fast5 reads, demultiplexed with guppy and/or deepbinner, and coming from disparate runs and barcodes, in bins corresponding to individual 'genomes' (or samples).
It must contain at least the follwing columns: Demultiplexer, Run_ID, ONT_Barcode, Genome_ID. Values in the
 `Genome_ID` correspond to the labels of the bin into which reads will eventually be grouped. **Make sure** that this
  labels do NOT contain spaces " " or other special characters like '|' '$' ':'. As separators, the safest options
   are to use "_" or "-".  
Likewise, `Run_ID` values should not contain special characters. In addition, these values must match the names of the
 top
 folders in the input fast5 directory.
  
Importantly, the `Barcode by genome` file does not only enable to group reads, it is necessary to provide such a file for the porechop and filtlong rules to be executed.



- **Configuring for a specific computing infrastructure (single machine *vs* HPC)**

to set parameters for Snakemake command-line arguments: `profile/config.yaml`.  

to set specific HPC job scheduler parameters for jobs derived from individual rules.







#### 1. Generating template configuration files

To simplify configuration, the `baseDmux configure` command generates 'template' configuration profiles for general use cases. These files can subsequently be modified to fit specific situations.

```
usage: baseDmux configure [-h] --mode {local,slurm,cluster,iTrop} [--barcodes_by_genome]
                          [--edit [EDITOR]]
                          dir

positional arguments:
  dir                   path to the folder to contain config file and profile you want to create

options:
  -h, --help            show this help message and exit
  --mode {local,slurm,cluster,iTrop}
                        choose the mode of running Snakemake, local mode or cluster mode
  --barcodes_by_genome  optional, create a tabular file containing information of barcodes for each
                        genome)
  --edit [EDITOR]       optional, open files with editor (nano, vim, gedit, etc.)
```




These files will be created:
```
  | dir
          -| profile  
                  -| config.yaml  
                  -| workflow_parameter.yaml  
                  -| barcodesByGenome.tsv (if --barcodes_by_genome)
                  -| ... (if mode slurm)
```
*Note*: the 'iTRop' and 'cluster' modes are obsolete and will be eventually removed.


##### **an exemple to prepare to run Snakemake locally** (local computer, local node on cluster)

Use this command:  

```
baseDmux configure ./test_baseDmux --mode local --barcodes_by_genome
```

Then `workflow_parameter.yaml` and `config.yaml` will be created inside a profile to the folder `./test_baseDmux`.


The `--barcodes_by_genome` option, a formatted file `barcodesByGenome.tsv` will be created (and its path appropriately specified in `workflow_parameter.yaml`). One can then modify the information on the table accordingly. It is important that this table contains at least the same columns as those in the provided example `barcodeByGenome_sample.tsv` file and that each value in the `Genome_ID` column is unique.  

`profile/config.yaml` will be created lastly and it will contain `./test_baseDmux/profile/config.yaml` as a set of parameters for Snakemake command-line.

##### **an exemple to prepare to run Snakemake on a HPC** with slurm.

Similarly, run the command below:
```
baseDmux configure ./test_baseDmux --edit nano --mode slurm --barcodes_by_genome
```
On cluster mode, a cluster configuration file will be created, `./test_baseDmux/profile/cluster.json`. baseDmux wraps
 all the parameters provided in this file to submit Snakemake jobs to cluster with slurm.

For other HPC job managment system (sge, ...), and more information of Snakemake profile and other utilities --> https://snakemake.readthedocs.io

Ultimately, the required files for passing HPC scheduler parameters throught the dedicated Snakemake mecanism of
 'profiles' need to be stored in the folder whose path is passed to the baseDmux `profile_dir` parameter.




#### 2. Run the workflow with the created profile:

```
usage: baseDmux run [-h] [--snakemake_report] profile_dir

positional arguments:
  profile_dir         profile folder to run baseDmux

options:
  -h, --help          show this help message and exit
  --snakemake_report  optionally, create snakemake report
```

Example:  
You can run `baseDmux dryrun ./test_baseDmux/profile` for dry-run to check if everything is right, before really execute the workflow.
```
baseDmux run ./test_baseDmux/profile
```

With the option `--snakemake_report`, a report file `snakemake_report.html` will be created in the report folder of pipeline output directory, when snakemake has successfully finished the workflow.



****

### Run a local test

Assuming the environement for baseDmux has been created as specified in the dedicated section on Installation. First
 activate either the conda or venv environement.

You can use the reads fast5 files in `sample/reads` folder for testing
```
## copy sample reads to a test folder
mkdir ./test_baseDmux
cp -r ./baseDmux/sample/reads_intermediate/ ./test_baseDmux

## create configuration file for Snakemake and Snakemake profile,
## and (optional) a tsv file containing information about genomes corresponding to barcode IDs
baseDmux configure ./test_baseDmux --mode local --barcodes_by_genome

## check the workflow by dryrun, then run
baseDmux dryrun ./test_baseDmux/profile
baseDmux run ./test_baseDmux/profile
```

The output will be written in `./test_baseDmux/results` by default
The first run may take a long time for the conda environments to be installed even if using Mamba.  
On a personnal computer with only a few CPU, even with this very minimal dataset,
guppy basecalling may also take several minutes...


### Input and Output
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
├── reads_per_genome
│   ├── fast5
│   ├── fastq
│   └── reads_per_genome.csv
├── log
│   ├── slurm
│   └── snakemake
└── report
   ├── demultiplex_report.html
   ├── demultiplex_report.RData
   └── demultiplex_report.tsv

```
