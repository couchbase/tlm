#!/bin/bash -ex

INSTALL_DIR=$1
PLATFORM=$2

pushd $(dirname $0) > /dev/null
SCRIPTPATH=$(pwd -P)
popd > /dev/null

DEPS=/tmp/deps
rm -rf ${DEPS}
mkdir -p ${DEPS}

# Download cbdep to get python2 (still required for this build sadly).
CBDEP_TOOL_VER=0.9.15
MINICONDA_VER=4.7.12.1

# Download cbdep, unless it's already available in the local .cbdepscache
OPSYS=$(uname -s | tr "[:upper:]" "[:lower:]")
CBDEP_BIN_CACHE=/home/couchbase/.cbdepscache/cbdep/${CBDEP_TOOL_VER}/cbdep-${CBDEP_TOOL_VER}-${OPSYS}

if [[ -f ${CBDEP_BIN_CACHE} ]]; then
    cp ${CBDEP_BIN_CACHE} /tmp/cbdep
else
    CBDEP_URL=https://packages.couchbase.com/cbdep/${CBDEP_TOOL_VER}/cbdep-${CBDEP_TOOL_VER}-${OPSYS}
    curl -o /tmp/cbdep ${CBDEP_URL}
fi

chmod +x /tmp/cbdep

# Use cbdep to install miniconda2. Add to PATH *last* (so it only adds
# python2, not overriding anything). Also add to LD_LIBRARY_PATH as the
# "vpython" script the build uses creates a copy of "python2" but doesn't
# copy libpython2 as well.
# On macosx, we need to use python from miniconda; otherwise, gclient will
# fail due to SIP.  Creating an alias doesn't seem to work; have to add
# miniconda2 in the front of PATH.  ubuntu20 comes with python3, v8 doesn't
# work well with python3, put miniconda2 in the front as well.

/tmp/cbdep install -d ${DEPS} miniconda2 ${MINICONDA_VER}
export PATH_ORG=${PATH}
export LD_LIBRARY_PATH=${DEPS}/miniconda2-${MINICONDA_VER}/lib

if [[ $PLATFORM != "macosx" && $PLATFORM != "ubuntu20.04" && $PLATFORM != "ubuntu18.04" ]]; then
    export PATH=${PATH_ORG}:${DEPS}/miniconda2-${MINICONDA_VER}/bin
else
    export PATH=${DEPS}/miniconda2-${MINICONDA_VER}/bin:${PATH_ORG}
fi

# Get Google's depot_tools; checkout from October 18th, 2018,
# which worked for the SuSE platforms on the last build.
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
pushd depot_tools && git checkout 93277a7 && popd
export PATH=$(pwd)/depot_tools:$PATH

# Set up gclient config for tag to pull for v8, then do sync
# (this handles the 'fetch v8' done by the usual process)
cat > .gclient <<EOF
solutions = [
  {
    "url": "https://github.com/couchbasedeps/v8-mirror.git@8.3.110.13",
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

#download older version of gn for centos7
#latest requires glibc 2.18, centos7 comes with 2.17
if [[ $PLATFORM == "centos7" ]]; then
    pushd v8/buildtools/linux64
    mv gn gn.org
    curl -L -o gn.zip https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-amd64/+/jCF636-ci00rA64wJkdAPZx3NrIvafSvZ_bajkcCMbUC
    unzip gn.zip
    popd
fi

# Actual v8 configure and build steps - we build debug and release.
cd v8
V8_ARGS='target_cpu="x64" is_component_build=true v8_enable_backtrace=true v8_use_external_startup_data=false use_custom_libcxx=false v8_enable_pointer_compression=false'

gn gen out.gn/x64.release --args="$V8_ARGS is_debug=false"
ninja -C out.gn/x64.release
V8_ARGS="$V8_ARGS v8_enable_slow_dchecks=true"
#only enable v8_optimized_debug=false if it is not macosx as of V8 8.3 as it causes unitest failures
if [[ $PLATFORM != "macosx" ]]; then
    V8_ARGS="$V8_ARGS v8_optimized_debug=false"
fi
gn gen out.gn/x64.debug --args="$V8_ARGS is_debug=true"
ninja -C out.gn/x64.debug

# Copy right stuff to output directory.
mkdir -p \
    $INSTALL_DIR/lib/Release \
    $INSTALL_DIR/lib/Debug \
    $INSTALL_DIR/include/libplatform \
    $INSTALL_DIR/include/cppgc \
    $INSTALL_DIR/include/unicode
(
    cd out.gn/x64.release
    cp -avi libv8*.* $INSTALL_DIR/lib/Release
    cp -avi libchrome*.* $INSTALL_DIR/lib/Release
    cp -avi libcppgc*.* $INSTALL_DIR/lib/Release
    cp -avi libicu*.* $INSTALL_DIR/lib/Release
    cp -avi icu*.* $INSTALL_DIR/lib/Release
)
(
    cd out.gn/x64.debug
    cp -avi libv8*.* $INSTALL_DIR/lib/Debug
    cp -avi libchrome*.* $INSTALL_DIR/lib/Debug
    cp -avi libcppgc*.* $INSTALL_DIR/lib/Debug
    cp -avi libicu*.* $INSTALL_DIR/lib/Debug
    cp -avi icu*.* $INSTALL_DIR/lib/Debug
)
(
    cd include
    cp -avi v8*.h $INSTALL_DIR/include
    cp -avi libplatform/[a-z]*.h $INSTALL_DIR/include/libplatform
    cp -avi cppgc/[a-z]*.h $INSTALL_DIR/include/cppgc
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
