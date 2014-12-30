#
# Keep the list sorted alphabetically, and the platforms alphabetically.
# The syntax is:
#
# DECLARE_DEP (name VERSION version-revision PLATFORMS platform1 platform2)
#

DECLARE_DEP (breakpad VERSION 6fa2f26-cb1
                      PLATFORMS centos6 centos7 macosx ubuntu12.04 ubuntu14.04)
DECLARE_DEP (curl VERSION 7.35.0 PLATFORMS windows_msvc)
DECLARE_DEP (curl VERSION 7.39.0-cb1 PLATFORMS centos7 sunos ubuntu14.04)
# Erlang - R16B03-cb2 contains OSX-specific packaging changes;
#          Windows isn't affected hence still uses R16B03.
DECLARE_DEP (erlang VERSION R16B03 PLATFORMS windows_msvc)
DECLARE_DEP (erlang VERSION R16B03-cb2 PLATFORMS macosx)
DECLARE_DEP (gperftools VERSION 2.2 PLATFORMS windows_msvc)
DECLARE_DEP (icu4c VERSION 53.1.0 PLATFORMS windows_msvc)
# Jemalloc - cb1 was incorrectly uploaded as cb2 for centos6; so cb3 created
#            just for CentOS6; which contains the same changes as per cb2 for
#            the other platforms (je_ prefix on symbols).
DECLARE_DEP (jemalloc VERSION 5d9732f-cb2
                      PLATFORMS macosx ubuntu12.04 ubuntu14.04 debian7 sunos)
DECLARE_DEP (jemalloc VERSION 5d9732f-cb3 PLATFORMS centos6 centos7)
DECLARE_DEP (libevent VERSION 2.1.4-alpha-dev PLATFORMS windows_msvc)
DECLARE_DEP (libevent VERSION 2.0.21-cb1
                      PLATFORMS centos7 macosx sunos ubuntu14.04)
DECLARE_DEP (libstdcxx VERSION 4.9.2-cb1 PLATFORMS ubuntu12.04)
DECLARE_DEP (openssl VERSION 1.0.1h PLATFORMS windows_msvc)
DECLARE_DEP (python-snappy VERSION c97d633 PLATFORMS windows_msvc)
DECLARE_DEP (snappy VERSION 1.1.1 PLATFORMS windows_msvc)
DECLARE_DEP (snappy VERSION 1.1.1-cb1 PLATFORMS centos7 sunos ubuntu14.04)
DECLARE_DEP (v8 VERSION 3.23.6 PLATFORMS windows_msvc)
DECLARE_DEP (v8 VERSION e24973a-cb1 PLATFORMS centos7 macosx sunos ubuntu14.04)
