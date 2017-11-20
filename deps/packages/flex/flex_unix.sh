#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

tar zxf flex-${VERSION}.tar.gz || exit 1
cd flex-${VERSION} || exit 1
./configure --prefix=${INSTALL_DIR} || exit 1
make && make install

if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -id @rpath/libfl.2.dylib ${INSTALL_DIR}/lib/libfl.2.dylib
fi
