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
DECLARE_DEP (breakpad V2 VERSION 2022.07.12 BUILD 1 PLATFORMS linux windows)
DECLARE_DEP (boost VERSION 1.86.0-cb2 PLATFORMS linux macosx windows)
DECLARE_DEP (cbpy V2 VERSION 3.11.10 BUILD 3 PLATFORMS linux macosx windows DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/python/interp")
DECLARE_DEP (curl V2 VERSION 8.14.1 BUILD 2 PLATFORMS linux macosx windows)
DECLARE_DEP (double-conversion VERSION 3.0.0-cb4 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (erlang V2 VERSION 26.2.5.15 BUILD 2 PLATFORMS linux macosx windows)
DECLARE_DEP (flatbuffers VERSION 1.10.0-cb5 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (fmt VERSION 11.0.0-cb5 PLATFORMS linux macosx windows)
DECLARE_DEP (folly VERSION v2022.05.23.00-couchbase-cb20 PLATFORMS linux macosx windows)
DECLARE_DEP (glog VERSION v0.4.0-cb1 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (googletest VERSION 1.14.0-cb1 PLATFORMS linux macosx windows)
DECLARE_DEP (grpc V2 VERSION 1.72.0 BUILD 3 PLATFORMS linux macosx windows)
#
# IMPORTANT: If you add a new package here or update an existing package
# version, you must also update couchbase-server-black-duck-manifest.json
# in this same directory!
#
DECLARE_DEP (jemalloc VERSION 5.2.1-cb9 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows)
DECLARE_DEP (json VERSION 3.11.2-cb1 PLATFORMS linux macosx windows)
DECLARE_DEP (libevent VERSION 2.1.11-cb12 PLATFORMS linux macosx windows)
DECLARE_DEP (liburing V2 VERSION 0.6 BUILD 2 PLATFORMS amzn2 centos7 debian9 debian10 suse12 suse15 ubuntu18.04 ubuntu20.04)
DECLARE_DEP (libuv V2 VERSION 1.20.3 BUILD 17 PLATFORMS windows)
DECLARE_DEP (libuv V2 VERSION 1.20.3 BUILD 22 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04)
DECLARE_DEP (lz4 V2 VERSION 1.9.4 BUILD 2 PLATFORMS linux macosx)
DECLARE_DEP (maven VERSION 3.5.2-cb6 PLATFORMS all)
DECLARE_DEP (numactl VERSION 2.0.11-cb3 PLATFORMS amzn2 centos7 debian9 debian10 suse12 suse15 ubuntu18.04 ubuntu20.04)
DECLARE_DEP (pcre VERSION 8.44-cb1 PLATFORMS linux macosx windows_msvc2017)
DECLARE_DEP (openssl V2 VERSION 3.5.1 BUILD 1 PLATFORMS linux macosx windows)
DECLARE_DEP (numactl VERSION 2.0.11-cb3 PLATFORMS amzn2 centos7 debian9 debian10 suse12 suse15 ubuntu18.04 ubuntu20.04)
DECLARE_DEP (prometheus V2 VERSION 2.53.5 BUILD 3 GO_DEP PLATFORMS linux macosx windows)
DECLARE_DEP (prometheus-cpp VERSION v1.2.1-couchbase-cb1 PLATFORMS linux macosx windows)
DECLARE_DEP (protoc-gen-go V2 VERSION 1.2.5 BUILD 4 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (snappy VERSION 1.1.10-cb2 PLATFORMS linux macosx windows)
DECLARE_DEP (spdlog VERSION v1.15.0-cb6 PLATFORMS linux macosx windows)
DECLARE_DEP (v8 V2 VERSION 13.4.115 BUILD 3 PLATFORMS linux macosx windows)
DECLARE_DEP (zlib V2 VERSION 1.2.13 BUILD 1 PLATFORMS linux macosx windows_msvc2017)
DECLARE_DEP (zstd-cpp V2 VERSION 1.5.0 BUILD 2 PLATFORMS linux macosx windows)

#
# IMPORTANT: If you add a new package here or update an existing package
# version, you must also update couchbase-server-black-duck-manifest.json
# in this same directory!
#
