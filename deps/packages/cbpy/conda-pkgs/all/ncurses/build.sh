#!/bin/bash

cp $BUILD_PREFIX/share/libtool/build-aux/config.* .

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
    export BUILD_CC=${CC_FOR_BUILD}
fi

if [[ $target_platform =~ osx-.* ]]; then
    export cf_cv_mixedcase=no
fi

for USE_WIDEC in false true;
do
    WIDEC_OPT=""
    w=""
    if [ "${USE_WIDEC}" = true ];
    then
        WIDEC_OPT="--enable-widec"
        w="w"
    fi
    sh ./configure \
	    --prefix=$PREFIX \
	    --without-debug \
	    --without-ada \
	    --without-manpages \
	    --with-shared \
	    --disable-overwrite \
	    --enable-symlinks \
	    --enable-termcap \
	    --with-termlib \
        --without-pkg-config \
	    $WIDEC_OPT

    if [[ "$target_platform" == osx* ]]; then
        sed -i.orig '/^SHLIB_LIST/s/-ltinfo/-Wl,-reexport&/' ncurses/Makefile
    fi

    make -j ${CPU_COUNT}
    make install
    make clean
    make distclean

    HEADERS_DIR="${PREFIX}/include/ncurses"
    if [ "${USE_WIDEC}" = true ];
    then
        HEADERS_DIR="${PREFIX}/include/ncursesw"
    fi
    for HEADER in $(ls $HEADERS_DIR);
    do
        mv "${HEADERS_DIR}/${HEADER}" "${PREFIX}/include/${HEADER}"
        ln -s "${PREFIX}/include/${HEADER}" "${HEADERS_DIR}/${HEADER}"
    done

    if [[ "$target_platform" != osx* ]]; then
        DEVLIB=$PREFIX/lib/libncurses$w.so
        RUNLIB=$(basename $(readlink $DEVLIB))
        rm $DEVLIB
        echo "INPUT($RUNLIB -ltinfo$w)" > $DEVLIB
    fi
done

for LIB_NAME in libncurses libtinfo libform libmenu libpanel; do
    rm ${PREFIX}/lib/${LIB_NAME}.a
    rm ${PREFIX}/lib/${LIB_NAME}w.a
done
