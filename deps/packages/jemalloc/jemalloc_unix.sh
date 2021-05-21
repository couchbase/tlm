#!/bin/bash

set -e

INSTALL_DIR=$1

# Profiling only supported on non-Darwin.
if [ $(uname -s) != "Darwin" ]; then
    extra_configure_args="--enable-prof"
fi

./autogen.sh
CPPFLAGS=-I/usr/local/include ./configure \
    --prefix=${INSTALL_DIR} \
    --with-jemalloc-prefix=je_ \
    --disable-cache-oblivious \
    --disable-zone-allocator \
    --disable-initial-exec-tls \
    ${extra_configure_args}
make -j8 build_lib_shared
make -j8 check
make install_lib_shared install_include install_bin

if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -id @rpath/libjemalloc.2.dylib ${INSTALL_DIR}/lib/libjemalloc.2.dylib
fi
