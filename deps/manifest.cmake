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
DECLARE_DEP (breakpad VERSION 20160926-cb1 PLATFORMS centos6 centos7 debian7 debian8 debian9 suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
DECLARE_DEP (boost VERSION 1.62.0-cb3 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
DECLARE_DEP (curl VERSION 7.49.1-cb1 PLATFORMS centos6 centos7 debian7 debian8 debian9 suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
DECLARE_DEP (erlang VERSION R16B03-1-couchbase-cb6 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04)
DECLARE_DEP (erlang VERSION R16B03-1-couchbase-cb4 PLATFORMS windows_msvc2015)
DECLARE_DEP (flatbuffers VERSION 1.4.0-cb1 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
DECLARE_DEP (flex VERSION 2.5.4a-cb1 PLATFORMS windows_msvc2015)
DECLARE_DEP (flex VERSION 2.6.4-cb3 PLATFORMS centos6 centos7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04)
DECLARE_DEP (icu4c VERSION 59.1-cb1 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
DECLARE_DEP (jemalloc VERSION 4.1.0-cb2 PLATFORMS windows_msvc2015)
DECLARE_DEP (jemalloc VERSION 4.3.1-cb2 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04)
DECLARE_DEP (json VERSION 1.1.0-cb1 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
DECLARE_DEP (libcouchbase VERSION 2.7.7-cb6 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
DECLARE_DEP (libevent VERSION 2.1.8-cb3 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
DECLARE_DEP (libuv VERSION 1.13.1-cb4 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
DECLARE_DEP (numactl VERSION 2.0.11-cb1 PLATFORMS centos6 centos7 debian7 debian8 debian9 suse11.2 suse12.2 ubuntu14.04 ubuntu16.04)
DECLARE_DEP (openssl VERSION 1.0.2k-cb2 PLATFORMS macosx windows_msvc2015)
DECLARE_DEP (python-snappy VERSION c97d633 PLATFORMS windows_msvc2015)
DECLARE_DEP (python-snappy VERSION c97d633-cb1 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04)
DECLARE_DEP (rocksdb VERSION 5.8.0-cb1 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04)
DECLARE_DEP (snappy VERSION 1.1.1 PLATFORMS windows_msvc2015)
DECLARE_DEP (snappy VERSION 1.1.1-cb2 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04)
DECLARE_DEP (v8 VERSION 5.9-cb3 PLATFORMS centos7 debian8 debian9 macosx suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
DECLARE_DEP (v8 VERSION 5.9-cb4 PLATFORMS centos6 suse11.2)
DECLARE_DEP (zlib VERSION 1.2.11-cb3 PLATFORMS centos6 centos7 debian8 debian9 macosx suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 windows_msvc2015)
