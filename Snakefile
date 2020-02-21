import os
import glob

report: "report/workflow.rst"

configfile:"config.yaml"


indir = config['INDIR']

outdir = config['0UTDIR']

run, = glob_wildcards(os.path.join(indir, "{run}/fast5"))

demultiplexer = config['DEMULTIPLEXER']

THREADS = config['THREADS']

##############################
## make slurm logs directory
SLURM_LOG = f'{outdir}/logs/slurm'
os.system(f"mkdir -p {SLURM_LOG}")

##############################
## guppy_basecaller parameters

RESOURCE = config['GUPPY_BASECALLER']['RESOURCE']

KIT = config['KIT']

FLOWCELL = config['FLOWCELL']

# QSCORE_FILTERING = config['BASECALLER']['QSCORE_FILTERING']
MIN_QSCORE = config['GUPPY_BASECALLER']['MIN_QSCORE']

CPU_THREADS_PER_CALLER = config['GUPPY_BASECALLER']['CPU_PER_CALLER']
NUM_CALLERS = config['GUPPY_BASECALLER']['NUM_CALLERS']

BASECALLER_ADDITION = config['GUPPY_BASECALLER']['ADDITION']

# CUDA = config['BASECALLER']['CUDA']

GPU_RUNNERS_PER_DEVICE = config['GUPPY_BASECALLER']['GPU_PER_DEVICE']

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
	BASECALLER_OPT = "--flowcell {flowcell} --kit {kit} --num_callers {num_callers} --cpu_threads_per_caller {cpu_threads_per_caller} --min_qscore {min_qscore} --qscore_filtering {addition}".format(flowcell=FLOWCELL, kit=KIT, num_callers=NUM_CALLERS, cpu_threads_per_caller=CPU_THREADS_PER_CALLER, min_qscore=MIN_QSCORE, addition=BASECALLER_ADDITION)
if RESOURCE == 'GPU':
	BASECALLER_OPT = "--flowcell {flowcell} --kit {kit} --num_callers {num_callers} --min_qscore {min_qscore} --qscore_filtering --gpu_runners_per_device {gpu_runners_per_device} --device $CUDA {addition}".format(flowcell=FLOWCELL, kit=KIT, num_callers=NUM_CALLERS, min_qscore=MIN_QSCORE, gpu_runners_per_device=GPU_RUNNERS_PER_DEVICE, addition=BASECALLER_ADDITION)

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
fig = config['MINIONQC']['FIG']

##############################
## deepbinner classify parameters

PRESET = config['DEEPBINNER_CLASSIFY']['PRESET']
OMP_NUM_THREADS = config['DEEPBINNER_CLASSIFY']['THREADS']
DEEPBINNER_ADDITION = config['DEEPBINNER_CLASSIFY']['ADDITION']

##############################
## use different containers for guppy and deepbinner if no single container for all pakages is specified

def guppy_container():
	if len(config['SINGULARITY']['ALL']) == 0:
		return(config['SINGULARITY']['GUPPY'])
	else:
		return(config['SINGULARITY']['ALL'])

def deepbinner_container():
	if len(config['SINGULARITY']['ALL']) == 0:
		return(config['SINGULARITY']['DEEPBINNER'])
	else:
		return(config['SINGULARITY']['ALL'])


##############################
## path to scripts

CHOOSE_AVAIL_GPU = config['SCRIPT']['CHOOSE_AVAIL_GPU']
FAST5_SUBSET = config['SCRIPT']['FAST5_SUBSET']
GET_FASTQ_PER_BARCODE = config['SCRIPT']['GET_FASTQ_PER_BARCODE']
GET_SUMMARY_PER_BARCODE = config['SCRIPT']['GET_SUMMARY_PER_BARCODE']
RENAME_FASTQ_GUPPY_BARCODER = config['SCRIPT']['RENAME_FASTQ_GUPPY_BARCODER']


##############################
##############################

# ruleorder: gpu_guppy_basecalling > cpu_guppy_basecalling

