# go_enrichment

Transcripts annotation and GO enrichment Fisher tests

## Overview

`go_enrichment` annotates transcript sequences and performs GO enrichment
Fisher tests. The transcript sequences are blasted against the swissprot
protein database and the uniprot information corresponding to the hit is
retrieved from the uniprot website. Fisher tests are performed with the
`goatools` Python module.

## Prerequisites

To use `go_enrichment`, you will need a UNIX system (Linux or Mac OSX) and conda. 
Conda will be used to create an environment with the software dependencies.
- `wget`
- `gnu parallel`
- `ncbi blast+ version greater than 2.7.1`
- `goatools version greater than 1.1.7`

You will also need to manually install these database resources
- `swissprot` blast database ftp://ftp.ncbi.nlm.nih.gov/blast/db/swissprot.tar.gz
- `GO database` (see GO database section below)

## Installation
### Create and activate the conda environment

Create the environment
```
cd 01_scripts
conda env create -f environment.yaml
cd ..
```

Activate the environment and test each tool is present
```
conda activate go_enrichment
wget -V
parallel --help
blastn -version

# ensure goatools on PATH
which find_enrichment.py
```

### Swissprot database

We will use wget to download the `swissprot` databases.

```
# Create a temporary bash session
bash

# Create folder to contain the databases
mkdir ~/blastplus_databases
cd ~/blastplus_databases

# Downloading the database
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/swissprot.*

# Confirming the integrity of the downloaded files
cat *.md5 | md5sum -c

# Decompressing
for file in `ls -1 swissprot.*.gz`; do tar -xzf $file ; done

# Exit temporary bash session
exit
```

### GO database

Installing the GO database will be faster:

```
# Create a temporary bash session
bash

# Moving to the GO database folder
cd 02_go_database

# Downloading the GO databases
wget http://geneontology.org/ontology/go-basic.obo

# Exit temporary bash session
exit
```

## Workflow

This is a brief description of the steps as well as the input and output formats expected by `go_enrichment`.

### Step 0 - Files and Variables

Put your sequences of interest in the `03_sequences` folder in a file named
`transcriptome.fasta`. If you use another name, you will need to modify the
`SEQUENCE_FILE` variable in the `blast_against_swissprot.py` script.

Modifying the `SWISSPROT_DB` variable may be useful if you prefer the script to point to a previously installed blastplus database in a different location.

The following steps are executed by the `piper.sh` pipeline.
- blast
- annotationData
- annotateTranscripts
- goatools
- filter

activate the environment with `conda activate go_enrichment`
call piper with `./run.sh`
or manually execute the following steps

### Step 1 - Blast against swissprot

Then run:

```
./01_scripts/01_blast_against_swissprot.sh
```

### Step 2 - Get annotation information from uniprot

This step will use the blast results to download the information of the genes
to which the transcript sequences correspond.

Run:

```
./01_scripts/02_get_uniprot_info.sh
```

### Step 3 - Annotate the transcripts

Use this step to create a .csv file containing the transcript names as well as
some annotation information (Name, Accession, Fullname, Altnames, GO).

Run:

```
./01_scripts/03_annotate_genes.py 03_sequences/transcriptome.fasta 05_annotations/ sequence_annotation.txt
```

### Step 4 - Extract genes

Before we can perform the Fisher tests, we need to generate two text files containing (one per line):
- The names of **all** the analyzed transcripts, 'all_ids.txt'   
- The names of the **significant** transcripts, 'significant_ids.txt'    

### Step 5 - Run `goatools`

**WARNING!** This is currently broken. Follow the next steps to use goatools:

#### Install goatools
See Installation section, including getting the GO databases
[https://github.com/tanghaibao/goatools](https://github.com/tanghaibao/goatools)

#### Run goatools
```
python2 scripts/find_enrichment.py --pval=0.05 --indent ../wanted_transcripts.ids ../all_ids.txt ../all_go_annotations.csv > ../go_annotation.tsv
```
This script will launch `goatools` and perform the Fisher tests. Note: edit the script to point to your own installation of `find_enrichment.py`    

 TODO put back in the following script
```
./01_scripts/04_goatools.sh
```

### Step 6 - Filter `goatools` results

### **WARNING!**
This script no longer works with goatools 1.1.6. Better to filter by hand.

We can now reformat the results of `goatools` to make them more useful.

```
./01_scripts/05_filter_goatools.py enrichment.csv 02_go_database/go-basic.obo filtered.csv
```

## Licence

`go_enrichment` is licensed under the GPL3 license. See the LICENCE file for
more details.
