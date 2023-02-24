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
DECLARE_DEP (benchmark VERSION v1.6.0-cb1 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (breakpad V2 VERSION 20200430 BUILD 1 PLATFORMS amzn2 centos7 debian9 debian10 suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (boost VERSION 1.74.0-cb1 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (cbpy VERSION 7.5.0-cb1 PLATFORMS linux macosx windows DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/python/interp")
DECLARE_DEP (curl V2 VERSION 7.84.0 BUILD 5 PLATFORMS linux macosx windows)
DECLARE_DEP (double-conversion VERSION 3.0.0-cb4 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (erlang V2 VERSION 24.3.4.4 BUILD 4 PLATFORMS linux macosx windows)
DECLARE_DEP (flatbuffers VERSION 1.10.0-cb5 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (fmt VERSION 7.1.3-cb2 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (folly VERSION v2020.09.07.00-couchbase-cb2 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows)
DECLARE_DEP (glog VERSION v0.4.0-cb1 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (googletest VERSION 1.11.0-cb4 PLATFORMS linux macosx windows_msvc2017)
DECLARE_DEP (grpc VERSION 1.28.1-cb3 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows)
#
# IMPORTANT: If you add a new package here or update an existing package
# version, you must also update couchbase-server-black-duck-manifest.json
# in this same directory!
#
DECLARE_DEP (jemalloc VERSION 5.2.1-cb9 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows)
DECLARE_DEP (json VERSION 3.9.0-cb1 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (libevent VERSION 2.1.11-cb9 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows)
DECLARE_DEP (liburing V2 VERSION 0.6 BUILD 2 PLATFORMS amzn2 centos7 debian9 debian10 suse12 suse15 ubuntu18.04 ubuntu20.04)
DECLARE_DEP (libuv V2 VERSION 1.20.3 BUILD 17 PLATFORMS windows_msvc2017)
DECLARE_DEP (libuv V2 VERSION 1.20.3 BUILD 22 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04)
DECLARE_DEP (lz4 VERSION 1.9.2-cb2 PLATFORMS linux macosx)
DECLARE_DEP (maven VERSION 3.5.2-cb6 PLATFORMS all)
DECLARE_DEP (numactl VERSION 2.0.11-cb3 PLATFORMS amzn2 centos7 debian9 debian10 suse12 suse15 ubuntu18.04 ubuntu20.04)
DECLARE_DEP (pcre VERSION 8.44-cb1 PLATFORMS linux macosx windows_msvc2017)
DECLARE_DEP (openssl V2 VERSION 1.1.1t BUILD 1 PLATFORMS linux macosx windows)
DECLARE_DEP (numactl VERSION 2.0.11-cb3 PLATFORMS amzn2 centos7 debian9 debian10 suse12 suse15 ubuntu18.04 ubuntu20.04)
DECLARE_DEP (prometheus V2 VERSION 2.33.3 BUILD 3 PLATFORMS linux macosx windows)
DECLARE_DEP (prometheus-cpp VERSION v0.10.0-couchbase-cb2 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (protoc-gen-go V2 VERSION 1.2.5 BUILD 4 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
# We don't want RocksDB to end up in shipped production builds.
# NB: I don't indent this IF() block just in case, because I know that some
# scripts (such as escrow) parse this file manually.
IF (NOT CB_PRODUCTION_BUILD)
DECLARE_DEP (rocksdb VERSION 5.18.3-cb6 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04)
ENDIF (NOT CB_PRODUCTION_BUILD)
DECLARE_DEP (snappy VERSION 1.1.8-cb4 PLATFORMS linux macosx windows_msvc2017)
DECLARE_DEP (spdlog VERSION v1.8.5-cb3 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (v8 V2 VERSION 10.7.21 BUILD 2 PLATFORMS linux macosx windows)
DECLARE_DEP (zlib V2 VERSION 1.2.13 BUILD 1 PLATFORMS linux macosx windows_msvc2017)
DECLARE_DEP (zstd-cpp V2 VERSION 1.5.0 BUILD 2 PLATFORMS linux macosx windows)

#
# IMPORTANT: If you add a new package here or update an existing package
# version, you must also update couchbase-server-black-duck-manifest.json
# in this same directory!
#
