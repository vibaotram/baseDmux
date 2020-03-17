import os
import glob
import getpass

report: "report/workflow.rst"

configfile: "config.yaml"


indir = config['INDIR']

outdir = config['0UTDIR']

run, = glob_wildcards(os.path.join(indir, "{run}/fast5/"))

demultiplexer = config['DEMULTIPLEXER']

# THREADS = config['THREADS']



##############################
## guppy_basecaller parameters

RESOURCE = config['RESOURCE']

KIT = config['KIT']

FLOWCELL = config['FLOWCELL']

# QSCORE_FILTERING = config['BASECALLER']['QSCORE_FILTERING']
MIN_QSCORE = config['GUPPY_BASECALLER']['MIN_QSCORE']

CPU_THREADS_PER_CALLER = config['GUPPY_BASECALLER']['CPU_PER_CALLER']
NUM_CALLERS = config['GUPPY_BASECALLER']['NUM_CALLERS']

BASECALLER_ADDITION = config['GUPPY_BASECALLER']['ADDITION']

# CUDA = config['BASECALLER']['CUDA']

GPU_RUNNERS_PER_DEVICE = config['GUPPY_BASECALLER']['GPU_PER_DEVICE']
NUM_GPUS = config['NUM_GPUS']

# adjust parameters and variales based on guppy_basecaller option 'qscore_filtering'
# if QSCORE_FILTERING == 'true':
# 	FILTERING_OPT = '--qscore_filtering --fast5_out'
# 	FASTQ = 'pass/fastq_runid_*.fastq'
# 	FAST5 = os.path.join(outdir, "basecall/{run}/workspace"),
# 	FAST5_OUTPUT = directory(FAST5)
# if QSCORE_FILTERING == 'false':
# 	FILTERING_OPT = ''
# 	FASTQ = 'fastq_runid_*.fastq'
# 	FAST5 = os.path.join(indir, "{run}/fast5"),
# 	FAST5_OUTPUT = []


# adjust guppy_basecaller parameters based on RESOURCE
if RESOURCE == 'CPU':
	BASECALLER_OPT = f"--flowcell {FLOWCELL} --kit {KIT} --num_callers {NUM_CALLERS} --cpu_threads_per_caller {CPU_THREADS_PER_CALLER} --min_qscore {MIN_QSCORE} --qscore_filtering {BASECALLER_ADDITION}"
	BASECALLER_THREADS = NUM_CALLERS*CPU_THREADS_PER_CALLER
if RESOURCE == 'GPU':
	BASECALLER_OPT = f"--flowcell {FLOWCELL} --kit {KIT} --num_callers {NUM_CALLERS} --min_qscore {MIN_QSCORE} --qscore_filtering --gpu_runners_per_device {GPU_RUNNERS_PER_DEVICE} --device $CUDA {BASECALLER_ADDITION}"
	BASECALLER_THREADS = NUM_CALLERS

##############################
## guppy_barcoder parameters

BARCODER_CONFIG = config['GUPPY_BARCODER']['CONFIG']
WORKER_THREADS = config['GUPPY_BARCODER']['WORKER_THREADS']
ADDITION = config['GUPPY_BARCODER']['ADDITION']

if RESOURCE == 'CPU':
	DEVICE = ''
if RESOURCE == 'GPU':
	DEVICE = "--device $CUDA"
##############################
## MinIONQC parameters

QSCORE_CUTOFF = config['MINIONQC']['QSCORE_CUTOFF']
SMALLFIGURES = config['MINIONQC']['SMALLFIGURES']
PROCESSORS = config['MINIONQC']['PROCESSORS']
fig = ["channel_summary", "flowcell_overview", "gb_per_channel_overview", "length_by_hour", "length_histogram", "length_vs_q", "q_by_hour", "q_histogram", "reads_per_hour", "yield_by_length", "yield_over_time"]

##############################
## deepbinner classify parameters

PRESET = config['DEEPBINNER_CLASSIFY']['PRESET']
OMP_NUM_THREADS = config['DEEPBINNER_CLASSIFY']['OMP_NUM_THREADS']
DEEPBINNER_ADDITION = config['DEEPBINNER_CLASSIFY']['ADDITION']

API_THREADS = config['ONT_FAST5_API']['THREADS']


##############################
## use different containers for guppy and deepbinner if no single container for all pakages is specified


