# Locate Google Glog library
# This module defines
#  GLOG_LIBRARIES, Library path and libs
#  GLOG_INCLUDE_DIR, where to find the headers

include(FindPackageHandleStandardArgs)
include(PlatformIntrospection)
include(SelectLibraryConfigurations)

cb_get_supported_platform(_is_supported_platform)
if (_is_supported_platform)
    # Supported platforms should only use the provided hints and pick it up
    # from cbdeps
    set(_glog_no_default_path NO_DEFAULT_PATH)
endif ()

set(_glog_exploded ${CMAKE_BINARY_DIR}/tlm/deps/glog.exploded)

find_path(GLOG_INCLUDE_DIR glog/logging.h
          PATH_SUFFIXES include
          PATHS ${_glog_exploded}
          ${_glog_no_default_path})

find_library(GLOG_LIBRARY_RELEASE
             NAMES glog
             HINTS ${_glog_exploded}/lib
             ${_glog_no_default_path})

find_library(GLOG_LIBRARY_DEBUG
             NAMES glogd
             HINTS ${_glog_exploded}/lib
             ${_glog_no_default_path})

# Defines GLOG_LIBRARY / LIBRARIES to the correct Debug / Release
# lib based on the current BUILD_TYPE
select_library_configurations(GLOG)

find_package_handle_standard_args(GLOG
    REQUIRED_VARS GLOG_LIBRARIES GLOG_INCLUDE_DIR)

# Set GOOGLE_GLOG_DLL_DECL to an empty value to avoid incorrect dllimport
# decoration (we build static versions of GLOG which should have an empty
# DLL declaration).
add_compile_definitions(GOOGLE_GLOG_DLL_DECL=)

# Set GLOG_NO_ABBREVIATED_SEVERITIES to disable the abbreviated severity macros
# ERROR, WARNING, etc - which on Windows can collide with macros defined by
# windgi.h (which is included via Windows.h).
add_compile_definitions(GLOG_NO_ABBREVIATED_SEVERITIES)

mark_as_advanced(GLOG_INCLUDE_DIR GLOG_LIBRARIES)
