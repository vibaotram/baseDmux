import os
import glob


configfile:"config.yaml"


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


DIR = config['DIR']

run, = glob_wildcards(os.path.join(DIR, "reads/{run}/fast5"))



KIT_PARAM = config['KIT']


FLOWCELL_PARAM = config['FLOWCELL']



MIN_QSCORE_PARAM = config['BASECALLER']['MIN_QSCORE']
HP_CORRECT_PARAM = config['BASECALLER']['HP_CORRECT']
ENABLE_TRIMMING_PARAM = config['BASECALLER']['ENABLE_TRIMMING']

THREADS = config['BASECALLER']['THREADS']

GPU_RUNNERS_PER_DEVICE_PARAM = config['BASECALLER']['GPU_RUNNERS']

NUM_CALLERS_PARAM = config['BASECALLER']['NUM_CALLERS']

DEVICE_PARAM = config['BASECALLER']['GPU_DEVICE']

demultiplexer = config['DEMULTIPLEXER']

#cpu_guppy_basecaller: guppy_basecaller -i $tempDir -s $tempOutDir --flowcell FLO-MIN106 --kit $kit --num_callers $ncallers --cpu_threads_per_caller $nthreads --qscore_filtering --min_qscore 7 --hp_correct true --enable_trimming true"
#gpu_guppy_basecaller: guppy_basecaller -i $tempDir -s $tempOutDir --flowcell FLO-MIN106 --kit $kit --num_callers $ncallers --cpu_threads_per_caller $nthreads --qscore_filtering --min_qscore 7 --hp_correct true --enable_trimming true --gpu_runners_per_device $ngpu --device $name"




rule all:
	input:
		expand(os.path.join(DIR, "basecall/multiqc_{run}.done"), run=run), # BASECALLING QC
		expand(os.path.join(DIR, "demultiplex/{demultiplexer}/{run}/multiqc/multiqc_report.html"), demultiplexer=demultiplexer, run=run), # DEMULTIPLEXING QC
		expand(os.path.join(DIR, "demultiplex/{demultiplexer}/{run}/fast5_per_barcode.done"), demultiplexer=demultiplexer, run=run)


##############################
################## BASECALLING
##################### BY GUPPY

rule cpu_guppy_basecalling:
	input: DIR + "reads/{run}/fast5"
	output:
		summary = DIR + "basecall/{run}/sequencing_summary.txt",
		fastq = DIR + "basecall/{run}/{run}.fastq"
	params:
		outpath = DIR + "basecall/{run}",
		flowcell = FLOWCELL_PARAM,
		kit = KIT_PARAM,
#		config = BASECALLER_CONFIG_PARAM,
		num_callers = NUM_CALLERS_PARAM,
		min_qscore = MIN_QSCORE_PARAM,
		hp_correct = HP_CORRECT_PARAM,
#		enable_trimming = ENABLE_TRIMMING_PARAM,
	threads: THREADS
	singularity: guppy_container()
	shell:
		"""
		guppy_basecaller -i {input} -s {params.outpath} --flowcell {params.flowcell} --kit {params.kit} --cpu_threads_per_caller {threads} --num_callers {params.num_callers} --qscore_filtering --min_qscore {params.min_qscore} --hp_correct {params.hp_correct}
		cat {params.outpath}/*.fastq > {output.fastq}
		rm -f {params.outpath}/fastq_runid_*.fastq
		"""


rule gpu_guppy_basecalling:
	input: DIR + "reads/{run}/fast5"
	output:
		summary = DIR + "basecall/{run}/sequencing_summary.txt",
		fastq = DIR + "basecall/{run}/{run}.fastq"
	params:
		outpath = DIR + "basecall/{run}",
		flowcell = FLOWCELL_PARAM,
		kit = KIT_PARAM,
#		config = BASECALLER_CONFIG_PARAM,
		num_callers = NUM_CALLERS_PARAM,
		min_qscore = MIN_QSCORE_PARAM,
		hp_correct = HP_CORRECT_PARAM,
		enable_trimming = ENABLE_TRIMMING_PARAM,
		gpu_runners_per_device = GPU_RUNNERS_PER_DEVICE_PARAM,
		device = DEVICE_PARAM,
	threads: THREADS
	singularity: guppy_container()
	shell:
		"""
		guppy_basecaller -i {input} -s {params.outpath} --flowcell {params.flowcell} --kit {params.kit} --cpu_threads_per_caller {threads} --num_callers {params.num_callers} --qscore_filtering --min_qscore {params.min_qscore} --hp_correct {params.hp_correct} --gpu_runners_per_device {params.gpu_runners_per_device} -device "{params.device}"
		cat {params.outpath}/*.fastq > {output.fastq}
		rm -f {params.outpath}/fastq_runid_*.fastq
		"""



##############################
############### DEMULTIPLEXING
##################### BY GUPPY

def rules_guppy_basecaller_output_fastq():
	if config['BASECALLER']['RESOURCE'] == 'cpu':
		return(rules.cpu_guppy_basecalling.output.fastq)
	elif config['BASECALLER']['RESOURCE'] == 'gpu':
		return(rules.gpu_guppy_basecalling.output.fastq)

def rules_guppy_basecaller_params_outpath():
	if config['BASECALLER']['RESOURCE'] == 'cpu':
		return(rules.cpu_guppy_basecalling.params.outpath)
	elif config['BASECALLER']['RESOURCE'] == 'gpu':
		return(rules.gpu_guppy_basecalling.params.outpath)

