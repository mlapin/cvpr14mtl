#!/bin/bash
#
# Creates a list of commands for running experiments
#

SRC_DIR="$1"
CMD_NAME="${2:-"seval"}"
SPLITS="${3:-"1"}"
SSIZES="${4:-"50"}"
KERNELS="${5:-"hell"}"
EXS="${6:-"S"}"
C1S="${7:-""}"
C2S="${8:-""}"
SUFFIX="${9:-""}"

CMD_FILE="cmd_mtl_${CMD_NAME##*/}${SUFFIX}"

# Make a command
if [[ ! "${CMD_NAME}" =~ '/' ]]; then
  CMD_NAME="./${CMD_NAME}"
fi

# Check that the binary exists and is executable
if [[ ! -x "${CMD_NAME}" ]]; then
  echo "Not an executable: ${CMD_NAME}"
  exit 1
fi

# Loop over all experiment scripts
for fpath in "${SRC_DIR}"/*; do
  name=${fpath%*/}
  name=${name##*/}
  echo "Processing \`${name}'..."

  # Remove the commands file (if any)
  rm -f "${CMD_FILE}-${name}.txt"

  # Create a command for each split, sample size, and kernel
  for krn in ${KERNELS}; do
    for splt in ${SPLITS}; do
      for ssz in ${SSIZES}; do
        for ex in ${EXS}; do
          if [[ -z "${C1S}" ]]; then
            echo "${CMD_NAME} '${fpath}' ${splt} ${krn} ${ssz} ${ex}" \
                >> "${CMD_FILE}-${name}.txt"
          else
            for c1 in ${C1S}; do
              for c2 in ${C2S}; do
                echo "${CMD_NAME} '${fpath}' ${splt} ${krn} ${ssz} ${ex} ${c1} ${c2}" \
                  >> "${CMD_FILE}-${name}.txt"
              done
            done
          fi
        done
      done
    done
  done
done
