# CMake modules

Some brief description / explanation of the use of certain files and
variables.


## CouchbaseXXX.cmake files

These files are used to define Couchbase-specific macros and
variables. For example, they define the the various compiler flags for
each supported compiler, supported memory allocator options, etc.

### Couchbase<Compiler>Options.cmake

These files define the default compilation flags for each of the
various supported compilers.

Descriptions of specific variables of interest:

* CMAKE_CXX_FLAGS_RELEASE / CMAKE_CXX_FLAGS_RELWITH_DEBINFO: Compiler
  flags for Release and RelWIthDebInfo builds. Note that as of 4.0 we
  actually ship a RelWithDebInfo build (to maximise our ability to
  debug issues from the field) and hence
  CMAKE_CXX_FLAGS_RELWITH_DEBINFO are overridden to be as optimized
  as the normal Release flags, but keeping debug enabled.

* CMAKE_CXX_FLAGS_DEBUG: Compiler flags for Debug builds. We override
  this to explicitly set Debug to have Optimization disabled (by
  default it just uses the implicit default). This allows us to use
  this variable to selectively force Debug flags (i.e. optimization
  off) for selected targets, such as unit tests.

* CB_C_FLAGS_NO_OPTIMIZE / CB_CXX_FLAGS_NO_OPTIMIZE: Compiler flags to
  disable optimization. This allows us to use this variable to
  selectively force optimization off for selected targets, such as
  unit tests.

## FindCouchbaseXXX.cmake files

These files are similar to the standard CMake FindXXX.cmake files,
except Couchbase-specific files. The main purpose of the 'Couchbase'
prefix is just to make it obvious which are ours and which are
standard when used.
