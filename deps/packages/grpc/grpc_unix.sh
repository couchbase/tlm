#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

# Build in /tmp due to grpc's header install being braindead
rm -rf /tmp/grpc /tmp/install && mkdir /tmp/grpc && cp -a . /tmp/grpc
cd /tmp/grpc
make prefix=/tmp/install install
cp -a /tmp/install/* ${INSTALL_DIR}
cd
rm -rf /tmp/install

# For MacOS, tweak install_name
if [ $(uname -s) = "Darwin" ]; then
    for grpc_lib in libgrpc_cronet.dylib libaddress_sorting.dylib libgrpc++_error_details.dylib libgrpc.dylib libgrpc++.dylib libgrpc_unsecure.dylib libgpr.dylib libgrpc++_cronet.dylib libgrpc++_unsecure.dylib libgrpc++_reflection.dylib libgrpcpp_channelz.dylib; do
        install_name_tool -id @rpath/${grpc_lib} ${INSTALL_DIR}/lib/${grpc_lib}
    done
fi
