========================
baseDmux WORKFLOW REPORT
========================


Sequencing informations:
  - Kit: {{ snakemake.config['KIT'] }}
  - Flowcell: {{ snakemake.config['FLOWCELL'] }}

**Basecalling was performed by guppy 3.6.0 on {{ snakemake.config['RESOURCE'] }}.**

**Demultiplexing was performed by {{ snakemake.config['DEMULTIPLEXER']|join(" and ") }}.**
