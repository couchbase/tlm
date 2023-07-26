#!/usr/bin/env bash
# Copyright 2023-Present Couchbase, Inc.
#
# Use of this software is governed by the Business Source License included in
# the file licenses/BSL-Couchbase.txt.  As of the Change Date specified in that
# file, in accordance with the Business Source License, use of this software
# will be governed by the Apache License, Version 2.0, included in the file
# licenses/APL2.txt.

# Convenience script to build Couchbase Server

# Dump an error message and terminate
errexit() {
  echo "FATAL ERROR: \"${1}\""
  exit 1
}

source_root=$(pwd)
build_root=$(pwd)/build
install_root=$(pwd)/install
# The link step may consume a _lot_ of memory as a lot of the programs
# use static linking of C++ objects with a ton of symbols (I've seen
# it go way above 1 GB). To work around the problem of the linker running
# out of memory and fail the build reduce the number of parallel link jobs.
cb_parallel_link_jobs=${CB_PARALLEL_LINK_JOBS-2}
macos_cross_compilation_flags=
tsan_cmake_option=
asan_cmake_option=
ubsan_cmake_option=

while getopts "s:b:i:hXTAUR" OPTION; do
  case $OPTION in
  s)
    source_root=${OPTARG}
    ;;
  b)
    build_root=${OPTARG}
    ;;
  i)
    install_root=${OPTARG}
    ;;
  X)
    macos_cross_compilation_flags="-D CMAKE_APPLE_SILICON_PROCESSOR=x86_64 -D CMAKE_OSX_ARCHITECTURES=x86_64"
    ;;
  T)
    if [ -z "${asan_cmake_option}" ]
    then
      tsan_cmake_option="-D CB_THREADSANITIZER=1"
    else
      errexit "Thread sanitizer cannot be used together with Address sanitizer"
    fi
    ;;
  U)
    ubsan_cmake_option="-D CB_UNDEFINEDSANITIZER=1"
    ;;
  A)
    if [ -z "${tsan_cmake_option}" ]
    then
      asan_cmake_option="-D CB_ADDRESSSANITIZER=1"
    else
      errexit "Address sanitizer cannot be used together with Thread sanitizer"
    fi
    ;;
  R)
    CMAKE_BUILD_TYPE=RelWithDebInfo
    ;;
  h)
    cat <<EOF
Usage:
   -s source_root  Source directory (default: ${source_root})
   -b build_root   Build directory (default: ${build_root})
   -i install_root Install directory (default: ${install_root})
   -X              Set Mac platform to x86_64 (Only needed when
                   building on Mac running arm64)
   -T              Enable thread sanitizer
   -A              Enable address sanitizer
   -U              Enable undefined behavior sanitizer
   -R              Set build type to RelWithDebInfo

EOF
      exit 0
      ;;
    *)
      echo "Incorrect options provided"
      exit 1
      ;;
  esac
done
shift $(($OPTIND - 1))

# Verify that we've got ninja in place
if ! which ninja > /dev/null
then
  cat << EOF
FATAL ERROR: ninja not installed (or not in path)
             install via: brew install ninja
                          apt install ninja-build
                          yum install ninja-build
EOF
  exit 1
fi

if ! which ccache > /dev/null
then
  echo "INFO: Using ccache would speed up the development cycle"
  echo "      install via: brew install ccache (mac)"
  echo "                   apt install ccache"
  echo "                   yum install ccache"
fi

mkdir -p ${build_root} || errexit "Failed to create build directory: ${build_root}"
cd ${build_root} || errexit "Failed to enter the build directory: ${build_root}"

if [ ${source_root}/tlm/CMakeLists.txt -nt ${source_root}/CMakeLists.txt ]
then
  chmod u+w ${source_root}/CMakeLists.txt || errexit "Failed to make ${source_root}/CMakeLists.txt writable"
  cp ${source_root}/tlm/CMakeLists.txt ${source_root}/CMakeLists.txt  || errexit "Failed to update ${source_root}/CMakeLists.txt"
  chmod u-w ${source_root}/CMakeLists.txt || errexit "Failed to make ${source_root}/CMakeLists.txt non-writable"
fi

if [ ! -f build.ninja ] || [ ${source_root}/CMakeLists.txt -nt build.ninja ]
then
   cmake -G Ninja \
         ${macos_cross_compilation_flags} \
         -D CMAKE_INSTALL_PREFIX=${install_root} \
         -D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE-DebugOptimized} \
         -D CB_PARALLEL_LINK_JOBS=${cb_parallel_link_jobs} \
         ${EXTRA_CMAKE_OPTIONS} \
         ${tsan_cmake_option} ${asan_cmake_option} ${ubsan_cmake_option} \
         ${source_root} \
          ||  errexit "Failed to generate build configuration"
fi

ninja install "$@" || errexit "Build failed"
