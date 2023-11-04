# Specific logic for building Faiss

# So far only Linux builds of faiss are supported, so only set the flag
# there by default. On Mac, run with "cmake -DCB_BUILD_FAISS=ON" to have
# it attempt to build faiss (requires LLVM from Homebrew).
IF (NOT EXISTS "${PROJECT_SOURCE_DIR}/faiss")
  SET (CB_BUILD_FAISS OFF CACHE BOOL "Whether to include Faiss in the build" FORCE)
ELSE ()
  IF (UNIX AND NOT APPLE)
    SET (_cb_build_faiss ON)
  ELSE ()
    SET (_cb_build_faiss OFF)
  ENDIF ()
  SET (CB_BUILD_FAISS ${_cb_build_faiss} CACHE BOOL "Whether to include Faiss in the build")
  IF (NOT BUILD_ONLY_TOOLS AND CB_BUILD_FAISS)
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

    # Faiss also handles the c_api headers all wrong. It doesn't set
    # target_include_directories(), and worse, the headers don't exist
    # in git in the right place - it's assumed they're in a directory
    # named "faiss/c_api", which they aren't. However, since our manifest
    # happens to put the faiss source into a directory named "faiss", we
    # can hack around it by setting the top of the repo sync itself as the
    # include_directory.
    TARGET_INCLUDE_DIRECTORIES (faiss_c PUBLIC
      $<BUILD_INTERFACE:${faiss_SOURCE_DIR}/..>)

    # Faiss also neglects to install() libfaiss_c
    INSTALL (TARGETS faiss_c
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )

    # Restore original CMake options
    SET (BUILD_TESTING ${_curr_build_testing})
    SET (BUILD_SHARED_LIBS ${_curr_build_shared_libs})
  ENDIF()
ENDIF ()
