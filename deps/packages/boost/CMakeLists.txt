# Downloads the declared version of boost source code and builds it.

include(ExternalProject)

### Download, configure and build boost ####################################
### Currently this is just a subset of boost, header-only libraries ########
### Multiple sub-modules of boost are checked out #########################

ExternalProject_Add(boost
  GIT_REPOSITORY git://github.com/couchbasedeps/boost_intrusive
  GIT_TAG boost-1.62.0

  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/boost/
          COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/boost/ <INSTALL_DIR>/include/boost/
)

# Now any other repositories from boostorg (note forked into couchbasedeps)
SET(boost_repos
  assert
  config
  core
  detail
  functional
  math
  move
  mpl
  optional
  preprocessor
  static_assert
  throw_exception
  type_index
  type_traits
  utility
  variant)

FOREACH(boost_repo ${boost_repos})

  ExternalProject_Add(${boost_repo}
    GIT_REPOSITORY git://github.com/couchbasedeps/boost_${boost_repo}
    GIT_TAG boost-1.62.0

    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/boost/
            COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include/boost/ <INSTALL_DIR>/include/boost/
  )

ENDFOREACH()

add_dependencies(boost ${boost_repos})

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
