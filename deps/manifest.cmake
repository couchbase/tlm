#
# Keep the list sorted alphabetically, and the platforms alphabetically.
# The syntax is:
#
# DECLARE_DEP (name VERSION version-revision PLATFORMS platform1 platform2)
#
# This manifest contains entries for SUPPORTED platforms. These are
# platforms on which Couchbase builds and delivers Server binaries
# to customers.
#
# The list of supported platforms may change between releases, but
# you may use the cmake macro CB_GET_SUPPORTED_PLATFORM to
# check if this is a supported platform.
#
# IMPORTANT: If you add a new package here or update an existing package
# version, you must also update couchbase-server-black-duck-manifest.json
# in this same directory!
#
DECLARE_DEP (benchmark VERSION v1.6.2-cb2 PLATFORMS linux macosx windows)
DECLARE_DEP (breakpad V2 VERSION 20200430 BUILD 4 PLATFORMS linux windows)
DECLARE_DEP (boost VERSION 1.82.0-cb1 PLATFORMS linux macosx windows)
DECLARE_DEP (cbpy VERSION 7.5.0-cb2 PLATFORMS windows DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/python/interp")
DECLARE_DEP (cbpy VERSION 7.5.0-cb3 PLATFORMS linux macosx windows DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/python/interp")
DECLARE_DEP (curl V2 VERSION 7.88.1 BUILD 6_openssl30x PLATFORMS linux macosx windows)
DECLARE_DEP (double-conversion VERSION 3.0.0-cb6 PLATFORMS linux macosx windows)
DECLARE_DEP (erlang V2 VERSION 25.3 BUILD 6 PLATFORMS linux macosx windows)
DECLARE_DEP (flatbuffers VERSION v1.10.0-cb7 PLATFORMS linux macosx windows)
DECLARE_DEP (fmt VERSION 8.1.1-cb4 PLATFORMS linux macosx windows)
DECLARE_DEP (folly VERSION v2022.05.23.00-couchbase-cb13 PLATFORMS linux macosx windows)
DECLARE_DEP (glog VERSION v0.4.0-cb3 PLATFORMS linux macosx windows)
DECLARE_DEP (googletest VERSION 1.11.0-cb6 PLATFORMS linux macosx windows)
DECLARE_DEP (grpc VERSION 1.49.2-cb8 PLATFORMS linux macosx windows)
#
# IMPORTANT: If you add a new package here or update an existing package
# version, you must also update couchbase-server-black-duck-manifest.json
# in this same directory!
#
DECLARE_DEP (jemalloc VERSION 5.3.0-cb3 PLATFORMS linux macosx windows)
DECLARE_DEP (json VERSION 3.9.0-cb3 PLATFORMS linux macosx windows)
DECLARE_DEP (libevent VERSION 2.1.11-cb11 PLATFORMS linux macosx windows)
DECLARE_DEP (libsodium V2 VERSION 1.0.18 BUILD 5 PLATFORMS linux macosx windows)
DECLARE_DEP (liburing V2 VERSION 0.6 BUILD 3 PLATFORMS linux)
DECLARE_DEP (libuv V2 VERSION 1.20.3 BUILD 17 PLATFORMS windows_msvc2017)
DECLARE_DEP (libuv V2 VERSION 1.20.3 BUILD 23 PLATFORMS linux macosx)
DECLARE_DEP (lz4 VERSION 1.9.2-cb5 PLATFORMS linux macosx)
DECLARE_DEP (maven VERSION 3.5.2-cb6 PLATFORMS all)
DECLARE_DEP (pcre VERSION 8.44-cb3 PLATFORMS linux macosx windows)
DECLARE_DEP (openssl V2 VERSION 3.0.7 BUILD 3 PLATFORMS linux macosx windows)
DECLARE_DEP (numactl VERSION 2.0.11-cb4 PLATFORMS linux)
DECLARE_DEP (prometheus V2 VERSION 2.33.3 BUILD 4 PLATFORMS linux macosx windows)
DECLARE_DEP (prometheus-cpp VERSION v0.10.0-couchbase-cb4 PLATFORMS linux macosx windows)
DECLARE_DEP (protoc-gen-go V2 VERSION 1.2.5 BUILD 7 PLATFORMS linux macosx windows)
# We don't want RocksDB to end up in shipped production builds.
# NB: I don't indent this IF() block just in case, because I know that some
# scripts (such as escrow) parse this file manually.
IF (NOT CB_PRODUCTION_BUILD)
DECLARE_DEP (rocksdb VERSION 5.18.3-cb9 PLATFORMS linux macosx)
ENDIF (NOT CB_PRODUCTION_BUILD)
DECLARE_DEP (snappy VERSION 1.1.10-cb2 PLATFORMS linux macosx windows)
DECLARE_DEP (spdlog VERSION v1.10.0-cb6 PLATFORMS linux macosx windows)
DECLARE_DEP (v8 V2 VERSION 11.6.189.8 BUILD 1 PLATFORMS linux macosx windows)
DECLARE_DEP (zlib V2 VERSION 1.2.13 BUILD 2 PLATFORMS linux macosx windows)
DECLARE_DEP (zstd-cpp V2 VERSION 1.5.0 BUILD 4 PLATFORMS linux macosx windows)

#
# IMPORTANT: If you add a new package here or update an existing package
# version, you must also update couchbase-server-black-duck-manifest.json
# in this same directory!
#
