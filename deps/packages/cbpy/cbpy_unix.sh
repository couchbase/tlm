#!/bin/bash -ex

SRC_DIR=$1
CBDEP=$2
MINICONDA_VERSION=$3
INSTALL_DIR=$4

CONSTRUCTOR_VERSION=3.2.1

# Clear positional parameters so "activate" works in a moment
set --

chmod 755 "${CBDEP}"

# Install and activate Miniconda3
"${CBDEP}" install -d . miniconda3-py39 ${MINICONDA_VERSION}
. ./miniconda3-${MINICONDA_VERSION}/bin/activate

# Install conda-build
conda install -y conda-build

# Download, build, and install constructor
git clone git://github.com/conda/constructor
conda build --output-folder "./conda-pkgs" $(pwd)/constructor/conda.recipe
conda install --channel "./conda-pkgs" constructor

# Build our local stub packages
conda build --output-folder "./conda-pkgs" ${SRC_DIR}/conda-pkgs/*

# Build cbpy environment - it'd be great if we could just list all these in a
# construct.yaml, but at least at the moment constructor produces broken
# installers when you add packages from a local-only channel. (No,
# channels_remap doesn't work either.)
conda env create -p ./cbpy-environment -f "${SRC_DIR}/environment.yaml" --force
conda env update -p ./cbpy-environment -f "${SRC_DIR}/environment-unix.yaml"
if [ $(uname -s) = "Darwin" ]; then
    platform=osx
else
    platform=linux-$(uname -m)
fi
conda env update -p ./cbpy-environment -f "${SRC_DIR}/environment-${platform}.yaml"

# Construct cbpy
mkdir -p constructor-cache
constructor --verbose --cache-dir ./constructor-cache --output-dir "${INSTALL_DIR}" "${SRC_DIR}"
rmdir "${INSTALL_DIR}/tmp"

# Has to have a .sh extension or else it whines about being run with bash
mv "${INSTALL_DIR}/cbpy-installer" "${INSTALL_DIR}/cbpy-installer.sh"

# Quick installation test
conda deactivate
bash "${INSTALL_DIR}/cbpy-installer.sh" -b -p "./cbpy"
"./cbpy/bin/python" -c "import requests"
