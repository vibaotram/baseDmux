import os
import glob
import getpass
import pandas as pd
import sys


report: "report/workflow.rst"

request = sys.argv[:]
if "--configfile" in request:
	arg_index = request.index("--configfile")
	cf = request[arg_index + 1]
else:
	cf = "config.yaml"
configfile: cf


indir = config['INDIR']

outdir = config['OUTDIR']

fast5_files = glob.glob(os.path.join(indir, "*/fast5"))
run = []
for f in fast5_files:
	run.append(os.path.basename(os.path.dirname(f)))

# run, = glob_wildcards(os.path.join(indir, "{run}/fast5/"))

demultiplexer = config['DEMULTIPLEXER']

# helper function
def by_cond(cond, yes, no, cond_ext = '', no_ext = ''): # it's working but needs to be improved ...
	if not cond_ext:
		cond_ext = not cond
	if cond:
		return yes
	elif cond_ext:
		return no
	else:
		return no_ext

##############################
## guppy_basecaller parameters
RESOURCE = config['RESOURCE']
if RESOURCE not in ['CPU', 'GPU']:
	raise KeyError(f'{RESOURCE} in RESOURCE is invalid (configfile line 19)')
else:
	pass

KIT = config['KIT']

FLOWCELL = config['FLOWCELL']

# QSCORE_FILTERING = config['BASECALLER']['QSCORE_FILTERING']
MIN_QSCORE = config['RULE_GUPPY_BASECALLING']['MIN_QSCORE']

CPU_THREADS_PER_CALLER = config['RULE_GUPPY_BASECALLING']['CPU_THREADS_PER_CALLER']
NUM_CALLERS = config['RULE_GUPPY_BASECALLING']['NUM_CALLERS']

BASECALLER_ADDITION = config['RULE_GUPPY_BASECALLING']['ADDITION']
CONFIG = by_cond("--config" in BASECALLER_ADDITION, '', f"--flowcell {FLOWCELL} --kit {KIT}")
# CUDA = config['BASECALLER']['CUDA']

GPU_RUNNERS_PER_DEVICE = config['RULE_GUPPY_BASECALLING']['GPU_RUNNERS_PER_DEVICE']
NUM_GPUS = config['NUM_GPUS']

# adjust guppy_basecaller parameters based on RESOURCE
BASECALLER_OPT = by_cond(cond = RESOURCE == 'CPU',
                         yes = f"{CONFIG} --num_callers {NUM_CALLERS} --cpu_threads_per_caller {CPU_THREADS_PER_CALLER} --min_qscore {MIN_QSCORE} --qscore_filtering {BASECALLER_ADDITION}",
                         no = f"{CONFIG} --num_callers {NUM_CALLERS} --min_qscore {MIN_QSCORE} --qscore_filtering --gpu_runners_per_device {GPU_RUNNERS_PER_DEVICE} --device $CUDA {BASECALLER_ADDITION}",
                         cond_ext = RESOURCE == 'GPU')

BASECALLER_THREADS = by_cond(cond = RESOURCE == 'CPU',
                             yes = NUM_CALLERS*CPU_THREADS_PER_CALLER,
                             no = NUM_CALLERS,
                             cond_ext = RESOURCE == 'GPU')



KEEP_FAIL_READS = config['RULE_GUPPY_BASECALLING']['KEEP_FAIL_READS']

FAST5_COMPRESSION = config['RULE_GUPPY_BASECALLING']['FAST5_COMPRESSION']

KEEP_LOG_FILES = config['RULE_GUPPY_BASECALLING']['KEEP_LOG_FILES']

##############################
## guppy_barcoder parameters
BARCODER_CONFIG = config['RULE_GUPPY_DEMULTIPLEXING']['CONFIG']
WORKER_THREADS = config['RULE_GUPPY_DEMULTIPLEXING']['WORKER_THREADS']
ADDITION = config['RULE_GUPPY_DEMULTIPLEXING']['ADDITION']

####

