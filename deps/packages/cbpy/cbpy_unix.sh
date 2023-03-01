#!/bin/bash -ex

# Copyright 2021-Present Couchbase, Inc.
#
# Use of this software is governed by the Business Source License included in
# the file licenses/BSL-Couchbase.txt.  As of the Change Date specified in that
# file, in accordance with the Business Source License, use of this software
# will be governed by the Apache License, Version 2.0, included in the file
# licenses/APL2.txt.

SRC_DIR=$1
CBDEP=$2
MINIFORGE_VERSION=$3
PYTHON_VERSION=$4
INSTALL_DIR=$5

# Clear positional parameters so "activate" works in a moment
set --

# "conda" being a shell function makes the bash -x output impossible to
# follow, so work around it
doconda() {
    set +x
    conda "$@"
    set -x
}

chmod 755 "${CBDEP}"

if [ $(uname -s) = "Darwin" ]; then
    platform=macosx-$(uname -m)
else
    platform=linux-$(uname -m)
fi

# Install and activate Miniforge3
"${CBDEP}" install -d . miniforge3 ${MINIFORGE_VERSION}
set +x
echo "+ <activating conda>"
# This is how to 'activate' conda without needing to modify .bashrc, etc.
source ./miniforge3-${MINIFORGE_VERSION}/etc/profile.d/conda.sh
conda activate base
set -x

# Create and activate a builder environment, with our desired version of
# python and the latest compatible conda-build/conda-pack/conda-verify.
# It's important to build our local packages in an environment with the
# same versin of python that we will bundle in cbpy, and this is the
# safest way to achieve that.
doconda create -y -n builder python=${PYTHON_VERSION} conda-build conda-pack conda-verify
conda activate builder

# Build our local packages and stubs per platform.
for subdir in ${platform} all stubs
do
    if [ -d "${SRC_DIR}/conda-pkgs/${subdir}" ]
    then
        doconda build --output-folder "./conda-pkgs" "${SRC_DIR}/conda-pkgs/${subdir}/*"
    fi
done

# Create cbpy environment with all our dependencies
doconda create -y -n cbpy \
    -c ./conda-pkgs -c conda-forge \
    --override-channels --strict-channel-priority \
    python=${PYTHON_VERSION} \
    --file "${SRC_DIR}/cb-dependencies.txt" \
    --file "${SRC_DIR}/cb-dependencies-${platform}.txt" \
    --file "${SRC_DIR}/cb-stubs.txt"

# Remove gmp (pycryptodome soft dep)
if doconda list -n cbpy gmp | grep gmp
then
    doconda remove -n cbpy gmp -y --force
fi

# Pack cbpy and then unpack into final dir
doconda pack -n cbpy --output cbpy.tar
mkdir -p "${INSTALL_DIR}"
tar xf cbpy.tar -C "${INSTALL_DIR}"
rm cbpy.tar

# Save the environment for future reference
pushd "${INSTALL_DIR}"
mkdir env
doconda list -n cbpy > env/environment-${platform}.txt
doconda env export -n cbpy > env/environment-${platform}.yml

# Deactivate builder environment, then base environment
doconda deactivate
doconda deactivate

# Ensure lib files are codesigned on Mac so that they can be loaded.
# Maybe we need to expand this to Mac x86_64.
# Temporarily add "set +e" to avoid exit due to "codesign --display" error
set +e
 if [ ${platform} = "osx-arm64" ]; then
     for f in $(find . -name '*.dylib' -type f); do
        codesign --display "$f"
        if [ $? -ne 0 ]; then
             codesign --force --deep -s - "$f"
         fi
     done
 fi
set -e

# Prune installation
find . -depth -type d -name tests -exec rm -rf \{} \;
find . -depth -type d -name info -exec rm -rf \{} \;
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
