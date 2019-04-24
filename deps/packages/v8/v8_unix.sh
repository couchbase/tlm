#!/bin/bash -ex

INSTALL_DIR=$1
PLATFORM=$2

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# Get Google's depot_tools; checkout from October 18th, 2018,
# which worked for the SuSE platforms on the last build.
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
pushd depot_tools && git checkout 93277a7 && popd
export PATH=`pwd`/depot_tools:$PATH

# Set up gclient config for tag to pull for v8, then do sync
# (this handles the 'fetch v8' done by the usual process)
cat > .gclient <<EOF
solutions = [
  {
    "url": "https://github.com/couchbasedeps/v8-mirror.git@7.1.321",
    "managed": False,
    "name": "v8",
    "deps_file": "DEPS",
  },
];
EOF

gclient sync

# Apply change to enable RPATH (runpath) for libraries/binaries on Linux
if [[ $PLATFORM != "macosx" ]]; then
    pushd v8/build
    git apply $SCRIPTPATH/v8_linux_runpath.patch
    popd
fi

# Actual v8 configure and build steps - we build debug and release.
cd v8
V8_ARGS='target_cpu="x64" is_component_build=true v8_enable_backtrace=true v8_use_external_startup_data=false'
gn gen out.gn/x64.release --args="$V8_ARGS is_debug=false"
ninja -C out.gn/x64.release
V8_ARGS="$V8_ARGS v8_enable_slow_dchecks=true v8_optimized_debug=false"
gn gen out.gn/x64.debug --args="$V8_ARGS is_debug=true"
ninja -C out.gn/x64.debug

# Copy right stuff to output directory.
mkdir -p \
    $INSTALL_DIR/lib/Release \
    $INSTALL_DIR/lib/Debug \
    $INSTALL_DIR/include/libplatform \
    $INSTALL_DIR/include/unicode
(
    cd out.gn/x64.release
    cp -avi libv8*.* $INSTALL_DIR/lib/Release
    cp -avi libicu*.* $INSTALL_DIR/lib/Release
    cp -avi icu*.* $INSTALL_DIR/lib/Release
    if [[ $PLATFORM != "macosx" ]]; then
        cp -avi libc++*.* $INSTALL_DIR/lib/Release
    fi
)
(
    cd out.gn/x64.debug
    cp -avi libv8*.* $INSTALL_DIR/lib/Debug
    cp -avi libicu*.* $INSTALL_DIR/lib/Debug
    cp -avi icu*.* $INSTALL_DIR/lib/Debug
    if [[ $PLATFORM != "macosx" ]]; then
        cp -avi libc++*.* $INSTALL_DIR/lib/Debug
    fi
)
(
    cd include
    cp -avi v8*.h $INSTALL_DIR/include
    cp -avi libplatform/[a-z]*.h $INSTALL_DIR/include/libplatform
)
(
    cd third_party/icu/source/common/unicode
    cp -avi *.h $INSTALL_DIR/include/unicode
)
(
    cd third_party/icu/source/io/unicode
    cp -avi *.h $INSTALL_DIR/include/unicode
)
(
    cd third_party/icu/source/i18n/unicode
    cp -avi *.h $INSTALL_DIR/include/unicode
)
(
    cd third_party/icu/source/extra/uconv/unicode
    cp -avi *.h $INSTALL_DIR/include/unicode
)
