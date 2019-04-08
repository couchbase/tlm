#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

./autogen.sh || exit 1
./configure --prefix=${INSTALL_DIR} || exit 1
git apply ${SCRIPTPATH}/numactl_define.patch
make -j8 && make install
rm -rf ${INSTALL_DIR}/bin ${INSTALL_DIR}/share
