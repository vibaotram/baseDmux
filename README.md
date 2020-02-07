# BASEcalling and DeMUltipleXing
## workflow for ONT sequencing data

The workflow will be available in local computer as well as cluster environment.


**Install**
```
git clone https://github.com/vibaotram/baseDmux.git, or
git clone git@github.com:vibaotram/baseDmux.git
```

**Usage**

```
**Locally:**
snakemake --use-singularity --use-conda --cores 4 -p --verbose --report report.html
```


```
**On cluster:**
 snakemake --use-singularity --use-conda --cores 4 -p --verbose -j 999 \
 --cluster-config cluster.json \
 --cluster "sbatch --job-name {cluster.job-name}
-p {cluster.partition} \
-t {cluster.time} \
--output {cluster.output} \
--error {cluster.error} \
--nodes {cluster.nodes} \
--ntasks {cluster.ntasks} \
--cpus-per-task {cluster.cpus} \
--mem {cluster.mem}" \
--mail-user {cluster.mail-user} \
--mail-type {cluster.mail-type}"
--report report.html
```
