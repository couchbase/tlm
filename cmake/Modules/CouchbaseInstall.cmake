# Functions for installing targets and their dependencies.

if (NOT CouchbaseInstall_INCLUDED)

  # Read list of files in install_funclib directory.
  file (
    GLOB funclib_files CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_LIST_DIR}/install_funclib/*.cmake"
  )

  include (ParseArguments)

  # Helper function to add install-time CMake code, which may make use
  # of CMake functions defined in `install_funclib` cmake scripts. This
  # arranges for all the install_funclib `.cmake` scripts to be
  # include()d from any subdirectory level, so that eg. `make install`
  # from a subdirectory can still work.
  #
  # Required arguments:
  #
  #  CODE - cmake code to run at install time
  #
  # Optional arguments:
  #
  #  COMPONENTS - a list of install components. If specified, the CODE
  #  will be marked EXCLUDE_FROM_ALL and only run for the given
  #  component.
  function (cb_install_code)
    parse_arguments(Code "CODE" "FUNCTIONS;COMPONENTS" "" ${ARGN})
    if (NOT Code_CODE)
      message(FATAL_ERROR "CODE is required!")
    endif ()

    # See if we've already included the funclib code for this directory.
    get_property (_funclib_included DIRECTORY . PROPERTY cb_funclib_included)
    if (NOT _funclib_included)
      # If not, include all the funclib files in this directory. Use
      # ALL_COMPONENTS so the functions are available regardless of the
      # component being installed.
      foreach (_file ${funclib_files})
        install (SCRIPT "${_file}" ALL_COMPONENTS)
      endforeach (_file)
    endif ()
    set_property (DIRECTORY . PROPERTY cb_funclib_included 1)

    if (Code_COMPONENTS)
      # If COMPONENTS is specified, mark the code as EXCLUDE_FROM_ALL
      # and only run it for the given components.
      install(CODE "${Code_CODE}" EXCLUDE_FROM_ALL COMPONENT ${Code_COMPONENTS})
    else ()
      # Add the code to the default component (ie, no COMPONENT argument).
      install(CODE "${Code_CODE}")
    endif ()

  endfunction (cb_install_code)

  # Installs the runtime dependencies of a target.
  #
  # Required arguments:
  #
  #   TARGET - name of an existing target. The target must be either a
  #   standard ADD_EXECUTABLE() or ADD_LIBRARY(SHARED) target.
  function (_install_target_deps)

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
    # to the DLLs for each of the dependencies of the `magma_shared`
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
        "${TLM_DEPS_DIR}/libsodium.exploded/bin"
        "${TLM_DEPS_DIR}/openssl.exploded/bin"
        "${TLM_DEPS_DIR}/snappy.exploded/bin"
        "${TLM_DEPS_DIR}/zstd-cpp.exploded/bin"
      )
    endif ()

    # Pass the paths to DLLs that CMake knows about from imported targets
    cb_install_code (
      CODE "cb_install_deps(${_binary} ${_install_type} ${CMAKE_INSTALL_PREFIX} $<TARGET_RUNTIME_DLL_DIRS:${Ins_TARGET}> ${_deps_dirs})"
    )

  endfunction(_install_target_deps)

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
      _install_target_deps(TARGET ${_target})
    endforeach (_target)

  endfunction(InstallWithDeps)

  set(CouchbaseInstall_INCLUDED 1)
endif (NOT CouchbaseInstall_INCLUDED)