rule finish:
	input:
		expand(os.path.join(outdir, "basecall/multiqc_{run}.done"), run=run), # BASECALLING QC
		expand(os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/multiqc/multiqc_report.html"), demultiplexer=demultiplexer, run=run), # DEMULTIPLEXING QC
		expand(os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/fast5_per_barcode.done"), demultiplexer=demultiplexer, run=run),
		#expand(os.path.join(DIR, "basecall/{run}/{fig}.png"), run=run, fig=fig),
		#expand(os.path.join(DIR, "demultiplex/{demultiplexer}/{run}/report.done"), demultiplexer=demultiplexer, run=run),


##############################
################## BASECALLING
##################### BY GUPPY


rule guppy_basecalling:
	input: os.path.join(indir, "{run}/fast5")
	output:
		summary = os.path.join(outdir, "basecall/{run}/sequencing_summary.txt"),
		passed_summary = os.path.join(outdir, "basecall/{run}/passed_sequencing_summary.txt"),
		# fastq = os.path.join(outdir, "basecall/{run}/{run}.fastq"),
		fastq = directory(os.path.join(outdir, "basecall/{run}/pass")),
		fast5 = directory(os.path.join(outdir, "basecall/{run}/passed_fast5"))
	message: "GUPPY basecalling running on {}".format(RESOURCE)
	params:
		outpath = os.path.join(outdir, "basecall/{run}"),
		fast5_name = "{run}_"
	threads: THREADS
	singularity: guppy_container()
	conda: config['CONDA']['MINIONQC']
	shell:
		"""
		CUDA=$(python3 {CHOOSE_AVAIL_GPU})
		guppy_basecaller -i {input} -s {params.outpath} {BASECALLER_OPT}
		# cat {params.outpath}/pass/fastq_runid_*.fastq > {output.fastq}
		# rm -rf {params.outpath}/pass/fastq_runid_*.fastq
		grep 'read_id' {output.summary} > {output.passed_summary}
		grep 'TRUE' {output.summary} >> {output.passed_summary}
		fast5_subset --input {input} --save_path {output.fast5} --read_id_list {output.passed_summary} --filename_base {params.fast5_name}
		"""


##############################
############### DEMULTIPLEXING
##################### BY GUPPY


rule guppy_demultiplexing:
	input: rules.guppy_basecalling.output.fastq
	output:
		demux = os.path.join(outdir, "demultiplex/guppy/{run}/barcoding_summary.txt")
	params:
		# inpath = rules.guppy_basecalling.params.outpath,
		outpath = os.path.join(outdir, "demultiplex/guppy/{run}"),
		# config = config['DEMULTIPLEXING_CONFIG'],
	singularity: guppy_container()
	conda: config['CONDA']['MINIONQC']
	threads: THREADS
	shell:
		"""
		CUDA=$(python3 {CHOOSE_AVAIL_GPU})
		guppy_barcoder -i {input} -s {params.outpath} --config {BARCODER_CONFIG} --barcode_kits {KIT} --worker_threads {WORKER_THREADS} {DEVICE} --trim_barcodes --compress_fastq {ADDITION}
		Rscript {RENAME_FASTQ_GUPPY_BARCODER} {params.outpath}
		"""



##############################
############### DEMULTIPLEXING
################ BY DEEPBINNER


rule multi_to_single_fast5:
	input: rules.guppy_basecalling.output.fast5
	output: temp(directory(os.path.join(outdir, "demultiplex/deepbinner/{run}/singlefast5")))
	singularity: deepbinner_container()
	threads: THREADS
	shell:
		"""
		multi_to_single_fast5 -i {input} -s {output} -t {threads}
		"""


rule deepbinner_classification:
	input: rules.multi_to_single_fast5.output
	output:
		classification = os.path.join(outdir, "demultiplex/deepbinner/{run}/classification")
	singularity: deepbinner_container()
	threads: THREADS
	shell:
		"""
		deepbinner classify --{PRESET} --omp_num_threads {OMP_NUM_THREADS} {DEEPBINNER_ADDITION} {input} > {output.classification}
		"""


rule deepbinner_bin:
	input:
		classes = rules.deepbinner_classification.output.classification,
		fastq = rules.guppy_basecalling.output.fastq
	output: os.path.join(outdir, "demultiplex/deepbinner/{run}/fastq_per_barcode.done")
	params:
		out_dir = os.path.join(outdir, "demultiplex/deepbinner/{run}"),
		fastq = temp(os.path.join(outdir, "demultiplex/deepbinner/{run}/{run}.fastq"))
	singularity: deepbinner_container()
	shell:
		"""
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
		summary = os.path.join(outdir, "basecall/{run}/summary.yaml")
	conda: config['CONDA']['MINIONQC']
	singularity: guppy_container()
	# params:
	# 	inpath = os.path.join(outdir, "basecall/{run}"),
	shell:
		"""
		MinIONQC.R -i {input} -q {QSCORE_CUTOFF} -s {SMALLFIGURES}
		"""

rule multiqc_basecall:
	input: expand(rules.minionqc_basecall.output.summary, run=run)
	output: expand(os.path.join(outdir, "basecall/multiqc_{run}.done"), run=run)
	singularity: guppy_container()
	conda: config['CONDA']['MULTIQC']
	params:
		inpath = os.path.join(outdir, "basecall"),
		outpath = os.path.join(outdir, "basecall/multiqc")
	shell:
		"""
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
	conda: config['CONDA']['MINIONQC']
	singularity: guppy_container()
	shell:
		"""
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
	conda: config['CONDA']['MINIONQC']
	singularity: guppy_container()
	threads: THREADS
	shell:
		"""
		MinIONQC.R -i {params.inpath} -q {QSCORE_CUTOFF} -s {SMALLFIGURES} -p {PROCESSORS}
		rm -rf {params.combinedQC}
		touch {output}
		"""


rule multiqc_demultiplex:
	input:
		rules.minionqc_demultiplex.output
	output: os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/multiqc/multiqc_report.html")
	singularity: guppy_container()
	conda: config['CONDA']['MULTIQC']
	params:
		inpath = rules.minionqc_demultiplex.params.inpath,
		outpath = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/multiqc")
	shell:
		"""
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
	singularity: deepbinner_container()
	params:
		path = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}"),
	shell:
		"""
		python3 {FAST5_SUBSET} {input.fast5} {params.path}
		touch {output.check}
		"""




rule report_basecall:
	input: rules.multiqc_basecall.output
	output: report(os.path.join(outdir, "basecall/{run}/{fig}.png"), caption = "report/basecall_minionqc.rst", category = "minionqc_basecall")
	shell:
		"touch {output}"

##############################
############### SOMETHING ELSE

rule clean:
	shell:
		"""
		rm -rf {outdir}
		echo "removed {outdir}"
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
