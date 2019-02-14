#!/bin/bash

INSTALL_DIR=$1

./autogen.sh || exit 1
CPPFLAGS=-I/usr/local/include ./configure \
    --prefix=${INSTALL_DIR} \
    --with-jemalloc-prefix=je_ \
    --disable-cache-oblivious \
    --disable-zone-allocator \
    --disable-initial-exec-tls \
    --enable-prof || exit 1
make build_lib_shared && make install_lib_shared install_include install_bin

if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -id @rpath/libjemalloc.2.dylib ${INSTALL_DIR}/lib/libjemalloc.2.dylib
fi
