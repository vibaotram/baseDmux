========================
baseDmux WORKFLOW REPORT
========================


The report contains results of MinIONQC for basecalling and MinIONQC for demultiplexing.


Basecalling was performed by GUPPY on {{ snakemake.config['GUPPY_BASECALLER']['RESOURCE'] }}.


Demultiplexing was performed by {{ snakemake.config['DEMULTIPLEXER']|join(" and ") }}.