DEVICE = by_cond(RESOURCE == 'CPU', None, f'--device $CUDA')



##############################
## MinIONQC parameters

#QSCORE_CUTOFF = config['RULE_MINIONQC_']['QSCORE_CUTOFF']
SMALLFIGURES = config['RULE_MINIONQC_']['SMALLFIGURES']
PROCESSORS = config['RULE_MINIONQC_']['PROCESSORS']
fig = ["channel_summary", "flowcell_overview", "gb_per_channel_overview", "length_by_hour", "length_histogram", "length_vs_q", "q_by_hour", "q_histogram", "reads_per_hour", "yield_by_length", "yield_over_time"]


##############################
## deepbinner classify parameters

PRESET = config['RULE_DEEPBINNER_CLASSIFICATION']['PRESET']
OMP_NUM_THREADS = config['RULE_DEEPBINNER_CLASSIFICATION']['OMP_NUM_THREADS']
DEEPBINNER_ADDITION = config['RULE_DEEPBINNER_CLASSIFICATION']['ADDITION']
API_THREADS = config['RULE_MULTI_TO_SINGLE_FAST5']['THREADS']


##############################
## get_reads_per_genome

TRANSFERING = config['RULE_GET_READS_PER_GENOME']['TRANSFERING']
BARCODE_BY_GENOME = config['RULE_GET_READS_PER_GENOME']['BARCODE_BY_GENOME']


if not BARCODE_BY_GENOME:
	genome = []
	get_demultiplexer = []
else :
	if os.path.isfile(BARCODE_BY_GENOME):
		genome = pd.read_csv(BARCODE_BY_GENOME, sep = "\t", usecols = ["Genome_ID"], squeeze = True).unique()
		get_demultiplexer = pd.read_csv(BARCODE_BY_GENOME, sep = "\t", usecols = ["Demultiplexer"], squeeze = True).unique()
	else:
		raise FileNotFoundError(f'"{BARCODE_BY_GENOME}" in BARCODE_BY_GENOME does not exist (configfile line 74)')

GET_READS_PER_GENOME_OUTPUT = [directory(expand(os.path.join(outdir, "reads_per_genome/fast5/{genome}"), genome = genome)), expand(os.path.join(outdir, "reads_per_genome/fastq/{genome}.fastq.gz"), genome = genome)]



# POST_DEMULTIPLEXING = sorted(config["POST_DEMULTIPLEXING"], reverse = True)
POST_DEMULTIPLEXING = config["POST_DEMULTIPLEXING"]


if len(POST_DEMULTIPLEXING) == 0:
	post_demux = "fastq"
else:
	post_demux = []
	n_filtlong = POST_DEMULTIPLEXING.copy()
	if "porechop" in POST_DEMULTIPLEXING:
		n_filtlong.remove("porechop")
		if len(n_filtlong) > 0:
			for i in n_filtlong:
				if re.match("filtlong.+", i):
					post_demux.append("_".join(["fastq", "porechop", i]))
		else:
			post_demux.append("fastq_porechop")
	else:
		for i in n_filtlong:
			if re.match("filtlong.+", i):
				t = ["fastq", i]
				post_demux.append("_".join(t))


PORECHOP_PARAMS = config["porechop"]["PARAMS"]
# FILTLONG_PARAMS = config["RULE_FILTLONG"]["PARAMS"]

##############################
## reports
DEMULTIPLEX_REPORT = config['REPORTS']['DEMULTIPLEX_REPORT']

##############################
## use different containers for guppy and deepbinner depending on resources

guppy_container = by_cond(RESOURCE == 'CPU', 'shub://vibaotram/singularity-container:guppy3.6.0cpu-conda-api', 'shub://vibaotram/singularity-container:guppy4.0.14gpu-conda-api', cond_ext = 'GPU')

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


user = getpass.getuser()

nasID = config['NASID']
HOST_PREFIX = by_cond(nasID, user + '@' + nasID + ':', '')

