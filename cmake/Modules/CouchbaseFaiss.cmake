# Specific logic for building / using Faiss

# On all platforms, if Faiss is available and BUILD_ENTERPRISE is true
# (and BUILD_ONLY_TOOLS is not true), then this file will:
#
# * set CB_USE_FAISS to ON
# * ensure the targets "faiss" and "faiss_c" exist
# * arrange for the "install" target to install libfaiss, libfaiss_c,
#   and any required dependent shared libraries.
#
# In all other cases, CB_USE_FAISS will be set to OFF.
#
# What "Faiss is available" differs by platform:
#
# On Linux, Faiss will be built from source. If the "faiss" subdirectory
# exists, and BUILD_ENTERPRISE is true, then CB_USE_FAISS will be set to
# ON and the faiss subdirectory will be added to the project. The faiss
# subproject is configured here.
#
# On MacOS, building Faiss requires installing LLVM from Homebrew and
# using that compiler. It does not seem to be possible to add a
# subproject to Server using a different compiler. So developers who
# wish to explore Faiss as part of a Server build on MacOS will need to
# build it in a separate directory, and then configure CMAKE_PREFIX_PATH
# to point to the root of the installation directory Faiss is built
# into. The Server build will attempt to "find" faiss if
# BUILD_ENTERPRISE is true.
#
# It is unclear whether Faiss works on Windows, so for the moment, the
# Server build on Windows will never attempt to build or use Faiss.
# CB_USE_FAISS will always be OFF.

SET (_use_faiss OFF)
IF (NOT BUILD_ENTERPRISE)
  # No Faiss for CE builds

ELSEIF (BUILD_ONLY_TOOLS)
  # No Faiss for tools-only builds

ELSEIF (WIN32)
  # No Faiss for Windows builds

ELSEIF (APPLE)
  #
  # MacOS: Attempt to find the faiss package
  #

  # Since faiss is a mostly-well-behaved "Modern CMake" package, the first
  # part is easy. Pass QUIET so it doesn't mention faiss if not found.
  FIND_PACKAGE (faiss CONFIG QUIET)

  IF (faiss_FOUND)
    SET (_use_faiss ON)
    MESSAGE (STATUS "Found faiss")

    # This very useful feature requires CMake 3.23, but our build agents
    # are currently on 3.20/3.21. For the moment, since this step is
    # only intended for use by local developers on their Macs, only
    # error out here.
    IF (CMAKE_VERSION VERSION_LESS 3.23.0)
      MESSAGE (FATAL_ERROR "CMake 3.23 or greater required - you are using CMake ${CMAKE_VERSION}")
    ENDIF ()
    INSTALL (IMPORTED_RUNTIME_ARTIFACTS faiss faiss_c)
  ENDIF ()

ELSEIF (NOT EXISTS "${PROJECT_SOURCE_DIR}/faiss")
  # No Faiss on Linux if the faiss subdirectory is missing

ELSEIF(NOT CMAKE_C_COMPILER_ID STREQUAL "GNU")
  # Skip faiss unless using GCC

ELSE ()
  #
  # Linux: Add faiss to Server project, and configure Faiss build
  #
  SET (_use_faiss ON)

  # Set faiss build options
  SET (FAISS_ENABLE_GPU OFF CACHE BOOL "Faiss: Enable GPU" FORCE)
  SET (FAISS_ENABLE_PYTHON OFF CACHE BOOL "Faiss: Enable python extension" FORCE)
  SET (FAISS_ENABLE_C_API ON CACHE BOOL "Faiss: Build C API" FORCE)

  # Set CMake options we need for Faiss but don't necessarily want to override for
  # the rest of the Server build
  SET (_curr_build_testing ${BUILD_TESTING})
  SET (BUILD_TESTING OFF)
  SET (_curr_build_shared_libs ${BUILD_SHARED_LIBS})
  SET (BUILD_SHARED_LIBS ON)

  MESSAGE (STATUS "Adding Faiss to project")
  ADD_SUBDIRECTORY(faiss)

  # Faiss depends on default gcc visibility, which CouchbaseGccOptions
  # sets to "hidden"
  IF ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
    TARGET_COMPILE_OPTIONS (faiss PRIVATE -fvisibility=default)
    TARGET_COMPILE_OPTIONS (faiss_c PRIVATE -fvisibility=default)
  ENDIF ()

  # Faiss handles the c_api headers all wrong. It doesn't set
  # target_include_directories(), and worse, the headers don't exist
  # in git in the right place - it's assumed they're in a directory
  # named "faiss/c_api", which they aren't. However, since our
  # manifest happens to put the faiss source into a directory named
  # "faiss", we can hack around it by setting the top of the repo sync
  # itself as the include_directory.
  TARGET_INCLUDE_DIRECTORIES (faiss_c PUBLIC
    $<BUILD_INTERFACE:${faiss_SOURCE_DIR}/..>)

  # Restore original CMake options
  SET (BUILD_TESTING ${_curr_build_testing})
  SET (BUILD_SHARED_LIBS ${_curr_build_shared_libs})
  IF (APPLE)
    SET (CMAKE_C_COMPILER "${_curr_cc}")
    SET (CMAKE_CXX_COMPILER "${_curr_cxx}")
    SET (CMAKE_PREFIX_PATH "${_curr_prefix}")
  ENDIF ()

ENDIF ()

SET (CB_USE_FAISS ${_use_faiss} CACHE BOOL "Whether Faiss is available in the build" FORCE)
