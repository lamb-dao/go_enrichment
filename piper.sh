#!/usr/bin/env bash

#strict mode
# https://gist.github.com/robin-a-meade/58d60124b88b60816e8349d1e3938615
set -euo pipefail
IFS=$'\n\t'

# tough, simple and airworthy pipeline template
# TODO ascii airplane
echo "===/-O-\=== Begin piper run!  ===/-O-\==="

# TODO add note on required environment

## use arg to set flag to skip interactive use
runMode=all
flag="${1:-default}"
if [ "${flag}" == "batch" ]; then
    runMode="${1}"
fi

## Setup mandatory locations
home=$(pwd)
checkpoints=${home}/checkpoints
# piper requires checkpoints; -p will check and create if necessary
mkdir -p ${checkpoints}

## create paths to recommended locations
input=${home}/input
data=${home}/data
scripts=${home}/scripts
output=${home}/output

#### functions
function doStep () {
    # doStep stepName, to check if a step is incomplete, returns true if step is required
    ( cd ${checkpoints}
      n=$(ls -1 $1 2>/dev/null | wc -l)
      if [ "$n" -ne 1 ]; then
          #do it
          echo "check: $1 requires completion"
          return 0
      else
          #it is done
          echo "check: $1 is marked complete"
          return 1
    fi
    )
}

function userApprove () {
    #batch mode, no interactive user,  assume approval for all step
    if [ "${runMode}" == "batch" ]; then
        echo "Continuing"
        return 0
    fi
    # user continue or exit
    read -p "To continue enter y: " continue
    if [ "${continue}" != "y" ]; then
        echo "Exiting"
        exit 0
    fi
}

function markStep () {
    # markStep add stepname, to mark complete
    # markStep del stepname, to remove mark
    ( cd ${checkpoints}
      if [ "${1}" == "add" ]; then
          echo "check: ${2} will be marked complete"
          touch ${2}
      fi
      if [ "${1}" == "del" ]; then
          echo "check: ${2} will be UN marked"
          rm -f ${2}
      fi
    )
}

#begin block comment
:<<'MASK'

#end block comment
MASK

#===================
# clean data for this run, leave input and checkpoints
step="sweep_Begin"
if( doStep ${step} ); then
    echo "BEGIN: ${step}"
    userApprove
    mkdir -p ${data}
    rm -r ${data}
    mkdir -p ${data}
    touch ${data}/.gitkeep

    # for some uses cleaning output is recommended for guaranteed fresh results
    # for other uses the finalize (vvv) step is useful for dropping sets of data in output
    # mkdir -p ${output}
    # rm -r ${output}
    # mkdir -p ${output}
    # touch ${output}/.gitkeep

    markStep add $step
fi
#===================

#===================
step="blast"
#markStep del $step #force do
#markStep add $step #force skip
if( doStep $step ); then
    echo "BEGIN: ${step}"
    userApprove
    ( cd ${data}
      ../01_scripts/01_blast_against_swissprot.sh
      echo -e "PIPER\t${step}"
    )
    markStep add $step
fi
#===================

#===================
step="annotationData"
#markStep del $step #force do
#markStep add $step #force skip
if( doStep $step ); then
    echo "BEGIN: ${step}"
    userApprove
    ( cd ${data}
      ../01_scripts/02_get_uniprot_info.sh
      echo -e "PIPER\t${step}"
    )
    markStep add $step
fi
#===================

#===================
step="annotateTranscripts"
#markStep del $step #force do
#markStep add $step #force skip
if( doStep $step ); then
    echo "BEGIN: ${step}"
    userApprove
    ( cd ${data}
      ../01_scripts/03_annotate_genes.py \
          03_sequences/transcriptome.fasta \
          05_annotations/ \
          sequence_annotation.txt
      echo -e "PIPER\t${step}"
    )
    markStep add $step
fi
#===================

#===================
step="extractGenes"
in="${out}" #grab last steps output
out="${step}.filetype" #set this steps major target
#markStep del $step #force do
#markStep add $step #force skip
if( doStep $step ); then
    echo "BEGIN: ${step}"
    userApprove
    ( cd ${data}
      echo "This step will do some action on ${in}" > ${out}
      exitStatus=$?
      # tab delimited data from action steps, must begin with PIPER\t${step}\t
      echo -e "PIPER\t${step}\tFiles:\t${in}\t${out}\tExitStatus:\t${exitStatus}"
    )
    markStep add $step
