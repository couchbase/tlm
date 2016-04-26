# Downloads the declared version of the JSON library and package it.
# The JSON library is a "header only" library, so we don't need any
# building

include(ExternalProject)

if (CMAKE_MAJOR_VERSION GREATER 2)
  # make_directory appeared in 3.0
  ExternalProject_Add(json
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/install/include
    BUILD_COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/install/include/nlohmann
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/src/json.hpp ${CMAKE_CURRENT_BINARY_DIR}/install/include/nlohmann
            COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/LICENSE.MIT ${CMAKE_CURRENT_BINARY_DIR}/install/include/nlohmann

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install)
else()
  ExternalProject_Add(json
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}
    CONFIGURE_COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/install/include
    BUILD_COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/install/include/nlohmann
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/src/json.hpp ${CMAKE_CURRENT_BINARY_DIR}/install/include/nlohmann
            COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/LICENSE.MIT ${CMAKE_CURRENT_BINARY_DIR}/install/include/nlohmann

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install)
endif()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
