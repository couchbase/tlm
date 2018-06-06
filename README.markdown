# tlm - Top-level Makefile

What's this, then? The tlm project contains the make information for
building Couchbase on multiple platforms.

**Table of Contents**

- [How to build](#user-content-how-to-build)
	- [Simple](#user-content-simple-build)
	- [Customize your builds](#user-content-customize-your-builds)
	- [Microsoft Windows](#user-content-microsoft-windows)
- [Static Analysis](#user-content-static-analysis)

## Software requirements

* C/C++ compiler:
  * Visual Studio 2015
  * clang
  * gcc
* ccache may speed up the development cycle when clang / gcc is used)
* CMake
* Google repo (in order to fetch all of the source code)

## How to build

Couchbase utilizes [CMake][cmake_link] in order to provide build
support for a wide range of platforms. CMake isn't a build system
like GNU Autotools, but a tool that generates build information for
external systems like: Visual Studio projects, XCode projects and
Makefiles to name a few. The nightly build of Couchbase (and hence
what we test) is using Makefiles (and ninja on Windows). Other
systems _may_ however work, but you're pretty much on your own if
you try to use them.

### Simple build

If you just want to build Couchbase and without any special
configuration, you may use the Makefile we've supplied for your
convenience:

    trond@ok > mkdir source
    trond@ok > cd source
    trond@ok source> repo init -u git://github.com/couchbase/manifest -m branch-master.xml
    trond@ok source> repo sync
    trond@ok source> make

This would install the build software in a subdirectory named
`install`. To change this you may run:

    trond@ok source> make EXTRA_CMAKE_OPTIONS='-DCMAKE_INSTALL_PREFIX=/opt/couchbase'

### Customize your builds

CMake offers a wide range of customizations, and this chapter won't
try to cover all of them. There is plenty of documentation available
on the [webpage](http://www.cmake.org/cmake/help/documentation.html).

There is no point of trying to keep a list of all tunables in this
document. To find the tunables you have two options: look in
`cmake/Modules/*.cmake` or you may look in the cache file generated
during a normal build (see `build/CMakeCache.txt`)

There are two ways to customize your own builds. You can do it all by
yourself by invoking cmake yourself:

    trond@ok > mkdir source
    trond@ok > mkdir build
    trond@ok > cd source
    trond@ok source> repo init -u git://github.com/couchbase/manifest -m branch-master.xml
    trond@ok source> repo sync
    trond@ok source> cd ../build
    trond@ok build> cmake -D CMAKE_INSTALL_PREFIX=/opt/couchbase -D CMAKE_BUILD_TYPE=Debug -D DTRACE_FOUND:BOOL=True -D DTRACE:FILEPATH=/usr/sbin/dtrace CMAKE_PREFIX_PATH="/opt/r14b04;/opt/couchbase"
    trond@ok build> gmake all install

Or pass extra options to the convenience Makefile provided:

    trond@ok > mkdir source
    trond@ok > mkdir build
    trond@ok > cd source
    trond@ok source> repo init -u git://github.com/couchbase/manifest -m branch-master.xml
    trond@ok source> repo sync
    trond@ok source> make PREFIX=/opt/couchbase CMAKE_PREFIX_PATH="/opt/r14b04;/opt/couchbase" EXTRA_CMAKE_OPTIONS='-D DTRACE_FOUND:BOOL=True -D DTRACE:FILEPATH=/usr/sbin/dtrace'

Use `CMAKE_PREFIX_PATH` to specify a "list" of directories to search
for tools/libraries if they are stored in "non-standard"
locations. Ex:

    CMAKE_PREFIX_PATH="/opt/r14b04;/opt/couchbase;/opt/local"

### Microsoft Windows

Couchbase use google repo to stich together all of the individual git
repositories. Repo is implemented in python, but it's unfortunately using
features not available on python for windows. The workaround I've been using
(and tested) is by using repo from http://github.com/esrlabs/git-repo. To
avoid any "problems" I'm performing all of the repo / git steps through
the bash shell provided with git (remember to enable support for creating
symbolic links for your user: "Windows Settings", "Security Settings",
"Local policies", "User Rights assignment" and locate the "Create symbolic
links" and add the user). I'm performing all of the build steps
through `command.com`.

I've only tested this on Windows 10PRO, but it may work with other (newer)
versions of windows:

* Install Microsoft Visual Studio 2015
* Install git from https://git-scm.com (I configured it to only be available from within bash)
* Install google repo (use the one from github.com/esrlabs/git-repo)
* Install cmake
* Install mingw via Chocolatey package manager (http://chocolatey.org) and
  add `c:\tools\mingw64\bin` to PATH

Before you can start the build process you need to set a lot of environemnt
variables, and all of them is located in `tlm\win32\environment.bat`. Open
up `command.com` and run the command above in the root of the source directory.

You could now be able to build Couchbase by executing:

    C:\compile> repo init -u git://github.com/couchbase/manifest -m branch-master.xml
    C:\compile> repo sync
    C:\compile> tlm\win32\environment.bat
    C:\compile> nmake

And that should be it

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
