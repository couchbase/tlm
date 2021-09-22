#!/bin/bash -ex

SRC_DIR=$1
CBDEP=$2
MINIFORGE_VERSION=$3
INSTALL_DIR=$4

# Clear positional parameters so "activate" works in a moment
set --

chmod 755 "${CBDEP}"

if [ $(uname -s) = "Darwin" ]; then
    platform=osx
else
    platform=linux-$(uname -m)
fi

# Install and activate Miniforge3
"${CBDEP}" install -d . miniforge3 ${MINIFORGE_VERSION}
. ./miniforge3-${MINIFORGE_VERSION}/bin/activate

# Install conda-build (to build our 'faked' packages) and conda-pack
conda install -y conda-build conda-pack conda-verify

# Build our local stub packages per platform. Currently the only platform-
# specific one is python-snappy, which is missing on conda-forge for
# linux-aarch64. Build that first, otherwise our hacked "pip" confuses it.
if [ -d "${SRC_DIR}/conda-pkgs/${platform}" ]; then
    conda build --output-folder "./conda-pkgs" "${SRC_DIR}/conda-pkgs/${platform}/*"
fi
conda build --output-folder "./conda-pkgs" "${SRC_DIR}/conda-pkgs/all/*"


# Create cbpy environment
conda create -y -n cbpy

# Populate cbpy environment - slightly different components per OS.
# Ensure that we use ONLY our locally-build packages and packages
# from conda-forge.
conda install -y \
    -n cbpy \
    -c ./conda-pkgs -c conda-forge \
    --override-channels --strict-channel-priority \
    --file "${SRC_DIR}/environment-base.txt" \
    --file "${SRC_DIR}/environment-${platform}.txt" \
    --file "${SRC_DIR}/environment-unix.txt"

# Pack cbpy and then unpack into final dir
conda pack -n cbpy --output cbpy.tar
conda deactivate
mkdir -p "${INSTALL_DIR}"
tar xf cbpy.tar -C "${INSTALL_DIR}"
rm cbpy.tar

# Prune installation
pushd "${INSTALL_DIR}"
rm -rf compiler_compat conda-meta include \
    lib/cmake lib/pkgconfig \
    lib/itcl* lib/tcl* lib/tk* \
    lib/python*/idlelib lib/python*/lib2to3 \
    lib/python*/tkinter \
    share/doc share/info share/man \
    $(uname -m)-conda*
cd bin
rm [0-9a-or-z]* pydoc* py*config
popd

# Quick installation test
"${INSTALL_DIR}/bin/python" "${SRC_DIR}/test_cbpy.py"