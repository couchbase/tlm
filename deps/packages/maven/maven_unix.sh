#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

tar zxf apache-maven-${VERSION}-bin.tar.gz || exit 1
cd apache-maven-${VERSION} || exit 1

cp -pr bin ${INSTALL_DIR}/ || exit 1
cp -pr boot ${INSTALL_DIR}/ || exit 1
cp -pr lib ${INSTALL_DIR}/ || exit 1
