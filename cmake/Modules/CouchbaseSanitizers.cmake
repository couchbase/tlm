include(CheckCXXCompilerFlag)
include(CMakePushCheckState)

# Tries to locate a sanitizer shared library with a name from the list
# 'lib_names'.  Returns the result in ${variable}.
function(try_search_sanitizer_library variable lib_names flags)
  # Trying to determine the location of a shared library
  # ahead of time complex and error-prone - particulry if multiple
  # versions of the shared library exist (for example the system
  # installed GCC-5 version, and our own compiled GCC 7.3.0 one).
  #
  # The runtime linker is the one which actually decides which file
  # should be loaded, so the method used is to compile a test program
  # which links against the library we are interested in, then examine
  # where the runtime linker finds it.
  string(REPLACE ";" " " flags_list "${flags}")
  try_compile(result
              ${CMAKE_BINARY_DIR}
              ${CMAKE_SOURCE_DIR}/tlm/cmake/Modules/try_search_sanitizer_library.c
              CMAKE_FLAGS -DCOMPILE_DEFINITIONS:STRING=${flags_list}
              OUTPUT_VARIABLE cc_output
              COPY_FILE ${CMAKE_BINARY_DIR}/CMakeFiles/try_search_sanitizer_library)
  if (NOT result)
    message(WARNING "try_search_sanitizer_library(): Failed to compile: ${cc_output}")
    return()
  endif()
  execute_process(COMMAND ldd ${CMAKE_BINARY_DIR}/CMakeFiles/try_search_sanitizer_library
                  OUTPUT_VARIABLE ldd_output)
  file(REMOVE ${CMAKE_BINARY_DIR}/CMakeFiles/try_search_sanitizer_library)

  # Extract the line listing the first found library name.
  # example format:
  #     \tlibgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007f78dc7d3000)
  foreach(name ${lib_names})
    string(REGEX MATCH "\t${name} => ([A-Za-z0-9/._-]+)" _ ${ldd_output})
    if (CMAKE_MATCH_1)
      set(${variable} ${CMAKE_MATCH_1} PARENT_SCOPE)
      break()
    endif()
  endforeach()
endfunction()

# Helper function used by
# Couchbase{Address,Thread,Undefined}Sanitizer.  Searches for a
# sanitizer_lib_name linked when compiling with sanitizer_flags, and
# once found installs it into sanitizer_dest.
function(install_sanitizer_library _name sanitizer_lib_name sanitizer_flags sanitizer_dest)
  try_search_sanitizer_library(${_name}_path "${sanitizer_lib_name}" "${sanitizer_flags}")
  if (${_name}_path)
    message(STATUS "Found ${_name} at: ${${_name}_path} installing to: ${sanitizer_dest}")
    file(COPY ${${_name}_path}
         DESTINATION ${sanitizer_dest})
    if (IS_SYMLINK ${${_name}_path})
      # Often a shared library is actually a symlink to a versioned file - e.g.
      # libtsan.so.1 -> libtsan.so.1.0.0
      # In which case we also need to install the real file.
      get_filename_component(${_name}_realpath ${${_name}_path} REALPATH)
      file(COPY ${${_name}_realpath} DESTINATION ${sanitizer_dest})
    endif ()
    get_filename_component(${_name}_relname ${${_name}_path} NAME)
    set(installed_${_name}_path ${sanitizer_dest}/${_name}_relname)

    # One some distros (at least Ubuntu18.04), the sanitizer library
    # includes a RUNPATH in the dynamic linker section. This
    # breaks the ability to use the RPATH from the base
    # executable (see description of function
    # use_rpath_for_sanitizers() for full details).
    #
    # To fix this problem, we need to modify our copy of
    # lib<SAN>.so to remove the RUNPATH directive.
    find_program(readelf NAMES readelf)
    if (NOT readelf)
      message(FATAL_ERROR "Unable to locate 'readelf' program to check ${sanitizer_lib_name}'s dynamic linker section.")
    endif()
    execute_process(COMMAND ${readelf} -d ${installed_${_name}_path}
                    COMMAND grep RUNPATH
                    RESULT_VARIABLE runpath_status
                    OUTPUT_VARIABLE runpath_output
                    ERROR_VARIABLE runpath_output)
    if (runpath_status GREATER 1)
      message(FATAL_ERROR "Failed to check for presence of RUNPATH using readelf. Status:${runpath_status} Output: ${runpath_output}")
    endif()

    if (runpath_status EQUAL 0)
      # RUNPATH directive found. Time to delete it using
      # chrpath. (Ideally we'd do something less disruptive
      # like convert to RPATH but chrpath doesn't support
      # that :(
      message(STATUS "Found RUNPATH directive in ${sanitizer_lib_name} (${installed_${_name}_path}) - removing RUNPATH")
      find_program(chrpath NAMES chrpath)
      if (NOT chrpath)
        message(FATAL_ERROR "Unable to locate 'chrpath' program to fix libtsan.so's dynamic linker section.")
      endif()
      execute_process(COMMAND ${chrpath} -d ${installed_${_name}_path}
                      RESULT_VARIABLE chrpath_status
                      OUTPUT_VARIABLE chrpath_output
                      ERROR_VARIABLE chrpath_output)
      if (NOT chrpath_status EQUAL 0)
        message(FATAL_ERROR "Unable to remove RUNPATH using 'chrpath' Status:${chrpath_status} Output: ${chrpath_output}")
      endif()
    endif()
  else ()
    # Only raise error if building for linux
    if (UNIX AND NOT APPLE)
      message(FATAL_ERROR "${_name} library not found.")
    endif ()
  endif ()
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
# - RPATH is the "older" property, it is used by the
#   executable and _any other libraries the executable loads_
#   to locate dlopen()ed files.
#
# - RUNPATH is the "newer" (and more secure) property - is is
#   only used when the executable itself loads a library -
#   i.e. it isn't inherited by opened libraries like RPATH.
#
# (Summary, see `man dlopen` for full details of search
#  order. There's also a good blog post on the full details at:
#  https://blog.qt.io/blog/2011/10/28/rpath-and-runpath/)
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
# means that if RUNPATH is used, then the dlopen() for engine
# and testsuite fails, as libtsan doesn't have the path to
# ep.so for example embedded in it, and with RUNPATH the paths
# arn't inherited from the main executable.
#
# Newer versions of ld (at least Ubuntu 17.10) now use RUNPATH
# by default (as it is more secure), which means that we hit
# the above problem. To avoid this, use RPATH instead when
# running on a system which recognises the flag.
#
# (To check what dynamic linker variable is used in a binary, run:
#     readelf --dynamic <binary>
# and look for the presence of RPATH / RUNPATH.
#
cmake_push_check_state()
set(CMAKE_REQUIRED_LINK_OPTIONS "-Wl,--disable-new-dtags")
check_cxx_compiler_flag("-Wl,--disable-new-dtags" COMPILER_SUPPORTS_DISABLE_NEW_DTAGS)
cmake_pop_check_state()

