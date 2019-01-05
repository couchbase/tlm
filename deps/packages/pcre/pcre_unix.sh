#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

./autogen.sh || exit 1
./configure --prefix=${INSTALL_DIR} || exit 1
make && make install

# For MacOS, tweak install_name
if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -id @rpath/libpcre.1.dylib ${INSTALL_DIR}/lib/libpcre.1.dylib
    install_name_tool -id @rpath/libpcrecpp.0.dylib ${INSTALL_DIR}/lib/libpcrecpp.0.dylib
    install_name_tool -id @rpath/libpcreposix.0.dylib ${INSTALL_DIR}/lib/libpcreposix.0.dylib
fi
