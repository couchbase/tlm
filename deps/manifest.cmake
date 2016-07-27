#
# Keep the list sorted alphabetically, and the platforms alphabetically.
# The syntax is:
#
# DECLARE_DEP (name VERSION version-revision PLATFORMS platform1 platform2)
#
# Please note that this file contains entries for both supported and
# unsupported platforms. The reason for putting unsupported platforms
# in this file is that people may then build the dependencies from:
# tlm/deps/packages and store the resulting dependency files in
# ~/.cbdepscache and build the system without having to patch this
# file (where people is people like Trond who wants to set up automated
# builders on platforms like SmartOS/Solars, FreeBSD etc).
#
# The list of supported platforms may change between releases, but
# you may use the cmake macro GET_SUPPORTED_PRODUCTION_PLATFORM to
# check if this is a supported platform.
#
DECLARE_DEP (breakpad VERSION 1e455b5-cb10 PLATFORMS centos6 centos7 debian7 debian8 suse11.2 ubuntu12.04 ubuntu14.04 windows_msvc)
DECLARE_DEP (curl VERSION 7.49.1-cb1 PLATFORMS centos6 centos7 debian7 debian8 freebsd sunos suse11.2 ubuntu12.04 ubuntu14.04 windows_msvc)
DECLARE_DEP (erlang VERSION R16B03-1-couchbase-cb1 PLATFORMS windows_msvc)
DECLARE_DEP (erlang VERSION R16B03-couchbase-cb2 PLATFORMS centos6 centos7 debian7 debian8 freebsd macosx sunos suse11.2 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (flatbuffers VERSION 1.2.0-cb1 PLATFORMS centos6 centos7 debian7 debian8 freebsd macosx sunos suse11.2 ubuntu12.04 ubuntu14.04 windows_msvc)
DECLARE_DEP (gperftools VERSION 2.4-cb3 PLATFORMS windows_msvc)
DECLARE_DEP (icu4c VERSION 54.1.0 PLATFORMS windows_msvc)
DECLARE_DEP (icu4c VERSION 54.1-cb7 PLATFORMS centos6 centos7 debian7 debian8 freebsd macosx sunos suse11.2 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (jemalloc VERSION 4.1.0-cb2 PLATFORMS windows_msvc)
DECLARE_DEP (jemalloc VERSION 4.0.4-cb2 PLATFORMS centos6 centos7 debian7 debian8 freebsd sunos suse11.2 ubuntu12.04 ubuntu14.04)
#maxosx remains on 4.0.4-cb1 until CBIT-4625 is resolved (missing dependencies on osx build slave)
DECLARE_DEP (jemalloc VERSION 4.0.4-cb1 PLATFORMS macosx)
DECLARE_DEP (libevent VERSION 2.1.4-alpha-dev PLATFORMS windows_msvc)
DECLARE_DEP (libevent VERSION 2.0.22-cb1 PLATFORMS macosx)
DECLARE_DEP (libevent VERSION 2.0.22-cb2 PLATFORMS centos6 centos7 debian7 debian8 freebsd sunos suse11.2 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (openssl VERSION 1.0.1h PLATFORMS windows_msvc)
DECLARE_DEP (pysqlite2 VERSION 0ff6e32-cb1 PLATFORMS centos6 centos7 debian7 debian8 macosx sunos suse11.2 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (python-snappy VERSION c97d633 PLATFORMS windows_msvc)
DECLARE_DEP (python-snappy VERSION c97d633-cb1 PLATFORMS centos6 centos7 debian7 debian8 freebsd macosx sunos suse11.2 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (snappy VERSION 1.1.1 PLATFORMS windows_msvc)
DECLARE_DEP (snappy VERSION 1.1.1-cb2 PLATFORMS centos6 centos7 debian7 debian8 freebsd macosx sunos suse11.2 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (v8 VERSION 4.8-cb4 PLATFORMS centos6 centos7 debian7 debian8 macosx sunos suse11.2 ubuntu12.04 ubuntu14.04 windows_msvc)
DECLARE_DEP (v8 VERSION b08066f-cb1 PLATFORMS freebsd)