function(use_rpath_for_sanitizers)
  if(COMPILER_SUPPORTS_DISABLE_NEW_DTAGS)
    set(CMAKE_EXE_LINKER_FLAGS
      "${CMAKE_EXE_LINKER_FLAGS} -Wl,--disable-new-dtags" PARENT_SCOPE)
    set(CMAKE_SHARED_LINKER_FLAGS
      "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--disable-new-dtags" PARENT_SCOPE)
  endif()
endfunction()


# Check if ELEMENT exists in the list of values for PROPERTY_NAME
# against TARGET.  If so, remove ELEMENT from the list of values.
function(remove_from_property TARGET PROPERTY_NAME)
    get_target_property(property_value ${TARGET} ${PROPERTY_NAME})
    if (property_value)
        list(REMOVE_ITEM property_value ${ARGN})
        set_property(TARGET ${TARGET} PROPERTY ${PROPERTY_NAME} ${property_value})
    endif()
endfunction()

include(CouchbaseAddressSanitizer)
include(CouchbaseThreadSanitizer)
include(CouchbaseUndefinedBehaviorSanitizer)
include(CouchbaseLibFuzzer)

# Set a variable to allow targets to know if at least one of the sanitizers is enabled.
if(CB_ADDRESSSANITIZER OR CB_THREADSANITIZER OR CB_UNDEFINEDSANITIZER OR CB_LIBFUZZER)
  set(CB_SANITIZERS True CACHE BOOL "Set if one or more sanitizers are enabled" FORCE)
else()
  set(CB_SANITIZERS False CACHE BOOL "Set if one or more sanitizers are enabled" FORCE)
endif()

# Enable sanitizers for specific target. No-op if none of the
#  Sanitizers are enabled.
function(add_sanitizers TARGET)
    add_sanitize_memory(${TARGET})
    add_sanitize_undefined(${TARGET})
    add_sanitize_libfuzzer(${TARGET})
endfunction()

# Override and always disable sanitizers for specific target. Useful
# when a target is incompatible with sanitizers.
# No-op if one of the sanitizers are enabled.
function(remove_sanitizers TARGET)
    remove_sanitize_memory(${TARGET})
    remove_sanitize_thread(${TARGET})
    remove_sanitize_undefined(${TARGET})
    remove_sanitize_libfuzzer(${TARGET})
endfunction()


# If at least one sanitizer enabled, Override the normal ADD_TEST
# macro to set environment variables for each enabled sanitizer. This
# allows us to specify default behaviour of our sanitizers
# (suppressions extra diagnostic info etc.).
if(CB_SANITIZERS)
    function(ADD_TEST name)
        if(${ARGV0} STREQUAL "NAME")
            set(_name ${ARGV1})
        else()
            set(_name ${ARGV0})
        endif()
        _ADD_TEST(${ARGV})
        add_sanitizer_env_vars_memory(${_name})
        add_sanitizer_env_vars_thread(${_name})
        add_sanitizer_env_vars_undefined(${_name})
    endfunction()
endif()