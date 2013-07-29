#
# This is the toplevel CMakeLists.txt that is used to build Couchbase
#
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/tlm/cmake/Modules/")

INCLUDE(CouchbaseSingleModuleBuild)

# Add a quick (and safe) way to nuke everything
ADD_CUSTOM_TARGET(reset
                  COMMAND repo forall -c "git clean -dfx"
                  VERBATIM)

# Add the code itself
ADD_SUBDIRECTORY(libvbucket)
ADD_SUBDIRECTORY(memcached)
ADD_SUBDIRECTORY(libconflate)
ADD_SUBDIRECTORY(couchstore)
ADD_SUBDIRECTORY(libmemcached)
ADD_SUBDIRECTORY(ep-engine)
