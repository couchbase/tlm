#!/bin/bash -x

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

./autogen.sh || exit 1
./configure --prefix=${INSTALL_DIR} || exit 1
make && make install

# For MacOS, tweak install_name
# There really MUST be a better way to do this
if [ $(uname -s) = "Darwin" ]; then
    for libname in libpcre.1.dylib libpcrecpp.0.dylib libpcreposix.0.dylib; do
        install_name_tool -id @rpath/${libname} ${INSTALL_DIR}/lib/${libname}

        for deplib in libpcre.1.dylib libpcrecpp.0.dylib libpcreposix.0.dylib; do
            install_name_tool -change \
            ${INSTALL_DIR}/lib/${deplib} \
            @rpath/${deplib} \
            ${INSTALL_DIR}/lib/${libname}
        done
    done
fi
