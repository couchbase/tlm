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
DECLARE_DEP (breakpad VERSION 1e455b5-cb10 PLATFORMS centos6 centos7 debian7 suse11.3 ubuntu12.04 ubuntu14.04 windows_msvc)
DECLARE_DEP (curl VERSION 7.35.0 PLATFORMS windows_msvc)
DECLARE_DEP (curl VERSION 7.40.0-cb2 PLATFORMS centos6 centos7 debian7 freebsd sunos suse11.3 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (erlang VERSION R16B03-1-cb1 PLATFORMS centos6 centos7 debian7 freebsd macosx sunos suse11.3 ubuntu12.04 ubuntu14.04 windows_msvc)
DECLARE_DEP (flatbuffers VERSION 1.1.0-cb1 PLATFORMS centos6 centos7 debian7 freebsd macosx sunos suse11.3 ubuntu12.04 ubuntu14.04 windows_msvc)
DECLARE_DEP (gperftools VERSION 2.4-cb3 PLATFORMS windows_msvc)
DECLARE_DEP (icu4c VERSION 53.1.0 PLATFORMS windows_msvc)
DECLARE_DEP (icu4c VERSION 263593-cb5 PLATFORMS centos6 centos7 debian7 freebsd macosx sunos suse11.3 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (jemalloc VERSION 5d9732f-cb5 PLATFORMS centos6 centos7 debian7 freebsd macosx sunos suse11.3 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (libevent VERSION 2.1.4-alpha-dev PLATFORMS windows_msvc)
DECLARE_DEP (libevent VERSION 2.0.22-cb1 PLATFORMS centos6 centos7 debian7 freebsd macosx sunos suse11.3 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (openssl VERSION 1.0.1h PLATFORMS windows_msvc)
DECLARE_DEP (pysqlite2 VERSION 0ff6e32-cb1 PLATFORMS centos6 centos7 debian7 macosx sunos suse11.3 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (python-snappy VERSION c97d633 PLATFORMS windows_msvc)
DECLARE_DEP (python-snappy VERSION c97d633-cb1 PLATFORMS centos6 centos7 debian7 freebsd macosx sunos suse11.3 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (snappy VERSION 1.1.1 PLATFORMS windows_msvc)
DECLARE_DEP (snappy VERSION 1.1.1-cb2 PLATFORMS centos6 centos7 debian7 freebsd macosx sunos suse11.3 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (v8 VERSION 3.23.6 PLATFORMS windows_msvc)
DECLARE_DEP (v8 VERSION e24973a-cb2 PLATFORMS centos6 centos7 debian7 macosx sunos suse11.3 ubuntu12.04 ubuntu14.04)
DECLARE_DEP (v8 VERSION b08066f-cb1 PLATFORMS freebsd)
