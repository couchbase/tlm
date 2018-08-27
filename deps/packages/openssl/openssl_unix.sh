#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

# NOTE: This script currently ONLY works on macOS and will need modifications
#       for any form of Linux/Unix

./Configure darwin64-x86_64-cc shared enable-ec_nistp_64_gcc_128 \
  no-comp no-ssl2 no-ssl3 --openssldir=${INSTALL_DIR} || exit 1
make depend || exit 1
# Note - don't use "make -j" as OpenSSL's target dependencies are messed up.
# There's a race which causes frequent build failures.
make  && make install || exit 1

rm ${INSTALL_DIR}/lib/libcrypto.a ${INSTALL_DIR}/lib/libssl.a

# NOTE: The below loop actually doesn't do anything; the libraries under
#       lib/engines are actually bundles on macOS and not shared libraries,
#       so the install_name_tool is a no-op.  Setting the install name
#       MAY be doable via compile time options, but this would require
#       further research.  Leaving the code here with a note for possible
#       future exploration into the issue.
for lib in $(ls ${INSTALL_DIR}/lib/engines); do
    chmod u+w ${INSTALL_DIR}/lib/engines/${lib}
    install_name_tool -id @rpath/${lib} ${INSTALL_DIR}/lib/engines/${lib}
    chmod u-w ${INSTALL_DIR}/lib/engines/${lib}
done

chmod u+w ${INSTALL_DIR}/lib/libssl.1.0.0.dylib ${INSTALL_DIR}/lib/libcrypto.1.0.0.dylib ${INSTALL_DIR}/bin/openssl
install_name_tool -id @rpath/libssl.1.0.0.dylib ${INSTALL_DIR}/lib/libssl.1.0.0.dylib
install_name_tool -change ${INSTALL_DIR}/lib/libcrypto.1.0.0.dylib @loader_path/libcrypto.1.0.0.dylib ${INSTALL_DIR}/lib/libssl.1.0.0.dylib
install_name_tool -id @rpath/libcrypto.1.0.0.dylib ${INSTALL_DIR}/lib/libcrypto.1.0.0.dylib
install_name_tool -change ${INSTALL_DIR}/lib/libssl.1.0.0.dylib @executable_path/../lib/libssl.1.0.0.dylib -change ${INSTALL_DIR}/lib/libcrypto.1.0.0.dylib @executable_path/../lib/libcrypto.1.0.0.dylib ${INSTALL_DIR}/bin/openssl
chmod u-w ${INSTALL_DIR}/lib/libssl.1.0.0.dylib ${INSTALL_DIR}/lib/libcrypto.1.0.0.dylib ${INSTALL_DIR}/bin/openssl

# We don't want CMake to "find" these libraries in the exploded directory,
# only headers, so we hide the lib directory. CMakeLists_package.txt will
# handle copying them to the INSTALL directory where we want CMake to find
# them.
mkdir ${INSTALL_DIR}/package
mv ${INSTALL_DIR}/lib ${INSTALL_DIR}/package
