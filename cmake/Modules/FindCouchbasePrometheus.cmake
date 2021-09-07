# Locate prometheus-cpp
# This module defines
#  PROMETHEUS_LIBRARIES, Library path and libs
#  PROMETHEUS_INCLUDE_DIR, where to find the headers

set(_prometheus_exploded ${CMAKE_BINARY_DIR}/tlm/deps/prometheus-cpp.exploded)

include(PlatformIntrospection)

cb_get_supported_platform(_is_supported_platform)
if (_is_supported_platform)
    set(_prometheus_no_default_path NO_DEFAULT_PATH)
endif ()

find_path(PROMETHEUS_INCLUDE_DIR prometheus/registry.h
        PATH_SUFFIXES include
        PATHS ${_prometheus_exploded}
        ${_prometheus_no_default_path})

find_library(PROMETHEUS_CORE_LIBRARY
        NAMES prometheus-cpp-core
        HINTS ${_prometheus_exploded}/lib
        ${_prometheus_no_default_path})

find_library(PROMETHEUS_PULL_LIBRARY
        NAMES prometheus-cpp-pull
        HINTS ${_prometheus_exploded}/lib
        ${_prometheus_no_default_path})

set(PROMETHEUS_LIBRARIES ${PROMETHEUS_PULL_LIBRARY} ${PROMETHEUS_CORE_LIBRARY})

if (NOT PROMETHEUS_INCLUDE_DIR)
    message(FATAL_ERROR "Failed to locate prometheus-cpp include directory")
endif ()

IF (PROMETHEUS_LIBRARIES AND PROMETHEUS_INCLUDE_DIR)
    MESSAGE(STATUS "Found prometheus-cpp in ${PROMETHEUS_INCLUDE_DIR} : ${PROMETHEUS_LIBRARIES}")
endif ()

mark_as_advanced(PROMETHEUS_INCLUDE_DIR PROMETHEUS_LIBRARIES)
