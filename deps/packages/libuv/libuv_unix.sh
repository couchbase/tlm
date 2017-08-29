#!/bin/bash

INSTALL_DIR=$1

# Unix build without gyp
./autogen.sh   || exit 1
./configure --disable-silent-rules --prefix=${INSTALL_DIR} || exit 1
make &&  make install
