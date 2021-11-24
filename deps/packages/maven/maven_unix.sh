#!/bin/bash

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

tar zxf apache-maven-${VERSION}-bin.tar.gz || exit 1
cd apache-maven-${VERSION} || exit 1

cp -pr bin ${INSTALL_DIR}/ || exit 1
cp -pr boot ${INSTALL_DIR}/ || exit 1
cp -pr conf ${INSTALL_DIR}/ || exit 1
cp -pr lib ${INSTALL_DIR}/ || exit 1
