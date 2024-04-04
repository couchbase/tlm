#
# This is the toplevel CMakeLists.txt that is used to build Couchbase
#
CMAKE_MINIMUM_REQUIRED(VERSION 3.19)

STRING(REGEX REPLACE "[ ]" "a" modified_source_dir "${CMAKE_SOURCE_DIR}")
IF (NOT modified_source_dir STREQUAL CMAKE_SOURCE_DIR)
  MESSAGE(FATAL_ERROR "Couchbase cannot be built in a source directory containing a space character")
ENDIF (NOT modified_source_dir STREQUAL CMAKE_SOURCE_DIR)

STRING(REGEX REPLACE "[ ]" "a" modified_binary_dir "${CMAKE_BINARY_DIR}")
IF (NOT modified_binary_dir STREQUAL CMAKE_BINARY_DIR)
  MESSAGE(FATAL_ERROR "Couchbase cannot be built in a build directory containing a space character")
ENDIF (NOT modified_binary_dir STREQUAL CMAKE_BINARY_DIR)

# The PROJECT() macro sets it's own default build type, so need to specify
# ours first.
IF (NOT DEFINED CMAKE_BUILD_TYPE)
   SET(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING
       "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel."
       FORCE)
ENDIF ()

# Include our custom build type (DebugOptimized) in the list.
SET(CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING
    "Choose the type of build, options are: Debug DebugOptimized Release RelWithDebInfo MinSizeRel."
    FORCE)

# Select the compiler to use (must be performed before the project()
# command).
LIST (APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/tlm/cmake/Modules/")
INCLUDE(CouchbaseSelectCompiler)

PROJECT("Couchbase")

#
# Choose deployment target on macOS.
# As of Morpheus the minimum supported platform is Ventura (13.0).
# Unfortunately the current CV is stuck on Catalina, but luckily we've
# got Ventura builders on the way. Given our new builders is arm and
# the old ones is x86 we may set the macos target to 13 while introducing
# the new builders.
if(APPLE)
    if (CB_OVERRIDE_OSX_DEPLOYMENT_TARGET)
        set(target ${CB_OVERRIDE_OSX_DEPLOYMENT_TARGET})
    elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
        set(target "10.15")
    elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "arm64")
        set(target "13.0")
    else()
        message(FATAL_ERROR "Unknown macOS CMAKE_HOST_SYSTEM_PROCESSOR "
                "'${CMAKE_HOST_SYSTEM_PROCESSOR}'. "
                "Supported values: x86_64 or arm64.")
    endif()
    set(CMAKE_OSX_DEPLOYMENT_TARGET ${target} CACHE STRING
            "Minimum supported version of macOS" FORCE)
endif()

# We also have a "sub-project", the tools project, which requires a few
# additional INSTALL() and other directives. Those targets should
# install into this directory.
SET (TOOLS_INSTALL_PREFIX "${PROJECT_BINARY_DIR}/tools-package-install")

# Make sure INSTALL(CODE) blocks know about TOOLS_INSTALL_PREFIX too.
INSTALL (CODE "SET (TOOLS_INSTALL_PREFIX \"${TOOLS_INSTALL_PREFIX}\")")

# Double-check that "repo sync" (or the user) didn't mess up our copyfiles
MACRO (CHECK_COPYFILE source_filename target_filename)
  EXECUTE_PROCESS(
    COMMAND "${CMAKE_COMMAND}" -E compare_files --ignore-eol
      "${PROJECT_SOURCE_DIR}/${source_filename}"
      "${PROJECT_SOURCE_DIR}/${target_filename}"
    RESULT_VARIABLE _retval)
  IF (_retval GREATER 0)
    MESSAGE (FATAL_ERROR "${source_filename} is different than ${target_filename}!! "
      "If you are editing one of those files, ensure that both copies are identical.")
  ENDIF ()
ENDMACRO ()
CHECK_COPYFILE (tlm/CMakeLists.txt CMakeLists.txt)
CHECK_COPYFILE (tlm/third-party-CMakeLists.txt third_party/CMakeLists.txt)

