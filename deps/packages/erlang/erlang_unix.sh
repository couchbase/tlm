#!/bin/bash -ex

INSTALL_DIR=$1
PLATFORM=$2
CBDEPS_OPENSSL_DIR=$3

case "$PLATFORM" in
    debian9|fedora26|rhel8|ubuntu18.04)
        # We need to do a private build of OpenSSL as the version
        # on debian 9 is too new for Erlang R16B03-1. Use our
        # vendored 1.0.2k source.
        echo .........................
        echo BUILDING OPENSSL 1.0.2k
        echo .........................
        OPENSSL_DIR=`pwd`/openssl-1.0.2k/install
        mkdir -p $OPENSSL_DIR
        (
            cd openssl-1.0.2k
            git clone -b OpenSSL_1_0_2k --depth 1 git://github.com/couchbasedeps/openssl
            cd openssl
            # OpenSSL's config script uses RELEASE to override the value
            # of uname -r, which breaks things when this script runs as
            # part of the cbdeps-platform-build Jenkins job. So, unset it.
            unset RELEASE
            ./config --prefix=$OPENSSL_DIR \
                shared no-comp no-ssl2 no-ssl3
            make depend
            make # parallel build might fail
            make install
        )
        OPENSSL_FLAGS="--disable-dynamic-ssl-lib --with-ssl=$OPENSSL_DIR"
        ;;
    macosx)
        OPENSSL_FLAGS="--disable-dynamic-ssl-lib --with-ssl=$CBDEPS_OPENSSL_DIR"
        ;;
    *)
        OPENSSL_FLAGS="--with-ssl"
        ;;
esac

./otp_build autoconf
touch ./lib/debugger/SKIP \
      ./lib/megaco/SKIP \
      ./lib/observer/SKIP \
      ./lib/wx/SKIP
./configure --prefix="$INSTALL_DIR" \
      --enable-smp-support \
      --disable-hipe \
      --disable-fp-exceptions \
      $OPENSSL_FLAGS \
      CFLAGS="-fno-strict-aliasing -O3 -ggdb3 -DOPENSSL_NO_EC=1"

make -j4

make install

# On MacOS, set up the RPath for the crypto plugin to find our custom OpenSSL
if [ $(uname -s) = "Darwin" ]; then
    install_name_tool -add_rpath @loader_path/../../../../.. \
        ${INSTALL_DIR}/lib/erlang/lib/crypto-3.2/priv/lib/crypto.so
fi

# For whatever reason, the special characters in this filename make
# Jenkins throw a fix (UI warnings about "There are resources Jenkins
# was not able to dispose automatically"), so let's just delete it.
rm -rf lib/ssh/test/ssh_sftp_SUITE_data/sftp_tar_test_data_*
