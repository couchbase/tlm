#!/bin/bash

# Copyright 2017-Present Couchbase, Inc.
#
# Use of this software is governed by the Business Source License included in
# the file licenses/BSL-Couchbase.txt.  As of the Change Date specified in that
# file, in accordance with the Business Source License, use of this software
# will be governed by the Apache License, Version 2.0, included in the file
# licenses/APL2.txt.

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

./configure --prefix=${INSTALL_DIR} || exit 1
make && make install

# For MacOS, tweak install_name
if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -id @rpath/libz.1.dylib ${INSTALL_DIR}/lib/libz.1.dylib
fi
