import os
import glob

report: "report/workflow.rst"

configfile:"config.yaml"


indir = config['INDIR']

outdir = config['0UTDIR']

run, = glob_wildcards(os.path.join(indir, "{run}/fast5"))

demultiplexer = config['DEMULTIPLEXER']

fig = config['MINIONQC']['FIG']

##############################
## guppy_basecaller parameters

RESOURCE = config['BASECALLER']['RESOURCE']

KIT = config['KIT']

FLOWCELL = config['FLOWCELL']

QSCORE_FILTERING = config['BASECALLER']['QSCORE_FILTERING']
MIN_QSCORE = config['BASECALLER']['MIN_QSCORE']
HP_CORRECT = config['BASECALLER']['HP_CORRECT']

THREADS = config['THREADS']

GPU_RUNNERS_PER_DEVICE = config['BASECALLER']['GPU_PER_DEVICE']

NUM_CALLERS = config['BASECALLER']['NUM_CALLERS']

CUDA = config['BASECALLER']['CUDA']

CPU_THREADS_PER_CALLER = config['BASECALLER']['CPU_PER_CALLER']

if QSCORE_FILTERING == 'yes' or 'true':
	FILTERING_OPT = '--qscore_filtering'
	FASTQ = 'pass/fastq_runid_*.fastq'
elif QSCORE_FILTERING == '' or 'no' or 'false':
	FILTERING_OPT = ''
	FASTQ = 'fastq_runid_*.fastq'

if RESOURCE == 'cpu' or 'CPU':
	SINGULARITY_ARGS = ''
	BASECALLER_OPT = "--flowcell {flowcell} --kit {kit} --num_callers {num_callers} --cpu_threads_per_caller {cpu_threads_per_caller} --min_qscore {min_qscore} --hp_correct {hp_correct} {qscore_filtering}".format(flowcell=FLOWCELL, kit=KIT, num_callers=NUM_CALLERS, cpu_threads_per_caller=CPU_THREADS_PER_CALLER, min_qscore=MIN_QSCORE, hp_correct=HP_CORRECT, qscore_filtering=FILTERING_OPT)
elif RESOURCE == 'gpu' or 'GPU':
	SINGULARITY_ARGS = '--nv'
	BASECALLER_OPT = "--flowcell {flowcell} --kit {kit} --num_callers {num_callers} --min_qscore {min_qscore} --hp_correct {hp_correct} --gpu_runners_per_device {gpu_runners_per_device} --device \"{cuda}\" {qscore_filtering}".format(flowcell=FLOWCELL, kit=KIT, num_callers=NUM_CALLERS, min_qscore=MIN_QSCORE, hp_correct=HP_CORRECT, gpu_runners_per_device=GPU_RUNNERS_PER_DEVICE, cuda=CUDA, qscore_filtering=FILTERING_OPT)




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
		fastq = os.path.join(outdir, "basecall/{run}/{run}.fastq")
	message: "GUPPY basecalling running on {}".format(RESOURCE)
	params:
		outpath = os.path.join(outdir, "basecall/{run}"),
		opt = BASECALLER_OPT,
		fastq = FASTQ,
	threads: THREADS
	singularity: guppy_container()
	shell:
		"""
		guppy_basecaller -i {input} -s {params.outpath} {params.opt}
		cat {params.outpath}/{params.fastq} > {output.fastq}
		rm -rf {params.outpath}/fastq_runid_*.fastq
		"""


##############################
############### DEMULTIPLEXING
##################### BY GUPPY


rule guppy_demultiplexing:
	input: rules.guppy_basecalling.output.fastq
	output:
		demux = os.path.join(outdir, "demultiplex/guppy/{run}/barcoding_summary.txt")
	params:
		inpath = rules.guppy_basecalling.params.outpath,
		outpath = os.path.join(outdir, "demultiplex/guppy/{run}"),
		kit = KIT,
		config = config['DEMULTIPLEXING_CONFIG']
	singularity: guppy_container()
	conda: config['CONDA']['MINIONQC']
	shell:
		"""
		guppy_barcoder -i {params.inpath} -s {params.outpath} -c {params.config} --barcode_kits {params.kit} --trim_barcodes --compress_fastq
		Rscript script/rename_fastq_guppy_barcoder.R {params.outpath}
		"""