##############################
## make slurm logs directory
SLURM_LOG = os.path.join(outdir, "log/slurm")
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



# shell.prefix("exec > >(tee "{SNAKEMAKE_LOG}/{log}") 2>&1; ")

##############################
##############################

ruleorder: filtlong > porechop

rule finish:
	input:
		expand(os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/multiqc/multiqc_report.html"), demultiplexer = demultiplexer, run = run), # DEMULTIPLEXING QC
		expand(os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/fast5_per_barcode.done"), demultiplexer = demultiplexer, run = run),
		os.path.join(outdir, "basecall/multiqc/multiqc_report.html"), # BASECALLING QC
		by_cond(DEMULTIPLEX_REPORT, os.path.join(outdir, "report/demultiplex_report.html"), ()),
		expand(os.path.join(outdir, "reads_per_genome/fast5/{genome}"), genome = genome),
		expand(os.path.join(outdir, "reads_per_genome/{post_demux}/{genome}.fastq.gz"), genome = genome, post_demux = post_demux),
		# expand(os.path.join(outdir, "reads_per_genome/fast5/{genome}"), genome = genome)
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
		# fastq = temp(os.path.join(outdir, "basecall/{run}/{run}.fastq")),
		fastq = temp(directory(os.path.join(outdir, "basecall/{run}/pass"))),
		compressed_fastq = os.path.join(outdir, "basecall/{run}/{run}.fastq.gz"),
		fast5 = temp(directory(os.path.join(outdir, "basecall/{run}/passed_fast5"))),
		# fast5 = directory(os.path.join(outdir, "basecall/{run}/passed_fast5")),
		fail = by_cond(cond = KEEP_FAIL_READS, yes = directory(os.path.join(outdir, "basecall/{run}/fail")), no = ())
	params:
		summary = lambda wildcards, output: os.path.basename(output.summary),
		passed_summary = lambda wildcards, output: os.path.basename(output.passed_summary),
		outpath = os.path.join(outdir, "basecall/{run}"),
		compressed_fastq = lambda wildcards, output: os.path.basename(output.compressed_fastq),
		compression = FAST5_COMPRESSION,
		keep_log_files = by_cond(KEEP_LOG_FILES, 'true', 'false'),
		# fast5_name = "{run}_",
		log = "guppy_basecalling_{run}.log"
	threads: BASECALLER_THREADS
	singularity: guppy_container
	conda: 'conda/conda_minionqc.yaml'
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		host_prefix='{HOST_PREFIX}'
		if [ -z $host_prefix ]; then
			temp_indir={input}
			temp_outdir={params.outpath}
		else
			temp_indir=$(mktemp -dp /scratch); echo -e "##$(date)    Creating temporary input directory on local drive: $temp_indir \\n"
			temp_outdir=$(mktemp -dp /scratch); echo -e "##$(date)    Creating temporary output directory on local drive: $temp_outdir \\n"
			rsync -arvP $host_prefix{input}/ $temp_indir
		fi
		CUDA=$(python3 {CHOOSE_AVAIL_GPU} {NUM_GPUS})
		guppy_basecaller -i $temp_indir -s $temp_outdir {BASECALLER_OPT}
		echo -e "\\nConcatenating passed fastq files into {params.compressed_fastq} \\n"
		cat $temp_outdir/pass/fastq_runid_*.fastq | gzip > $temp_outdir/{params.compressed_fastq} && echo -e "Compressing done.\\n"
		# rm -rf {params.outpath}/pass/fastq_runid_*.fastq
		grep 'read_id' $temp_outdir/{params.summary} > $temp_outdir/{params.passed_summary}
		grep 'TRUE' $temp_outdir/{params.summary} >> $temp_outdir/{params.passed_summary}
		echo -e "Filtering passed reads in fast5 files \\n"
		fast5_subset --input $temp_indir --save_path $temp_outdir/passed_fast5 --read_id_list $temp_outdir/passed_sequencing_summary.txt --filename_base {wildcards.run}_ --threads {threads} --compression {params.compression}
		tobe_saved={output.fail}
		if [ -z $tobe_saved ]; then
			rm -rf $temp_outdir/fail && echo -e "##$(date)    Removed failed reads from $temp_outdir \\n"
		fi
		if ! {params.keep_log_files} ; then
			rm -rf $temp_outdir/guppy_basecaller_log*.log && echo -e "##$(date)    Removed guppy_basecaller log files from $temp_outdir \\n"
		fi
		if [ ! -z $host_prefix ]; then
			echo -e "##$(date)    Transfering temporary output directory $temp_outdir to host directory {params.outpath}\\n"; rsync -arvP --chmod 755 $temp_outdir/ $host_prefix{params.outpath}
			rm -rf $temp_indir; echo -e "##$(date)    Removed temporary input directory on local drive: $temp_indir \\n"
			rm -rf $temp_outdir; echo -e "##$(date)    Removed temporary input directory on local drive: $temp_outdir \\n"
		fi
		"""


##############################
############### DEMULTIPLEXING
##################### BY GUPPY


rule guppy_demultiplexing:
	message: "GUPPY demultiplexing running on {RESOURCE}"
	input: rules.guppy_basecalling.output.fastq
	output:
		demux = os.path.join(outdir, "demultiplex/guppy/{run}/barcoding_summary.txt"),
		check = temp(os.path.join(outdir, "demultiplex/guppy/{run}/demultiplex.done"))
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
		guppy_barcoder -i {input} -s {params.outpath} --config {BARCODER_CONFIG} --barcode_kits {KIT} --worker_threads {threads} {DEVICE} {ADDITION} # --compress_fastq
		Rscript {RENAME_FASTQ_GUPPY_BARCODER} {params.outpath}
		touch {output.check}
		"""



##############################
############### DEMULTIPLEXING
################ BY DEEPBINNER


rule multi_to_single_fast5:
	input: rules.guppy_basecalling.output.fast5
	output:
		temp(directory(os.path.join(outdir, "demultiplex/deepbinner/{run}/singlefast5")))
		# directory(os.path.join(outdir, "demultiplex/deepbinner/{run}/singlefast5"))
	threads: API_THREADS
	singularity: deepbinner_container
	params:
		log = "multi_to_single_fast5_{run}.log"
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		host_prefix='{HOST_PREFIX}'
		if [ -z $host_prefix ]; then
			temp_indir={input}
			temp_outdir={output}
		else
			temp_indir=$(mktemp -dp /scratch); echo -e "##$(date)    Creating temporary input directory on local drive: $temp_indir \\n"
			temp_outdir=$(mktemp -dp /scratch); echo -e "##$(date)    Creating temporary output directory on local drive: $temp_outdir \\n"
			rsync -arvP $host_prefix{input}/ $temp_indir
		fi
		multi_to_single_fast5 -i $temp_indir -s $temp_outdir -t {threads}
		if [ ! -z $host_prefix ]; then
			echo -e "##$(date)    Transfering temporary output directory $temp_outdir to host directory {output}\\n"; rsync -arvP --chmod 755 $temp_outdir/ $host_prefix{output}
			rm -rf $temp_indir; echo -e "##$(date)    Removing temporary input directory on local drive: $temp_indir \\n"
			rm -rf $temp_outdir; echo -e "##$(date)    Removing temporary input directory on local drive: $temp_outdir \\n"
		fi
		"""

OMP_NUM_THREADS_OPT = by_cond(RESOURCE == 'CPU', '', '--omp_num_threads %s' % OMP_NUM_THREADS)

## THE DEEPBINNER CONTAINER CANNOT USE A GPU SO IT WILL ALWAYS RUN ON CPU EVEN IF RESOURCE IS GPU
## BESIDE, ON ITROP WE WILL ALWAYS HAVE RESOURCE = 'GPU'
## SO I DO NOT UNDERSTAND THE POINT OF OMP_NUM_THREADS_OPT
## IS TENSORFLOW INSTALLED TOGETHER WITH DEEPBINNER?


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
	output:
		check = temp(os.path.join(outdir, "demultiplex/deepbinner/{run}/demultiplex.done")),
		fastq = temp(os.path.join(outdir, "demultiplex/deepbinner/{run}/{run}.fastq")),
		# os.path.join(outdir, "demultiplex/deepbinner/{run}/fastq_per_barcode.done")
	params:
		out_dir = os.path.join(outdir, "demultiplex/deepbinner/{run}"),
		log = "deepbinner_bin_{run}.log"
	singularity: deepbinner_container
	threads: 1
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		cat {input.fastq}/fastq_runid_*.fastq > {output.fastq}
		deepbinner bin --classes {input.classes} --reads {output.fastq} --out_dir {params.out_dir}
		python3 {GET_FASTQ_PER_BARCODE} {params.out_dir}
		touch {output.check}
		"""

##############################
## determine which demultiplexer to be executed


DEEPBINNER_BIN_OUTPUT = by_cond(cond = "deepbinner" in demultiplexer, yes = rules.deepbinner_bin.output, no = ())

GUPPY_DEMULTIPLEXING_OUTPUT = by_cond("guppy" in demultiplexer, rules.guppy_demultiplexing.output, ())


##############################
############# MINIONQC/MULTIQC
############## FOR BASECALLING


MINIONQC_BASECALL_FIG = [os.path.join(outdir, "basecall/{run}") + "/{fig}.png".format(fig=fig) for fig in fig]
REPORT_MINIONQC_BASECALL = config['REPORTS']['SNAKEMAKE_REPORT']['MINIONQC_BASECALL']

rule minionqc_basecall:
	input: rules.guppy_basecalling.output.summary
	output:
		summary = os.path.join(outdir, "basecall/{run}/summary.yaml"),
		fig = by_cond(REPORT_MINIONQC_BASECALL, report(MINIONQC_BASECALL_FIG, caption = "report/basecall_minionqc.rst", category = "minionqc_basecall"), ())
	conda: 'conda/conda_minionqc.yaml'
	singularity: guppy_container
	params:
	# 	inpath = os.path.join(outdir, "basecall/{run}"),
		log = "minionqc_basecall_{run}.log"
	threads: 1
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		MinIONQC.R -i {input} -q {MIN_QSCORE} -s {SMALLFIGURES}
		"""

MULTIQC_BASECALL_OUTPUT = os.path.join(outdir, "basecall/multiqc/multiqc_report.html")
REPORT_MULTIQC_BASECALL = config['REPORTS']['SNAKEMAKE_REPORT']['MULTIQC_BASECALL']

rule multiqc_basecall:
	input:
		expand(rules.minionqc_basecall.output.summary, run=run),
		# inpath = os.path.join(outdir, "basecall")
	output:
		# os.path.join(outdir, "basecall/multiqc/multiqc_report.html")
		by_cond(REPORT_MULTIQC_BASECALL, report(MULTIQC_BASECALL_OUTPUT, category = "multiqc_basecall"), MULTIQC_BASECALL_OUTPUT)
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
		"""

##############################
############# MINIONQC/MULTIQC
########### FOR DEMULTIPLEXING


rule get_sequencing_summary_per_barcode:
	input:
		# DEEPBINNER_BIN_OUTPUT,
		# GUPPY_DEMULTIPLEXING_OUTPUT
		os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/demultiplex.done")
	output:
		temp(os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/get_summary.done"))
		# os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/get_summary.done")
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
###

# def summary_per_barcode(wildcards):
# 	checkpoint_output = checkpoints.demultiplexing_guppy_sequencing_summary.get(**wildcards).output[0]
#     barcodes=glob_wildcards(os.path.join(os.path.dirname(checkpoint_output), '{barcode}/sequencing_summary.txt')).barcode)
# 	summaryFilesList=[os.path.dirname(checkpoint_output) + "/{bc}/sequencing_summary.txt".format(bc = barcode) for barcode in barcodes]
# 	return(summaryFilesList)

###


## for snakemake report only
figpath = glob.glob(os.path.join(outdir, "demultiplex/**/*.png"), recursive = True)
figname = []
for f in figpath:
	figname.append(os.path.join(f.rsplit("/", 2)[-2], f.rsplit("/", 2)[-1]))

MINIONQC_DEMULTIPLEX_FIG = [os.path.join(outdir, "demultiplex/{demultiplexer}/{run}") + "/{figname}".format(figname=figname) for figname in figname]
REPORT_MINIONQC_DEMULTIPLEX = config['REPORTS']['SNAKEMAKE_REPORT']['MINIONQC_DEMULTIPLEX']

rule minionqc_demultiplex:
	input:
		rules.get_sequencing_summary_per_barcode.output
	output:
		check = temp(os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/minionqc.done")),
		# check = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/minionqc.done"),
		fig = by_cond(REPORT_MINIONQC_DEMULTIPLEX, report(MINIONQC_DEMULTIPLEX_FIG, caption = "report/demultiplex_minionqc.rst", category = "minionqc_demultiplex"), ())
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
		MinIONQC.R -i {params.inpath} -q {MIN_QSCORE} -s {SMALLFIGURES} -p {threads}
		rm -rf {params.combinedQC}
		touch {output.check}
		"""

MULTIQC_DEMULTIPLEX_OUTPUT = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/multiqc/multiqc_report.html")
REPORT_MULTIQC_DEMULTIPLEX = config['REPORTS']['SNAKEMAKE_REPORT']['MULTIQC_DEMULTIPLEX']

rule multiqc_demultiplex:
	input:
		rules.minionqc_demultiplex.output.check
	output:
		by_cond(REPORT_MULTIQC_DEMULTIPLEX, report(MULTIQC_DEMULTIPLEX_OUTPUT, category = "multiqc_demultiplex"), MULTIQC_DEMULTIPLEX_OUTPUT),
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
		check = temp(os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/fast5_per_barcode.done"))
		# check = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/fast5_per_barcode.done")
	singularity: deepbinner_container
	params:
		path = os.path.join(outdir, "demultiplex/{demultiplexer}/{run}"),
		log = "get_multi_fast5_per_barcode_{demultiplexer}_{run}.log"
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		python3 {FAST5_SUBSET} {input.fast5} {params.path}
		touch {output.check}
		"""


##############################
################# SUBSET READS
#################### BY GENOME

GET_READS_PER_GENOME_INPUT = [expand(rules.get_sequencing_summary_per_barcode.input, demultiplexer = get_demultiplexer, run = run),
                              expand(rules.get_multi_fast5_per_barcode.output, demultiplexer = get_demultiplexer, run = run)]

rule get_reads_per_genome:
	input:
		# indir = outdir,
		expand(rules.get_multi_fast5_per_barcode.output, demultiplexer = get_demultiplexer, run = run),
		expand(os.path.join(outdir, "demultiplex/{demultiplexer}/{run}/demultiplex.done"), demultiplexer = get_demultiplexer, run = run)
	output:
		# GET_READS_PER_GENOME_OUTPUT
		fast5 = directory(expand(os.path.join(outdir, "reads_per_genome/fast5/{genome}"), genome = genome)),
		fastq = expand(os.path.join(outdir, "reads_per_genome/fastq/{genome}.fastq.gz"), genome = genome),
		# csv = os.path.join(outdir, "reads_per_genome/reads_per_genome.csv")
	params:
		outpath = directory(os.path.join(outdir, "reads_per_genome")),
		barcode_by_genome = BARCODE_BY_GENOME,
		transfering = TRANSFERING,
		log = "get_reads_per_genome.log"
	singularity: guppy_container
	conda: 'conda/conda_minionqc.yaml'
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		Rscript script/get_reads_per_genome.R -b {outdir} -o {params.outpath} -d {params.barcode_by_genome} --{params.transfering}
		"""

##############################
########## POST_DEMULTIPLEXING

rule porechop:
	input: os.path.join(outdir, "reads_per_genome/fastq/{genome}.fastq.gz")
	output:
		fastq = os.path.join(outdir, "reads_per_genome/fastq_porechop/{genome}.fastq.gz")
	params:
		porechop = PORECHOP_PARAMS,
		log = "porechop_{genome}.log"
	singularity: guppy_container
	conda: 'conda/conda_porechop.yaml'
	threads: config["porechop"]["THREADS"]
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		porechop -i {input} -o {output} --format auto --verbosity 3 --threads {threads} {params.porechop}
		"""

FILTLONG_INPUT = by_cond("porechop" in POST_DEMULTIPLEXING, rules.porechop.output.fastq, os.path.join(outdir, "reads_per_genome/fastq/{genome}.fastq.gz"))

FILTLONG_OUTPUT = by_cond("porechop" in POST_DEMULTIPLEXING, os.path.join(outdir, "reads_per_genome/fastq_porechop_{n_filtlong}/{genome}.fastq.gz"), os.path.join(outdir, "reads_per_genome/fastq_{n_filtlong}/{genome}.fastq.gz"))

def filtlong_params(wildcards):
	params = config[wildcards.n_filtlong].values()
	return unpack(params)




rule filtlong:
	input: FILTLONG_INPUT
	output:
		fastq = FILTLONG_OUTPUT
	params:
		filtlong = filtlong_params,
		log = "{n_filtlong}_{genome}.log"
	singularity: guppy_container
	conda: 'conda/conda_filtlong.yaml'
	shell:
		"""
		exec > >(tee "{SNAKEMAKE_LOG}/{params.log}") 2>&1
		filtlong {params.filtlong} {input} | gzip > {output}
		"""


##############################
####################### REPORT

REPORT_DEMULTIPLEX_INPUT = by_cond(cond = DEMULTIPLEX_REPORT, yes = expand(rules.multiqc_demultiplex.output, demultiplexer = demultiplexer, run = run), no = ())

rule report_demultiplex:
	input:
		fast5 = expand(os.path.join(outdir, "reads_per_genome/fast5/{genome}"), genome = genome),
		fastq = expand(os.path.join(outdir, "reads_per_genome/{post_demux}/{genome}.fastq.gz"), genome = genome, post_demux = post_demux),
	message: " Reporting demultiplex results"
	output: os.path.join(outdir, "report/demultiplex_report.html")
	params:
		barcode_by_genome = BARCODE_BY_GENOME,
		fastq = os.path.join(outdir, "reads_per_genome/fastq"),
		demultiplex = os.path.join(outdir, "demultiplex"),
		postdemux = expand(os.path.join(outdir, "reads_per_genome/{post_demux}"), post_demux = post_demux),
		log = "report_demultiplex.log",
		outpath = lambda wildcards, output: os.path.dirname(output[0])
	singularity: guppy_container
	conda: 'conda/conda_rmarkdown.yaml'
	script:
		"report/report_demultiplex.Rmd"

##############################
############### SOMETHING ELSE

rule clean:
	message: "Cleaning output directory {outdir}"
	shell:
		"""
		rm -rf {outdir}
		echo "#################  removed {outdir}  #################"
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

rule test:
	shell:
		"""
		echo "{n_filtlong}"
		"""

# rule add_slurm_logs:
# 	shell:
# 		"""
# 		mkdir -p {outdir}/slurm_logs
# 		"""
##############################
##################### HANDLERS

# onstart:
# 	print("Basecalling will be performed by Guppy on", RESOURCE)
# 	print("Demultiplexing will be performed by",)
# 	for d in demultiplexer: print("\t-", d)


#onsuccess:
#	print("Workflow finished, yay")
#	print("Basecalling by Guppy on", RESOURCE)
#	print("Demultiplexing by")
#	for d in demultiplexer: print("\t-", d)

#onerror:
#	print("OMG ... error ... error ... again")
