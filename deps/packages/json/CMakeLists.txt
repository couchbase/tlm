# Downloads the declared version of the JSON library and package it.
# The JSON library is a "header only" library, so we don't need any
# building

include(ExternalProject)

ExternalProject_Add(json
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}

    CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
                      -D CMAKE_BUILD_TYPE=RelWithDebInfo
                      -D JSON_BuildTests=OFF
                      -D JSON_Install=ON
                      -D JSON_MultipleHeaders=ON
                      -D JSON_ImplicitConversions=ON
                      -D JSON_SystemInclude=ON

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
                      COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/pkgconfig)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
