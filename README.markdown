# tlm - "Top-level Makefile" for Couchbase Server

This repository contains a number of tools and scripts for building
Couchbase Server. The main interesting part is the top-level CMakeLists.txt,
which is the entry point for a complete Server build. There are also a number
of utility CMake libraries in cmake/Modules.

## Software requirements

* C/C++ compiler; one of:
  * gcc 10.2 or newer
  * Visual Studio 2017 or newer
  * Xcode
  * clang
* CMake 3.19 or newer
* Google repo (in order to fetch all of the source code)
* [Ninja](https://ninja-build.org) build
* ccache may speed up the development cycle when clang / gcc is used

Our production builds currently use gcc-10.2.0 on Linux platforms;
Visual Studio 2017 on Windows; and Xcode 11.3.1 on MacOS.

### Requirements on Windows

In addition to Visual Studio, gcc must be installed and on the PATH for
building some of the Go language tools. We use a recent version of MinGW for
this.

Couchbase uses Google repo to stitch together all of the individual git
repositories. Repo is implemented in python, but it's unfortunately using
features not available on python for windows. We use a modified version of
repo from http://github.com/esrlabs/git-repo.

It is important to set the git config option `core.longpaths` to `true`.

In general it is quite challenging to get a Windows box configured perfectly
for building Couchbase Server. If you are familiar with Ansible, it may be
useful to look at the Ansible scripts we use to configure our build VMs.
They are available here: https://github.com/couchbase/build-infra/tree/master/ansible/windows/couchbase-server/window2016

## How to build

Couchbase utilizes [CMake][cmake_link] in order to provide build support for
a wide range of platforms. Internal builds of Couchbase (and hence what we test)
use Ninja. Other systems _may_ however work, but you're pretty much on your own
if you try to use them.

### Simple build (Linux and MacOS)

If you just want to build Couchbase and without any special configuration,
you may use the `Build.sh` script we supplied for your convenience:

    trond@ok > mkdir source
    trond@ok > cd source
    trond@ok source> repo init -u https://github.com/couchbase/manifest -m branch-master.xml
    trond@ok source> repo sync
    trond@ok source> ./Build.sh

This would install the build software in a subdirectory named `install`. `Build.sh`
accepts a limited set of options which may be used to "tweak" your build:

    -s source_root  Source directory (default: current working directory (aka cwd))
    -b build_root   Build directory (default: <cwd>/build)
    -i install_root Install directory (default: <cwd>/install)
    -X              Set Mac platform to x86_64 (Only needed when
                    building on Mac running arm64)
    -T              Enable thread sanitizer
    -A              Enable address sanitizer
    -U              Enable undefined behavior sanitizer
    -R              Set build type to RelWithDebInfo

`Build.sh` respects the following environment variables:

* `CB_PARALLEL_LINK_JOBS` The number of link jobs to run in parallel.
  Due to static linking (and C++) each link process may consume *a lot*
  of memory (I've seen it go beyond 1GB). The default is set to two
  link steps in parallel.
* `EXTRA_CMAKE_OPTIONS` Extra options you would like to pass on to
  cmake.
* `CMAKE_BUILD_TYPE` By default it produce a `Debug` build; this may be
  set to `Debug`, `Release`, `RelWithDebInfo` or `MinSizeRel`.

### Simple build (Windows)

The build is not optimized for Windows, but the following steps should work. Start with the
same "repo init" and "repo sync" steps as above, then run:

    tlm\win32\environment.bat
    mkdir build
    cd build
    cmake -G Ninja -D CMAKE_C_COMPILER=cl -D CMAKE_CXX_COMPILER=cl -D CMAKE_BUILD_TYPE=RelWithDebInfo ..
    ninja install

### Running Couchbase Server locally
Instructions to run Couchbase Server locally (for development) are provided
in the [ns_server repo](https://github.com/couchbase/ns_server#running).

### Specifying what to build

The default build target if not explicitly specified is `all` - this builds all
binaries required for the shipping product. This is sufficient to run Couchbase
Server itself, but doesn't include unit test / benchmark binaries etc.

The following additional targets are available:

* `everything` : Builds both production binaries, along with unit tests, benchmarks etc for
all subprojects.
* `install` : Standard CMake target; builds all production binaries and installs them to
  `CMAKE_INSTALL_PREFIX`.
* `test` : Run all the unit tests
* `<PROJECT>_everything` : Builds all binaries for the specific project, e.g `platform_everything`.
* `<PROJECT>/test` : Run all the unit tests for the specific project.

### cbbackupmgr, cbimport and cbexport

Please note that the Community Edition packages on couchbase.com contain `cbbackupmgr`, `cbimport` and `cbexport`.
They will not be built when compiling from source as the source code is private. As well as not having these
programs the sample buckets cannot be loaded as it uses `cbimport`. To workaround this issue `cbbackupmgr`,
`cbimport` and `cbexport` can be copied from the Community Edition binaries.

**End of the basic build information**

The remainder of this document covers certain special cases for building
Couchbase Server. You likely will not be interested in anything beyond this
point unless you work for Couchbase and have specific development issues to
work on.

### "Best" Developer experience

If you're building Couchbase Server more than just a one-off, there are
a few modifications you can make to make your life easier and speed up
your compile-edit-debug cycle.

Use a non-optimised (Debug) build. This is around 2x faster to compile,
and also improves debuggability over the default _RelWithDebInfo_ build
type. Note it does produce slower code, so this isn't suitable if you're
doing any performance measuremnts.

Another tip would be to put the following in your `~/.profile` file:

```commandline
export CMAKE_GENERATOR=Ninja
export CB_PARALLEL_LINK_JOBS=4
```

And cmake would use Ninja by default if it is available on your system so
that you no longer need to pass `-G Ninja` and `-D CB_PARALLEL_LINK_JOBS=4`
every time you want to run cmake.

#### Tips for people transitioning from make

* Ninja can build specific targets just like make, simply specify the name
of the target as you would with make:
```commandline
ninja memcached
```

* Ninja can also build only a single project of the tree (like make),
however the syntax is a bit different - instead of changing into the
subdirectory and running `make`, you _always_ run Ninja from the toplevel
build dir, but specify `<project>/all` as the target - for example:
```commandline
ninja kv_engine/all
```

* Similary to just compile and install a single project specify
`<project>/install` as the target to build:
```commandline
ninja couchstore/install
```

* You only have to explicitly run CMake (`cmake -G Ninja ...`) the first time a
  build directory is setup, after then you just need to invoke `ninja` to build
  whatever has changed. This includes both local changes and if you pull new
  code from git. Ninja will automagically invoke CMake if necessary
  (for example if source files have been added / removed).

### Customize your builds

CMake offers a wide range of customizations, and this chapter won't
try to cover all of them. There is plenty of documentation available
on the [webpage](http://www.cmake.org/cmake/help/documentation.html).

There is no point of trying to keep a list of all tunables in this
document. To find the tunables you have two options: look in
`cmake/Modules/*.cmake` or you may look in the cache file generated
during a normal build (see `build/CMakeCache.txt`)

There are two ways to customize your own builds. You can do it all by
yourself by passing the options via `-D KEY=VALUE` as part of
invoking cmake directly:

    trond@ok build> cmake -D KEY=VALUE <path_to_source>

Or pass extra options to the convenience `Build.sh` script provided:

    trond@ok source> EXTRA_CMAKE_OPTIONS="-D KEY=VALYE" ./Build.sh

## Static Analysis

There are pre-canned build rules to allow you to run the
[Clang Static Analyzer][clang_static_analyzer_link] against the Couchbase
codebase.

So far this has only been tested on OS X, using Clang shipping as part
of OS X Developer Tools. It *should* be possible to also run on other
platforms which Clang/LLVM is available, however this isn't tested.

### Prerequisites

* Install `clang` (from OS X Developer Tools). If you can build from source
  you should already have this :)
* Download and extract clang Static Analyzer tools
  (from [clang-analyzer.llvm.org][clang_static_analyzer_link]).
  Note that while the actual analyzer functionality is built into
  clang, this is needed for `scan-build` and `scan-view` tools to
  invoke and display the analyser results.

### Running

*  Add `scan-build` and `scan-view` to your path:

        export PATH=$PATH:/path/to/scan-build

*  Run `make analyze` at the top-level to configure clang-analyser as the
   'compiler':

        make analyze

*  At the end you will see a message similar to the following - Invoke the
   specified command to browse the found bugs:

        scan-build: 31 bugs found.
        scan-build: Run 'scan-view /source/build-analyzer/analyser-results/2014-06-05-173247-52416-1' to examine bug reports.

## Address / Thread / UndefinedBehavior Sanitizers

There are pre-canned build rules to allow you to build with
[ThreadSanitizer][thread_sanitizer_link] to detect threading issues,
[AddressSanitizer][address_sanitizer_link] to detect memory errors, or
[UndefinedBehaviorSanitizer][undefined_sanitizer_link] to detect
undefined behavior.

### Prerequities

* A compiler which supports Address / Thread / UndefinedBehavior
  Sanitizer. Recent version of Clang (3.2+) or GCC (4.8+) are claimed
  to work. Currently automatied tests use GCC 7 / Clang 3.9.

### Running

* Ensure that the compiler supporting *Sanitizer is chosen by
  CMake. If it's the system default compiler there is nothing to do;
  otherwise you will need to set both `CC` and `CXX` environment
  variables to point to the C / C++ compiler before calling the build
  system.

* Pass the variable `CB_THREADSANITIZER=1` / `CB_ADDRESSSANITIZER=1` /
  `CB_UNDEFINEDSANITIZER=1` to CMake.

ThreadSanitizer one liner for a Ubuntu-based system where Clang isn't
the default system compiler:

        CC=clang CXX=clang++ make EXTRA_CMAKE_OPTIONS="-D CB_THREADSANITIZER=1"

and for AddressSanitizer:

        CC=clang CXX=clang++ make EXTRA_CMAKE_OPTIONS="-D CB_ADDRESSSANITIZER=1"

similary for UndefinedBehaviorSanitizer:

        CC=clang CXX=clang++ make EXTRA_CMAKE_OPTIONS="-D CB_UNDEFINEDSANITIZER=1"

* Run one or more tests. Any issues will be reported (to stderr by default).

### Customizing Address / Thread / UndefinedBehavior Sanitizer

See `cmake/Modules/CouchbaseThreadSanitizer.cmake` CMake fragment for
how ThreadSanizer is configured.

See the `TSAN_OPTIONS` environment variable (documented on the
ThreadSanitizer [Flags][thread_sanitizer_flags] wiki page) for more
information on configuring.

Similarly for AddressSanitizer / UndefinedBehaviorSanitizer see
`cmake/Modules/CouchbaseAddressSanitizer.cmake` or
`cmake/Modules/CouchbassUndefinedBehaviorSanitizer.cmake`, and the
`ASAN_OPTIONS` / `UBSAN_OPTIONS` environment variable (documented on
the AddressSanitizer [Flags][address_sanitizer_flags] wiki page) for
details..

[cmake_link]: http://www.cmake.org/cmake/
[clang_static_analyzer_link]: http://clang-analyzer.llvm.org
[thread_sanitizer_link]: https://code.google.com/p/thread-sanitizer/wiki/CppManual
[thread_sanitizer_flags]: https://code.google.com/p/thread-sanitizer/wiki/Flags
[address_sanitizer_link]: https://github.com/google/sanitizers/wiki/AddressSanitizer
[address_sanitizer_flags]: https://github.com/google/sanitizers/wiki/AddressSanitizerFlags
[undefined_sanitizer_link]: https://github.com/google/sanitizers/wiki/AddressSanitizer
