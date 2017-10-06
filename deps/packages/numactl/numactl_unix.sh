#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

./autogen.sh || exit 1
./configure --prefix=${INSTALL_DIR} || exit 1
make -j8 && make install
rm -rf ${INSTALL_DIR}/bin ${INSTALL_DIR}/share
