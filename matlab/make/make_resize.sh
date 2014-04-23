#!/bin/bash
#
# Creates a resized version of the original dataset
#

# Define what to convert and how
SRC_DIR="$1"
SRC_EXT="$2"
TRG_DIR="$3"
TRG_EXT="${4:-"png"}"
TRG_GEO="${5:-"100000@"}" # alternative: "500x500>"


# Loop over all subdirectories
for subdir in "${SRC_DIR}"/*/; do
  name=${subdir%*/}
  name=${name##*/}
  echo "Processing \`${name}'..."

  # Get file names
  fnames=$(find "${subdir}" -type f -name "*.${SRC_EXT}")

  # Re-create directory structure in the destination folder
  sed <<< "${fnames}" \
    -n -e "s|${SRC_DIR}\(.*\)/.*\.${SRC_EXT}|'${TRG_DIR}\1'|p" \
    | uniq \
    | xargs --verbose -l1 mkdir -p

  # Resize images
  sed <<< "${fnames}" \
    -n -e "s|${SRC_DIR}\(.*\)\.${SRC_EXT}|'&' '${TRG_DIR}\1.${TRG_EXT}'|p" \
    | xargs --verbose -l1 convert -resize "${TRG_GEO}"

done

# Fix files created from animated GIFs
# (e.g. /b/barndoor/sun_azgzzyckzvzwnxnl.jpg is a GIF in SUN397 and
# `convert` adds '-0', '-1', ... suffixes for each frame)
# Keep the first frame (-0)
find "${TRG_DIR}" -type f -regex "^.*/[^/]+-0\.${TRG_EXT}$" \
  -exec /bin/bash -c "mv -v \"{}\" \"\${0/-0.${TRG_EXT}/.${TRG_EXT}}\"" '{}' \;
# Remove any other frames (-1,...)
find "${TRG_DIR}" -type f -regex "^.*/[^/]+-[1-9][0-9]*\.${TRG_EXT}$" \
  -delete
