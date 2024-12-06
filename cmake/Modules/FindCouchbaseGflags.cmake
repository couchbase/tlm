set(gflags_ROOT ${CMAKE_BINARY_DIR}/tlm/deps/gflags.exploded)

find_package(gflags REQUIRED)
if(gflags_FOUND)
    message(STATUS "Found gflags at: ${gflags_DIR}")
endif()
