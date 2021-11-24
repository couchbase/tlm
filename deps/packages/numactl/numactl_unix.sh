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

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

./autogen.sh || exit 1
./configure --prefix=${INSTALL_DIR} || exit 1
git apply ${SCRIPTPATH}/numactl_define.patch
make -j8 && make install
rm -rf ${INSTALL_DIR}/bin ${INSTALL_DIR}/share