OPTION(COUCHBASE_KV_COMMIT_VALIDATION
       "Only build modules used by KV commit validation"
       OFF)

# This option should be be enabled in the early phases of development
# (e.g. when developing off master) and is used to guard additional
# runtime checks which are desirable to report during testing; but
# should not trigger in production.  As such this option should be set
# to OFF before we move into the Beta/pre-release phase.
#
# Example usage - asserting that statistical counters are of an
# expected range (don't underflow) - we would like to detect such
# bugs; but they arn't serious enough to warrant crashing in a
# customer environment.
OPTION(CB_DEVELOPMENT_ASSERTS
       "Enable additional asserts which abort execution if they fail."
       ON)

# Always run with assertions for CV
IF(COUCHBASE_KV_COMMIT_VALIDATION)
    SET(CB_DEVELOPMENT_ASSERTS ON)
ENDIF(COUCHBASE_KV_COMMIT_VALIDATION)

IF (CB_DEVELOPMENT_ASSERTS)
   MESSAGE(STATUS "Enabling CB_DEVELOPMENT_ASSERTS")
   ADD_DEFINITIONS(-DCB_DEVELOPMENT_ASSERTS)
ENDIF (CB_DEVELOPMENT_ASSERTS)

IF ($ENV{JETBRAINS_IDE})
   SET(JETBRAINS_CLION_IDE True CACHE BOOL "Build Couchbase under CLion")
ENDIF ($ENV{JETBRAINS_IDE})

IF (DEFINED JETBRAINS_CLION_IDE)
   ADD_DEFINITIONS(-DJETBRAINS_CLION_IDE)
ENDIF (DEFINED JETBRAINS_CLION_IDE)

