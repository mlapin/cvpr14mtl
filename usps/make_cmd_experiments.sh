#!/bin/bash
#
# Creates a list of commands for running experiments
#

CMD_NAME="$1"
SSIZES="$2"
EPS1S="$3"
EPS2S="$4"

CMD_FILE="cmd_${CMD_NAME##*/}"

# Make a command
if [[ ! "${CMD_NAME}" =~ '/' ]]; then
  CMD_NAME="./${CMD_NAME}"
fi

# Check that the binary exists and is executable
if [[ ! -x "${CMD_NAME}" ]]; then
  echo "Not an executable: ${CMD_NAME}"
  exit 1
fi

# Remove the commands file (if any)
rm -f "${CMD_FILE}.txt"

# Create a command for sample size, etc.
for ssz in ${SSIZES}; do
  for eps1 in ${EPS1S}; do
    for eps2 in ${EPS2S}; do
      echo "${CMD_NAME} ${ssz} ${eps1} ${eps2}" >> "${CMD_FILE}.txt"
    done
  done
done
