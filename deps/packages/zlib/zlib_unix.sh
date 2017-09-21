#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

./configure --prefix=${INSTALL_DIR} || exit 1
make && make install
