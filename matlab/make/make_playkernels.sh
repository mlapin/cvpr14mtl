#!/bin/bash
#
# Downloads kernels for the playground.m script
#

KERNELS="${1:-data/kernels}"
BASEURL="${2:-http://datasets.d2.mpi-inf.mpg.de/lapin14cvpr}"
KERNELSXIAO="${3:-data/kernels_xiao10}"
BASEURLXIAO="${4:-http://vision.princeton.edu/projects/2010/SUN}"

echo "Downloading a subset of kernels from ${BASEURL}..."
mkdir -p "${KERNELS}"
pushd "${KERNELS}"
wget -nc -v "${BASEURL}/Train-S01-N05-SIFT-LCS-PN-L2-Khell.mat"
wget -nc -v "${BASEURL}/Test-S01-N05-SIFT-LCS-PN-L2-Khell.mat"
wget -nc -v "${BASEURL}/meta-S01-N05-SIFT.mat"
wget -nc -v "${BASEURL}/meta-S01-N50-SIFT.mat"
popd
echo "Done."

echo "Downloading a subset of kernels from ${BASEURLXIAO}..."
mkdir -p "${KERNELSXIAO}"
pushd "${KERNELSXIAO}"
wget -nc -v "${BASEURLXIAO}/Train_all__split_01__combine__weighted_F__bow_F__normalize_F__.mat"
wget -nc -v "${BASEURLXIAO}/Test_all__split_01__combine__weighted_F__bow_F__normalize_F__.mat"
popd
echo "Done."
