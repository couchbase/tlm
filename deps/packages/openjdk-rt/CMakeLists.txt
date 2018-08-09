# Downloads the OpenJDK rt.jar and packages it

include(ExternalProject)

ExternalProject_Add(openjdk-rt
    SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${CMAKE_COMMAND} -D OPENJDK_VER=${_dep_version} -D TARGET_DIR=<INSTALL_DIR> -P "${CMAKE_CURRENT_SOURCE_DIR}/dl_rt_jar.cmake"
    INSTALL_COMMAND ""

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
