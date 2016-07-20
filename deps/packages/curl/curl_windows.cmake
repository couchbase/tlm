# Downloads the declared version of libcurl source code and builds it.

include(ExternalProject)

IF ($ENV{target_arch} STREQUAL "x86")
  SET (CURL_MACHINE x86)
ELSE ()
  SET (CURL_MACHINE x64)
ENDIF ()

SET (OUTPUT_DIR "builds/libcurl-vc12-${CURL_MACHINE}-release-dll-ipv6-sspi-winssl")
SET (OBJLIB_DIR "${OUTPUT_DIR}-obj-lib")

### Download, configure and build curl ####################################
ExternalProject_Add(curl
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  # Bug in the Curl Windows build script if these directories are missing
  CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory "<SOURCE_DIR>/${OBJLIB_DIR}/vauth"
            COMMAND ${CMAKE_COMMAND} -E make_directory "<SOURCE_DIR>/${OBJLIB_DIR}/vtls"

  BUILD_COMMAND cd <SOURCE_DIR>/winbuild
        COMMAND nmake /f Makefile.vc mode=dll VC=12 MACHINE=${CURL_MACHINE} DEBUG=no GEN_PDB=yes

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory "<SOURCE_DIR>/${OUTPUT_DIR}" <INSTALL_DIR>
          COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY bin lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

