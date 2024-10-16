# Functions for installing targets and their dependencies.

if (NOT CouchbaseInstall_INCLUDED)

  include (ParseArguments)

  # Load the helper functions into the install scripts.
  install(SCRIPT "${CMAKE_CURRENT_LIST_DIR}/cb_install_helper.cmake" ALL_COMPONENTS)

  # Installs the runtime dependencies of a target.
  #
  # Required arguments:
  #
  #   TARGET - name of an existing target. The target must be either a
  #   standard ADD_EXECUTABLE() or ADD_LIBRARY(SHARED) target.
  function (InstallDeps)

    parse_arguments(Ins "TARGET" "" "" ${ARGN})
    if (NOT Ins_TARGET)
      message(FATAL_ERROR "TARGET is required!")
    endif ()

    # Determine the target type
    get_target_property (_type ${Ins_TARGET} TYPE)
    if (_type STREQUAL "EXECUTABLE")
      set (_install_type EXECUTABLES)
    elseif (_type STREQUAL "SHARED_LIBRARY")
      set (_install_type LIBRARIES)
    else ()
      message(FATAL_ERROR "TARGET '${Ins_TARGET}' must be an executable or shared library!")
    endif ()
    set (_binary "$<TARGET_FILE:${Ins_TARGET}>")

    # MB-63898: Hack! Until we have proper "Modern CMake" IMPORTED
    # targets for each of these, we need to manually pass in the paths
    # to the DLLs for each of the depenedencies of the `magma_shared`
    # target (the only one using InstallWithDeps() so far). This is only
    # needed on Windows. Once they can all be removed, we can also drop
    # ${_deps_dirs} from the install(CODE) below.
    if (WIN32)
      set(TLM_DEPS_DIR "${CMAKE_BINARY_DIR}/tlm/deps")
      if (CMAKE_BUILD_TYPE STREQUAL Debug)
        set (_deps_dirs "${TLM_DEPS_DIR}/jemalloc.exploded/Debug/bin")
      else ()
        set (_deps_dirs "${TLM_DEPS_DIR}/jemalloc.exploded/Release/bin")
      endif ()
      list (APPEND _deps_dirs
        "${TLM_DEPS_DIR}/openssl.exploded/bin"
        "${TLM_DEPS_DIR}/snappy.exploded/bin"
        "${TLM_DEPS_DIR}/zstd-cpp.exploded/bin"
      )
    endif ()

    # Pass the paths to DLLs that CMake knows about from imported targets
    install (CODE "InstallDependencies(${_binary} ${_install_type} $<TARGET_RUNTIME_DLL_DIRS:${Ins_TARGET}> ${_deps_dirs})")

  endfunction(InstallDeps)

  # Installs targets with all their runtime dependencies.
  #
  # Required arguments:
  #
  #   TARGETS - names of existing targets. Each target must be either a
  #   standard ADD_EXECUTABLE() or ADD_LIBRARY(SHARED) target.
  function (InstallWithDeps)

    parse_arguments(Ins "" "TARGETS" "" ${ARGN})
    if (NOT Ins_TARGETS)
      message(FATAL_ERROR "TARGETS is required!")
    endif ()

    foreach (_target ${Ins_TARGETS})
      # Check the target type is appropriate
      get_target_property (_type ${_target} TYPE)
      if (NOT ( _type STREQUAL "EXECUTABLE" OR _type STREQUAL "SHARED_LIBRARY" ) )
        message(FATAL_ERROR "TARGET must be an executable or shared library!")
      endif ()

      # Install the target itself
      install (TARGETS ${_target})

      # Install the target's runtime dependencies
      InstallDeps(TARGET ${_target})
    endforeach (_target)

  endfunction(InstallWithDeps)

  set(CouchbaseInstall_INCLUDED 1)
endif (NOT CouchbaseInstall_INCLUDED)