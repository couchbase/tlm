# Locate Google gflags library
# This module defines the targe
#  GLOG_LIBRARIES, Library path and libs
#  GLOG_INCLUDE_DIR, where to find the headers

set(gflags_ROOT ${CMAKE_BINARY_DIR}/tlm/deps/gflags.exploded)
find_package(gflags COMPONENTS static)
