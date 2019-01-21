#!/bin/bash -ex

INSTALL_DIR=$1
SCRIPT_DIR=$2
PLATFORM=$3
CBDEPS_OPENSSL_DIR=$4

case "$PLATFORM" in
    macosx)
        export MACOSX_DEPLOYMENT_TARGET=10.10
        ;;
    *)
	# Arg.. you got to hate autoconf and trying to get something
	# as simple as $ORIGIN passed down to the linker ;)
	# the crypto module in Erlang use openssl for crypto routines,
	# and it is installed in
	#  ${INSTALL_DIR}/lib/erlang/lib/crypto-4.2.2.2/priv/lib/crypto.so
	# so we need to tell the runtime linker how to find libssl.so
	# at runtime (which is located in ${INSTALL_DIR}/..
	# We could of course do this by adding /opt/couchbase/lib,
	# but that would break "non-root" installation (and people
	# trying to build the sw themselves and run from a dev dir).
	SSL_RPATH=--with-ssl-rpath=\'\$\$ORIGIN/../../../../..\'
	;;
esac

./otp_build autoconf
./configure --prefix="$INSTALL_DIR" \
      --enable-smp-support \
      --disable-hipe \
      --disable-fp-exceptions \
      --without-javac \
      --without-wx \
      --without-et \
      --without-debugger \
      --without-megaco \
      --without-observer \
      --with-ssl=$CBDEPS_OPENSSL_DIR \
      $SSL_RPATH \
      CFLAGS="-fno-strict-aliasing -O3 -ggdb3"

make -j4

make install

# Copy in cbdeps CMakeLists
cp ${SCRIPT_DIR}/CMakeLists_package.txt ${INSTALL_DIR}/CMakeLists.txt

# On MacOS, set up the RPath for the crypto plugin to find our custom OpenSSL
if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -add_rpath @loader_path/../../../../.. \
        ${INSTALL_DIR}/lib/erlang/lib/crypto-4.2.2.2/priv/lib/crypto.so
fi

# For whatever reason, the special characters in this filename make
# Jenkins throw a fix (UI warnings about "There are resources Jenkins
# was not able to dispose automatically"), so let's just delete it.
rm -rf lib/ssh/test/ssh_sftp_SUITE_data/sftp_tar_test_data_*
