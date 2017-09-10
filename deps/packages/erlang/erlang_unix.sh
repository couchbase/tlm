#!/bin/bash

INSTALL_DIR=$1
PLATFORM=$2

case "$PLATFORM" in
    debian9)
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
            git clone -b OpenSSL_1_0_2k git://github.com/couchbasedeps/openssl
            cd openssl
            ./config --prefix=$OPENSSL_DIR \
                shared no-comp no-ssl2 no-ssl3
            make depend
            make -j4
            make install
        )
        OPENSSL_FLAGS="--disable-dynamic-ssl-lib --with-ssl=$OPENSSL_DIR"
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
