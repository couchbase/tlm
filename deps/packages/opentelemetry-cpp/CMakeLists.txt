include(ExternalProject)

set(_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
set(_opentelemetry_deps_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
set(CMAKE_INSTALL_PREFIX "${_opentelemetry_deps_install}")
DECLARE_DEP (json VERSION 3.9.0-cb1 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (boost VERSION 1.74.0-cb1 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)
DECLARE_DEP (curl V2 VERSION 7.78.0 BUILD 3 PLATFORMS linux macosx windows_msvc2017)
DECLARE_DEP (grpc VERSION 1.28.1-cb1 PLATFORMS windows_msvc2017)
DECLARE_DEP (grpc VERSION 1.28.1-cb2 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04)
DECLARE_DEP (zlib V2 VERSION 1.2.11 BUILD 7 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04 windows_msvc2017)

set(CMAKE_INSTALL_PREFIX ${_orig_install_prefix})

### Download, configure and build libevent ####################################
ExternalProject_Add(opentelemetry-cpp
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D CMAKE_INSTALL_LIBDIR=lib
             -D CMAKE_BUILD_TYPE=RelWithDebInfo
             -D CMAKE_FIND_PACKAGE_PREFER_CONFIG=true
             -D BUILD_TESTING=OFF
             -D BUILD_SHARED_LIBS=OFF
             -D WITH_EXAMPLES=OFF
             -D WITH_OTLP=ON
             -D WITH_OTLP_GRPC=OFF
             -D WITH_OTLP_HTTP=ON
             -D nlohmann_json_ROOT=${CMAKE_CURRENT_BINARY_DIR}/json.exploded/
             -D CURL_ROOT=${CMAKE_CURRENT_BINARY_DIR}/curl.exploded
             -D gRPC_ROOT=${CMAKE_CURRENT_BINARY_DIR}/grpc.exploded
             -D Protobuf_ROOT=${CMAKE_CURRENT_BINARY_DIR}/grpc.exploded
             -D PROTOBUF_PROTOC_EXECUTABLE=${CMAKE_CURRENT_BINARY_DIR}/grpc.exploded/bin/protoc
             -D ZLIB_ROOT=${CMAKE_CURRENT_BINARY_DIR}/zlib.exploded

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND git submodule update --recursive --init
                  COMMAND ${CMAKE_COMMAND} --build . --target install
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/pkgconfig
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
