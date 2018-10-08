# Downloads the declared version of boost source code and builds it.

include(ExternalProject)

### Download, configure and build boost ####################################

if (WIN32)
   set(boost_bootstrap bootstrap.bat)
   set(boost_cxx_version "")
else (WIN32)
   set(boost_bootstrap bootstrap.sh)
   set(boost_cxx_version "cxxflags=-std=c++14")
endif (WIN32)

ExternalProject_Add(boost
  GIT_REPOSITORY git://github.com/boostorg/boost
  GIT_TAG ${_git_rev}
  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND <SOURCE_DIR>/${boost_bootstrap} --prefix=<INSTALL_DIR>
      --with-libraries=context,chrono,date_time,filesystem,program_options,regex,system,thread
  BUILD_COMMAND <SOURCE_DIR>/b2 --prefix=<INSTALL_DIR>
      ${boost_cxx_version}
      variant=release
      link=static
      threading=multi
      runtime-link=shared
      cxxflags=-fno-omit-frame-pointer
      cflags=-fno-omit-frame-pointer
      -j 4
      install
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  # CB Server and Folly (particulary) require most of Boost's submodules;
  # however there are few large modules we don't need - and hence don't want to
  # bloat the cbdeps with. Remove these before packaging up.
  INSTALL_COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/include/boost/asio
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/include/boost/fusion
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/include/boost/geometry
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/include/boost/hana
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/include/boost/phoenix
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/include/boost/spirit
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/include/boost/typeof
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