##############################
############### DEMULTIPLEXING
################ BY DEEPBINNER


rule multi_to_single_fast5:
	input: os.path.join(indir, "{run}/fast5")
	output: temp(directory(os.path.join(indir, "{run}/singlefast5")))
	params:
		output = os.path.join(indir, "{run}/singlefast5")
	singularity: deepbinner_container()
	threads: THREADS
	shell:
		"""
		multi_to_single_fast5 -i {input} -s {params.output} -t {threads}
		"""


rule deepbinner_classification:
	input: rules.multi_to_single_fast5.output
	output:
		classification = os.path.join(outdir, "demultiplex/deepbinner/{run}/classification")
	singularity: deepbinner_container()
	shell:
		"""
		deepbinner classify --rapid {input} > {output.classification}
		"""


rule deepbinner_bin:
	input:
		classes = rules.deepbinner_classification.output.classification,
		fastq = rules.guppy_basecalling.output.fastq
	output: os.path.join(outdir, "demultiplex/deepbinner/{run}/fastq_per_barcode.done")
	params:
		out_dir = os.path.join(outdir, "demultiplex/deepbinner/{run}")
	singularity: deepbinner_container()
	shell:
		"""
		deepbinner bin --classes {input.classes} --reads {input.fastq} --out_dir {params.out_dir}
		python3 script/redirect_fastq.py {params.out_dir}
		touch {output}
		"""

##############################
## determine which demultiplexer to be executed

def deepbinner_bin_output():
	if "deepbinner" or "DEEPBINNER" or "Deepbinner" in demultiplexer:
		return(rules.deepbinner_bin.output)
	else:
		return()

def deepbinner_classification_output():
	if "deepbinner" or "DEEPBINNER" or "Deepbinner" in demultiplexer:
		return(rules.deepbinner_classification.output)
	else:
		return()

def guppy_demultiplexing_output():
	if "guppy" or "GUPPY" or "Guppy" in demultiplexer:
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
	params:
		inpath = os.path.join(outdir, "basecall/{run}")
	shell:
		"""
		MinIONQC.R -i {params.inpath}
		"""

rule multiqc_basecall:
	input: rules.minionqc_basecall.output.summary
	output: os.path.join(outdir, "basecall/multiqc_{run}.done")
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
		sequencing_file = rules.guppy_basecalling.output.summary
	conda: config['CONDA']['MINIONQC']
	singularity: guppy_container()
	shell:
		"""
		Rscript script/get_summary_per_barcode.R {params.sequencing_file} {params.barcoding_path}
		touch {output}
		"""


rule minionqc_demultiplex:
	input:
		rules.get_sequencing_summary_per_barcode.output
	output: os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/minionqc.done")
	params:
		outpath = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/minionqc"),
		inpath = rules.get_sequencing_summary_per_barcode.params.barcoding_path,
		combinedQC = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/combinedQC")
	conda: config['CONDA']['MINIONQC']
	singularity: guppy_container()
	shell:
		"""
		MinIONQC.R -i {params.inpath}
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
	input: rules.get_sequencing_summary_per_barcode.output
	output:
		check = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/fast5_per_barcode.done")
	singularity: deepbinner_container()
	params:
		fast5 = os.path.join(indir, "{run}/fast5"),
		path = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}")
	shell:
		"""
		python3 script/fast5_subset.py {params.fast5} {params.path}
		touch {output.check}
		"""




rule report_basecall:
	input: rules.multiqc_basecall.output
	output: report(os.path.join(outdir, "basecall/{run}/{fig}.png"), caption = "report/basecall_minionqc.rst", category = "minionqc_basecall")
	shell:
		"touch {output}"



rule clean:
	params:
		basecall = os.path.join(outdir, "basecall"),
		demultiplex = os.path.join(outdir, "demultiplex")
	shell:
		"""
		rm -rf {params.basecall} {params.demultiplex}
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
