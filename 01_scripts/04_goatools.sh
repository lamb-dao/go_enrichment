#!/bin/bash

#strict mode
set -euo pipefail
IFS=$'\n\t'

# Global variables
GO_DATABASE=02_go_database/go-basic.obo #
FISHER_FOLDER=06_fisher_tests #
ANNOTATIONS="${FISHER_FOLDER}/all_go_annotations.csv" #

ALL_IDS="all_ids.txt"
SIGNIFICANT_IDS="significant_ids.txt"

ENRICHMENT="${FISHER_FOLDER}/go_enrichment.csv"

# Before we can perform the Fisher tests, we need to generate two text files containing (one per line):

# TODO all ids
# - The names of **all** the analyzed transcripts, 'all_ids.txt'
&&& col 1 of sequence_annotation.csv

# TODO significant ids
# - The names of the **significant** transcripts, 'significant_ids.txt'
&&& col 1 of ENRICHMENT
OR col 1 of sequence_annotation when line has data
OR hand selected

# Running goa tools

# this was in the readme
#python2 scripts/find_enrichment.py --pval=0.05 --indent ../wanted_transcripts.ids ../all_ids.txt ../all_go_annotations.csv > ../go_annotation.tsv

echo "Running enrichment analysis..."
find_enrichment.py --pval=0.05 --indent \
                   --obo $GO_DATABASE \
                   $SIGNIFICANT_IDS \
                   $ALL_IDS \
                   $ANNOTATIONS \
                   --outfile $ENRICHMENT

echo "  --- Please find your results in '$ENRICHMENT' ---"


####
exit 1
####
In the context of a GO pipeline I find this partiall completed script. What could be the meaning of the 2 TODO items

The two TODO items in this script are related to generating input files for a Gene Ontology (GO) enrichment analysis using the GOATools package. Here's what they likely mean:

1. TODO all ids:
   This refers to creating a file named 'all_ids.txt' that should contain the IDs of all analyzed transcripts. The comment suggests extracting these IDs from column 1 of a file named 'sequence_annotation.csv'.

2. TODO significant ids:
   This involves creating a file named 'significant_ids.txt' containing IDs of transcripts considered significant. The comment provides three possible ways to obtain these IDs:
   - From column 1 of the ENRICHMENT file
   - From column 1 of 'sequence_annotation.csv', but only for lines containing data (possibly implying some filtering criteria)
   - Manual selection of IDs

These files are crucial inputs for the GO enrichment analysis performed by the 'find_enrichment.py' script. The 'all_ids.txt' file serves as the background set, while 'significant_ids.txt' contains the genes of interest for which enrichment is being tested.
