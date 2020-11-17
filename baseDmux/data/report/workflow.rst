========================
baseDmux WORKFLOW REPORT
========================


Sequencing informations:
  - Kit: {{ snakemake.config['KIT'] }}
  - Flowcell: {{ snakemake.config['FLOWCELL'] }}

**Basecalling was performed by guppy on {{ snakemake.config['RESOURCE'] }}.**

**Demultiplexing was performed by {{ snakemake.config['DEMULTIPLEXER']|join(" and ") }}.**
