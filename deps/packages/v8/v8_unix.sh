#!/bin/bash -ex

INSTALL_DIR=$1
PLATFORM=$2

case "$PLATFORM" in
    ubuntu14.04|debian7|debian8|debian9)
        # The buildslave images should contain this package. However
        # we're doing this v8 upgrade right in the last days of Spock,
        # and re-building the buildslaves images seems an unnecessary risk.
        sudo apt-get update && sudo apt-get install -y pkg-config
        ;;
esac

# Some old Linuxes have a glibc version too old to work with the tools
# in the Google-provided toolchain. So, we have to use a hackier build
# process. Isolate that away in a separate script
case "$PLATFORM" in
    suse11*|centos6|debian7)
        pushd `dirname $0` > /dev/null
        SCRIPTPATH=`pwd -P`
        popd > /dev/null
        exec $SCRIPTPATH/v8_old_unix.sh $INSTALL_DIR $PLATFORM
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

# Actual v8 configure and build steps - we build debug and release.
cd v8
V8_ARGS='target_cpu="x64" is_component_build=true v8_enable_backtrace=true v8_use_snapshot=true v8_use_external_startup_data=false v8_enable_i18n_support=true v8_test_isolation_mode="noop"'
gn gen out.gn/release --args="$V8_ARGS is_debug=false"
ninja -C out.gn/release
gn gen out.gn/debug --args="$V8_ARGS is_debug=true"
ninja -C out.gn/debug

# Copy right stuff to output directory.
mkdir -p \
    $INSTALL_DIR/lib/Release \
    $INSTALL_DIR/lib/Debug \
    $INSTALL_DIR/include/libplatform
(
    cd out.gn/release
    cp -avi libv8*.* $INSTALL_DIR/lib/Release
)
(
    cd out.gn/debug
    cp -avi libv8*.* $INSTALL_DIR/lib/Debug
)
(
    cd include
    cp -avi v8*.h $INSTALL_DIR/include
    cp -avi libplatform/[a-z]*.h $INSTALL_DIR/include/libplatform
)
