#!/bin/bash
#
# Downloads kernels for the playground.m script
#

KERNELS="${1:-data/kernels}"
BASEURL="${2:-http://datasets.d2.mpi-inf.mpg.de/lapin14cvpr}"

echo "Downloading all available kernels from ${BASEURL}..."
mkdir -p "${KERNELS}"
pushd "${KERNELS}"
wget -nc -v -i "${BASEURL}/All-Kernels.txt"
popd
echo "Done."