IF (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    if (JETBRAINS_CLION_IDE)
        # Cmake use directories like: cmake-build-[build-type]-[toolchain]
        # Lets let the install directory be cmake-install-[build-type]-[toolchain]
        string(REGEX REPLACE "(.*)build(.*)" "\\1install\\2" cb_install_dir ${CMAKE_BINARY_DIR})
        set(CMAKE_INSTALL_PREFIX "${cb_install_dir}" CACHE STRING "The install location" FORCE)
    else ()
        SET(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/install" CACHE STRING
            "The install location" FORCE)
    endif ()
    LIST(APPEND CMAKE_PREFIX_PATH "${CMAKE_INSTALL_PREFIX}")
ENDIF (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

SET (COUCHBASE_SERVER_BUILD True CACHE BOOL "Indicating this is a server build")

# GNUInstallDirs (a standard CMake module) sets the variable
# CMAKE_INSTALL_LIBDIR. libcouchbase and faiss (which we will add to the
# Server build in a moment) call GNUInstallDirs and then uses that
# variable to determine the installation location. On RHEL-based
# systems, that ends up putting those shared libraries into lib64/. We
# don't want that, so we override that variable here - fortunately
# GNUInstallDirs won't override them if they're already set.
SET (CMAKE_INSTALL_LIBDIR "lib" CACHE STRING "Override libdir to violate FHS" FORCE)

# Try to download the prebuilt 3rd-party dependencies by default
IF (NOT DEFINED CB_DOWNLOAD_DEPS)
   SET(CB_DOWNLOAD_DEPS True
       CACHE BOOL "Download prebuilt dependencies by default")
ENDIF (NOT DEFINED CB_DOWNLOAD_DEPS)

# Have to add deps first, before any other part of the build tries to
# FIND anything
ADD_SUBDIRECTORY(tlm/deps)

# Also set up python first, since cbpy is installed in the previous step
ADD_SUBDIRECTORY(tlm/python)

# Also install the necessary GCC libraries.
# Note this is done regardless of if the compiler is GCC or Clang,
# as either way we use GCC's standard libraries.
MACRO (_install_gcc_file GCCFILENAME)
  IF (UNIX AND NOT APPLE)
    EXECUTE_PROCESS(
      COMMAND "${CMAKE_CXX_COMPILER}" ${CMAKE_CXX_FLAGS} -print-file-name=${GCCFILENAME}
      OUTPUT_VARIABLE _gccfile OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_VARIABLE _errormsg
      RESULT_VARIABLE _failure)
    IF (_failure)
      MESSAGE (FATAL_ERROR "Error (${_failure}) determining path to ${GCCFILENAME}: ${_errormsg}")
    ENDIF ()
    # We actually need to copy any files with longer filenames - this can be eg.
    # libstdc++.so.6, or libgcc_s.so.1.
    # Note: RPM demands that .so files be executable or else it won't
    # extract debug info from them.
    FILE (GLOB _gccfiles "${_gccfile}*")
    FOREACH (_gccfile ${_gccfiles})
      # Weird extraneous file not desired
      IF (_gccfile MATCHES ".py$")
        CONTINUE ()
      ENDIF ()
      INSTALL (FILES "${_gccfile}" DESTINATION lib
               PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                  GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    ENDFOREACH ()
  ENDIF ()
ENDMACRO (_install_gcc_file)

_install_gcc_file(libstdc++.so)
_install_gcc_file(libgcc_s.so)
_install_gcc_file(libgomp.so)
INCLUDE(CouchbaseDefaultValues)

# If the user has synced any closed-source code, assume building EE
IF (EXISTS "${PROJECT_SOURCE_DIR}/cbbs")
  SET (_ee_found ON)
ELSE ()
  SET (_ee_found OFF)
ENDIF()
OPTION (BUILD_ENTERPRISE "Building Enterprise Edition" ${_ee_found})

# Build 'developer builds' by default
OPTION (CB_DEVELOPER_BUILD "Produce Developer builds" ON)

# 'Production builds' are those built by the official Couchbase build jobs
OPTION (CB_PRODUCTION_BUILD "Official production build" OFF)

# Add option to build tools only
SET(BUILD_ONLY_TOOLS False)
IF ($ENV{CB_TOOLS_ONLY})
  SET(BUILD_ONLY_TOOLS True)
ENDIF ($ENV{CB_TOOLS_ONLY})

# If set, limit the number of concurrent link jobs to the specified value.
# This can be useful to constrain parallelism for machines with high CPU
# count but relatively low RAM, to avoid linker getting OOM-killed (particulary
# for Debug / Sanitizer build which seem to have much higher RAM usage).
# Only works with the Ninja generator.
SET(CB_PARALLEL_LINK_JOBS "$ENV{CB_PARALLEL_LINK_JOBS}" CACHE STRING "Define the maximum number of concurrent link jobs.")
IF(CB_PARALLEL_LINK_JOBS)
  SET_PROPERTY(GLOBAL APPEND PROPERTY JOB_POOLS link_job_pool=${CB_PARALLEL_LINK_JOBS})
  SET(CMAKE_JOB_POOL_LINK link_job_pool)
ENDIF()

MESSAGE(STATUS "Using cmake version: ${CMAKE_VERSION}")
MESSAGE(STATUS "Installing to ${CMAKE_INSTALL_PREFIX}")
MESSAGE(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

INCLUDE(CouchbaseCompilerOptions)
INCLUDE(CouchbaseSanitizers)
INCLUDE(CouchbaseMemoryAllocator)
INCLUDE(CouchbaseCompression)
INCLUDE(CouchbaseUnityBuild)
INCLUDE(CouchbasePrecompiledHeaders)
INCLUDE(CouchbaseFunctions)
INCLUDE(CouchbasePlugInUI)
INCLUDE(MetricsMetadata)

INCLUDE(FindCouchbaseBoost)
INCLUDE(FindCouchbaseFolly)
INCLUDE(FindCouchbaseOpenSSL)
INCLUDE(FindCouchbaseLibevent)
INCLUDE(FindCouchbaseCurl)
INCLUDE(FindCouchbaseLua)
INCLUDE(FindCouchbaseErlang)
INCLUDE(FindCouchbaseGo)
INCLUDE(FindCouchbaseBreakpad)
INCLUDE(FindCouchbaseFlatbuffers)
INCLUDE(FindCouchbaseValgrind)
INCLUDE(FindCouchbaseV8)
INCLUDE(FindCouchbaseIcu)
INCLUDE(FindCouchbaseNlohmannJson)
INCLUDE(FindCouchbaseOpentracing)
INCLUDE(FindCouchbasePCRE)
INCLUDE(FindCouchbasePrometheus)
INCLUDE(FindCouchbaseNuma)
INCLUDE(FindCouchbaseFmt)
INCLUDE(FindCouchbaseLibsodium)
INCLUDE(FindCouchbaseLiburing)
include(FindCouchbaseBenchmark)
include(FindCouchbaseGoogletest)
INCLUDE(FindCouchbaseSimdutf)
INCLUDE(FindCouchbaseSpdlog)
INCLUDE(FindCouchbaseZstd)

if (BUILD_ENTERPRISE)
    # libuv is currently only used by the enterpise builds
    include(FindCouchbaseLibuv)
endif()

# PRODUCT_VERSION logic:
# 1. If PRODUCT_VERSION is already defined, that means it's either cached
#    or was explicitly specified with -D on the command-line. In either
#    case, force it into the cache so it will be remembered in future runs.
# 2. Otherwise, we do NOT want to cache PRODUCT_VERSION, which will
#    force CMake to re-discover it every time. In that case, extract
#    VERSION from the manifest and stick the fake build number -0000
#    on the end.
IF (DEFINED PRODUCT_VERSION)
  SET (PRODUCT_VERSION "${PRODUCT_VERSION}" CACHE STRING "Product version with build number" FORCE)
ELSE ()
  SET (_product_version)
  # Try to determine product version from manifest. Allow SERVER_VERSION
  # to override VERSION.
  EXECUTE_PROCESS(
    COMMAND ${PYTHON_EXE}
      tlm/scripts/get_manifest_annot.py SERVER_VERSION VERSION
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    OUTPUT_VARIABLE _product_version
    ERROR_VARIABLE _err_output
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  IF (_err_output)
    MESSAGE (WARNING "${_err_output}")
    # Just in case
    SET (_product_version)
  ENDIF ()
  IF (_product_version)
    SET (PRODUCT_VERSION "${_product_version}-0000")
  ELSE ()
    SET (PRODUCT_VERSION "0.0.0-0000")
  ENDIF ()
ENDIF ()

# BUILD_COLUMNAR logic: Similar to above.
# 1. If BUILD_COLUMNAR is already defined, the means it's either cached
#    or was explicitly specified with -D on the command-line. In either
#    case, force it into the cache so it will be remembered for future runs.
# 2. Otherwise, we do NOT want to cache BUILD_COLUMNAR, which will force
#    CMake to re-discover it every time. In that case, extract it from the
#    manifest. Assume 'false' if not found in manifest.
IF (DEFINED BUILD_COLUMNAR)
  SET (BUILD_COLUMNAR "${BUILD_COLUMNAR}" CACHE BOOL "Building Couchbase Columnar" FORCE)
ELSE ()
  SET (_build_columnar)
  EXECUTE_PROCESS(
      COMMAND ${PYTHON_EXECUTABLE} tlm/scripts/get_manifest_annot.py COLUMNAR
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      OUTPUT_VARIABLE _build_columnar
      ERROR_VARIABLE _err_output
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  IF (_err_output)
    MESSAGE (WARNING "${_err_output}")
    # Just in case
    SET (_build_columnar)
  ENDIF ()
  IF (_build_columnar)
    SET (BUILD_COLUMNAR ${_build_columnar})
  ELSE ()
    SET (BUILD_COLUMNAR 0)
  ENDIF ()
ENDIF ()

# COLUMNAR_PRODUCT_VERSION logic: Similar to above.
# 1. If COLUMNAR_PRODUCT_VERSION is already defined, the means it's either
#    cached or was explicitly specified with -D on the command-line. In either
#    case, force it into the cache so it will be remembered for future runs.
# 2. Otherwise, we do NOT want to cache COLUMNAR_PRODUCT_VERSION, which will
#    force CMake to re-discover it every time. In that case, extract it from
#    the manifest. Default to '0.0.0-0000' if not found in manifest.
IF (BUILD_COLUMNAR AND DEFINED COLUMNAR_PRODUCT_VERSION)
  SET (COLUMNAR_PRODUCT_VERSION "${COLUMNAR_PRODUCT_VERSION}" CACHE BOOL
      "Couchbase Columnar product version with build number" FORCE)
ELSEIF (BUILD_COLUMNAR AND NOT DEFINED COLUMNAR_PRODUCT_VERSION)
  SET (_columnar_version)
  EXECUTE_PROCESS(
      COMMAND ${PYTHON_EXECUTABLE} tlm/scripts/get_manifest_annot.py VERSION
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      OUTPUT_VARIABLE _columnar_version
      ERROR_VARIABLE _err_output
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  IF (_err_output)
    MESSAGE (WARNING "${_err_output}")
    # Just in case
    SET (_columnar_version)
  ENDIF ()
  IF (_columnar_version)
    SET (COLUMNAR_PRODUCT_VERSION "${_columnar_version}-0000")
  ELSE ()
    SET (COLUMNAR_PRODUCT_VERSION "0.0.0-0000")
  ENDIF ()
ENDIF ()

# Toplevel target for generated source files from different projects
ADD_CUSTOM_TARGET(generated_source_files)

IF (BUILD_ENTERPRISE)
  IF (BUILD_COLUMNAR)
    MESSAGE (STATUS "Building Couchbase Columnar ${COLUMNAR_PRODUCT_VERSION} (server version ${PRODUCT_VERSION})")
  ELSE ()
    MESSAGE (STATUS "Building Couchbase Server ${PRODUCT_VERSION} Enterprise Edition")
  ENDIF ()
  ADD_DEFINITIONS(-DCOUCHBASE_ENTERPRISE_EDITION=1)
ELSE ()
  MESSAGE (STATUS "Building Couchbase Server ${PRODUCT_VERSION} Community Edition")
ENDIF ()

IF (WIN32)
   SET(COUCHBASE_NETWORK_LIBS "Ws2_32")
ELSEIF ("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS")
   SET(COUCHBASE_NETWORK_LIBS socket nsl)
ENDIF (WIN32)
MESSAGE(STATUS "Linking with network libraries: ${COUCHBASE_NETWORK_LIBS}")

IF (NOT WIN32)
   SET(COUCHBASE_MATH_LIBS m)
ENDIF(NOT WIN32)

INCLUDE(CouchbaseCodeCoverage)

INCLUDE(TestBigEndian)
TEST_BIG_ENDIAN(WORDS_BIG_ENDIAN)
IF (WORDS_BIG_ENDIAN)
  MESSAGE(STATUS "Builing on big endian system")
  ADD_DEFINITIONS(-DWORDS_BIGENDIAN=1)
ENDIF(WORDS_BIG_ENDIAN)

ENABLE_TESTING()

IF (NOT BUILD_ONLY_TOOLS)
  INCLUDE_DIRECTORIES(BEFORE ${CMAKE_BINARY_DIR}/platform/include)
  INCLUDE_DIRECTORIES(AFTER SYSTEM ${NLOHMANN_JSON_INCLUDE_DIR})
ENDIF()

# Add a quick (and safe) way to nuke everything
ADD_CUSTOM_TARGET(reset
                  COMMAND repo forall -c "git clean -dfx"
                  VERBATIM)

ADD_SUBDIRECTORY(third_party EXCLUDE_FROM_ALL)

IF (NOT BUILD_ONLY_TOOLS)
  ADD_SUBDIRECTORY(phosphor)
ENDIF()

IF (NOT BUILD_ONLY_TOOLS)
  ADD_SUBDIRECTORY(platform)
  ADD_SUBDIRECTORY(subjson)
  ADD_SUBDIRECTORY(kv_engine/include)
  ADD_SUBDIRECTORY(couchstore)

  IF (BUILD_ENTERPRISE AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/fusion")
    ADD_SUBDIRECTORY(fusion)
  ENDIF()

  IF (BUILD_ENTERPRISE AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/magma")
    ADD_SUBDIRECTORY(magma)
  ENDIF()

ENDIF()

IF (NOT COUCHBASE_KV_COMMIT_VALIDATION)
    ADD_SUBDIRECTORY(forestdb)
    SET (FORESTDB_INCLUDE_DIR "${ForestDB_SOURCE_DIR}/include")
    SET(FORESTDB_LIBRARY_DIR "${ForestDB_BINARY_DIR}")
    SET (FORESTDB_TARGET forestdb)
ENDIF()

INCLUDE (CouchbaseFaiss)

IF (NOT BUILD_ONLY_TOOLS)
  ADD_SUBDIRECTORY(sigar)
  ADD_SUBDIRECTORY(kv_engine)
ENDIF()

IF (NOT BUILD_ONLY_TOOLS AND NOT COUCHBASE_KV_COMMIT_VALIDATION)
  ADD_SUBDIRECTORY(product-texts/couchbase-server)
  INSTALL (FILES "product-texts/capella/tools/README.txt" DESTINATION ${TOOLS_INSTALL_PREFIX})
  INSTALL (FILES "product-texts/couchbase-server/license/ee-license.txt" RENAME "LICENSE.txt" DESTINATION ${TOOLS_INSTALL_PREFIX})
  STRING (REGEX MATCH "^[^-]+" _version "${PRODUCT_VERSION}")
  SET (NOTICES_FILE "product-metadata/couchbase-server/blackduck/${_version}/notices.txt")
  IF (EXISTS "${CMAKE_SOURCE_DIR}/${NOTICES_FILE}")
    INSTALL (FILES "${NOTICES_FILE}" RENAME "NOTICES.txt" DESTINATION .)
    INSTALL (FILES "${NOTICES_FILE}" RENAME "NOTICES.txt" DESTINATION ${TOOLS_INSTALL_PREFIX})
  ELSE ()
    MESSAGE (WARNING "Could not find ${NOTICES_FILE} - will not be included in installation package")
  ENDIF ()
ENDIF()

IF (NOT COUCHBASE_KV_COMMIT_VALIDATION)
    IF (NOT BUILD_ONLY_TOOLS)
      ADD_SUBDIRECTORY(couchbase-cli)
      ADD_SUBDIRECTORY(couchdb)
      ADD_SUBDIRECTORY(geocouch)
    ENDIF()

    SET (GODEPSDIR "${CMAKE_CURRENT_SOURCE_DIR}/godeps")
    IF (NOT BUILD_ONLY_TOOLS)

      ADD_SUBDIRECTORY(ns_server ${CMAKE_CURRENT_SOURCE_DIR}/ns_server/build)
      ADD_SUBDIRECTORY(query-ui)
      ADD_SUBDIRECTORY(vbmap)

      IF (BUILD_ENTERPRISE)
          ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/eventing-ee)
      ENDIF()

      ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/query)
      ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/indexing)
      ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/goxdcr)
      ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/gometa)
      ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/cbauth)

      ADD_SUBDIRECTORY(cbft)
      ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/docloader)

      # Analytics CBGT connector
      IF (BUILD_ENTERPRISE AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/goproj/src/github.com/couchbase/cbas")
        ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/cbas)
      ENDIF ()

      # Analytics Maven project
      IF (BUILD_ENTERPRISE AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/analytics/CMakeLists.txt")
        ADD_SUBDIRECTORY (analytics)
      ENDIF ()

      # Analytics UI
      IF (BUILD_ENTERPRISE AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cbas-ui")
        ADD_SUBDIRECTORY (cbas-ui)
      ENDIF ()
    ENDIF()

    IF (EXISTS "${PROJECT_SOURCE_DIR}/backup")
      ADD_SUBDIRECTORY(backup)
    ENDIF()

    IF (BUILD_ENTERPRISE AND EXISTS "${PROJECT_SOURCE_DIR}/cbbs")
        ADD_SUBDIRECTORY(cbbs)
    ENDIF()

    IF (BUILD_ENTERPRISE AND EXISTS "${PROJECT_SOURCE_DIR}/goproj/src/github.com/couchbase/plasma" AND NOT BUILD_ONLY_TOOLS)
      ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/plasma)
    ENDIF()

    IF (EXISTS "${PROJECT_SOURCE_DIR}/libcouchbase")
      # Set libcouchbase build options
      SET (LCB_NO_PLUGINS ON CACHE BOOL "Don't build plugins" FORCE)
      SET (LCB_NO_TESTS ON CACHE BOOL "Don't run tests" FORCE)
      SET (LCB_BUILD_DTRACE OFF CACHE BOOL "Turn off tracing" FORCE)
      SET (LCB_INSTALL_HEADERS OFF CACHE BOOL "Don't install headers" FORCE)
      SET (LCB_INSTALL_PKGCONFIG OFF CACHE BOOL "Don't install libcouchbase.pc" FORCE)
      SET (LCB_SNAPPY_LIB "${SNAPPY_LIBRARIES}" CACHE PATH "Path to Server's snappy library" FORCE)
      SET (LCB_SNAPPY_INCLUDE_DIR "${SNAPPY_INCLUDE_DIR}" CACHE PATH "Path to Server's snappy headers" FORCE)

      ADD_SUBDIRECTORY(libcouchbase)
    ENDIF()

    IF (NOT BUILD_ONLY_TOOLS)
      IF (BUILD_ENTERPRISE)
        ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/eventing)
      ENDIF()

      IF (BUILD_ENTERPRISE AND EXISTS "${PROJECT_SOURCE_DIR}/goproj/src/github.com/couchbase/cbsummary")
        ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/cbsummary)
      ENDIF()
    ENDIF ()

    IF (EXISTS "${PROJECT_SOURCE_DIR}/voltron/CMakeLists.txt")
      ADD_SUBDIRECTORY(voltron)
    ENDIF ()
ENDIF (NOT COUCHBASE_KV_COMMIT_VALIDATION)

IF (NOT WIN32)
   CONFIGURE_FILE(tlm/memcached-wrapper.in ${CMAKE_BINARY_DIR}/tlm/memcached-wrapper)
ENDIF (NOT WIN32)

# Target for "standalone tools" package.
#
# This implementation depends on other parts of the build adding
# INSTALL() directives to redundantly install their bits into
# TOOLS_INSTALL_PREFIX. GoModBuild() in particular has some specialized
# logic to copy requested Go binaries and all dependent shared
# libraries.
#
# Note: This 'tools-package' target effectively depends on the "install"
# target, but you can't do that literally in CMake. So it's important
# that this target only be invoked after "make install" has been run.
# Since we can't have proper dependency tracking anyway, we just use a
# straight ADD_CUSTOM_TARGET rather than the more proper
# ADD_CUSTOM_COMMAND setup.
_DETERMINE_BASIC_PLATFORM (_platform)
STRING (CONCAT _archive_base
  "${PROJECT_BINARY_DIR}/couchbase-server-tools"
  "_${PRODUCT_VERSION}"
  "-${_platform}"
  "_${CB_DOWNLOAD_DEPS_ARCH}"
)
IF (WIN32 OR APPLE)
  ADD_CUSTOM_TARGET (tools-package
    COMMAND "${CMAKE_COMMAND}" -E
      tar cf "${_archive_base}.zip" --format=zip "."
    WORKING_DIRECTORY "${TOOLS_INSTALL_PREFIX}"
    COMMENT "Creating Standalone Tools package at ${_archive_base}.zip"
  )
ELSE (WIN32 OR APPLE)
  ADD_CUSTOM_TARGET (tools-package
    COMMAND "${CMAKE_COMMAND}" -E
      tar czf "${_archive_base}.tar.gz" "*"
    WORKING_DIRECTORY "${TOOLS_INSTALL_PREFIX}"
    COMMENT "Creating Standalone Tools package at ${_archive_base}.tar.gz"
  )
ENDIF (WIN32 OR APPLE)

# End of top-level CMakeLists.txt - call any end-processing hooks.
# You may add your own hooks with:
#
#   SET_PROPERTY (GLOBAL APPEND PROPERTY CB_CMAKE_END_HOOKS <function name>)
#
# These will be called with no arguments.
GET_PROPERTY (_end_hooks GLOBAL PROPERTY CB_CMAKE_END_HOOKS)
FOREACH (_hook ${_end_hooks})
    CMAKE_LANGUAGE (EVAL CODE "${_hook}()")
ENDFOREACH ()
