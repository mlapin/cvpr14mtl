#!/bin/bash
#
# Adds diary files to the corresponding archive
#
set -e

SRC_DIR="$1"

process_dir() {
  # Find diary files
  local files=$(find "$1" -maxdepth 1 -name 'diary*.txt' -print)

  if [[ ${#files} -gt 0 ]]; then
    # Zip it
    echo "${files}" | zip -gjm "$1/diary.zip" -@
  else
    # Try subdirectories
    for subdir in "$1"/*; do
      if [[ -d "${subdir}" ]]; then
        process_dir "${subdir}"
      fi
    done
  fi
}

process_dir "${SRC_DIR}"
