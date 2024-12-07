#!/usr/bin/env bash

#strict mode
set -euo pipefail
IFS=$'\n\t'

## these calls all ensure nice log file handling
# single input interactive mode
# ./run.sh

./piper.sh 2>&1 | tee -a log.txt
