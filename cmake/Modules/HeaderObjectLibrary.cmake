#
# add_header_object_library(): Compile a set of (C++) header files
# into an Object library.
#
# Motivation:
#
# This isn't normally possible in CMake (any headers defined as
# dependancies on a target are ignored in terms of what it built), but
# in two specific situations it can be useful to have CMake actually
# compile a header:
#
# 1. To verify that header have all required #include directives
#
# All header files _should_ be standalone - i.e. they include all
# headers they rely on. However headers arn't (usually) compiled
# directly, but as part of a source file. Therefore if a header
# 'foo.h' requires 'required.h' but omits #including it itself, as
# long as all source files which include 'foo.h' have already included
# 'required.h' then the build will succeed.
#
# This is all fine and well until a new consumer of foo.h is added
# which doesn't already include 'required.h' - the developer will see
# a confusing build error in foo.h (which they likely never changed).
#
# While tools exist (e.g. include-what-you-use) which attempt to
# detect and fix such issues, they can be hard to get working 100%
# correctly in large codebases (like ours). Instead, if one compiles
# every header file by itself we verify there are no missing headers -
# we'll see the lack of '#include <required.h>' when we attempt to
# compile foo.h.
#
# 2. To determine how costly a header is to compile.
#
# (This is the primary motivation for adding this function).  Large
# C++ codebases can quickly have their build-times mushroom, and a
# primary source of compile-time is the cost of #including headers,
# including the headers own dependencies. However it can be hard to
# directly determine the cost of building a header, given they are
# normally compiled indirectly as part of a .cc file - is a particular
# .cc file slow to build because of the code in that file itself, or
# in it's dependant headers?
#
# To answer this question we can compile each header by itself, and
# then look at the compilation time.
#
#
# Usage:
#
# add_header_object_library(
#     NAME <target_name>
#     HEADERS <headers...>
# )
#
# This will define an object library NAME, which consists of the
# specified list of headers.
#
# The object library isn't expected to be linked against - it exists
# only for the above two reasons, so the headers get compiled. As such
# the target will be excluded from the 'all' target - to build it one
# must explicilty specify that target to be build.

# To convince CMake to actually compile the headers, we symlink each
# specified header to <headerh>.cc; so CMake treats it as a C++ source
# file.
#
function(add_header_object_library)
  set(oneValueArgs NAME)
  set(multiValueArgs HEADERS)
  cmake_parse_arguments(arg "" "${oneValueArgs}"
    "${multiValueArgs}" ${ARGN})

  # CMake ignores files it considers headers from any list of files to
  # compile. To workaround this, create a symlink with the '.cc' suffix
  # for each found header; and use the symlinks as the list of files to
  # compile.
  foreach(_path ${arg_HEADERS})
    set(_header_cc ${CMAKE_CURRENT_BINARY_DIR}/${_path}.cc)

    add_custom_command(OUTPUT ${_header_cc}
      COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_CURRENT_SOURCE_DIR}/${_path} ${_header_cc}
      DEPENDS ${_path}
      )
    list(APPEND _headers_cc ${_header_cc})

    # As we have effecitively relocated the header file from its
    # original source-side to the binary-side; relative #include
    # (e.g. #include "foo.h") which reside in the same directory as
    # the header may not work (if that directory was not otherwise on
    # the include path). As such; explicitly add the directory the
    # header resides in to the INCLUDE_DIRECTORIES of the .h.cc
    # 'source' file.
    get_filename_component(_directory
      ${CMAKE_CURRENT_SOURCE_DIR}/${_path} DIRECTORY)
    set_source_files_properties(${_header_cc} PROPERTIES
      INCLUDE_DIRECTORIES "${_directory}")
  endforeach()

  add_library(${arg_NAME} OBJECT ${_headers_cc})
  # Given we are directly compiling headers, this generates spurious warnings
  # as we're reading headers as .CC. Disable these to quieten
  # the build.
  set_target_properties(${arg_NAME} PROPERTIES
    COMPILE_FLAGS
    "-Wno-pragma-once-outside-header -Wno-unused-const-variable -Wno-unused-function")

  # We don't actually want to build these targets by default (given
  # they arn't actually used by any targets in normal build).
  set_target_properties(${arg_NAME} PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
