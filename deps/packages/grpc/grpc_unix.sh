#!/bin/bash -ex

# Copyright 2018-Present Couchbase, Inc.
#
# Use of this software is governed by the Business Source License included in
# the file licenses/BSL-Couchbase.txt.  As of the Change Date specified in that
# file, in accordance with the Business Source License, use of this software
# will be governed by the Apache License, Version 2.0, included in the file
# licenses/APL2.txt.

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3
CBDEPS_DIR=$4

# Build and install cares and protobuf from third_party
cd third_party/protobuf/cmake
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -Dprotobuf_BUILD_TESTS=OFF \
  -D CMAKE_PREFIX_PATH="${CBDEPS_DIR}/zlib.exploded" \
  ..
make -j8 install
cd ../../../..

# Build grpc binaries and libraries
mkdir .build
cd .build
cmake -D CMAKE_BUILD_TYPE=RelWithDebInfo \
  -D CMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
  -D CMAKE_PREFIX_PATH="${CBDEPS_DIR}/zlib.exploded;${CBDEPS_DIR}/openssl.exploded;${INSTALL_DIR}" \
  -DgRPC_INSTALL=ON \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DgRPC_BUILD_TESTS=OFF \
  -DgRPC_PROTOBUF_PROVIDER=package \
  -DgRPC_ZLIB_PROVIDER=package \
  -DgRPC_CARES_PROVIDER=module \
  -DCARES_STATIC_PIC=ON \
  -DgRPC_SSL_PROVIDER=package \
  ..
make -j8 install

exit 0
