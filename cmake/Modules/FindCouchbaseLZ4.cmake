# Locate lz4 library
# This module defines
#  LZ4_FOUND, if false, do not try to link with lz4
#  LZ4_LIBRARIES, Library path and libs
#  LZ4_INCLUDE_DIR, where to find the ICU headers
set(_lz4_exploded ${CMAKE_BINARY_DIR}/tlm/deps/lz4.exploded)
set(_lz4_library_dir ${CMAKE_INSTALL_PREFIX})

include(PlatformIntrospection)

cb_get_supported_platform(_supported_platform)
if (_supported_platform)
  # Supported platforms should only use the provided hints and pick up
  # LZ4 from cbdeps
  set(NO_DEFAULT_PATH NO_DEFAULT_PATH)
endif ()

find_path(LZ4_INCLUDE_DIR lz4.h
          HINTS ${_lz4_exploded}/include
          ${NO_DEFAULT_PATH})

find_library(LZ4_LIBRARIES
             NAMES lz4
             HINTS ${_lz4_library_dir}/lib
             ${NO_DEFAULT_PATH})

if (LZ4_INCLUDE_DIR AND LZ4_LIBRARIES)
  set(LZ4_FOUND True CACHE BOOL "Whether LZ4 has been found")
  message(STATUS "Found LZ4:")
  message(STATUS "   headers: ${LZ4_INCLUDE_DIR}")
  message(STATUS "   library: ${LZ4_LIBRARIES}")
else()
  message(WARNING "LZ4 not found")
  set(LZ4_FOUND False CACHE BOOL "Whether LZ4 has been found")
endif()

mark_as_advanced(LZ4_FOUND LZ4_INCLUDE_DIR LZ4_LIBRARIES)
