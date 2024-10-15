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
standard when used. We hope to phase these out; see below.

# A history of CMake and third-party dependencies in Server builds

## Early days and problems

Since the dawn of time, we have shipped cbdeps binaries by copying them
under CMAKE_INSTALL_PREFIX as part of the initial CMake run. This was
necessary because, while CMake offered functions to "find" the deps for
the purposes of compiling and linking, it didn't have any mechanism to
install those deps into the final installation location. This has led to
a number of minor problems, such as unnecessary files being included in
Server packages. It's also messy to maintain, as each cbdeps package
needs to have its own CMakeLists.txt which copies just the right stuff,
and/or the cbdeps build scripts need to prune the contents of any
shipping directories.

Also since the dawn of time, we have added CMAKE_INSTALL_PREFIX to
CMAKE_PREFIX_PATH. This was hack to allow dep binaries to be "found" by
CMake's find functions and scripts. Over the years we've modified most
packages and their corresponding FindCouchbaseXXX.cmake scripts to
instead "find" the dependency from where the cbdeps downloads are
unpacked in the build tree (`build/tlm/deps/xxx.exploded`). However,
while CMake is clever enough to link binaries to libs found in this way,
it is not always clever enough to set those binaries up with RPATHs that
point to all the necessary build-tree locations. This led to situations
where binaries could not be run from the build tree without additional
hacks like setting `LD_LIBRARY_PATH`.

On the whole, this is a pretty scattered solution with a lot of strange
historic warts, that is challenging to maintain.

## "Modern CMake"

CMake has improved significantly over the years (albeit in highly
esoteric and poorly-documented ways), and these days there are a variety
of newer conventions for using it that are loosely grouped under the
name "Modern CMake". The main guidelines are:

