#!/bin/bash

# Copyright 2018-Present Couchbase, Inc.
#
# Use of this software is governed by the Business Source License included in
# the file licenses/BSL-Couchbase.txt.  As of the Change Date specified in that
# file, in accordance with the Business Source License, use of this software
# will be governed by the Apache License, Version 2.0, included in the file
# licenses/APL2.txt.

set -x

if [ $(uname -s) = "Darwin" ]; then
    XLOCALE_FILE=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/xlocale.h
else
    XLOCALE_FILE=/usr/include/xlocale.h
fi

LOCALE_FILE=/usr/include/locale.h

if [ ! -e ${XLOCALE_FILE} ]; then
    echo "$XLOCALE_FILE does not exist!"
    echo "Creating symlink for $XLOCALE_FILE ..."
    ln -s ${LOCALE_FILE} ${XLOCALE_FILE}
fi