fi
#===================

#===================
step="goatools"
in="${out}" #grab last steps output
out="${step}.filetype" #set this steps major target
#markstep del $step #force do
#markstep add $step #force skip
if( dostep $step ); then
    echo "begin: ${step}"
    userapprove
    ( cd ${data}
      #python 2 or 3 &&&
      find_enrichment.py \
          --pval=0.05 \
          --indent \
          ../wanted_transcripts.ids \
          ../all_ids.txt \
          ../all_go_annotations.csv \
          > ../go_annotation.tsv
      echo -e "piper\t${step}"
    )
    markstep add $step
fi
#===================

#===================
step="filter"
#markstep del $step #force do
#markstep add $step #force skip
if( dostep $step ); then
    echo "begin: ${step}"
    userapprove
    ( cd ${data}
      ../01_scripts/05_filter_goatools.py \
          enrichment.csv \
          02_go_database/go-basic.obo \
          filtered.csv
      echo -e "piper\t${step}"
    )
    markstep add $step
fi
#===================

#===================
# for this run extract summary lines from full log for inter-run comparison
step="piper_summary"
#markStep del $step #force do
#markStep add $step #force skip
if( doStep $step ); then
    echo "BEGIN: ${step}"
    userApprove
    cat log*.txt | grep PIPER > ${data}/summary.raw.txt
    #log is cumulative of all runs, to get last instance of a step, flip and take first unique
    ( cd ${data}
      tac summary.raw.txt \
          | awk '!seen[$2]++' \
          | tac - \
          > summary.txt
    )
    markStep add $step
fi
#===================

:<<'MASK'
#===================
# create a unique dir of outputs for this run, log summary and files.
# when complete place in main outputs dir
step="finalize"
#markStep del $step #force do
#markStep add $step #force skip
if( doStep $step ); then
    echo "BEGIN: ${step}"
    userApprove
    cp log*.txt ${data}
    # TODO cat a copy of this file as well so step arguments are documented
    ( cd ${data}
      #attach an important input file name to the dirname of these outputs for tracking
      # TODO USER set for current use
      #eg: get a vcf file, strip the filetype
      runName=$(cd ${input}; n="*.vcf"; echo ${n} | sed s/.vcf//)
      op="OP_${runName}"

      #make new unique dir
      rm -r ${op} || echo ""
      mkdir -p ${op}/logs
      #package logging outputs
      cp summary.txt ${op}
      cp log*.txt ${op}/logs
      #package data outputs
      # TODO USER set files being copied for current use
      # cp *.vcf ${op}
      # cp *.log ${op}/logs #error here
      # cp *.pdf ${op}
      # cp *.png ${op}

      #push the complete set of outputs once
      mv -f ${op} ${output}
    )
    markStep add $step
fi
#===================

#===================
# full reset for the next run. Remove inputs, checkpoints, run data, run logs
step="sweep_End"
#markStep del $step #force do
markStep add $step #force skip by default. This step removes all input, ensure original files are archived.
if( doStep $step ); then
    echo "BEGIN: ${step}"
    userApprove
    ( cd ${input}
      rm * || echo ""
      cd ${checkpoints}
      rm * || echo ""
      cd ${data}
      rm -r * || echo ""
      cd ..
      rm log*.txt
    )
fi
#===================

MASK



###################################
echo "===/-O-\=== End of piper run!  ===/-O-\==="
exit 0
###################################

#===================
step="templateStep"
in="${out}" #grab last steps output
out="${step}.filetype" #set this steps major target
#markStep del $step #force do
#markStep add $step #force skip
if( doStep $step ); then
    echo "BEGIN: ${step}"
    userApprove
    ( cd ${data}
      echo "This step will do some action on ${in}" > ${out}
      exitStatus=$?
      # tab delimited data from action steps, must begin with PIPER\t${step}\t
      echo -e "PIPER\t${step}\tFiles:\t${in}\t${out}\tExitStatus:\t${exitStatus}"
    )
    markStep add $step
fi
#===================