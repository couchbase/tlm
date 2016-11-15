# Downloads the declared version of boost source code and builds it.

include(ExternalProject)

### Download, configure and build boost ####################################
ExternalProject_Add(boost
  #GIT_REPOSITORY ${_git_repo_intrusive}
  GIT_REPOSITORY https://github.com/boostorg/intrusive  
  #GIT_TAG ${_git_rev}
  GIT_TAG boost-1.62.0

  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/boost/
          COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/boost/ <INSTALL_DIR>/include/boost/
)

ExternalProject_Add(boost_move
  #GIT_REPOSITORY ${_git_repo_move}
  GIT_REPOSITORY https://github.com/boostorg/move
  #GIT_TAG ${_git_rev}
  GIT_TAG boost-1.62.0

  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/boost/
          COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/boost/ <INSTALL_DIR>/include/boost/
)

ExternalProject_Add(boost_config
  #GIT_REPOSITORY ${_git_repo_config}
  GIT_REPOSITORY https://github.com/boostorg/config
  #GIT_TAG ${_git_rev}
  GIT_TAG boost-1.62.0

  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/boost/
          COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/boost/ <INSTALL_DIR>/include/boost/
)

ExternalProject_Add(boost_assert
  #GIT_REPOSITORY ${_git_repo_assert}
  GIT_REPOSITORY https://github.com/boostorg/assert
  #GIT_TAG ${_git_rev}
  GIT_TAG boost-1.62.0

  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/boost/
          COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/boost/ <INSTALL_DIR>/include/boost/
)

ExternalProject_Add(boost_static_assert
  #GIT_REPOSITORY ${_git_repo_static_assert}
  GIT_REPOSITORY https://github.com/boostorg/static_assert
  #GIT_TAG ${_git_rev}
  GIT_TAG boost-1.62.0

  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/boost/
          COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/boost/ <INSTALL_DIR>/include/boost/
)

ExternalProject_Add(boost_core
  #GIT_REPOSITORY ${_git_repo_core}
  GIT_REPOSITORY https://github.com/boostorg/core
  #GIT_TAG ${_git_rev}
  GIT_TAG boost-1.62.0

  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/boost/
          COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/boost/ <INSTALL_DIR>/include/boost/
)
add_dependencies(boost boost_move boost_config boost_assert boost_static_assert boost_core)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