* Within `CMakeLists.txt` files, as much as possible, declare
  dependencies on *targets* rather than *files*. In particular, if a
  binary depends on a library, use
  `target_link_libraries(*binary-target* *lib-target*), rather than
  `target_link_libraries(*binary-target* */path/to/library*)`. Targets
  in CMake have grown a number of features such as knowing their
  associated include directories, compile directives, and so on, mostly
  eliminating the need for `include_directories()` and
  `add_compile_definitions()`.

* Use `find_package()` where possible, rather than collections of
  `find_library()` and `find_path()`. In particular, where possible,
  third-party packages should come with bespoke `PACKAGEConfig.cmake` or
  `package-config.cmake` files that define IMPORTED targets that CMake
  can use, including all the details like platform-specific compile
  directives, include paths, and so on.

The above simplifies creating a CMake project considerably, and we have
been transitioning to those rules where possible. In particular, some
existing `FindCouchbaseXXXX.cmake` modules now declare IMPORTED
targets which the rest of the build can depend on.

## Moving forward

The ideal would be that all cbdeps packages include the necessary CMake
`config.cmake` files as mentioned above. To support this, cbdeps has a
new feature: when adding a package that does *not* contain a
`CMakeLists.txt`, `CBDownloadDeps.cmake` will set the CMake cache
variable `<dep>_ROOT` to point to the `dep.exploded` directory in the
build tree. `find_package(dep)` uses this directory preferentially to
find the `-config.cmake` files.

The first cbdeps package to make use of this feature was Faiss. However,
we do still have a `FindCouchbaseFaiss.cmake`, which wraps a call to
`find_package(faiss)` and adds some additional logic.

We have now added a cbdeps package for AWSSDK, and this one requires no
`FindCouchbaseAWSSDK.cmake` at all - fusion can use a bog-standard
`find_package(AWSSDK)` call.

## Creating cbdeps packages compatible with Modern CMake

If a package is itself built with CMake, ideally it will also use
"export sets" and create the required CMake files as part of its own
installation process. AWSSDK and Faiss work this way (although Faiss
does not include references for its own dependencies, such as OpenBLAS,
which is part of why `FindCouchbaseFaiss.cmake` currently still needs to
exist).

If a package is not built with CMake, our cbdeps build scripts can
create an appropriate CMake config file to go with it. jemalloc does
this today. Doing this *comprehensively* is pretty involved, but a
simple good-enough configuration is not really any more difficult than
what is already done in `FindCouchbaseXxxx.cmake`.

## Shipping dependency libraries

The one thing that all of the above does not fix is the fact that CMake
has no facilities for *installing* dependent libraries, or any other
binaries that were not built as a part of the project itself. If a CMake
target was not initially created via `add_library(SHARED)` or
`add_executable()`, CMake refuses to allow `install(TARGETS <target>)`
to work, leaving you to implement it manually with eg. `install(FILES)`.
More frustratingly, even though CMake does generally know about any
target's transitive dependencies (eg., "fusion" depends on "AWSSDK"), it
makes it impossible to walk this dependency tree - see some of the
longer comments in `FindCouchbaseGo.cmake` for some more about that. So
there's no generalized way to implement "install this binary and all of
its dependencies".

However, recent versions of CMake have added support for determining
"runtime dependency sets". This does effectively the equivalent of `ldd`
to determine all of a *file's* dependencies - including those deps which
came from a cbdeps package - and from there you can arrange to copy this
binaries into the installation tree.

This, combined with some annoyingly hand-crafted CMake scripts and
`install(CODE)`, finally allows a solution to this problem. This was
first used to implement the "standalone dev/admin tools packages"
feature, along with using CMake's "installation components" feature -
see details in `CouchbaseStandalonePackages.cmake`.

I have now written a new CMake function `InstallWithDeps()` (in
`CouchbaseInstall.cmake`), which can replace the basic CMake `install()`
directive for installing an executable or shared library along with all
of its dependencies. The first target to use this is `magma_shared` -
this library depends on fusion, which in turn depends on AWSSDK. Since
the AWSSDK cbdeps package has no CMakeLists.txt nor
`FindCouchbaseAWSSDK.cmake`, this call to `InstallWithDeps()` is the
sole thing which causes the AWSSDK shared libraries to get installed as
part of the Server package. This the model that all Server libraries and
cbdeps packages should strive towards.

## The future

We should incrementally work towards the following:

1. Update all cbdeps packages to include the necessary CMake
   `-config.cmake` files so they are compatible with `find_package()`.

2. Ensure all targets built as part of Server use "Modern CMake"
   conventions, in particular only declaring dependencies on targets
   (including IMPORTED targets from cbdeps package) and removing calls
   to `add_compile_definitions()` and `include_directories()`.

3. Simplify all `FindCouchbaseXXXX.cmake` packages to only run
   `find_package()` and drop any custom-installation stuff they may
   have. Ultimately, eliminate `FindCouchbaseXXXX.cmake` packages
   wherever possible in favor of just calling `find_package()` directly.

4. Replace most `install(TARGETS)` throughout the Server build with
   calls to `InstallWithDeps()`.

5. Ultimately, remove the code in `tlm/CMakeLists.txt` that adds
   `CMAKE_INSTALL_PREFIX` to `CMAKE_PREFIX_PATH`.

In addition, some other consolidation can be done:

1. Extend `InstallWithDeps()` to include the ability to install
   additional components to different installation directories,
   ultimately removing the functions in
   `CouchbaseStandalonePackage.cmake`.

2. Keep looking for ways to improve `GoModBuild()`. Currently
   `GoModBuild()` does a sort of partial configure-time walk of the
   dependency tree (the best that CMake can allow) to find all the
   dependency library files, but it needs to do this so that the
   *compiler* can be told where they all exist - again, because CMake
   keeps its more comprehensive solution to this problem locked in a
   walled garden that only C/C++ targets can access. This is only
   tangentially related to all of this discussion about cbdeps, but if
   CMake ever offers a better solution, we should explore it.
