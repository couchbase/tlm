#!/usr/bin/env bash
set -e

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

if [ $(uname -s) != "Darwin" ]; then
    export LDFLAGS="-Wl,-rpath,'\$\$ORIGIN/../lib'"
fi

autoreconf -i
./configure --prefix=${INSTALL_DIR} \
            --disable-debug \
            --enable-optimize \
            --disable-warnings \
            --disable-werror \
            --disable-curldebug \
            --enable-shared \
            --disable-static \
            --without-libssh2
make all
make install

# Remove unneeded files
rm -rf ${INSTALL_DIR}/bin/curl-config
rm -rf ${INSTALL_DIR}/lib/pkgconfig
rm -rf ${INSTALL_DIR}/share
rm -f ${INSTALL_DIR}/lib/libcurl.la

# stuff
if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -id @rpath/libcurl.4.dylib ${INSTALL_DIR}/lib/libcurl.4.dylib
    install_name_tool -change ${INSTALL_DIR}/lib/libcurl.4.dylib @executable_path/../lib/libcurl.4.dylib ${INSTALL_DIR}/bin/curl
fi
