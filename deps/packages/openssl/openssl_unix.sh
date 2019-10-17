#!/bin/bash
set -e

INSTALL_DIR=$1
PLATFORM=$2
VERSION=$3

OS=`uname -s`
case "$OS" in
    Darwin)
        target=darwin64-x86_64-cc
        ;;
    Linux)
        target=linux-x86_64
        extra_flags=-Wl,--enable-new-dtags,-rpath,\''$$ORIGIN/../lib/'\'
        ;;
    *)
        echo "Unknown platform"
        exit 1
        ;;
esac

./Configure ${target} \
            enable-ec_nistp_64_gcc_128 \
            shared \
            threads \
            no-tests \
            no-ssl \
            no-ssl2 \
            no-ssl3 \
            --prefix=${INSTALL_DIR} \
            --openssldir=${INSTALL_DIR} \
            ${extra_flags}

# Note - don't use "make -j" as OpenSSL's target dependencies are messed up.
# There's a race which causes frequent build failures.
make && make install

if [ "$OS" == "Darwin" ]
then
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

    chmod u+w ${INSTALL_DIR}/lib/libssl.1.1.dylib \
              ${INSTALL_DIR}/lib/libcrypto.1.1.dylib \
              ${INSTALL_DIR}/bin/openssl
    install_name_tool -id @rpath/libssl.1.1.dylib \
                      ${INSTALL_DIR}/lib/libssl.1.1.dylib
    install_name_tool -change ${INSTALL_DIR}/lib/libcrypto.1.1.dylib \
                      @loader_path/libcrypto.1.1.dylib \
                      ${INSTALL_DIR}/lib/libssl.1.1.dylib
    install_name_tool -id @rpath/libcrypto.1.1.dylib \
                      ${INSTALL_DIR}/lib/libcrypto.1.1.dylib
    install_name_tool -change ${INSTALL_DIR}/lib/libssl.1.1.dylib \
                      @executable_path/../lib/libssl.1.1.dylib \
                      -change ${INSTALL_DIR}/lib/libcrypto.1.1.dylib \
                      @executable_path/../lib/libcrypto.1.1.dylib \
                      ${INSTALL_DIR}/bin/openssl
    chmod u-w ${INSTALL_DIR}/lib/libssl.1.1.dylib \
              ${INSTALL_DIR}/lib/libcrypto.1.1.dylib \
              ${INSTALL_DIR}/bin/openssl
fi

# We don't want the entire manual set added to the package
rm -rf ${INSTALL_DIR}/man
