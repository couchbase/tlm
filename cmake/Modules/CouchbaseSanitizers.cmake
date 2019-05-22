include(CheckCXXCompilerFlag)

# Helper function used by CouchbaseAddressSanitizer / UndefinedSanitizer.
# Searches for a sanitizer_lib_name, returning the path in the variable named <path_var>
function(find_sanitizer_library path_var sanitizer_lib_name)
  execute_process(COMMAND ${CMAKE_C_COMPILER} -print-search-dirs
    OUTPUT_VARIABLE cc_search_dirs)
  # Extract the line listing the library paths
  string(REGEX MATCH "libraries: =(.*)\n" _ ${cc_search_dirs})
  # CMAKE expects lists to be semicolon-separated instead of colon.
  string(REPLACE ":" ";" cc_library_dirs ${CMAKE_MATCH_1})
  find_file(${path_var} ${sanitizer_lib_name}
    PATHS ${cc_library_dirs})
endfunction()

# Helper function to workaround a problem with ASan/TSan, dlopen and
# RPATH:
#
# Background:
#
# Couchbase server (e.g. engine_testapp) makes use of dlopen()
# to load the engine and the testsuite. The runtime linker
# determines the search path to use by looking at the values
# of RPATH and RUNPATH in the executable (e.g. engine_testapp)
#
# - RUNPATH is the "older" property, it is used by the
#   executable and _any other libraries the executable loads_
#   to locate dlopen()ed files.
#
# - RPATH is the "newer" (and more secure) property - is is
#   only used when the executable itself loads a library -
#   i.e. it isn't inherited by opened libraries like RUNPATH.
#
# (Summary, see `man dlopen` for full details of search
# order).
#
# CMake will set RPATH / RUNPATH (via linker arg -Wl) to the
# set of directories where all dependancies reside - and this
# is necessary for engine_testapp to load the engine and
# testsuite.
#
# Problem:
#
# When running under Asan/TSan, *San intercepts dlopen()
# and related functions, which results in the dlopen()
# appearing to come from libtsan.so. Given the above, this
# means that if RPATH is used, then the dlopen() for engine
# and testsuite fails, as libtsan doesn't have the path to
# ep.so for example embedded in it, and with RPATH the paths
# arn't inherited from the main executable.
#
# Newer versions of ld (at least Ubuntu 17.10) now use RPATH
# by default (as it is more secure), which means that we hit
# the above problem. To avoid this, use RUNPATH instead when
# running on a system which recognises the flag.
check_cxx_compiler_flag("-Wl,--disable-new-dtags" COMPILER_SUPPORTS_DISABLE_NEW_DTAGS)
function(use_runpath_for_sanitizers)
  if(COMPILER_SUPPORTS_DISABLE_NEW_DTAGS)
    set(CMAKE_EXE_LINKER_FLAGS
      "${CMAKE_EXE_LINKER_FLAGS} -Wl,--disable-new-dtags" PARENT_SCOPE)
    set(CMAKE_SHARED_LINKER_FLAGS
      "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--disable-new-dtags" PARENT_SCOPE)
  endif()
endfunction()


include(CouchbaseAddressSanitizer)
include(CouchbaseThreadSanitizer)
include(CouchbaseUndefinedBehaviorSanitizer)

# Set a variable to allow targets to know if at least one of the sanitizers is enabled.
if(CB_ADDRESSSANITIZER OR CB_THREADSANITIZER OR CB_UNDEFINEDSANITIZER)
  set(CB_SANITIZERS True CACHE BOOL "Set if one or more sanitizers are enabled" FORCE)
else()
  set(CB_SANITIZERS False CACHE BOOL "Set if one or more sanitizers are enabled" FORCE)
endif()

# Enable sanitizers for specific target. No-op if none of the
#  Sanitizers are enabled.
function(add_sanitizers TARGET)
    add_sanitize_memory(${TARGET})
    add_sanitize_undefined(${TARGET})
endfunction()

# Override and always disable sanitizers for specific target. Useful
# when a target is incompatible with sanitizers.
# No-op if one of the sanitizers are enabled.
function(remove_sanitizers TARGET)
    remove_sanitize_memory(${TARGET})
    remove_sanitize_undefined(${TARGET})
endfunction()
