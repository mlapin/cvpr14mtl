#!/bin/bash
#
# Moves cache folders around
#
set -e

SRC_DIR="$1"
TRG_DIR="$2"
MOVE_DIR="${3:-"cache"}"


process_subdirs() {
  for subdir in "$1"/*; do
    if [[ -d "${subdir}" && ! -h "${subdir}" ]]; then
      if [[ "${subdir##*/}" = "${MOVE_DIR}" ]]; then
        move_dir "${subdir}"
      #elif [[ ! "${subdir}" =~ .*S01.* ]]; then
      else
        process_subdirs "${subdir}"
      #else
      #  echo "Skip: ${subdir}"
      fi
    fi
  done
}

move_dir() {
  local src="$1"
  local trg="$TRG_DIR/${1%/*}"
  local name="${1##*/}"
  printf "Moving: \`${src}' to \`${trg}'\nin..."
  for i in {3..1}; do
    printf "$i..."
    sleep 1s
  done
  echo

  mkdir -p "${trg}" \
    && rsync -av --remove-source-files "${src}" "${trg}" \
    && rm -rf "${src}" \
    && ln -s "${trg}/${name}" "${src}"
}

process_subdirs "${SRC_DIR}"
