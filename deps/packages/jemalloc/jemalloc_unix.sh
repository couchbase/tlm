#!/bin/bash

# Copyright 2017-Present Couchbase, Inc.
#
# Use of this software is governed by the Business Source License included in
# the file licenses/BSL-Couchbase.txt.  As of the Change Date specified in that
# file, in accordance with the Business Source License, use of this software
# will be governed by the Apache License, Version 2.0, included in the file
# licenses/APL2.txt.

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