if RESOURCE == 'CPU':
	guppy_container = 'shub://vibaotram/singularity-container:cpu-guppy3.4-conda-api'
elif RESOURCE == 'GPU':
	guppy_container = 'shub://vibaotram/singularity-container:guppy3.4gpu-conda-api'

deepbinner_container = 'shub://vibaotram/singularity-container:deepbinner-api'


##############################
## path to scripts

CHOOSE_AVAIL_GPU = 'script/choose_avail_gpu.py'
FAST5_SUBSET = 'script/fast5_subset.py'
GET_FASTQ_PER_BARCODE = 'script/get_fastq_per_barcode.py'
GET_SUMMARY_PER_BARCODE = 'script/get_summary_per_barcode.R'
RENAME_FASTQ_GUPPY_BARCODER = 'script/rename_fastq_guppy_barcoder.R'



##############################
## cluster variables

# snakemake_dir = os.getcwd()

# user = subprocess.check_output("whoami")
# user = user.decode('UTF-8').strip('\n')

user = getpass.getuser()

nasID = config['NASID']
if nasID:
	HOST_PREFIX = user + '@' + nasID + ':'
	# TEMPDIR = '`mktemp -d`'
	# TEMP_INDIR = '$tempdir/indir'
	# TEMP_OUTDIR = '$tempdir/outdir'
else:
	HOST_PREFIX = ''
	# TEMPDIR = '\'\''
	# TEMP_INDIR = indir
	# TEMP_OUTDIR = outdir

##############################
## make slurm logs directory
SLURM_LOG = os.path.join(outdir, "log/slurm")
# os.system(f"mkdir -p {SLURM_LOG}")
os.makedirs(SLURM_LOG, exist_ok=True)

SNAKEMAKE_LOG = os.path.join(outdir, "log/snakemake")
os.makedirs(SNAKEMAKE_LOG, exist_ok=True)

##############################
## slurm ssh
ssh_dir = os.path.join(os.getcwd(), ".ssh")
if nasID and not os.path.isdir(ssh_dir):
	user_ssh = os.path.join('/home', user, '.ssh')
	cp_ssh = ' '.join(('rsync -avrP', user_ssh, os.getcwd()))
	os.system(cp_ssh)



# shell.prefix("exec > >(tee "{log}") 2>&1; ")

##############################
##############################



