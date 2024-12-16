#!/bin/bash

#strict mode
set -euo pipefail
IFS=$'\n\t'

# Global variables
SWISSPROT_HITS=04_blast_results/analyzed_genes.hits
ANNOTATION_FOLDER=05_annotations
FISHER_FOLDER=06_fisher_tests

# Get info from uniprot for each hit in parallel
echo "Prepare uniprot sequences for retrieval"
cat $SWISSPROT_HITS | while read i; do feature=$(echo $i | cut -d " " -f 1) hit=$(echo $i | cut -d " " -f 2 | cut -d "." -f 1); echo "wget -q -O - http://www.uniprot.org/uniprot/${hit}.txt > $ANNOTATION_FOLDER/${feature}.info"; done > .temp_wget_commands.txt

echo "Download info from uniprot"
cat .temp_wget_commands.txt | parallel -j 20 "eval {}"
#rm .temp_wget_commands.txt

# Extract wanted info
echo "Retrieve GO terms from downloaded info"
for i in $ANNOTATION_FOLDER/*.info; do echo -e "$(basename $i | perl -pe 's/\.info//')\t$(cat $i | grep -E '^DR\s+GO' | awk '{print $3}' | perl -pe 's/\n//')"; done > $FISHER_FOLDER/all_go_annotations.csv

#Test if input and output linecount are same
hits_count=$(wc -l < "$SWISSPROT_HITS")
csv_count=$(wc -l < "$FISHER_FOLDER/all_go_annotations.csv")
if [ "$hits_count" -ne "$csv_count" ]; then
    echo "Error: Line count mismatch between $SWISSPROT_HITS ($hits_count) and $FISHER_FOLDER/all_go_annotations.csv ($csv_count). The operation in 02_get_uniprot_info.sh may not have completed correctly."
    exit 1
fi
