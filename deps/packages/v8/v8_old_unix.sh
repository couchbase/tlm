#!/bin/bash -ex

INSTALL_DIR=$1
PLATFORM=$2

# Do the various platform-specific hacks to get the buildslave into
# a good-enough state for this build.

case "$PLATFORM" in
    suse11*|centos6)
        # We'll install newer Python for this user only, and not on
        # standard path
        export PYDIR=/home/couchbase/opt/python
        if [ ! -d "$PYDIR" ]; then
            mkdir -p $PYDIR
            mkdir tmp
            (
                cd tmp
                curl -O https://www.python.org/ftp/python/2.7.12/Python-2.7.12.tgz
                tar xf Python-2.7.12.tgz
                cd Python-2.7.12
                ./configure --prefix=$PYDIR --disable-shared
                make -j8
                make install
            )
        fi
        export PATH=$PYDIR/bin:$PATH
        ;;
esac

case "$PLATFORM" in
    suse11*)
        # See also https://forums.opensuse.org/showthread.php/446927-missing-library-libtinfo-so-5
        sudo ln -sf libncurses.so.5.6 /lib64/libtinfo.so.5
        ;;
esac

case "$PLATFORM" in
    centos6)
        ;;
esac

# Get our vendored copy of Google's depot_tools.
# The v8-5.9 branch in our mirror is set to the version as of
# early September 2017, when this v8 package was created.
git clone -b couchbasedeps-v8-5.9 git://github.com/couchbasedeps/depot_tools
export PATH=`pwd`/depot_tools:$PATH

# Disable gclient auto-update (won't work anyway since we're using a
# vendored copy)
export DEPOT_TOOLS_UPDATE=0

# Use gclient (from depot_tools) to sync our vendored version
# of v8. Note: this is not truly vendored, as both depot_tools
# and the v8 build download many things from Google as part
# of the build. Therefore we can't guarantee this will work
# indefinitely. I could not find a way around this issue.
# I do pull our couchbasedeps version of icu4c to ensure that
# couchbase can link against libv8.so with our cbdeps icu4c.
cat > .gclient <<EOF
solutions = [
  {
    "url": "https://github.com/couchbasedeps/v8.git@5.9.223",
    "managed": False,
    "name": "v8",
    "deps_file": "DEPS",
    "custom_deps": { "v8/third_party/icu": "https://chromium.googlesource.com/chromium/deps/icu.git@origin/chromium/59staging" },
  },
];
EOF
gclient sync --noprehooks --nohooks
gclient runhooks

cd v8

# Now we've gotten all Google's binaries, but most of them won't work on
# these platforms. Either disable them or overwrite them, depending on
# the platform and excessive experimentation.

case "$PLATFORM" in
    suse11*)
        # Just skip the provided binutils entirely. This works for
        # release mode but, oddly, not for debug, so we'll skip that.
        BINUTILS_ARG="-Dlinux_use_bundled_binutils=0 -Dlinux_use_bundled_gold=0 -Dlinux_use_gold_flags=0"
        DO_DEBUG=no
        ;;
    centos6)
        # Ensure 'as' and 'ld.gold' are on PATH, then copy to overwrite
        # the binutils-provided version.
        source /opt/rh/devtoolset-2/enable
        cp `type -P as` third_party/binutils/Linux_x64/Release/bin/as
        cp `type -P nm` third_party/binutils/Linux_x64/Release/bin/nm
        cp `type -P ld.gold` third_party/binutils/Linux_x64/Release/bin/ld.gold
        BINUTILS_ARG=
        DO_DEBUG=yes
        ;;
    *)
        # Wing and a prayer
        BINUTILS_ARG=
        DO_DEBUG=yes
        ;;
esac

# The test builds are unnecessary and in fact seem to break with these
# build steps, so skip 'em by making their condition false
sed -i.bak 's/host_os!/host_os=/' gypfiles/all.gyp
sed -i.bak 's/OS!/OS=/' gypfiles/all.gyp

# Actual v8 configure and build steps - we build debug and release.
# Note: these steps use the older "gyp" build mechanism, which is
# deprecated in v8. However the newer "gn" tool doesn't work with
# the old glibc on these distros, and building gn from source
# is not really documented.
# We also disable the bundled binutils and gold linker for the same reason.
python gypfiles/gyp_v8
V8_ARGS="$BINUTILS_ARG -Dclang=0 -Dcomponent=shared_library -Dv8_enable_backtrace=1 -Dv8_use_snapshot='true' -Dv8_use_external_startup_data=0 -Dv8_enable_i18n_support=1 -Dtest_isolation_mode=noop -Dwerror=-Wno-error"
make -j8 x64.release GYPFLAGS="$V8_ARGS"
if [ "$DO_DEBUG" = "yes" ]; then
    make -j8 x64.debug GYPFLAGS="$V8_ARGS"
fi

# Copy right stuff to output directory.
mkdir -p \
    $INSTALL_DIR/lib/Release \
    $INSTALL_DIR/include/libplatform
(
    cd out/x64.release/lib.target
    cp -avi libv8*.* $INSTALL_DIR/lib/Release
)
(
    cd include
    cp -avi v8*.h $INSTALL_DIR/include
    cp -avi libplatform/[a-z]*.h $INSTALL_DIR/include/libplatform
)
if [ "$DO_DEBUG" = "yes" ]; then
    mkdir -p $INSTALL_DIR/lib/Debug
    (
        cd out/x64.debug/lib.target
        cp -avi libv8*.* $INSTALL_DIR/lib/Debug
    )
fi
