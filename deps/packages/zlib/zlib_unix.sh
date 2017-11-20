#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

./configure --prefix=${INSTALL_DIR} || exit 1
make && make install

# For MacOS, tweak install_name
if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -id @rpath/libz.1.dylib ${INSTALL_DIR}/lib/libz.1.dylib
fi