rule guppy_demultiplexing:
	input: rules_guppy_basecaller_output_fastq()
	output:
		demux = DIR + "demultiplex/guppy/{run}/barcoding_summary.txt",
		#check = DIR + "demultiplex/guppy/{run}/demux.done"
	params:
		inpath = rules_guppy_basecaller_params_outpath(),
		outpath = DIR + "demultiplex/guppy/{run}",
		kit = KIT_PARAM,
		config = "configuration.cfg"
	singularity: guppy_container()
	conda: config['CONDA']['MINIONQC']
	shell:
		"""
		guppy_barcoder -i {params.inpath} -s {params.outpath} -c {params.config} --barcode_kits {params.kit} --trim_barcodes --compress_fastq
		Rscript script/rename_fastq_guppy_barcoder.R {params.outpath}
		#touch {output.check}
		"""



##############################
############### DEMULTIPLEXING
################ BY DEEPBINNER


rule multi_to_single_fast5:
	input: DIR + "reads/{run}/fast5"
	output: temp(directory(DIR + "reads/{run}/singlefast5"))
	params:
		output = DIR + "reads/{run}/singlefast5"
	singularity: deepbinner_container()
	shell:
		"""
		multi_to_single_fast5 -i {input} -s {params.output}
		"""


rule deepbinner_classification:
	input: rules.multi_to_single_fast5.output
	output:
		classification = DIR + "demultiplex/deepbinner/{run}/classification",
		#check = DIR + "demultiplex/deepbinner/{run}/demux.done"
	singularity: deepbinner_container()
	shell:
		"""
		deepbinner classify --rapid {input} > {output.classification}
		"""




rule deepbinner_bin:
	input:
		classes = rules.deepbinner_classification.output.classification,
		fastq = rules_guppy_basecaller_output_fastq()
	output: DIR + "demultiplex/deepbinner/{run}/fastq_per_barcode.done"
	params:
		out_dir = DIR + "demultiplex/deepbinner/{run}"
	singularity: deepbinner_container()
	shell:
		"""
		deepbinner bin --classes {input.classes} --reads {input.fastq} --out_dir {params.out_dir}
		python3 script/redirect_fastq.py {params.out_dir}
		touch {output}
		"""



##############################
############# MINIONQC/MULTIQC
############## FOR BASECALLING

def rules_guppy_basecaller_output_summary():
	if config['BASECALLER']['RESOURCE'] == 'cpu':
		return(rules.cpu_guppy_basecalling.output.summary)
	elif config['BASECALLER']['RESOURCE'] == 'gpu':
		return(rules.gpu_guppy_basecalling.output.summary)

rule minionqc_basecall:
	input: rules_guppy_basecaller_output_summary()
	output:
		summary = DIR + "basecall/{run}/summary.yaml",
	conda: config['CONDA']['MINIONQC']
	singularity: guppy_container()
	params:
		inpath = DIR + "basecall/{run}",
		#combinedQC = "basecall/combinedQC"
	shell:
		"""
		MinIONQC.R -i {params.inpath}
		"""

rule multiqc_basecall:
	input: rules.minionqc_basecall.output
	output:
		DIR + "basecall/multiqc_{run}.done"
	singularity: guppy_container()
	conda: config['CONDA']['MULTIQC']
	params:
		inpath = DIR + "basecall",
		outpath = DIR + "basecall/multiqc"
	shell:
		"""
		multiqc -f -v -d -dd 2 -o {params.outpath} {params.inpath}
		touch {output}
		"""

##############################
############# MINIONQC/MULTIQC
########### FOR DEMULTIPLEXING


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


rule get_sequencing_summary_per_barcode:
	input:
		#DIR + "demultiplex/{demultiplexer}/{run}/demux.done",
		deepbinner_bin_output(),
		deepbinner_classification_output(),
		guppy_demultiplexing_output()
	output: DIR + "demultiplex/{demultiplexer}/{run}/get_summary.done"
	params:
		barcoding_path = DIR + "demultiplex/{demultiplexer}/{run}",
		sequencing_file = rules_guppy_basecaller_output_summary()
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
	output: DIR + "demultiplex/{demultiplexer}/{run}/minionqc.done"
	params:
		outpath = DIR + "demultiplex/{demultiplexer}/{run}/minionqc",
		inpath = rules.get_sequencing_summary_per_barcode.params.barcoding_path,
		combinedQC = DIR + "demultiplex/{demultiplexer}/{run}/combinedQC"
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
	output: DIR + "demultiplex/{demultiplexer}/{run}/multiqc/multiqc_report.html"
	singularity: guppy_container()
	conda: config['CONDA']['MULTIQC']
	params:
		inpath = rules.minionqc_demultiplex.params.inpath,
		outpath = DIR + "demultiplex/{demultiplexer}/{run}/multiqc"
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
		#fast5 = DIR + "demultiplex/{demultiplexer}/{run}/{barcode}/batch_output_0.fast5",
		check = DIR + "demultiplex/{demultiplexer}/{run}/fast5_per_barcode.done"
	singularity: deepbinner_container()
	params:
		fast5 = DIR + "reads/{run}/fast5",
		path = DIR + "demultiplex/{demultiplexer}/{run}"
	shell:
		"""
		python3 script/fast5_subset.py {params.fast5} {params.path}
		touch {output.check}
		"""


##############################
##################### HANDLERS

onstart:
	print("Demultiplexing will be performed by")
	for d in demultiplexer: print("-", d)

onsuccess:
	print("Workflow finished, yay")

onerror:
    print("OMG ... error ... error ... again")