rule finish:
	input:
		os.path.join(outdir, "basecall/multiqc/multiqc_report.html"), # BASECALLING QC
		expand(os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/multiqc/multiqc_report.html"), demultiplexer=demultiplexer, run=run), # DEMULTIPLEXING QC
		expand(os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/fast5_per_barcode.done"), demultiplexer=demultiplexer, run=run),
		# expand(os.path.join(outdir, "basecall/{run}/{fig}.png"), run=run, fig=fig),
		# os.path.join(outdir, "report/demultiplex_report.html")
		#expand(os.path.join(DIR, "demultiplex/{demultiplexer}/{run}/report.done"), demultiplexer=demultiplexer, run=run),


##############################
################## BASECALLING
##################### BY GUPPY


rule guppy_basecalling:
	message: "GUPPY basecalling running on {RESOURCE}"
	input: os.path.join(indir, "{run}/fast5")
	output:
		summary = os.path.join(outdir, "basecall/{run}/sequencing_summary.txt"),
		passed_summary = os.path.join(outdir, "basecall/{run}/passed_sequencing_summary.txt"),
		# fastq = os.path.join(outdir, "basecall/{run}/{run}.fastq"),
		fastq = directory(os.path.join(outdir, "basecall/{run}/pass")),
		fast5 = directory(os.path.join(outdir, "basecall/{run}/passed_fast5"))
	params:
		outpath = os.path.join(outdir, "basecall/{run}"),
		fast5_name = "{run}_",
		log = "guppy_basecalling_{run}.log"
	threads: BASECALLER_THREADS
	singularity: guppy_container
	conda: 'conda/conda_python_package.yaml'
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		host_prefix='{HOST_PREFIX}'
		if [ $host_prefix == '' ]; then
			temp_indir={input}
			temp_outdir={params.outpath}
		else
			temp_indir=$(mktemp -d); echo -e "##$(date)    Creating temporary input directory on local drive: $temp_indir \n"
			temp_outdir=$(mktemp -d); echo -e "##$(date)    Creating temporary output directory on local drive: $temp_outdir \n"
			rsync -arvP $host_prefix{input}/ $temp_indir
		fi
		CUDA=$(python3 {CHOOSE_AVAIL_GPU} {NUM_GPUS})
		guppy_basecaller -i $temp_indir -s $temp_outdir {BASECALLER_OPT}
		# cat {params.outpath}/pass/fastq_runid_*.fastq > {output.fastq}
		# rm -rf {params.outpath}/pass/fastq_runid_*.fastq
		grep 'read_id' $temp_outdir/sequencing_summary.txt > $temp_outdir/passed_sequencing_summary.txt
		grep 'TRUE' $temp_outdir/sequencing_summary.txt >> $temp_outdir/passed_sequencing_summary.txt
		echo "Filtering passed reads in fast5 files \n"; fast5_subset --input $temp_indir --save_path $temp_outdir/passed_fast5 --read_id_list $temp_outdir/passed_sequencing_summary.txt --filename_base {params.fast5_name}
		if [ $host_prefix != '' ]; then
			echo -e "##$(date)    Transfering temporary output directory $temp_outdir to host directory {params.outpath}\n"; rsync -arvP $temp_outdir/ {HOST_PREFIX}{params.outpath}
			rm -rf $temp_indir; echo -e "##$(date)    Removing temporary input directory on local drive: $temp_indir \n"
			rm -rf $temp_outdir; echo -e "##$(date)    Removing temporary input directory on local drive: $temp_outdir \n"
		fi
		"""


##############################
############### DEMULTIPLEXING
##################### BY GUPPY


rule guppy_demultiplexing:
	message: "GUPPY demultiplexing running on {RESOURCE}"
	input: rules.guppy_basecalling.output.fastq
	output:
		demux = os.path.join(outdir, "demultiplex/guppy/{run}/barcoding_summary.txt")
	params:
		# inpath = rules.guppy_basecalling.params.outpath,
		outpath = os.path.join(outdir, "demultiplex/guppy/{run}"),
		# config = config['DEMULTIPLEXING_CONFIG'],
		log = "guppy_demultiplexing_{run}.log"
	singularity: guppy_container
	conda: 'conda/conda_minionqc.yaml'
	threads: WORKER_THREADS
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		CUDA=$(python3 {CHOOSE_AVAIL_GPU} {NUM_GPUS})
		guppy_barcoder -i {input} -s {params.outpath} --config {BARCODER_CONFIG} --barcode_kits {KIT} --worker_threads {threads} {DEVICE} --trim_barcodes --compress_fastq {ADDITION}
		Rscript {RENAME_FASTQ_GUPPY_BARCODER} {params.outpath}
		"""



##############################
############### DEMULTIPLEXING
################ BY DEEPBINNER


rule multi_to_single_fast5:
	input: rules.guppy_basecalling.output.fast5
	output: temp(directory(os.path.join(outdir, "demultiplex/deepbinner/{run}/singlefast5")))
	threads: API_THREADS
	singularity: deepbinner_container
	params:
		log = "multi_to_single_fast5_{run}.log"
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		host_prefix='{HOST_PREFIX}'
		if [ $host_prefix == '' ]; then
			temp_indir={input}
			temp_outdir={output}
		else
			temp_indir=$(mktemp -d); echo -e "##$(date)    Creating temporary input directory on local drive: $temp_indir \n"
			temp_outdir=$(mktemp -d); echo -e "##$(date)    Creating temporary output directory on local drive: $temp_outdir \n"
			rsync -arvP $host_prefix{input}/ $temp_indir
		fi
		multi_to_single_fast5 -i $temp_indir -s $temp_outdir -t {threads}
		if [ $host_prefix != '' ]; then
			echo -e "##$(date)    Transfering temporary output directory $temp_outdir to host directory {output}\n"; rsync -arvP $temp_outdir/ {HOST_PREFIX}{output}
			rm -rf $temp_indir; echo -e "##$(date)    Removing temporary input directory on local drive: $temp_indir \n"
			rm -rf $temp_outdir; echo -e "##$(date)    Removing temporary input directory on local drive: $temp_outdir \n"
		fi
		"""

if RESOURCE == 'CPU':
	OMP_NUM_THREADS_OPT = ''
if RESOURCE == 'GPU':
	OMP_NUM_THREADS_OPT = '--omp_num_threads %s' % OMP_NUM_THREADS

rule deepbinner_classification:
	message: "DEEPBINNER classify running on {RESOURCE}"
	input: rules.multi_to_single_fast5.output
	output:
		classification = os.path.join(outdir, "demultiplex/deepbinner/{run}/classification")
	singularity: deepbinner_container
	threads: OMP_NUM_THREADS
	params:
		log = "deepbinner_classification_{run}.log"
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		deepbinner classify --{PRESET} {OMP_NUM_THREADS_OPT} {DEEPBINNER_ADDITION} {input} > {output.classification}
		"""


rule deepbinner_bin:
	input:
		classes = rules.deepbinner_classification.output.classification,
		fastq = rules.guppy_basecalling.output.fastq
	output: os.path.join(outdir, "demultiplex/deepbinner/{run}/fastq_per_barcode.done")
	params:
		out_dir = os.path.join(outdir, "demultiplex/deepbinner/{run}"),
		fastq = temp(os.path.join(outdir, "demultiplex/deepbinner/{run}/{run}.fastq")),
		log = "deepbinner_bin_{run}.log"
	singularity: deepbinner_container
	threads: 1
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		cat {input.fastq}/fastq_runid_*.fastq > {params.fastq}
		deepbinner bin --classes {input.classes} --reads {params.fastq} --out_dir {params.out_dir}
		python3 {GET_FASTQ_PER_BARCODE} {params.out_dir}
		touch {output}
		"""

##############################
## determine which demultiplexer to be executed

def deepbinner_bin_output():
	if "deepbinner" in demultiplexer:
		return(rules.deepbinner_bin.output)
	else:
		return()

def deepbinner_classification_output():
	if "deepbinner" in demultiplexer:
		return(rules.deepbinner_classification.output)
	else:
		return()

def guppy_demultiplexing_output():
	if "guppy" in demultiplexer:
		return(rules.guppy_demultiplexing.output)
	else:
		return()

##############################
############# MINIONQC/MULTIQC
############## FOR BASECALLING



rule minionqc_basecall:
	input: rules.guppy_basecalling.output.summary
	output:
		summary = os.path.join(outdir, "basecall/{run}/summary.yaml"),
		fig = report([os.path.join(outdir, "basecall/{run}") + "/{fig}.png".format(fig=fig) for fig in fig], caption = "report/basecall_minionqc.rst", category = "minionqc_basecall")
		# fig = report(os.path.join(outdir, "basecall/{run}", "{fig}.png".format(fig=fig)), caption = "report/basecall_minionqc.rst", category = "minionqc_basecall")
	conda: 'conda/conda_minionqc.yaml'
	singularity: guppy_container
	params:
	# 	inpath = os.path.join(outdir, "basecall/{run}"),
		log = "minionqc_basecall_{run}.log"
	threads: 1
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		MinIONQC.R -i {input} -q {QSCORE_CUTOFF} -s {SMALLFIGURES}
		"""

rule multiqc_basecall:
	input:
		expand(rules.minionqc_basecall.output.summary, run=run),
		# inpath = os.path.join(outdir, "basecall")
	output: os.path.join(outdir, "basecall/multiqc/multiqc_report.html")
	singularity: guppy_container
	conda: 'conda/conda_multiqc.yaml'
	params:
		inpath = os.path.join(outdir, "basecall"),
		outpath = os.path.join(outdir, "basecall/multiqc"),
		log = "multiqc_basecall.log"
	threads: 1
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		multiqc -f -v -d -dd 2 -o {params.outpath} {params.inpath}
		touch {output}
		"""

##############################
############# MINIONQC/MULTIQC
########### FOR DEMULTIPLEXING


rule get_sequencing_summary_per_barcode:
	input:
		deepbinner_bin_output(),
		deepbinner_classification_output(),
		guppy_demultiplexing_output()
	output: os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/get_summary.done")
	params:
		barcoding_path = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}"),
		sequencing_file = rules.guppy_basecalling.output.passed_summary,
		log = "get_sequencing_summary_per_barcode_{demultiplexer}_{run}.log"
	conda: 'conda/conda_minionqc.yaml'
	singularity: guppy_container
	threads: 1
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		Rscript {GET_SUMMARY_PER_BARCODE} {params.sequencing_file} {params.barcoding_path}
		touch {output}
		"""


rule minionqc_demultiplex:
	input:
		rules.get_sequencing_summary_per_barcode.output
	output: os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/minionqc.done")
	params:
		outpath = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/minionqc"),
		inpath = rules.get_sequencing_summary_per_barcode.params.barcoding_path,
		combinedQC = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/combinedQC"),
		log = "minionqc_demultiplex_{demultiplexer}_{run}.log"
	conda: 'conda/conda_minionqc.yaml'
	singularity: guppy_container
	threads: PROCESSORS
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		MinIONQC.R -i {params.inpath} -q {QSCORE_CUTOFF} -s {SMALLFIGURES} -p {threads}
		rm -rf {params.combinedQC}
		touch {output}
		"""
###

# def summary_per_barcode(wildcards):
# 	checkpoint_output = checkpoints.demultiplexing_guppy_sequencing_summary.get(**wildcards).output[0]
#     barcodes=glob_wildcards(os.path.join(os.path.dirname(checkpoint_output), '{barcode}/sequencing_summary.txt')).barcode)
# 	summaryFilesList=[os.path.dirname(checkpoint_output) + "/{bc}/sequencing_summary.txt".format(bc = barcode) for barcode in barcodes]
# 	return(summaryFilesList)

###

rule multiqc_demultiplex:
	input:
		rules.minionqc_demultiplex.output
	output:
		os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/multiqc/multiqc_report.html"),
		# report = directory(os.path.join(outdir, "report"))
	singularity: guppy_container
	conda: 'conda/conda_multiqc.yaml'
	params:
		inpath = rules.minionqc_demultiplex.params.inpath,
		outpath = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/multiqc"),
		log = "multiqc_demultiplex_{demultiplexer}_{run}.log"
	threads: 1
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		multiqc -f -v -d -dd 2 -o {params.outpath} {params.inpath}
		"""


##############################
################# FAST5_SUBSET
################ ONT_FAST5_API


rule get_multi_fast5_per_barcode:
	input:
		summary = rules.get_sequencing_summary_per_barcode.output,
		fast5 = rules.guppy_basecalling.output.fast5
	output:
		check = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/fast5_per_barcode.done")
	singularity: deepbinner_container
	params:
		path = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}"),
		log = "get_multi_fast5_per_barcode_{demultiplexer}_{run}.log"
	threads: 1
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		python3 {FAST5_SUBSET} {input.fast5} {params.path}
		touch {output.check}
		"""




# rule report_basecall:
# 	input: rules.multiqc_basecall.output
# 	output: report(os.path.join(outdir, "basecall/{run}/{fig}.png"), caption = "report/basecall_minionqc.rst", category = "minionqc_basecall")
# 	shell:
# 		"touch {output}"



rule report_demultiplex:
	# input: rules.multiqc_basecall.output
	message: " Reporting demultiplex results"
	output: os.path.join(outdir, "report/demultiplex_report.html")
	params:
		indir = os.path.join(outdir, "demultiplex")
	singularity: guppy_container
	conda: 'conda/conda_minionqc.yaml'
	script:
		"report/report_demultiplex.Rmd"




##############################
############### SOMETHING ELSE

rule clean:
	message: "Cleaning output directory {outdir}"
	shell:
		"""
		rm -rf {outdir}
		echo "#################\nremoved {outdir}\n#################"
		"""

rule clean_basecall:
	params:
		basecall = os.path.join(outdir, "basecall"),
	shell:
		"""
		rm -rf {params.basecall}
		"""

rule clean_demultiplex:
	params:
		demultiplex = os.path.join(outdir, "demultiplex")
	shell:
		"""
		rm -rf {params.demultiplex}
		"""

rule help:
	shell:
		"""
		cat README.md
		"""

# rule add_slurm_logs:
# 	shell:
# 		"""
# 		mkdir -p {outdir}/slurm_logs
# 		"""
##############################
##################### HANDLERS

#onstart:
#	print("Basecalling will be performed by Guppy on", RESOURCE)
#	print("Demultiplexing will be performed by",)
#	for d in demultiplexer: print("\t-", d)


#onsuccess:
#	print("Workflow finished, yay")
#	print("Basecalling by Guppy on", RESOURCE)
#	print("Demultiplexing by")
#	for d in demultiplexer: print("\t-", d)

#onerror:
#	print("OMG ... error ... error ... again")
