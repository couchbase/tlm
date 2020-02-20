# Downloads the declared version of boost source code and builds it.

include(ExternalProject)

### Download, configure and build boost ####################################

if (WIN32)
   set(boost_bootstrap bootstrap.bat)
   set(boost_extra_flags "")
   set(boost_variant "debug,release")
else (WIN32)
   set(boost_bootstrap bootstrap.sh)
   set(boost_extra_flags cxxflags=-std=c++17 cflags=-fno-omit-frame-pointer cxxflags=-fno-omit-frame-pointer cxxflags=-fPIC)
   set(boost_variant "release")
endif (WIN32)

ExternalProject_Add(boost
  GIT_REPOSITORY git://github.com/boostorg/boost
  GIT_TAG ${_git_rev}
  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND <SOURCE_DIR>/${boost_bootstrap} --prefix=<INSTALL_DIR>
      --with-libraries=context,chrono,date_time,filesystem,program_options,regex,system,thread
  BUILD_COMMAND <SOURCE_DIR>/b2
      -j 4
      --prefix=<INSTALL_DIR>
      address-model=64
      ${boost_extra_flags}
      link=static
      runtime-link=shared
      threading=multi
      variant=${boost_variant}
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
