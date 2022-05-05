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

configure_args="--prefix=${INSTALL_DIR} \
   --with-jemalloc-prefix=je_ \
   --disable-cache-oblivious \
   --disable-zone-allocator \
   --disable-initial-exec-tls \
   --disable-cxx"

# Profiling only supported on non-Darwin.
if [ $(uname -s) != "Darwin" ]; then
    configure_args+=" --enable-prof"
fi

# Re configure and build twice:
# - once for Release build (fully optimized, no runtime assertions)
# - once for Debug build (optimisation disable, runtime asserts enabled.
./autogen.sh ${configure_args}
make -j8 build_lib_shared
make -j8 check
make install_lib_shared install_include install_bin

# Note that jemalloc --with-debug by default disables all optimisations (-O0).
# This has a significant performance hit; we mostly want --with-debug for
# runtime assertions. As such, turn back on "optimise for debug" (-Og).
CFLAGS=-Og ./autogen.sh ${configure_args} --enable-debug \
    --with-install-suffix=d
make -j8 build_lib_shared
make -j8 check
make install_lib_shared

if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -id @rpath/libjemalloc.2.dylib ${INSTALL_DIR}/lib/libjemalloc.2.dylib
    install_name_tool -id @rpath/libjemallocd.2.dylib ${INSTALL_DIR}/lib/libjemallocd.2.dylib
fi
