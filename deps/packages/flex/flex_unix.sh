#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

# Build and install m4, then add to path
tar zxf m4-1.4.18.tar.gz || exit 1
pushd m4-1.4.18 || exit 1
./configure --prefix=${INSTALL_DIR} || exit 1
make && make install
popd || exit 1
PATH=${INSTALL_DIR}/bin:$PATH

# Build and install flex
tar zxf flex-${VERSION}.tar.gz || exit 1
pushd flex-${VERSION} || exit 1
./configure --prefix=${INSTALL_DIR} || exit 1
make && make install

if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -id @rpath/libfl.2.dylib ${INSTALL_DIR}/lib/libfl.2.dylib
fi
