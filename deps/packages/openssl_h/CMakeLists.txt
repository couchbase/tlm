include(ExternalProject)

ExternalProject_Add(openssl_h
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/openssl/
          COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/openssl/ <INSTALL_DIR>/include/openssl/
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
